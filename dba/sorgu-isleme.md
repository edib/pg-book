# Sorgu İşleme

* PostgreSQL’in en karmaşık alt sistemlerinden birisidir. 
* SQL standartlarının gerektirdiği çok sayıda özelliği destekler ve sorguları en verimli şekilde işler.
  
[Görsel](https://tubitak-bilgem-yte.github.io/pg-yonetici/images/Query-Processing-1.png)

* 9.6 ile beraber paralel sorgu, birden çok background worker process kullanılıyor. olsa
* Temel olarak bağlı istemci tarafından verilen tüm sorgular bir backend process tarafından işlenir.
  
| **`Parser`** | Düz metin SQL ifadesinden parse tree oluşturur. | |
| **`Analyzer/Analyser`** | Parse tree'nin anlamsal analizini gerçekleştirir ve bir sorgu ağacı (query tree) oluşturur. |
| **`Rewriter`** | Varsa rule system'deki kuralları kullanarak sorgu ağacını dönüştürür. |
| **`Planner`** | Sorgu ağacından en etkin şekilde yürütülebilecek plan ağacını (plan tree) oluşturur. |
| **`Executor`** | Plan ağacı tarafından oluşturulan sırada, tablo ve indekslere erişerek sorguyu yürütür. |



## Parser

```
degerlidb=# SELECT id, data FROM tbl_a WHERE id < 300 ORDER BY data;

```

[parse tree](https://www.interdb.jp/pg/img/fig-3-02.png)

Parser, bir parse tree oluştururken yalnızca bir sorgunun sözdizimini kontrol eder ve hata varsa bir hata döndürür.
Sorgusunun anlamını kontrol etmez. Örneğin, sorgu, olmayan bir tablo adı içerse bile parser bir hata döndürmez. İçerik kontrolleri analyzer tarafından yapılır.

## Analyzer

[query tree](https://www.interdb.jp/pg/img/fig-3-03.png)

* **targetList**, bu sorgunun sonucu olan sütunların bir listesidir. Bu örnekte, bu liste iki sütundan oluşmaktadır: 'id' ve 'data'. 
* Sorgu ağacı ∗ kullanıyorsa tüm sütunların listesi gelir.
* **rtable**, bu sorguda kullanılan ilişkilerin bir listesidir. Bu örnekte, bu tablo, bu tablonun oid'i ve bu tablonun adı gibi 'tbl_a' tablosunun bilgilerini tutar.
* **jointree**, FROM yan tümcesini ve WHERE yan tümcelerini saklar.
* **SortGroupClause**

## Rewriter

**Query tree**’yi **pg_rules** sistem kataloğunda saklanan kurallara göre dönüştüren sistemdir. **View**’lar bir kural sistemi örneğidir. `CREATE VIEW` ile bir view tanımlandığında, karşılık gelen kural otomatik olarak oluşturulup katalogta saklanır. 

Böyle bir viewumuz var.
```psql
sampledb=# CREATE VIEW employees_list AS SELECT e.id, e.name, d.name AS department 
    FROM employees AS e, departments AS d WHERE e.department_id = d.id;
```

Kullandık

```psql

sampledb=# SELECT * FROM employees_list;
```
[yeni query tree](https://tubitak-bilgem-yte.github.io/pg-yonetici/images/Query-Processing-1.4.png)

## Planner ve Executor

* Planner’ın sorumluluğu, query tree’yi taramak ve sorguyu yürütmek için tüm olası planları bulmaktır. 
* Bu adımda rewriter’dan query tree’yi alınır ve executor’ın en verimli şekilde işleyebildiği bir plan tree oluşturulur. 
* Üretilen plan sequential scan veya yararlı bir indeks tanımlıysa index scan içerebilir. 
* Sorgu iki veya daha fazla tablo içeriyorsa, planner tablolara joinlemek için birkaç farklı yöntem önerebilir. 
* EXPLAIN komutu ile planner’ın bir sorguyu yürütmeye nasıl karar verdiği görülebilir.

```psql

testdb=# EXPLAIN SELECT * FROM tbl_a WHERE id < 300 ORDER BY data;
                       QUERY PLAN
---------------------------------------------------------------
Sort  (cost=182.34..183.09 rows=300 width=8)
  Sort Key: data
  ->  Seq Scan on tbl_a  (cost=0.00..170.00 rows=300 width=8)
         Filter: (id < 300)

```

[plan tree ve explain](https://tubitak-bilgem-yte.github.io/pg-yonetici/images/Query-Processing-1.5.png)

[executor bellek ilişkisi](https://tubitak-bilgem-yte.github.io/pg-yonetici/images/Query-Processing-1.6.png)

* Executor, Buffer Manager aracılığıyla küme içerisindeki tablo ve indeksler üzerinde okuma yazma işlemleri yapar. 
* Sorgular işlenirken executor, önceden ayrılmış temp_buffers ve work_mem bellek alanlarını kullanır, gerekli durumlarda geçici dosyalar oluşturabilir. 
* PostgreSQL kayıtlara erişirken, çalışan transaction’ların tutarlılığı ve izolasyonu için concurrency control mekanizmasını kullanır.
* PostgreSQL'de sorgu ipuçları yoktur ve hiç bir zamanda olmayacak. [bir extension](http://pghintplan.osdn.jp/pg_hint_plan.html)

## Sorgu Maliyet Hesaplama

* Sorgu optimizasyonu maliyete dayalıdır. 
* Mutlak performans göstergeleri değil, operasyonların göreli performansını karşılaştırmak için göstergelerdir.


* PostgreSQL'de üç tür maliyet vardır: 
  * start-up, 
  * run
  * total: start-up + run 

* **start-up cost**, ilk kayıt getirilmeden önce harcanan maliyettir. Örneğin, **index_scan**'in başlangıç ​​maliyeti, hedef tablodaki ilk kayda erişmek için index sayfalarını okuma maliyetidir.
* **run cost**, sorguda istenen tüm demetleri getirme maliyetidir.
* **Toplam maliyet**

```sql
testdb=# EXPLAIN SELECT * FROM tbl;
                        QUERY PLAN                        
---------------------------------------------------------
    Seq Scan on tbl  (cost=0.00..145.00 rows=10000 width=8)
(1 row)

--- 0.00 : start-up 
--- 145.00 : run cost

```

```sql
testdb=# CREATE TABLE tbl (id int PRIMARY KEY, data int);
testdb=# CREATE INDEX tbl_data_idx ON tbl (data);
testdb=# INSERT INTO tbl SELECT generate_series(1,10000),generate_series(1,10000);
testdb=# ANALYZE;
testdb=# \d tbl
      Table "public.tbl"
 Column |  Type   | Modifiers 
--------+---------+-----------
 id     | integer | not null
 data   | integer | 
Indexes:
    "tbl_pkey" PRIMARY KEY, btree (id)
    "tbl_data_idx" btree (data)
```

### Sequential Scan

```sql
testdb=# SELECT * FROM tbl WHERE id < 8000;

```

* matematiksel olarak açıklayalım

```math
"run cost"="cpu run cost"+"disk run cost"
          =(cpu_tuple_cost+cpu_operator_cost)×Ntuple+seq_page_cost×Npage,

"cpu run cost" = (cpu_tuple_cost+cpu_operator_cost)×Ntuple
"disk run cost" = seq_page_cost×Npage

```
#### Ayarlanacak parametreler

Varsayılan değerler

* **cpu_tuple_cost** :  0.0025
* **cpu_operator_cost** : 0.01
* **seq_page_cost** : 1.0

```sql
testdb=# SELECT relpages, reltuples FROM pg_class WHERE relname = 'tbl';
 relpages | reltuples 
----------+-----------
       45 |     10000
(1 row)

```
* Ntuple = 10000  
* Npage = 45

Maliyeti tekrar hesaplayalım

```math

"run cost" = (0.01+0.0025)×10000+1.0×45
           =170.0

-- seq scan'de start-up cost 0'dır. 

"total cost" = 0.0 + 170.0
             = 170.0
```


Onaylayalım

```sql
testdb=# EXPLAIN SELECT * FROM tbl WHERE id < 8000;
                        QUERY PLAN                       
--------------------------------------------------------
    Seq Scan on tbl  (cost=0.00..170.00 rows=8000 width=8)
    Filter: (id < 8000)
(2 rows)

```

## Heap Only Tuple
[Göz gezdir](https://www.interdb.jp/pg/pgsql07.html)

* pg_stat eklentisi

```
select * from pg_stat_*; 

```

## Index-Only Scans
[Yapısı](https://www.interdb.jp/pg/img/fig-7-07.png)



### Index Scan
[Maliyet Hesabı](https://www.interdb.jp/pg/pgsql03.html#_3.2.)


