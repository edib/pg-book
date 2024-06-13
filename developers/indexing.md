# INDEKSLER

* İndeksler, veritabanı performansını arttırmak için kullanılan önemli nesnelerdendir.İndeks olan bir alanda arama yapıldığı zaman indeksler, aramanın çok daha hızlı sonuçlanmasını ve istenilen bilgiye ulaşılmasını sağlar.
* Gereksiz indeks kullanımı veritabanı performansını olumsuz etkiler. Ayrıca indeksler fiziksel yer kapladıkları için gereksiz indekslerin bir de depolama maliyeti olacaktır.
* Küçük tablolar, büyük parti **INSERT** ve **UPDATE** olan tablolar ve çok fazla NULL içeren kolonların olduğu durumlarda indeks oluşturmamak daha iyi olacaktır.


## İndeks Oluşturmak

Indeks **CREATE INDEX** komutu ile oluşturulur.

###Parametreleri :

**UNIQUE** : Var olan tablo için oluşturuluyorsa önce verilerin tekilliğini kontrol eder. Verinin benzersiz olmasını sağlar.
**CONCURRENTLY** : Fazla veri içeren tabloya index eklenmek istenildiğinde tablo index oluşumu sırasında kilitlenir ve işlem yapılamaz. Bunu önlemek için kullanılır.
**USING** (metod) : indeksin hangi methodu kullanacağı burada belirtilir.btree, hash, gist, spgist ve brin metotlarından biri seçilebilir.

**CREATE INDEX** söz dizisinin en basit hali :
```
CREATE INDEX index_adi ON tablo_adi (kolon_ adi)
```
*Bu şekilde oluşturulan indexin B-tree olur varsayılan olarak*

* Çoklu kolonlu index oluşturma :

```sql
  CREATE INDEX index_adi ON tablo_adi USING btree (kolon_adi1,kolon_adi2,kolon_adi3);
```

```sql

CREATE TABLE musteri (
    musteri_id SERIAL PRIMARY KEY,
    ad VARCHAR(100),
    soyad VARCHAR(100),
    dogum_tarihi DATE,
    aktif bit null
);

-- Rastgele adlar ve soyadlar oluşturmak için örnek isimler
WITH generated_data AS (
    SELECT 
        generate_series('1990-01-01'::date, '2001-12-31'::date, '1 day') AS dogum_tarihi,
        (ARRAY['Ahmet', 'Mehmet', 'Ayşe', 'Fatma', 'Ali', 'Veli', 'Zeynep', 'Can'])[floor(random() * 8 + 1)] AS ad,
        (ARRAY['Yılmaz', 'Kara', 'Demir', 'Çelik', 'Arslan', 'Aydın', 'Polat', 'Korkmaz'])[floor(random() * 8 + 1)] AS soyad, 
        (ARRAY['0','1'])[floor(random() * 2 + 1)]::bit AS aktif
)
-- Veriyi tabloya ekleme
INSERT INTO musteri (ad, soyad, dogum_tarihi, aktif)
SELECT ad, soyad, dogum_tarihi, aktif
FROM generated_data;

```

```sql
INSERT INTO foo (id, name) SELECT i, 'foo ' || i::text FROM generate_series(1, 500000) i;
```

* Doldurduğumuz tablo üzerinde **SELECT** sorgusu çalıştırdığımız zaman:

```sql
postgres=# EXPLAIN SELECT name FROM foo ;
                       QUERY PLAN                        
---------------------------------------------------------
 Seq Scan on foo  (cost=0.00..771.00 rows=500000 width=9)
(1 row)
```

* foo tablosu üzerindeki tüm *name*'leri **sequential scan** yaparak baştan sona select etmiş olduk.Peki eğer spesifik bir satırı *select* etmek isteseydik?

```sql
postgres=# EXPLAIN SELECT name FROM foo WHERE id=526;
                     QUERY PLAN                      
-----------------------------------------------------
 Seq Scan on foo  (cost=0.00..896.00 rows=1 width=9)
   Filter: (id = 526)
(2 rows)
```

* Tekrar  **sequential scan** kullanıldı. Bu aslında bir problem olarak görülebilir çünkü bir sadece bir satırı isterken burada tüm satırları en tepeden tarıyor ve id'si 526 olan satırı bulmaya çalışıyoruz. Küçük boyutlu tablolar için bir problem olarak görülmesede eğer elimizde milyonlarca satır olan bir tablo üzerinde yapmış olsaydık istenilen satırı select etmek çok uzun süre alacaktı.  

