# SQL Kavramları
## Veri Tanımlama Dili (DDL)
* create {database | table | schema, view} vb.

## CRUD İşlemleri (DML)
* CREATE
* READ
* UPDATE
* DELETE
### INSERT
### [SELECT](https://www.postgresql.org/docs/current/sql-select.html)
En çok kullanılan ve en karmaşık olabilecek.
Kullandığı sözcükler
```
SELECT
   alan_1,
   alan_2,
   ...
FROM
   table_name;

```

* DISTINCT: sadece farklı satırları getirir.
  - DISTINCT ON

```
SELECT
   DISTINCT alan_1, alan_2
FROM
   table_name;

```
* ORDER BY: sıralar

```
SELECT
   alan_1,
   alan_2
FROM
   table
ORDER BY
   alan_1 ASC,
   alan_2 DESC;

```
* WHERE: süzer.

```
SELECT
   last_name,
   first_name
FROM
   customer
WHERE
   first_name = 'Jamie'
AND last_name = 'Rice';
```

* LIMIT/FETCH: alt kümelerini sayısal olarak sınırlayarak getirir.

```
SELECT
   *
FROM
   table
LIMIT n OFFSET m;

```
* **GROUP BY**: satırları sınıflandırır.
* **HAVING**: süzer. **WHERE** ile farkı: where **GROUP BY** sözcüğünden önce uygulanır, having sonra uygulanır.
* **INNER JOIN, LEFT JOIN, FULL OUTER JOIN, CROSS JOIN**: diğer tablolarla katıştırır.
* **UNION, INTERSECT ve EXCEPT**: Diğer sözcükler
* **WITH**: With listesindeki tüm sorgular hesaplanır. Bunlar **FROM** listesinde referans gösterilebilecek geçici tablolar olarak etkili olur.
* **BETWEEN, IN ve LIKE** ile kullanım : BETWEEN ile belirli aralık içerisinde yer alan sonuç değerlerini döndürür. IN tümcesi ile içinde verilen sunuçların sorgu çıktısında yer alan değerleri döndürür.
* **ALIAS** : Bir tabloyu veya sütunu geçici olarak yeniden adlandırmak için ALIAS kullanılır. Bu işlem geçicidir, veritabanında gerçek tablo veya sütun adları değişmez.
```
SELECT
   cuta.id
FROM
   cok_uzun_tablo_adi cuta;

```

### UPDATE  
### DELETE
