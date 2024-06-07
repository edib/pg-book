## views 

### 1. Tablonun Oluşturulması

Öncelikle, `sales` adında bir tablo oluşturalım:

```sql
CREATE TABLE sales (
    id serial PRIMARY KEY,
    sale_date date NOT NULL,
    amount numeric NOT NULL,
    product_name varchar(100) NOT NULL
);
```

### 2. Veri Ekleme (INSERT)

`sales` tablosuna bazı örnek veriler ekleyelim:

```sql
INSERT INTO sales (sale_date, amount, product_name) VALUES
('2023-01-01', 100, 'Product A'),
('2023-01-02', 150, 'Product B'),
('2023-01-03', 200, 'Product A'),
('2023-01-04', 250, 'Product C'),
('2023-01-01', 300, 'Product B'),
('2023-01-02', 350, 'Product A');
```

### 3. View Oluşturma

`sales` tablosundaki verilerin özetini almak için bir view oluşturalım:

```sql
CREATE VIEW sales_summary AS
SELECT sale_date, product_name, SUM(amount) AS total_sales
FROM sales
GROUP BY sale_date, product_name;
```

Bu view, `sales` tablosundaki her bir ürün için her günün toplam satışlarını gösterecektir.

### 4. Materialized View Oluşturma

Aynı özeti tutan bir materialized view oluşturalım. Bu materialized view, `WITH NO DATA` seçeneği ile veri çekmeden oluşturulacak:

```sql
CREATE MATERIALIZED VIEW sales_summary_materialized
AS
SELECT sale_date, product_name, SUM(amount) AS total_sales
FROM sales
GROUP BY sale_date, product_name
WITH NO DATA;
```

### 5. Materialized View Yenileme

Materialized view'ı veri çekerek güncelleyelim:

```sql
REFRESH MATERIALIZED VIEW sales_summary_materialized;
```

### 6. Sorgulama

View ve materialized view'ı sorgulayarak sonuçları görelim:

- **View Sorgulama:**

  ```sql
  SELECT * FROM sales_summary;
  ```

  Bu sorgu, anlık olarak `sales` tablosundaki verilerin özetini döndürecektir.

- **Materialized View Sorgulama:**

  ```sql
  SELECT * FROM sales_summary_materialized;
  ```

  Bu sorgu, son yenileme işlemi sırasında `sales` tablosundaki verilerin özetini döndürecektir.

### Özet

Bu örnekler, PostgreSQL'de bir tablo oluşturma, veri ekleme, view ve materialized view oluşturma işlemlerini göstermektedir. `sales_summary` view ve `sales_summary_materialized` materialized view, `sales` tablosundaki verilerin özetini almak için kullanılmıştır. `WITH NO DATA` seçeneği ile oluşturulan materialized view, verilerin başlangıçta yüklenmesini engeller ve veri yenileme işlemi ile verilerin güncellenmesini sağlar.