* PostgreSQL tablolarında *explicitly* select ettiğimiz kolon(ctid) vardır. Bu kolonu görmek için:

```sql

postgres=# SELECT ctid, * FROM foo ;
   ctid    |  id   |   name    
-----------+-------+-----------
 (0,1)     |     1 | foo 1
 (0,2)     |     2 | foo 2
 (0,3)     |     3 | foo 3
 (0,4)     |     4 | foo 4
 (0,5)     |     5 | foo 5
 (0,6)     |     6 | foo 6
 --More--
```

Yukarıda fiziksel konumunu bulduğumuz tablomuz aslından default 8K'lık *page*'ler olarak tutulur. Datalar bu 8K'lık *page*'ler içerisinde tutulur. *Explicitly* olarak tutulan **ctid** aslında bu pagelerdeki satırların yerini ifade eder. **ctid** değerindeki ilk column block(page) number, ikinci column ise offset(Tuple)'ı ifade eder.

Aslında SELECT işlemlerimde bu dosya ctid değerlerini sequential olarak tarıyoruz. Milyonlarca tuble içeren bir tablo(heap) üzerinde SELECT ile istenilen bir tuble'ı seçmeyi düşünürsek performans açısından kayıplar yaşamamız muhtemel.

## Neden İndeksleme?

Bir kitap içerisinde istenilen kelimeyi bulmaya çalışalım, bunun ne kadar zor ve zaman gerektiren bir durum olduğunu anlayabiliriz. Tüm kitabı baştan sona aranılan kelimeyi bulmak için taramak mantıksızdır. PostgreSQL'de de istenilen tuble'ı bulmaya çalışmayı buna benzetebilir. Bu sorunu **INDEX**'leri kullanarak aşabilir.**INDEX**'leri kullanarak hız anlamında büyük kazanç sağlayabiliriz ama başta söylediğimi gibi indexler fiziksel olarak yer kapladığı için diskten fedakarlık yapmamız gerekir.

```sql
EXPLAIN SELECT name FROM foo WHERE id= 4896;
                               QUERY PLAN                               
------------------------------------------------------------------------
 Gather  (cost=1000.00..196832.24 rows=1 width=11)
   Workers Planned: 2
   ->  Parallel Seq Scan on foo  (cost=0.00..195832.14 rows=1 width=11)
         Filter: (id = 4896)
(4 rows)
```

```sql
CREATE INDEX foo_idx ON foo (id);
```

```sql
EXPLAIN SELECT name FROM foo WHERE id= 4896;
                             QUERY PLAN                             
--------------------------------------------------------------------
 Index Scan using foo_idx on foo  (cost=0.43..8.45 rows=1 width=11)
   Index Cond: (id = 4896)
(2 rows)
```

foo tablosunun üzerinde id alanını indexledikten sonra search işleminin total costuna bakarak Sequential scan'a göre  Index Scan'ın hızlı olduğunu söyleyebiliriz.
Tıpkı Table'larada olduğu gibi Index'lerde dosyalarda tutulur. Bu dosyanın ismine bakacak olursak :

```sql
SELECT relfilenode FROM pg_class WHERE relname LIKE 'foo_idx';
 relfilenode
-------------
       24581
(1 row)
```

* **pg_class** : PostgreSQL's Catalog for relations/Index.
* **24581** : Physical file name of the index.
* PostgreSQL index has its own file on disk.

```bash
#-bash-4.2$ ls -lrth /var/lib/pgsql/11/data/base/13025/24581
-rw------- 1 postgres postgres 108M Jul  4 08:20 /var/lib/pgsql/11/data/base/13025/24581
```

* Planner ver Optimizer bir tablo üzerinde birden fazla index oluşturduğumuzda hangisinin seçileceğine karar verir.
* PostgreSQL Index oluştururken tabloları *lock*'lar yani herhangi bir alanı modify etmek istersek, index oluşana kadar başarısız olacaktır.
* **CREATE INDEX CONCURRENTLY** ile Index oluşturulana kadar **INSERT** ve **UPDATE** işlemlerini sorunsuz gerçekleştirebiliriz ancak index oluşturulma zamanıda indexlenen veri boyutuna göre artar.

