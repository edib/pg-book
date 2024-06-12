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


## views ile dml işletme

Evet, PostgreSQL'de `VIEW` (görünüm) kullanarak `INSERT`, `UPDATE` veya `DELETE` sorguları oluşturabilirsiniz. Ancak, bu işlemler doğrudan bazı kısıtlamalar ve gereksinimler ile gelir. Görünümler üzerinde veri manipülasyonu yapmanın bazı önemli noktaları vardır:

### Görünümler Üzerinde Veri Manipülasyonu

#### 1. Doğrudan `INSERT`, `UPDATE` ve `DELETE`

Görünümler, temel tabloların alt kümesi veya birleşimi olduğundan, doğrudan `INSERT`, `UPDATE` veya `DELETE` işlemleri bazı durumlarda çalışabilir. Ancak, bu işlemler sadece görünümdeki her satırın temel tablo(s)unda benzersiz ve doğrudan eşlenebildiği basit görünümler için geçerlidir.

- **Doğrudan `INSERT`, `UPDATE` veya `DELETE` Destekleyen Görünümler**: Basit görünümler temel tabloya tek bir şekilde eşlenir ve bu tablo üzerinde doğrudan işlem yapılabilir.

  ```sql
  CREATE VIEW simple_view AS
  SELECT id, name, salary FROM employees;
  ```

  Bu basit görünümde, `employees` tablosu üzerinde doğrudan `INSERT`, `UPDATE`, ve `DELETE` işlemleri yapılabilir.

- **Kısıtlamalar**: Daha karmaşık görünümler, özellikle birden fazla tabloyu içeren veya toplama (aggregation) içeren görünümler, doğrudan veri manipülasyonu desteklemez.

#### 2. INSTEAD OF Trigger Kullanımı

Karmaşık görünümler üzerinde veri manipülasyonu yapmak için `INSTEAD OF` tetikleyiciler (triggers) kullanabilirsiniz. Bu tetikleyiciler, bir `INSERT`, `UPDATE`, veya `DELETE` işlemi gerçekleştiğinde, temel tabloya yapılacak işlemi özelleştirmenizi sağlar.

##### Örnek: INSTEAD OF Trigger ile INSERT

Aşağıda, `INSTEAD OF` tetikleyici kullanarak bir görünümde `INSERT` işlemi yapmayı gösteren bir örnek bulunmaktadır.

1. **Temel Tablo Oluşturma**:

   ```sql
   CREATE TABLE employees (
       id SERIAL PRIMARY KEY,
       first_name TEXT,
       last_name TEXT,
       department_id INT,
       salary NUMERIC
   );
   ```

2. **Görünüm Oluşturma**:

   ```sql
   CREATE VIEW employee_view AS
   SELECT first_name, last_name, department_id, salary FROM employees;
   ```

3. **INSTEAD OF INSERT Trigger Tanımlama**:

   ```sql
   CREATE FUNCTION insert_employee() RETURNS TRIGGER AS $$
   BEGIN
       INSERT INTO employees (first_name, last_name, department_id, salary)
       VALUES (NEW.first_name, NEW.last_name, NEW.department_id, NEW.salary);
       RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   ```

   Bu fonksiyon, görünümde bir `INSERT` işlemi gerçekleştirildiğinde çağrılacak olan tetikleyiciyi tanımlar.

4. **Trigger Kullanımı**:

   ```sql
   CREATE TRIGGER employee_view_insert
   INSTEAD OF INSERT ON employee_view
   FOR EACH ROW
   EXECUTE FUNCTION insert_employee();
   ```

   Bu tetikleyici, `employee_view` üzerinde bir `INSERT` işlemi gerçekleştirildiğinde `insert_employee` fonksiyonunu çalıştırır.

5. **Görünüm Üzerine INSERT İşlemi Yapma**:

   ```sql
   INSERT INTO employee_view (first_name, last_name, department_id, salary)
   VALUES ('John', 'Doe', 1, 50000);
   ```

   Bu `INSERT` işlemi, `employee_view` görünümünü kullanarak temel tablo `employees`'a veri ekler.

##### Örnek: INSTEAD OF Trigger ile UPDATE

Aynı şekilde, `INSTEAD OF` tetikleyici kullanarak görünümde `UPDATE` işlemi de yapabilirsiniz.

1. **UPDATE Tetikleyici Fonksiyon Tanımlama**:

   ```sql
   CREATE FUNCTION update_employee() RETURNS TRIGGER AS $$
   BEGIN
       UPDATE employees
       SET first_name = NEW.first_name,
           last_name = NEW.last_name,
           department_id = NEW.department_id,
           salary = NEW.salary
       WHERE id = OLD.id;
       RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   ```

2. **Trigger Kullanımı**:

   ```sql
   CREATE TRIGGER employee_view_update
   INSTEAD OF UPDATE ON employee_view
   FOR EACH ROW
   EXECUTE FUNCTION update_employee();
   ```

   Bu tetikleyici, `employee_view` üzerinde bir `UPDATE` işlemi gerçekleştirildiğinde `update_employee` fonksiyonunu çalıştırır.

3. **Görünüm Üzerine UPDATE İşlemi Yapma**:

   ```sql
   UPDATE employee_view
   SET salary = 55000
   WHERE first_name = 'John' AND last_name = 'Doe';
   ```

   Bu `UPDATE` işlemi, `employee_view` üzerinden `employees` tablosunda ilgili satırı günceller.

### Özet

- **Basit Görünümler**: Tek bir tabloyu doğrudan yansıtan basit görünümler, doğrudan `INSERT`, `UPDATE`, ve `DELETE` işlemlerini destekleyebilir.
- **Karmaşık Görünümler**: Birden fazla tabloyu içeren veya toplama işlemleri içeren görünümler, doğrudan veri manipülasyonu desteklemez. Bu durumda `INSTEAD OF` tetikleyiciler kullanılmalıdır.
- **INSTEAD OF Triggerlar**: Karmaşık görünümler için `INSTEAD OF` tetikleyiciler tanımlayarak `INSERT`, `UPDATE`, ve `DELETE` işlemlerini özelleştirebilirsiniz.

Bu yöntemler, PostgreSQL'de görünümler üzerinden veri manipülasyonu yapmanızı sağlar ve karmaşık veri modelleri ile çalışırken esneklik sağlar.