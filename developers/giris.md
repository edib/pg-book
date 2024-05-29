# PostgreSQL Developer Eğitimi

## PostgreSQL Tarihçesi ve Yapısı

## PostgreSQL Kurulumu

## PostgreSQL Konfigürasyonu
## PostgreSQL İstemcileri ve psql
## SQL temelleri
## PostgreSQL Gelişmiş Özellikleri
## Kullanıcı ve Erişim Yönetimi
## Veri Sözlüğü
## WAL
## Bakım araçlarına giriş: MVCC Yapısı ve Vacuum
## Tablespace Yapısı

## Temel Yedekleme Araçları
    - pg_dump
    - 
## PostgreSQL Veri Tipleri, Fonksiyon ve Operatörler
## Sorguların Yapısı ve Davranışları
## Transactionlar

## Foreign Key
## Window Fonksiyonları
## WITH Sorgular (Common Table Expressions)

```sql

CREATE TABLE employees
(
  employeeid int NOT NULL PRIMARY KEY,
  firstname varchar(50) NOT NULL,
  lastname varchar(50) NOT NULL,
  managerid int NULL
);

INSERT INTO employees VALUES (1, 'Ken', 'Thompson', NULL);
INSERT INTO employees VALUES (2, 'Terri', 'Ryan', 1);
INSERT INTO employees VALUES (3, 'Robert', 'Durello', 1);
INSERT INTO employees VALUES (4, 'Rob', 'Bailey', 2);
INSERT INTO employees VALUES (5, 'Kent', 'Erickson', 2);
INSERT INTO employees VALUES (6, 'Bill', 'Goldberg', 3);
INSERT INTO employees VALUES (7, 'Ryan', 'Miller', 3);
INSERT INTO employees VALUES (8, 'Dane', 'Mark', 5);
INSERT INTO employees VALUES (9, 'Charles', 'Matthew', 6);
INSERT INTO employees VALUES (10, 'Michael', 'Jhonson', 6) ;

with recursive ctereports (empid, firstname, lastname, mgrid, emplevel)
  as
  (
    select employeeid, firstname, lastname, managerid, 1
    from employees
    where managerid is null
    union all
    select e.employeeid, e.firstname, e.lastname, e.managerid, 
      r.emplevel + 1
    from employees e
      inner join ctereports r
        on e.managerid = r.empid
  )
Select
  firstname || ' ' || lastname as fullname, 
  emplevel,
  (select firstname || ' '  ||  lastname from employees 
    where employeeid = ctereports.Mgrid) as manager
From ctereports 
Order by emplevel, mgrid;


```

```sql
WITH RECURSIVE count_series(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM count_series WHERE n < 5
)
SELECT * FROM count_series;

```

recursive query örneği

```sql

CREATE TABLE directory (
  id           INT NOT NULL,
  parent_id    INT,
  label        text,

  CONSTRAINT pk_directory PRIMARY KEY (id),
  CONSTRAINT fk_directory FOREIGN KEY (parent_id) REFERENCES directory (id)
);

INSERT INTO directory VALUES ( 1, null, 'C:');
INSERT INTO directory VALUES ( 2,    1, 'eclipse');
INSERT INTO directory VALUES ( 3,    2, 'configuration');
INSERT INTO directory VALUES ( 4,    2, 'dropins');
INSERT INTO directory VALUES ( 5,    2, 'features');
INSERT INTO directory VALUES ( 7,    2, 'plugins');
INSERT INTO directory VALUES ( 8,    2, 'readme');
INSERT INTO directory VALUES ( 9,    8, 'readme_eclipse.html');
INSERT INTO directory VALUES (10,    2, 'src');
INSERT INTO directory VALUES (11,    2, 'eclipse.exe');

WITH RECURSIVE t (
  id,
  name,
  path
) AS (
  SELECT
    DIRECTORY.ID,
    DIRECTORY.LABEL,
    DIRECTORY.LABEL
  FROM
    DIRECTORY
  WHERE
    DIRECTORY.PARENT_ID IS NULL
  UNION ALL
  SELECT
    DIRECTORY.ID,
    DIRECTORY.LABEL,
    t.path
      || '\'
      || DIRECTORY.LABEL
  FROM
    t
  JOIN
    DIRECTORY
  ON t.id = DIRECTORY.PARENT_ID
)
SELECT *
FROM
  t;

```

