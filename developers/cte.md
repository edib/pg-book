# CTE

PostgreSQL'de **`WITH`** ifadesi, ortak tablo ifadeleri (CTE - Common Table Expressions) olarak bilinir ve karmaşık sorguları daha okunabilir ve yönetilebilir hale getirmek için kullanılır. `WITH` ifadesi, geçici bir ad verilmiş alt sorgular tanımlayarak, bu alt sorguları ana sorguda kullanmanıza olanak tanır.

### `WITH` İfadesinin Kullanımı

Aşağıda, `WITH` ifadesi ile çeşitli örnekler yer almaktadır. Örneklerde, `employees` ve `departments` adlı iki tablonun kullanıldığını varsayalım.

### Örnek Tablolar

```sql
CREATE TABLE employees (
employee_id SERIAL PRIMARY KEY,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
department_id INT,
salary NUMERIC(10, 2)
);

CREATE TABLE departments (
department_id SERIAL PRIMARY KEY,
department_name VARCHAR(100) NOT NULL
);

INSERT INTO employees (first_name, last_name, department_id, salary) VALUES
('John', 'Doe', 1, 5000.00),
('Jane', 'Smith', 2, 6000.00),
('Emily', 'Jones', 1, 5500.00),
('Michael', 'Brown', 3, 4500.00),
('Sarah', 'Davis', 2, 5200.00);

INSERT INTO departments (department_name) VALUES
('HR'),
('Engineering'),
('Marketing');
```

### `WITH` İfadesi Kullanarak Basit Bir Örnek

Amacımız, her departmandaki ortalama maaşı hesaplayıp, bu bilgiyi kullanarak ortalama maaştan daha yüksek maaş alan çalışanları bulmak.

```sql
WITH department_avg_salary AS (
    SELECT department_id,
        AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.first_name,
    e.last_name,
    e.salary,
    d.department_name
FROM employees e
    JOIN department_avg_salary das ON e.department_id = das.department_id
    JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > das.avg_salary;
```

### Açıklama

1. **`WITH` İfadesi**:

```sql
WITH department_avg_salary AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
```

- `department_avg_salary` adlı geçici bir tablo (CTE) oluşturur.
- Bu alt sorgu, her departmanın ortalama maaşını hesaplar.

2. **Ana Sorgu**:

```sql
SELECT e.first_name, e.last_name, e.salary, d.department_name
FROM employees e
JOIN department_avg_salary das ON e.department_id = das.department_id
JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > das.avg_salary;
```

- `employees` tablosundaki her çalışanı seçer ve `department_avg_salary` CTE'si ile birleştirir.
- `departments` tablosu ile birleşim yapılarak departman adları da eklenir.
- Sonuç kümesi, maaşı ortalama maaştan yüksek olan çalışanları içerir.

### Karmaşık Bir `WITH` İfadesi Örneği

Birden fazla CTE kullanarak daha karmaşık bir sorgu oluşturabiliriz. Bu örnekte, her departmandaki en yüksek maaşı alan çalışanları bulalım.

```sql
WITH max_salary_per_department AS (
    SELECT department_id, MAX(salary) AS max_salary
    FROM employees
    GROUP BY department_id
),
highest_paid_employees AS (
    SELECT e.first_name, e.last_name, e.department_id, e.salary
    FROM employees e
    JOIN max_salary_per_department mspd
    ON e.department_id = mspd.department_id AND e.salary = mspd.max_salary
)
SELECT hpe.first_name, hpe.last_name, hpe.salary, d.department_name
FROM highest_paid_employees hpe
JOIN departments d ON hpe.department_id = d.department_id;
```

### Açıklama

1. **`WITH` İfadesi ile En Yüksek Maaşı Hesaplayan CTE**:

```sql
WITH max_salary_per_department AS (
    SELECT department_id, MAX(salary) AS max_salary
    FROM employees
    GROUP BY department_id
),
```

- `max_salary_per_department` adlı bir CTE oluşturur.
- Bu CTE, her departmandaki en yüksek maaşı bulur.

2. **`WITH` İfadesi ile En Yüksek Maaşlı Çalışanları Bulan CTE**:

```sql
highest_paid_employees AS (
    SELECT e.first_name, e.last_name, e.department_id, e.salary
    FROM employees e
    JOIN max_salary_per_department mspd
    ON e.department_id = mspd.department_id AND e.salary = mspd.max_salary
)
```

- `highest_paid_employees` adlı bir CTE oluşturur.
- Bu CTE, her departmandaki en yüksek maaşı alan çalışanları bulur.

3. **Ana Sorgu**:

```sql
SELECT hpe.first_name, hpe.last_name, hpe.salary, d.department_name
FROM highest_paid_employees hpe
JOIN departments d ON hpe.department_id = d.department_id;
```

- `highest_paid_employees` CTE'sindeki verileri kullanarak en yüksek maaşı alan çalışanları seçer ve `departments` tablosu ile birleştirir.
- Sonuç kümesi, her departmandaki en yüksek maaşı alan çalışanların bilgilerini içerir.

### Sonuç

Bu `WITH` ifadesi ve alt sorgu örnekleri, PostgreSQL'de karmaşık veri ilişkilerini ve hesaplamalarını nasıl daha okunabilir ve yönetilebilir hale getirebileceğinizi gösterir. `WITH` ifadesi, geçici sonuç kümeleri oluşturmanıza ve bu kümeleri ana sorguda kullanmanıza olanak tanır, böylece sorguların okunabilirliğini artırır ve performansını iyileştirir.