# CASE

PostgreSQL’de `CASE` ifadesi, belirli koşullara göre farklı sonuçlar döndürmek için kullanılan güçlü bir ifadedir. `CASE` ifadesi, SQL sorgularında genellikle şartlı mantık uygulamak için kullanılır.


### Genel Söz Dizimi

```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ...
    ELSE resultN
END
```

- **`condition`**: Değerlendirilecek koşul.
- **`result`**: Koşul doğru olduğunda döndürülecek sonuç.
- **`ELSE`**: Yukarıdaki hiçbir koşul sağlanmadığında döndürülecek varsayılan sonuç.
- **`END`**: `CASE` ifadesinin sonunu belirtir.



### `CASE` İfadesinin Kullanım Örnekleri


Tabii! Aşağıda, `employees` tablosuna `salary` (maaş) sütununu ekleyerek yeniden oluşturduk. Bu tabloya bazı örnek veriler ekleyeceğiz ve ardından daha önce verilen `CASE` ifadesi ile birlikte maaşları da içeren bir sorgu çalıştıracağız.

### 1. `employees` Tablosunu Oluşturma (Salary Alanı Eklenmiş)

```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL  -- Maaş alanı eklendi
);
```

### 2. `employees` Tablosuna Veri Ekleme (Salary Alanı ile)

```sql
INSERT INTO employees (first_name, last_name, department, salary) VALUES
('John', 'Doe', 'Sales', 7500.00),
('Jane', 'Smith', 'Engineering', 6000.00),
('Emily', 'Jones', 'Marketing', 4500.00),
('Michael', 'Brown', 'Sales', 5800.00),
('Sarah', 'Davis', 'Engineering', 5200.00),
('James', 'Wilson', 'Marketing', 7300.00),
('Anna', 'Moore', 'HR', 5000.00),
('Robert', 'Taylor', 'Finance', 6200.00),
('David', 'Anderson', 'Sales', 5900.00),
('Laura', 'Thomas', 'Engineering', 6400.00);
```

Aşağıda PostgreSQL’de `CASE` ifadesinin çeşitli kullanım örneklerini bulabilirsiniz.

#### Örnek 1: Basit `CASE` Kullanımı

Bu örnekte, bir çalışanın maaşına göre bir kategori belirlemek istiyoruz. Çalışanın maaşı `5000` ve üzeriyse `High`, `3000` ile `5000` arasında ise `Medium`, `3000`'den düşükse `Low` olarak sınıflandıracağız.

```sql
SELECT employee_id, first_name, last_name,
       CASE
           WHEN salary >= 7000 THEN 'High'
           WHEN salary >= 5000 THEN 'Medium'
           ELSE 'Low'
       END AS salary_category
FROM employees;
```

#### Örnek 2: `CASE` İfadesiyle Fiyat İndirim Hesaplama

Bu örnekte, ürünlerin fiyatlarına göre bir indirim uygulamak istiyoruz. Fiyatı `100`'den fazla olan ürünlere `%20`, `50` ile `100` arasında olanlara `%10`, ve `50`'den düşük olanlara `%5` indirim uygulanacak.

```sql
SELECT product_id, product_name, price,
       CASE
           WHEN price > 100 THEN price * 0.80  -- %20 indirim
           WHEN price >= 50 THEN price * 0.90  -- %10 indirim
           ELSE price * 0.95  -- %5 indirim
       END AS discounted_price
FROM products;
```

#### Örnek 3: `CASE` İfadesi ve `ORDER BY` ile Koşullu Sıralama

Bu örnekte, çalışanların departmanına göre sıralama yapmak istiyoruz. Departman adı 'Sales' olanlar öncelikli olarak en üstte yer alacak, diğerleri alfabetik sıraya göre sıralanacak.

```sql
SELECT employee_id, first_name, last_name, department
FROM employees
ORDER BY
       CASE
           WHEN department = 'Sales' THEN 1
           ELSE 2
       END, department;
```

**Açıklama**:
- Bu `CASE` ifadesi `ORDER BY` ile kullanılarak, 'Sales' departmanındaki çalışanların en üstte olmasını sağlar. Diğer departmanlar alfabetik olarak sıralanır.

#### Örnek 5: `CASE` İfadesi ile Koşullu Güncelleme

Bu örnekte, `inventory` tablosunda stok seviyelerine göre farklı işlemler yapacağız. Stok seviyesine bağlı olarak farklı `stock_status` değerleri ayarlanacak.

```sql
UPDATE inventory
SET stock_status =
       CASE
           WHEN stock_level > 100 THEN 'High'
           WHEN stock_level BETWEEN 50 AND 100 THEN 'Medium'
           ELSE 'Low'
       END;
```

**Açıklama**:
- `CASE` ifadesi, `stock_level` sütununu değerlendirir ve `stock_status` sütununu uygun değere günceller (`High`, `Medium`, `Low`).