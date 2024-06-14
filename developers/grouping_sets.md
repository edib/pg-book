# GROUPING SETS

GROUPING SETS kullanarak çok sayıda GROUP BY ifadesinin UNION ALL ile birleştirilmesi ile elde edilen sonuç kümesine denk bir çıktı elde etmek mümkündür.

Alıştırmalar için bir yabancı dil eğitim merkezinin kurs_kayit ismindeki tablosunu oluşturalım. İki dil ve iki seviye için temsili öğrenci kayıtları ekleyelim.

```sql
CREATE TABLE kurs_kayit (
ogrenci_no integer,
ogrenci_adsoyad VARCHAR,
dil VARCHAR,
seviye VARCHAR,
PRIMARY KEY (ogrenci_no)
);
```

```sql
INSERT INTO kurs_kayit
VALUES
    (301, 'adsoyad1', 'İSPANYOLCA', 'Giriş'),
    (302, 'adsoyad2', 'İSPANYOLCA', 'Giriş'),
    (303, 'adsoyad3', 'İSPANYOLCA', 'Giriş'),
    (304, 'adsoyad4', 'İSPANYOLCA', 'Giriş'),
    (305, 'adsoyad5', 'İSPANYOLCA', 'Giriş'),
    (306, 'adsoyad6', 'İSPANYOLCA', 'Giriş'),
    (307, 'adsoyad7', 'İSPANYOLCA', 'Orta'),
    (308, 'adsoyad8', 'İSPANYOLCA', 'Orta'),
    (309, 'adsoyad9', 'İSPANYOLCA', 'Orta'),
    (401, 'adsoyad10', 'JAPONCA', 'Giriş'),
    (402, 'adsoyad11', 'JAPONCA', 'Giriş'),
    (403, 'adsoyad12', 'JAPONCA', 'Giriş'),
    (404, 'adsoyad13', 'JAPONCA', 'Giriş'),
    (405, 'adsoyad14', 'JAPONCA', 'Orta'),
    (406, 'adsoyad15', 'JAPONCA', 'Orta');

```

GROUPING SETS gruplama için kullanılan sütunlar kümesi olarak ifade edilebilir. Bu küme tek sütun ya da birden fazla sütun içerebildiği gibi tablodaki bütün kayıtlar üzerindeki toplam (aggregation) sorgularında olduğu gibi boş bir küme de olabilir.

Aşağıdaki sorguda dil ve seviye sütunlarından oluşan bir gruplama kümesi (grouping set) görüyoruz. Bu sorgu dil ve seviyeye göre kayıtlı öğrenci sayılarını döner.

```sql

SELECT dil, seviye, COUNT (ogrenci_no)
FROM
    kurs_kayit
GROUP BY
    dil,
    seviye;
```




Aşağıdaki sorgu her dilde kayıtlı öğrenci sayısını döner. Burada gruplama kümesi (grouping set) dil sütunudur.

```sql
SELECT dil, COUNT (ogrenci_no)
FROM
    kurs_kayit
GROUP BY
    dil;
```


Aşağıdaki sorgu öğrenci sayılarını seviyeler bazında gösterir. Seviye sütunu gruplama kümesini oluşturur.

```sql
SELECT seviye, COUNT (ogrenci_no)
FROM
    kurs_kayit
GROUP BY
    seviye;
```


Bu sorgu da bütün dil ve seviyeler için kayıtlı öğrenci sayısını bulur. Gruplama kümesi boş bir kümedir

```sql
SELECT COUNT(ogrenci_no)
FROM
    kurs_kayit;
```




Dört ayrı sonuç kümesi yerine tüm gruplama kümeleri için birleştiriliş bir sonuç kümesi görmek istediğimizde UNION ALL ile bütün sorguları bir araya getirmek gerekir.

UNION ALL içinde geçen sorguların sütun sayılarının eşit olması gerektiğinden bazı sorgularda aşağıdaki gibi uygun yerlerde NULL sütun eklemek gerekiyor.

```sql
SELECT dil, seviye, COUNT (ogrenci_no)
FROM
    kurs_kayit
GROUP BY
    dil,
    seviye
UNION ALL
SELECT dil, NULL, COUNT (ogrenci_no)
FROM
    kurs_kayit
GROUP BY
    dil
UNION ALL
SELECT NULL, seviye, COUNT (ogrenci_no)
FROM
    kurs_kayit
GROUP BY
    seviye
UNION ALL
SELECT NULL, NULL, COUNT(ogrenci_no)
FROM
 kurs_kayit;
```