```sql
CREATE INDEX idx_btree ON foo USING BTREE(id);
CREATE INDEX
Time: 5550.213 ms (00:05.550)
```

* **CONCURRENTLY** opsiyonu index oluştururken tabloyu locklamaz.

```sql
CREATE INDEX CONCURRENTLY idx_btree ON foo USING BTREE(id);
CREATE INDEX
Time: 6511.691 ms (00:06.512)
```

* Index **CONCURRENTLY** opsiyonu ile create edildiğinde oluşturulma zamanı artar.

```sql
CREATE INDEX CONCURRENTLY index_adi ON tablo_adi (kolon_adi,kolon_adi2)
```

* Index silmek için **DROP INDEX** ifadesi kullanılır.

### Tekil INDEX (UNIQUE INDEX) 
Bu tür indexler sadece performans için değil, aynı zamanda veri bütünlüğünü sağlamak içinde kullanılır. Verilen kolon veya kolonların içerdiği verilerin tablo içinde benzersiz olarak tutulmasını sağlar.

```sql
CREATE UNIQUE INDEX index_adi ON tablo_adi (kolon_adi);
```

* Dahili Index ( Implicit Index ) : Birincil anahtar (primary key) ve benzersiz (unique) kısıtlamaları için indexler otomatik oluşturulur.
* Zamanlı Index (Concurrent Index): Index oluştururken, index oluşacak oluşacak tabloda bir lock. Bu durumda tablo üzerinde işlem yapılamaz. Bu durumlarda indexin tablo üzerinde bir lock oluşturmadan yapılabilmesi için **CONCURRENT** ifadesi kullanılır.



## EXPRESSION INDEX

*name* kolonundan bir ismi bulmaya çalışan bir sorgu olduğunu varsayalım ancak bu sefer name kolonunu yerine lower name expression kolonunu kullanalım.

```sql
EXPLAIN SELECT * FROM foo WHERE lower(name) LIKE 'foo 25589';
                                 QUERY PLAN                                 
----------------------------------------------------------------------------
 Gather  (cost=1000.00..204507.77 rows=24894 width=15)
   Workers Planned: 2
   ->  Parallel Seq Scan on foo  (cost=0.00..201018.37 rows=10372 width=15)
         Filter: (lower(name) ~~ 'foo 25589'::text)
(4 rows)
```

* büyük / küçük harf duyarlı olmayan karşılaştırmalar yapmak için *lower* fonksiyonu kullanılır.  
* lower(name) kolonu üzerine index oluşturalım:

```sql

CREATE INDEX foo_expression_idx ON foo  (lower(name) );
```
EXPLAIN SELECT * FROM foo WHERE lower(name) LIKE 'foo 25589';
                                 QUERY PLAN                                 
----------------------------------------------------------------------------
 Bitmap Heap Scan on foo  (cost=582.18..68241.31 rows=25000 width=15)
   Filter: (lower(name) ~~ 'foo 25589'::text)
   ->  Bitmap Index Scan on idx_exp  (cost=0.00..575.93 rows=25000 width=0)
         Index Cond: (lower(name) = 'foo 25589'::text)
(4 rows)
```

* Burada *name* kolununu index olarak kullanmadık bunun yerine lower(name) expression kolonu index olarak kullanıldı.

## PARTIAL INDEX

Bazı durumlarda tüm tabloyu indexlememize gerek olmayabilir. Mesela oluşturduğumuz tabloda sadece *id* değeri 10000'den küçük değerler üzerinde işlem yoğunluğumuz varsa burada tüm tabloyu indexlemeye ihtiyaç duymayabiliriz. Çok fazla data içeren tablolarda daha önemli olan kısımları indexleyerek disk alanından tasarruf edebiliriz.

```sql
create index idx_part on foo(id) where id < 10000;
CREATE INDEX

explain select * from foo where id < 1000 and name like 'foo 326';
                              QUERY PLAN                              
----------------------------------------------------------------------
 Index Scan using idx_part on foo  (cost=0.29..69.06 rows=1 width=15)
   Index Cond: (id < 1000)
   Filter: (name ~~ 'foo 326'::text)
(3 rows)
```

* Oluşturduğumuz indexlerin boyutlarını karşılaştıracak olursak:

```sql
SELECT pg_size_pretty(pg_total_relation_size('idx_full'));
 pg_size_pretty
----------------
 107 MB
