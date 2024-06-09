# json


Elbette! PostgreSQL'in JSONB veri türü, JSON verilerini saklamak için oldukça esnek ve güçlü bir yol sunar. JSONB, verilerin ikili biçimde (binary) depolanmasını sağlar, bu da genellikle daha hızlı sorgulama ve işleme anlamına gelir. JSONB ile çalışmanın temel adımlarını ve bazı yaygın kullanımları inceleyelim.

### JSONB ile Çalışma: Örnekler

#### 1. JSONB Sütunu İçeren Tablo Oluşturma

Öncelikle, JSONB veri türünü içeren bir tablo oluşturalım:

```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    attributes JSONB
);
```

Bu örnekte, `products` tablosu `id`, `name` ve `attributes` sütunlarını içerir. `attributes` sütunu JSONB türünde olup, ürünlere ait çeşitli özellikleri JSON formatında saklayabilir.

#### 2. JSONB Veri Ekleme

Tabloya JSONB veri ekleyelim:

```sql
INSERT INTO products (name, attributes)
VALUES
('Laptop', '{"brand": "BrandX", "processor": "Intel i7", "RAM": "16GB"}'),
('Smartphone', '{"brand": "BrandY", "processor": "Snapdragon 888", "RAM": "8GB"}');

INSERT INTO products (name, attributes)
VALUES
('Tablet', '{"brand": "BrandZ", "processor": "Apple A12", "storage": "128GB"}'),
('Smartwatch', '{"brand": "BrandW", "features": ["Heart Rate Monitor", "GPS", "Bluetooth"]}');

INSERT INTO products (name, attributes)
VALUES
('Gaming Console', '{"brand": "BrandG", "specs": {"CPU": "Custom", "GPU": "RDNA 2", "RAM": "16GB"}, "released_year": 2021}');

INSERT INTO products (name, attributes)
VALUES
('Headphones', '{"brand": "BrandH", "type": "Over-Ear", "wireless": true, "noise_cancellation": true}');

INSERT INTO products (name, attributes)
VALUES
('E-Reader', '{"brand": "BrandE"}');

```

##### Belirli Bir JSON Anahtarını Çekmek

JSONB sütunundan belirli bir anahtarın değerini almak için `->>` operatörünü kullanabiliriz:

```sql
SELECT name, attributes->>'brand' AS brand
FROM products;
```

Bu sorgu, `attributes` sütunundaki `brand` anahtarının değerini alır.

##### JSONB İçindeki Belirli Bir Anahtara Göre Filtreleme

JSONB içindeki belirli bir anahtara göre filtreleme yapmak için `@>` operatörünü kullanabiliriz:

```sql
SELECT * FROM products
WHERE attributes @> '{"RAM": "8GB"}';
```

Bu sorgu, `attributes` içinde `RAM` değeri `8GB` olan tüm ürünleri döndürecektir.

##### JSONB Veri Güncelleme

JSONB veri tipinde belirli bir anahtarın değerini güncellemek için `jsonb_set` fonksiyonunu kullanabiliriz:

```sql
UPDATE products
SET attributes = jsonb_set(attributes, '{processor}', '"AMD Ryzen 7"')
WHERE name = 'Laptop';
```

Bu sorgu, `Laptop` ürünü için `attributes` içindeki `processor` anahtarının değerini `"AMD Ryzen 7"` olarak günceller.

##### JSONB'den Belirli Bir Anahtarı Silme

JSONB veri tipinden belirli bir anahtarı kaldırmak için `-` operatörünü kullanabiliriz:

```sql
UPDATE products
SET attributes = attributes - 'RAM'
WHERE name = 'Smartphone';
```

Bu sorgu, `Smartphone` ürünü için `attributes` içindeki `RAM` anahtarını kaldırır.


Ve belirli JSONB veri yapılarını sorgulamak için daha gelişmiş sorgular da yapabiliriz. Örneğin, `features` anahtarını içeren ürünleri bulmak için:

```sql
SELECT name, attributes
FROM products
WHERE attributes ? 'features';
```

### JSONB ile İleri Düzey Kullanımlar

#### JSONB İndeksleme

JSONB sütunlarına daha hızlı erişim sağlamak için `GIN` veya `BTREE` indeksleri kullanabilirsiniz. Örneğin:

```sql
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);
```

Bu indeks, `attributes` sütunundaki JSONB verileri üzerinde daha hızlı sorgular çalıştırmanıza olanak tanır.

#### JSONB Fonksiyonları ve Operatörleri