Yukarda görüldüğü gibi bütün gruplama kümelerinin toplamları (aggregate) için tek bir sonuç kümesi elde edebildik. Fakat kullanılan yöntemin iki ana sorunu var. Bunlardan biri sorgunun uzunluğu diğeri de PostgreSQL’in kurslar tablosunu bütün sorgular için ayrı ayrı taraması gerekmesi.

Bu noktada GROUP BY cümleciğinin alt cümleciği olarak GROUPING SETS (gruplama kümeleri) kullanışlı bir seçenek olarak önümüze çıkıyor.

GROUPING SETS aynı sorguda birden çok gruplama kümesi tanımlanmasına imkan vermektedir. Genel yazımı aşağıdaki şekildedir:

```sql
SELECT   
   sutun1,  
   sutun2,   
   toplam_fonksiyonu(sutun3)
FROM   
   tablo_adi
GROUP BY   
   GROUPING SETS (        
      (sutun1, sutun2),        
      (sutun1),        
      (sutun2),        
      ()
   );

   ```
Bu yazımda 4 adet gruplama kümesi bulunmaktadır: (sutun1, sutun2), (sutun1), (sutun2) ve ().

Örnek tablomuzda bu yazımı uyguladığımızda aşağıdaki gibi bir sorgu elde ediyoruz:

```sql

SELECT dil, seviye, COUNT (ogrenci_no)
FROM
    kurs_kayit
GROUP BY
    GROUPING SETS (
       (dil, seviye),
       (dil),
       (seviye),
       ()
    );


```



Daha kısa bir sorguyla öncekine denk bir sonuç kümesi elde ettik. Ayrıca bu sorgu her bir gruplama kümesi için tablonun tekrar baştan aşağı taranmasını gerektirmiyor.

## CUBE
CUBE,  GROUP BY'ın altında birden fazla sayıda gruplama kümesi oluşturmak için kullanılan bir alt cümleciktir. CUBE genel yazımı aşağıdaki şekildedir:

```sql

SELECT   
   sutun1,  
   sutun2,
   sutun3,   
   toplam_fonksiyonu(sutun4)
FROM   
   tablo_adi
GROUP BY   
   CUBE (sutun1, sutun2, sutun3);
```

CUBE ifadesi parantez içinde verilen (boyut) sütunlarının bütün gruplama kümesi kombinasyonlarını oluşturur. Yani aşağıdaki iki yazım birbirine denktir:

```sql
CUBE(sutun1,sutun2,sutun3)


GROUPING SETS (
    (sutun1,sutun2,sutun3),
    (sutun1,sutun2),
    (sutun1,sutun3),
    (sutun2,sutun3),
    (sutun1),
    (sutun2),
    (sutun3),
    ()
)

```
Eğer CUBE ifadesi içinde n sütun varsa 2n  gruplama seti kombinasyonu elde edilir.

Aşağıdaki sorgu ile GROUPING SETS için kullandığımız kurs_kayit tablosu üzerinde CUBE kullanarak gruplama kümeleri oluşturuyoruz:

```sql
SELECT dil, seviye, COUNT(ogrenci_no)
FROM
   kurs_kayit
GROUP BY
   CUBE(dil, seviye);

```


Bu sorgu ile de kısmi (partial) bir CUBE örneği göreceğiz:

```sql
SELECT dil, seviye, COUNT(ogrenci_no)
FROM
   kurs_kayit
GROUP BY
   dil,
   CUBE(seviye)
ORDER BY
   dil,
   seviye;

```
## ROLLUP

GROUP BY ile birlikte kullanılabilecek çoklu gruplama kümeleri oluşturmayı sağlayan cümleciklerden biri de ROLLUP'tır. Yukarıda CUBE ile belirtilen sütunlara ait muhtemel bütün gruplama kümelerinin oluşturulduğunu görmüştük. ROLLUP ile ise muhtemel gruplama kümelerinin hepsi değil belirli alt kümelerine göre gruplandırma yapar.

CUBE anlatılırken CUBE (sutun1, sutun2, sutun3) cümleciğinin denginin GROUPING SETS ile 8 ayrı satırda nasıl yazılabildiği gösterilmişti. Benzer şekilde aşağıdaki iki yazım da birbirine denktir:

```sql
ROLLUP(sutun1,sutun2,sutun3)

GROUPING SETS (
    (sutun1,sutun2,sutun3),
    (sutun1,sutun2),
    (sutun1),
    ()
)

```

ROLLUP kullanımında belirtilen sütunlar arasında bir hiyerarşi olduğu varsayılır ve sütunların belirtiliş sırasına göre alt toplamlar (aggregate) ve genel toplam değerleri gösterilir. Yıl > çeyrek yıl (quarter)> ay arasında mevcut olan hiyerarşi itibariyle ROLLUP kullanılarak tarih boyutunda değişik kırınımlara göre toplamların (aggregate) hesaplanması yaygın bir kullanımdır.

Aşağıda PostgreSQL'de ROLLUP kullanımının genel yazımı görülmektedir:

```sql
SELECT   
   sutun1,  
   sutun2,
   sutun3,   
   toplam_fonksiyonu(sutun4)
FROM   
   tablo_adi
GROUP BY   
   ROLLUP (sutun1, sutun2, sutun3);

   ```
Oluşturulacak alt toplamların sayısını azaltmak için aşağıdaki şekilde kısmi ROLLUP yazılması da mümkündür:

```sql
SELECT   
   sutun1,  
   sutun2,
   sutun3,   
   toplam_fonksiyonu(sutun4)
FROM   
   tablo_adi
GROUP BY
   sutun1,   
   ROLLUP (sutun2, sutun3);

   ```

Aşağıdaki örnek sorgu ROLLUP alt cümleciği ile dillere göre öğrenci sayıları (alt toplam) ve tüm seviye ve diller için öğrenci sayılarını (toplam) vermektedir:

```sql
SELECT dil, seviye, COUNT(ogrenci_no)
FROM
   kurs_kayit
GROUP BY
   ROLLUP (dil, seviye)
ORDER BY
   dil,
   seviye;

```

Sorgu çıktısında görüldüğü üzere 3. satırda İspanyolca 6. satırda Japonca dili için toplam öğrenci satırları, son satırda da genel öğrenci sayısı toplamı hesaplanmıştır. Bu örnekte boyut alanları arasındaki hiyerarşi, dil > seviye şeklindedir.

Sorguda ROLLUP kısmında dil ve seviyenin sıralamasını değiştirisek sonuç aşağıdaki gibi olacaktır:

```sql
SELECT seviye, dil, COUNT(ogrenci_no)
FROM
   kurs_kayit
GROUP BY
   ROLLUP (seviye, dil)
ORDER BY
   seviye,
   dil;
```

Yukardaki örnekte ise hiyerarşi, seviye > dil şeklindedir.

Aşağıda da kısmi ROLLUP için bir örnek verilmektedir:

```sql
SELECT seviye, dil, COUNT(ogrenci_no)
FROM
   kurs_kayit
GROUP BY
   seviye,
   ROLLUP (dil)
ORDER BY
   seviye,
   dil;

```


http://www.postgresqltutorial.com/postgresql-rollup/


## başka bir örnek

```sql

CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    sale_date DATE,
    quantity_sold INT
);

-- rastgele oluştur
INSERT INTO sales (product_name, sale_date, quantity_sold)
SELECT
    'Product ' || (i % 5 + 1),  -- Rastgele 5 farklı ürün adı oluştur
    CURRENT_DATE - INTERVAL '1 day' * i,  -- Geçmişten bugüne kadar olan tarihler
    (RANDOM() * 100)::INT  -- 0 ile 100 arasında rastgele satış miktarı
FROM generate_series(1, 10365) AS s(i);  -- 365 günlük bir seri oluştur


-- nasıl bir data oluştu
select * from sales order by sale_id desc;


select
	product_name,
   TO_CHAR(sale_date, 'YYYY') AS year,  -- Yıl
   -- TO_CHAR(sale_date, 'Month') AS month,  -- Ay adı (tam isim)
   EXTRACT(MONTH FROM sale_date) AS month,
   TO_CHAR(sale_date, 'DD') AS day,  -- Gün
   SUM(quantity_sold) AS total_quantity
FROM
    sales
GROUP BY
    cube(product_name, year,month,day)
ORDER BY
    product_name, year, month, day;   

```