(1 row)
```

```sql
SELECT pg_size_pretty(pg_total_relation_size('idx_part'));
 pg_size_pretty
----------------
 240 kB
(1 row)
```
## [ B-Tree ](http://www.bilisim-kulubu.com/sozluk/sozluk.php?e=B+Tree&from[]=BTree) INDEX

* Index türü belirtilmediğinde default olarak B-tree index kullanılır.

**Desteklediği operatörler:**

* küçüktür <
* küçük eşittir <=
* eşittir  =
* büyük eşittir >=
* büyüktür >

```sql
CREATE INDEX idx_btree ON foo USING BTREE(name);
```
* Oluşturduğumuz **foo** tablosunda explicitly olarak **ctid** kolonunun varlığından, ilk değerin *page number* ikinci değerin ise *tuple ID* olduğundan daha önce bahsetmiştik.

```sql
SELECT ctid, * FROM foo ;
   ctid    |  id   |   name    
-----------+-------+-----------
 (0,1)     |     1 | foo 1
 (0,2)     |     2 | foo 2
 (0,3)     |     3 | foo 3
 --More--
```

**ctid(0,2)** page 0 , 2. tuple denilebilir ve **foo 2**'nin yerini point eder.

## HASH INDEX

* Hash daha çok equality operatorü ele alır ve sortable değildir.
* 10 dan önce Hash index kullanılması genellikle önerilmez. Transactional değildi ve Raplikasyonla taşınmazdı. Equality operatöründe bile B-tree daha iyi sonuçlar verebilmektedir. Daha az yer kaplar.


```sql
CREATE INDEX idx_hash ON foo USING HASH (name);
```

## BRIN INDEX (Block Range Index)

* Büyük veriler için anlamlıdır. BRIN  datalar arasında bağlantı olduğu(tarihler vb.) zaman kullanılması uygundur.
* BRIN index sadece :
  * Page number
  * Min value of column
  * Max value of column

tuttuğu için fiziksel alan bakımından en avantajlı olan türdür.

```sql
CREATE INDEX idx_btree ON foo USING BTREE(date); // Size of index = 21 MB
CREATE INDEX idx_hash ON foo USING HASH (date);  // Size of index = 47 MB
CREATE INDEX idx_brin ON foo USING BRIN (date); // Size of index = 48 KB
```

## GIN Index (Generalized Inverted indexes) [+](https://hashrocket.com/blog/posts/exploring-postgres-gin-index)

* Composite değerlere index eklemek istediğimizde B-tree kullanamayız. Örneğin elimizde isim,telefon numrası, TC kimlik no bilgilerini tutan JSONB veri tipinde bir kolon ve bu kolonun sadece TC kimlik no kısmına index eklemek istenildiğinde **GIN Index** kullanılması daha verimli olacaktır. tsvector, jsonb de kullanılır.


```sql
CREATE TABLE users (
    first_name text,
    last_name text
);

INSERT INTO users (first_name, last_name)
SELECT 
    md5(random()::text), 
    md5(random()::text)
FROM 
    generate_series(1, 1000000) AS id;

explain analyze SELECT count(*) FROM users where first_name ilike '%505%';        

explain analyze SELECT count(*) FROM users where first_name ilike '%aeb%' or last_name ilike'%aeb%';

CREATE INDEX users_search_idx ON users USING gin (first_name gin_trgm_ops, last_name gin_trgm_ops);

-- boyutlarına bakalım
-- tablo için
SELECT
    pg_size_pretty (pg_relation_size('users')) size;


SELECT
    pg_size_pretty (pg_relation_size('users_search_idx')) size;

```

## GIST INDEX (Generalized Search Tree)

### GIS

```sql
-- PostGIS uzantısını etkinleştirme
CREATE EXTENSION postgis;

-- Coğrafi veri içeren bir tablo oluşturma
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    location GEOMETRY(Point, 4326)  -- WGS 84 koordinat sistemi
);

-- GiST indeksi oluşturma
CREATE INDEX idx_locations_gist ON locations USING GIST (location);


```

### Tam Metin Arama

```sql
-- Aralık veri türlerini içeren bir tablo oluşturma
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_name VARCHAR(100),
    event_time TSRANGE  -- Time range
);