PostgreSQL, JSONB veri türü ile çalışmak için birçok fonksiyon ve operatör sağlar. İşte bazı yaygın kullanılanlar:

- `->` : JSON nesnesi içindeki bir anahtarı veya dizin numarasını döndürür.
- `->>` : JSON nesnesi içindeki bir anahtarın veya dizin numarasının metin değerini döndürür.
- `@>` : Bir JSON nesnesinin diğer bir JSON nesnesini içerip içermediğini kontrol eder.
- `jsonb_set` : JSON nesnesindeki bir değeri günceller.
- `jsonb_array_elements` : JSONB dizisini elemanlarına ayırır.




Tabii! PostgreSQL'in JSONB veri türü üzerinde çalışırken, belirli JSON anahtarlarına veya değerlerine erişimi hızlandırmak için indeksler kullanabilirsiniz. Bu, büyük JSONB veri kümeleri üzerinde daha hızlı sorgular çalıştırmanıza olanak tanır. JSONB veri yapısında indeksleme yapabileceğiniz bazı yaygın yöntemlere bakalım.

### JSONB Üzerinde İndeksleme

#### 1. Basit GIN İndeksi

GIN (Generalized Inverted Index) indeksi, JSONB veri türü üzerinde hızlı sorgulama yapmayı sağlar. GIN indeksleri, tüm JSON yapısını indeksler ve özellikle içerik aramaları için etkilidir.

```sql
CREATE INDEX idx_products_attributes_gin
ON products
USING gin (attributes);
```

Bu indeks, `attributes` sütunundaki tüm JSONB verilerini kapsar ve hızlı içerik aramaları sağlar. Örneğin, belirli bir anahtarı içeren tüm kayıtları bulmak için:

```sql
SELECT * FROM products
WHERE attributes @> '{"brand": "BrandX"}';
```

Bu sorgu, `attributes` sütununda `"brand": "BrandX"` değerine sahip tüm satırları döndürecektir ve GIN indeksi sayesinde hızlı olacaktır.

#### 2. Belirli Bir JSON Anahtarına Göre B-Tree İndeksi

B-Tree indeksi, JSONB verilerinde belirli bir anahtarın metin değeri üzerinde sıralı arama yapmayı hızlandırır. Örneğin, belirli bir JSON anahtarına göre indeks oluşturmak isterseniz:

```sql
CREATE INDEX idx_products_brand
ON products ((attributes->>'brand'));
```

Bu indeks, `attributes` içindeki `brand` anahtarının değerini çıkarır ve metin olarak B-Tree indeksi oluşturur. Bu, belirli bir markaya sahip tüm ürünleri hızlıca bulmanızı sağlar:

```sql
SELECT * FROM products
WHERE attributes->>'brand' = 'BrandX';
```

#### 3. JSONB Verisindeki Dizilere Erişim İçin GIN İndeksi

Eğer JSONB verinizde diziler varsa ve bu dizilere erişim yapmanız gerekiyorsa, GIN indeksi kullanarak hızlı aramalar yapabilirsiniz. Örneğin:

```sql
CREATE INDEX idx_products_features
ON products
USING gin (jsonb_array_elements_text(attributes->'features'));
```

Bu indeks, `attributes` içindeki `features` anahtarının içindeki her bir dizi elemanı üzerinde bir GIN indeksi oluşturur. Bu, belirli bir özellik içeren ürünleri hızlıca bulmanızı sağlar:

```sql
SELECT * FROM products
WHERE attributes->'features' ? 'GPS';
```

#### 4. JSONB Verisinde Çoklu Anahtar Üzerinde B-Tree İndeksi

Birden fazla JSON anahtarını içeren sorgular için B-Tree indeksleri oluşturabilirsiniz. Örneğin, `brand` ve `processor` anahtarlarına göre indeks oluşturmak isterseniz:

```sql
CREATE INDEX idx_products_brand_processor
ON products ((attributes->>'brand'), (attributes->>'processor'));
```

Bu indeks, `attributes` içindeki `brand` ve `processor` anahtarlarının değerleri üzerinde bir B-Tree indeksi oluşturur. Bu, hem marka hem de işlemciye göre hızlı aramalar yapmanızı sağlar:

```sql
SELECT * FROM products
WHERE attributes->>'brand' = 'BrandX'
AND attributes->>'processor' = 'Intel i7';
```


https://tubitak-bilgem-yte.github.io/pg-gelistirici/docs/03-ozellikler/json/

