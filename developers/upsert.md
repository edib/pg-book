# UPSERT

PostgreSQL'de **upsert** işlemi, yani veritabanında bir satırın var olup olmadığını kontrol edip, eğer yoksa eklemek (insert), varsa güncellemek (update) için kullanılan bir tekniktir. Bu işlem PostgreSQL 9.5'ten itibaren `INSERT ON CONFLICT` ifadesi ile desteklenmektedir.

`INSERT ON CONFLICT` ifadesi, `INSERT` komutu ile eklenmek istenen satırın, belirli bir anahtar (genellikle birincil anahtar veya benzersiz anahtar) üzerinde çakışma (conflict) olup olmadığını kontrol eder ve eğer bir çakışma varsa, belirli bir eylemi gerçekleştirir.

### Temel `INSERT ON CONFLICT` Kullanımı

Aşağıda, `INSERT ON CONFLICT` ifadesini kullanarak temel bir upsert işlemini nasıl gerçekleştirebileceğinizi göstereceğim.

#### Örnek Tablo

Öncelikle bir örnek tablo oluşturalım:

```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) UNIQUE,
    price NUMERIC
);
```

Bu tablo, ürünleri tutar ve `product_name` sütunu üzerinde bir benzersiz kısıtlamaya sahiptir.

### INSERT ON CONFLICT Kullanarak Upsert

Şimdi, `INSERT ON CONFLICT` ifadesini kullanarak bir ürün ekleyeceğiz veya zaten mevcutsa fiyatını güncelleyeceğiz.

```sql
INSERT INTO products (product_name, price)
VALUES ('Apple', 1.50)
ON CONFLICT (product_name)
DO UPDATE SET price = EXCLUDED.price;
```

### Açıklama

- **`INSERT INTO products (product_name, price)`**: `products` tablosuna `product_name` ve `price` sütunlarına yeni bir satır eklemeye çalışırız.
- **`VALUES ('Apple', 1.50)`**: Eklenecek yeni satırın değerleri olarak `'Apple'` ve `1.50` belirlenir.
- **`ON CONFLICT (product_name)`**: `product_name` sütununda bir çakışma olup olmadığını kontrol eder. Yani, `'Apple'` adlı bir ürün zaten mevcutsa bir çakışma oluşur.
- **`DO UPDATE SET price = EXCLUDED.price`**: Çakışma varsa, mevcut satırı günceller. `EXCLUDED.price`, eklenmeye çalışılan yeni satırın `price` değerini ifade eder.

### Ek Bir Sütun Kullanarak Upsert

Birden fazla sütunu içeren bir upsert örneği de yapabiliriz. Bu durumda, ürünün adını ve fiyatını ekleyecek veya fiyat ve başka bir bilgiyi güncelleyeceğiz.

```sql
INSERT INTO products (product_name, price)
VALUES ('Banana', 0.75)
ON CONFLICT (product_name)
DO UPDATE SET 
    price = EXCLUDED.price,
    product_name = EXCLUDED.product_name || ' (Updated)';
```

### Açıklama

- **`ON CONFLICT (product_name)`**: `product_name` sütununda çakışma olup olmadığını kontrol eder.
- **`DO UPDATE SET price = EXCLUDED.price, product_name = EXCLUDED.product_name || ' (Updated)'`**:
  - Çakışma varsa, mevcut satırı günceller.
  - `price` sütununu yeni değer ile günceller.
  - `product_name` sütununu güncellerken, mevcut adı " (Updated)" ifadesi ile birleştirir.

### `DO NOTHING` Kullanarak Çakışma Yönetimi

Eğer çakışma durumunda herhangi bir işlem yapmak istemiyorsanız, `DO NOTHING` ifadesini kullanabilirsiniz.

```sql
INSERT INTO products (product_name, price)
VALUES ('Orange', 1.00)
ON CONFLICT (product_name)
DO NOTHING;
```

### Açıklama

- **`ON CONFLICT (product_name)`**: `product_name` sütununda çakışma olup olmadığını kontrol eder.
- **`DO NOTHING`**: Çakışma varsa, hiçbir şey yapmaz. Mevcut satır üzerinde herhangi bir güncelleme yapılmaz ve yeni satır eklenmez.

### `ON CONFLICT` ile Birden Fazla Sütunda Çakışma Yönetimi

Birden fazla sütun üzerinde çakışmayı kontrol etmek için, bir benzersiz kısıtlama (UNIQUE constraint) veya birincil anahtar (PRIMARY KEY) kullanabilirsiniz.

#### Örnek Tablo

```sql
CREATE TABLE inventory (
    warehouse_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (warehouse_id, product_id)
);
```

Bu tablo, `warehouse_id` ve `product_id` sütunları üzerinde bir birincil anahtara sahiptir.

#### Birden Fazla Sütunda Çakışma ile Upsert

```sql
INSERT INTO inventory (warehouse_id, product_id, quantity)
VALUES (1, 101, 500)
ON CONFLICT (warehouse_id, product_id)
DO UPDATE SET quantity = inventory.quantity + EXCLUDED.quantity;
```

### Açıklama

- **`ON CONFLICT (warehouse_id, product_id)`**: `warehouse_id` ve `product_id` sütunlarında çakışma olup olmadığını kontrol eder.
- **`DO UPDATE SET quantity = inventory.quantity + EXCLUDED.quantity`**:
  - Çakışma varsa, mevcut satırı günceller.
  - `quantity` sütununu mevcut değerine yeni eklenmek istenen değeri ekleyerek günceller.

### `INSERT ON CONFLICT` ile İlişkili Veriler

Daha karmaşık bir örnek olarak, ilişkili verilerle çalışmak mümkündür. Örneğin, bir müşteri siparişi sistemi düşünelim:

#### Örnek Tablo

```sql
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    order_total NUMERIC
);

CREATE TABLE order_details (
    detail_id SERIAL PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT
);
```

#### Sipariş ve Detayları İçin Upsert

Bir müşteri siparişinin toplamını ve detaylarını güncelleyen bir sorgu yazabiliriz:

```sql
INSERT INTO orders (customer_id, order_total)
VALUES (1, 150.00)
ON CONFLICT (order_id)
DO UPDATE SET order_total = orders.order_total + EXCLUDED.order_total;

INSERT INTO order_details (order_id, product_id, quantity)
VALUES (1, 101, 5)
ON CONFLICT (detail_id)
DO UPDATE SET quantity = order_details.quantity + EXCLUDED.quantity;
```

### Açıklama

- **`ON CONFLICT (order_id)` ve `ON CONFLICT (detail_id)`**: `order_id` ve `detail_id` sütunlarında çakışma olup olmadığını kontrol eder.
- **`DO UPDATE SET ...`**: Çakışma varsa, mevcut satırları günceller.

### Özet

- **Upsert İşlemi**: `INSERT ON CONFLICT` ifadesi, PostgreSQL'de veri eklerken veya güncellerken çakışmaları yönetmek için kullanılır.
- **Çakışma Yönetimi**: Çakışma durumunda, `DO UPDATE` veya `DO NOTHING` seçeneklerini kullanarak mevcut satırları güncelleyebilir veya hiçbir şey yapmayabilirsiniz.
- **Esneklik ve Performans**: Bu yöntem, veritabanı işlemlerini daha esnek ve performanslı hale getirir, özellikle büyük veritabanları ve karmaşık veri işleme senaryolarında faydalıdır.

Bu örnekler, PostgreSQL'de upsert işleminin nasıl gerçekleştirileceğini ve `INSERT ON CONFLICT` ifadesinin nasıl kullanılacağını göstermektedir.