* https://www.postgresql.org/docs/current/queries-with.html

## JSON ve XML

## Tablolarda Miras


## İndeks Türleri ve Özellikleri
[İndexleme](docs/Indexing.md)
## View ve Materialized View

**PostgreSQL Materialized View**

PostgreSQL Materialized View, bir veritabanı tablosu gibi davranan, ancak bir SQL sorgusunun sonucunu saklayan bir veri yapısıdır. Materialized View, sorgunun sonucunu disk üzerinde saklayarak performansı artırabilir çünkü tekrar eden sorgulamalarda veriyi yeniden hesaplamak yerine saklanan sonuç kullanılabilir. Bu, özellikle karmaşık ve zaman alıcı sorgular için çok faydalıdır.

**Özellikler:**
- Materialized View, bir tablo gibi sorgulanabilir.
- Veriler düzenli aralıklarla veya manuel olarak yenilenebilir.
- Performans iyileştirmesi sağlar çünkü sık kullanılan veriler saklanır ve sorgular daha hızlı çalışır.

**Materialized View Oluşturma ve Kullanma**

1. **Materialized View Oluşturma**

```sql
CREATE MATERIALIZED VIEW my_materialized_view AS
SELECT column1, column2, ...
FROM my_table
WHERE conditions;
```

2. **Materialized View Yenileme**

Materialized View verilerini yenilemek için aşağıdaki komutu kullanabilirsiniz:

```sql
REFRESH MATERIALIZED VIEW my_materialized_view;
```

3. **Materialized View Kullanımı**

Materialized View, normal bir tablo gibi sorgulanabilir:

```sql
SELECT * FROM my_materialized_view;
```

**Örnek**

Diyelim ki büyük bir `sales` tablomuz var ve bu tablodan belirli ürünlerin toplam satışlarını sık sık sorgulamak istiyoruz. Bu durumda bir Materialized View oluşturmak performans açısından faydalı olabilir.

1. **Sales Tablosu**

```sql

CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    product_id INT,
    sale_amount DECIMAL,
    sale_date DATE
);

INSERT INTO sales (product_id, sale_amount, sale_date)
SELECT
    (random() * 10 + 1)::INT, -- 1 ile 10 arasında rastgele product_id
    100.00 * random(), -- 10.00 ile 100.00 arasında rastgele sale_amount
    CURRENT_DATE - (random() * 30)::INT -- Son 30 gün içinde rastgele sale_date
FROM
    generate_series(1, 1000); -- 1000 satır veri oluştur

```

2. **Materialized View Oluşturma**

```sql

CREATE MATERIALIZED VIEW total_sales_per_product AS
SELECT product_id, SUM(sale_amount) AS total_sales
FROM sales
GROUP BY product_id;
```

3. **Materialized View Yenileme**

Satış verileri güncellendiğinde Materialized View'ı yenileyebilirsiniz:

```sql

REFRESH MATERIALIZED VIEW total_sales_per_product;

```

4. **Materialized View Sorgulama**

Toplam satışları sorgulamak için Materialized View'ı kullanabilirsiniz:

```sql
SELECT * FROM total_sales_per_product;
```

Bu şekilde, sık kullanılan sorgular için performansı artırabilir ve veritabanı kaynaklarını daha verimli kullanabilirsiniz.

## Özyinelemeli Sorgular
* CTE 

## Ortak Tablo İfadeleri
* CTE

## Gruplama Kümeleri

### [Gruplama](grouplama.md)

### [Grouping Sets](grouping_sets.md)

## Plpgsql

[Fonksiyonlar](functions.md)

## Fonksiyon ve Prosedürler

## Triggerlar

## PostgreSQL Eklentileri

## pgLoader

## SQL Tuning ve Security 