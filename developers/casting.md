# CAST

PostgreSQL'de, `CAST` operatörü veya `::` operatörü kullanılarak bir veri türünü başka bir veri türüne dönüştürme işlemi gerçekleştirilir. Veri türleri arasında dönüşüm yaparken çeşitli yöntemler kullanabilirsiniz. Aşağıda PostgreSQL'de `CAST` ve `::` operatörlerinin farklı kullanım örneklerini görebilirsiniz.

### 1. `CAST` Kullanarak Dönüştürme

`CAST` sözdizimi ile bir değeri belirtilen bir veri türüne dönüştürebilirsiniz:

```sql
SELECT CAST('123' AS INTEGER);  -- String'i tamsayıya dönüştürme
```

Bu sorgu, `'123'` string değerini tamsayı (`INTEGER`) veri türüne dönüştürür ve `123` olarak döndürür.

### 2. `::` Operatörünü Kullanarak Dönüştürme

`::` operatörü, bir değeri belirtilen bir veri türüne dönüştürmenin alternatif bir yoludur:

```sql
SELECT '123'::INTEGER;  -- String'i tamsayıya dönüştürme
```

Bu sorgu da aynı şekilde `'123'` string değerini tamsayı (`INTEGER`) veri türüne dönüştürür ve `123` olarak döndürür.

### 3. Tarih ve Saat Dönüşümleri

Tarih ve saat verilerini dönüştürmek için `CAST` veya `::` operatörünü kullanabilirsiniz:

```sql
SELECT CAST('2024-06-01' AS DATE);  -- String'i tarihe dönüştürme
```

veya

```sql
SELECT '2024-06-01'::DATE;  -- String'i tarihe dönüştürme
```

Bu sorgular, `'2024-06-01'` string değerini tarih (`DATE`) veri türüne dönüştürür ve `2024-06-01` tarihini döndürür.

### 4. Sayısal Dönüşümler

Sayısal verileri farklı veri türlerine dönüştürmek için `CAST` veya `::` kullanabilirsiniz:

```sql
SELECT CAST(123 AS DECIMAL(5, 2));  -- Tamsayıyı ondalıklı sayıya dönüştürme
```

veya

```sql
SELECT 123::DECIMAL(5, 2);  -- Tamsayıyı ondalıklı sayıya dönüştürme
```

Bu sorgular, `123` tamsayı değerini `DECIMAL` veri türüne dönüştürür ve `123.00` olarak döndürür.

### 5. Metin ve Karakter Dönüşümleri

Metin verilerini karakter dizisi (string) veri türüne dönüştürmek için `CAST` veya `::` kullanabilirsiniz:

```sql
SELECT CAST(123 AS TEXT);  -- Tamsayıyı metne dönüştürme
```

veya

```sql
SELECT 123::TEXT;  -- Tamsayıyı metne dönüştürme
```

Bu sorgular, `123` tamsayı değerini metin (`TEXT`) veri türüne dönüştürür ve `'123'` olarak döndürür.

### 6. JSON ve JSONB Dönüşümleri

PostgreSQL'de JSON ve JSONB veri türleri arasında dönüşüm yapmak mümkündür:

```sql
SELECT CAST('{"key": "value"}' AS JSONB);  -- JSON string'i JSONB'ye dönüştürme
```

veya

```sql
SELECT '{"key": "value"}'::JSONB;  -- JSON string'i JSONB'ye dönüştürme
```

Bu sorgular, `'{"key": "value"}'` JSON string değerini `JSONB` veri türüne dönüştürür.

### 7. NULL Değerlerini Dönüştürme

`NULL` değerlerini belirli bir veri türüne dönüştürmek için `CAST` veya `::` kullanabilirsiniz:

```sql
SELECT CAST(NULL AS INTEGER);  -- NULL değerini tamsayıya dönüştürme
```

veya

```sql
SELECT NULL::INTEGER;  -- NULL değerini tamsayıya dönüştürme
```

Bu sorgular, `NULL` değerini tamsayı (`INTEGER`) veri türüne dönüştürür.

### 8. Karmaşık Dönüşümler

Birden fazla veri türü dönüştürmesi yapılabilir. Örneğin, bir `TIMESTAMP` değerini önce `TEXT` sonra `DATE` türüne dönüştürme:

```sql
SELECT CAST(CAST('2024-06-05 12:34:56' AS TEXT) AS DATE);  -- Zaman damgasını önce metne, sonra tarihe dönüştürme
```

veya

```sql
SELECT ('2024-06-05 12:34:56'::TEXT)::DATE;  -- Zaman damgasını önce metne, sonra tarihe dönüştürme
```

Bu sorgular, `'2024-06-05 12:34:56'` zaman damgası değerini önce metin (`TEXT`) veri türüne, ardından tarih (`DATE`) veri türüne dönüştürür ve `2024-06-05` tarihini döndürür.

### 9. Veri Tablosunda Dönüşüm

Bir tablo sütunundaki verileri dönüştürmek için `CAST` veya `::` kullanılabilir. Örneğin, bir `orders` tablosunda `total` sütunundaki sayısal değerleri metin olarak almak için:

```sql
SELECT CAST(total AS TEXT) FROM orders;  -- total sütunundaki sayısal verileri metin olarak döndürme
```

veya

```sql
SELECT total::TEXT FROM orders;  -- total sütunundaki sayısal verileri metin olarak döndürme
```

Bu sorgular, `orders` tablosundaki `total` sütunundaki sayısal değerleri metin olarak döndürür.

### Özet

PostgreSQL'de veri türlerini dönüştürmek için `CAST` ve `::` operatörlerini kullanarak çeşitli veri türleri arasında dönüşüm yapabilirsiniz. Bu dönüşümler, veritabanı işlemleri sırasında esnekliği artırır ve farklı veri türleri ile çalışma olanağı sağlar. Bu örnekler, PostgreSQL'deki dönüşümleri nasıl gerçekleştireceğinizi ve farklı veri türlerini nasıl dönüştüreceğinizi anlamanıza yardımcı olacaktır.