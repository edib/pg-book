## sql-2

### having
belli bir şarta uymayan kayıt gruplarını elemek için kullanılır. Sıklıkla `group by` ile birlikte kullanılır. Örneğin aşağıdaki sorguyu `where` ile yazamayız. Çünkü `where` her bir satır için filtre oluştururken `having` bütünleme fonksiyonlarını çalıştırmamıza izin verir.

```
SELECT
   customer_id,
   SUM (amount)
FROM
   payment
GROUP BY
   customer_id
HAVING
   SUM (amount) > 200;
```

### join türleri
 - [Komik](https://66.media.tumblr.com/11ba835a623fdedfb18153f14c8d8105/tumblr_pkthgeel1f1rh9ffao1_500.jpg)
 - [Gerçek](https://blog.jooq.org/2016/07/05/say-no-to-venn-diagrams-when-explaining-joins/)
 - [Görsel Join](http://joins.spathon.com/)

```
CREATE TABLE sepet_a (
    id INT PRIMARY KEY,
    meyve VARCHAR (100) NOT NULL
);

CREATE TABLE sepet_b (
    id INT PRIMARY KEY,
    meyve VARCHAR (100) NOT NULL
);

INSERT INTO sepet_a (id, meyve)
VALUES
    (1, 'Elma'),
    (2, 'Portakal'),
    (3, 'Muz'),
    (4, 'Üzüm');

INSERT INTO sepet_b (id, meyve)
VALUES
    (1, 'Portakal'),
    (2, 'Elma'),
    (3, 'Karpuz'),
    (4, 'Armut');
```
#### inner join
* sol ve sağ tablodan eşleşenlerin satırlarını getirir.
```
SELECT
    a.id id_a,
    a.meyve meyve_a,
    b.id id_b,
    b.meyve meyve_b
FROM
    sepet_a a
INNER JOIN sepet_b b ON a.meyve = b.meyve;
```
#### left join
* sol tablodan tamamını, sağdan eşleşen satırları getirir.
```
SELECT
    a.id id_a,
    a.meyve meyve_a,
    b.id id_b,
    b.meyve meyve_b
FROM
    sepet_a a
LEFT JOIN sepet_b b ON a.meyve = b.meyve;
```
#### left outer join
* sadece sol tabloda olup sağ tabloyla eşleşmeyen satırları getirir.
```
SELECT
    a.id id_a,
    a.meyve meyve_a,
    b.id id_b,
    b.meyve meyve_b
FROM
    sepet_a a
LEFT JOIN sepet_b b ON a.meyve = b.meyve
WHERE b.id IS NULL;
```



#### right join
* sol tablodan tamamını, sağdan eşleşen satırları getirir.
```
SELECT
    a.id id_a,
    a.meyve meyve_a,
    b.id id_b,
    b.meyve meyve_b
FROM
    sepet_a a
RIGHT JOIN sepet_b b ON a.meyve = b.meyve;
```

#### right outer join
* sadece sağ tabloda olup sol tabloyla eşleşmeyen satırları getirir.
```
SELECT
    a.id id_a,
    a.meyve meyve_a,
    b.id id_b,
    b.meyve meyve_b
FROM
    sepet_a a
RIGHT JOIN sepet_b b ON a.meyve = b.meyve
WHERE a.id IS NULL;
```

#### FULL [OUTER] JOIN
* sol ve sağ tablodan eşleşenleri ve eğer eşleşmiyorsa karşılarına `NULL` yazarak getir. Birleşim kümesi diyebiliriz.
```
SELECT
    a.id id_a,
    a.meyve meyve_a,
    b.id id_b,
    b.meyve meyve_b
FROM
    sepet_a a
FULL OUTER JOIN sepet_b b ON a.meyve = b.meyve
```

### USING
* eğer 2 join edilen tablonun karşılaştırma alanlarının adları aynıysa bir üstteki sorgu ve şöyle değiştirilebilir.

```
SELECT
    a.id id_a,
    a.meyve meyve_a,
    b.id id_b,
    b.meyve meyve_b
FROM
    sepet_a a
FULL OUTER JOIN sepet_b b USING(meyve)
```

### INTERSECT
* Birden dönen satırları karşılaştırıp, eşleşenleri alır. Kümelerdeki kesişim kümesi.

### UNION [ALL]
* Sorgu sonuçlarını birleştirir. İki sorguda da dönen satır sayısının ve veri tiplerinin aynı olması gerekir.
* `ALL` kelimesi `DISTINCT` sorgusu gibi çalışır.

### EXCEPT
* sol sorgudan gelen ve sağ sorguda olmayan satırları listeler. İki sorguda da dönen satır sayısının ve veri tiplerinin aynı olması gerekir.

```
--- inventory tablosunda olmayan filmlerin listesi

SELECT
   film_id,
   title
FROM
   film
EXCEPT
   SELECT
      DISTINCT inventory.film_id,
      title
   FROM
      inventory
   INNER JOIN film ON film.film_id = inventory.film_id
ORDER BY title;
```

### [Aggregate Functions](http://www.postgresqltutorial.com/postgresql-aggregate-functions/)

### [Window Functions](http://www.postgresqltutorial.com/postgresql-window-function/)