-- GiST indeksi oluşturma
-- GiST indeksi oluşturma
CREATE INDEX events_gist_idx ON events USING GIST (event_time);
CREATE INDEX events_hash_idx ON events USING HASH (event_time); 
CREATE INDEX events_btree_idx ON events (event_time); 

-- boyutlarına bakalım
SELECT
    pg_size_pretty (pg_relation_size('idx_events_gist')) size;

-- Örnek verileri ekleme
INSERT INTO events (event_name, event_time) VALUES
('Conference', '[2024-06-01 09:00, 2024-06-01 17:00)'),
('Meeting', '[2024-06-02 10:00, 2024-06-02 12:00)');

-- Belirli bir tarihte geçen tüm etkinlikleri bulma
explain analyze SELECT * FROM events 
WHERE event_time && '[2024-06-01 12:00, 2024-06-01 13:00)';

```

### Aralık Arama

```sql
-- Tam metin arama için bir tablo oluşturma
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT
);

-- GiST indeksi oluşturma
CREATE INDEX idx_documents_gist ON documents USING GIST (to_tsvector('english', content));

-- Örnek verileri ekleme
INSERT INTO documents (content) VALUES 
('PostgreSQL supports full-text search through GiST indexes.'),
('Generalized Search Trees are versatile and powerful.');

-- Tam metin arama yapma
SELECT * FROM documents 
WHERE to_tsvector('english', content) @@ to_tsquery('english', 'powerful');


```
### ltree

https://www.cybertec-postgresql.com/en/postgresql-ltree-vs-with-recursive/

https://stackoverflow.com/questions/63363408/why-in-ltree-example-in-postgresql-documentation-the-author-has-created-two-ind

## index sıralama

```sql
CREATE INDEX articles_published_at_index ON articles(published_at DESC NULLS LAST);
```

## WHERE and WHAT?

* **B-Tree INDEX** : Farklı data tipleri.(common)
* **HASH INDEX** : Eşitlik operetörü.
* **BRIN** : Büyük sıralı ve arasında ilişki olan datasetler. (correlation with physical disk)
* **GIN**  : Documents ve Arrays.
* **GIST** : Full text search.

### **Kullanılmayan İndexler**:

* Zamanla birden çok index oluşturur ve bunları silmeyi unutabilir, istediğimiz performansı alamayabilir veya daha iyi bir index kurabiliriz.
* Bu gibi durumlarda hangi index'e ihtiyacımız olduğunu görebilmek için :

```sql
SELECT relname, indexrelname,idx_scan FROM pg_catalog.pg_stat_user_indexes;

 relname | indexrelname  | idx_scan
---------+---------------+----------
 foo     | idx_btree_ios |        2
 foo     | foo_idx       |        0
 foo     | idx_btree     |        0
 foo     | idx_part      |        4
 foo     | idx_full      |        6
(5 rows)

```

* Görüldüğü gibi hiç kullanılmayan indexlerimiz mevcut. Disk alanını verimli kullanmak için gereksiz indexleri silebiliriz.


## INDEX ONLY SCANS

* Index oluşturunca asıl tablomuzdan ayrı bir şekilde tutulduğundan daha önce bahsetmiştik.
* Normal bir sorguda hem asıl tablo(Heap) hemde index taranması gerekir.
* Eğer *WHERE* komutuyla almak istediğimiz kısım zaten index içinde varsa tablomuza gitmeye gerek kalmaz. Bu durumda PostgreSQL verileri sadece indexten çeker.  

```sql
CREATE INDEX idx_btree_ios ON foo (id, name);
```

```sqlsql
EXPLAIN SELECT id, name,dt FROM foo WHERE id > 100000 AND id < 100010;
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Index Scan using idx_btree_ios on foo  (cost=0.43..19.07 rows=7 width=19)
   Index Cond: ((id > 100000) AND (id < 100010))
(2 rows)
```

```sql
EXPLAIN SELECT id, name FROM foo WHERE id > 100000 AND id < 100010;
                                   QUERY PLAN                                   
--------------------------------------------------------------------------------
 Index Only Scan using idx_btree_ios on foo  (cost=0.43..10.32 rows=7 width=15)
   Index Cond: ((id > 100000) AND (id < 100010))
(2 rows)
```


## Analyze 

https://andreigridnev.com/blog/2016-04-01-analyze-reindex-vacuum-in-postgresql/
[Analyze](analyze.md)

## Diğer Kaynaklar
https://postgrespro.com/blog/pgsql/3994098