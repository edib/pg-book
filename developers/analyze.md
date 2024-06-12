# ANALYZE

PostgreSQL'de `ANALYZE` komutu, veritabanındaki tabloların istatistiklerini toplamak ve güncellemek için kullanılır. Bu istatistikler, sorgu planlayıcı (query planner) tarafından en iyi sorgu yürütme planını belirlemek için kullanılır. `ANALYZE` komutu, tablolardaki veri dağılımı ve veri hacmi hakkında bilgi toplar ve bu bilgileri PostgreSQL sistem kataloglarına kaydeder.

### `ANALYZE` Komutunun Kullanımı

`ANALYZE` komutu, bir tablo veya tüm veritabanı üzerinde çalıştırılabilir. 

#### 1. Temel Kullanım

**Tüm Veritabanı İçin**:

```sql
ANALYZE;
```

Bu komut, veritabanındaki tüm tabloların istatistiklerini toplar.

**Belirli Bir Tablo İçin**:

```sql
ANALYZE tb_musteri;
```

Bu komut, yalnızca `tb_musteri` tablosunun istatistiklerini toplar.

**Belirli Sütunlar İçin**:

```sql
ANALYZE tb_musteri (ad, soyad);
```

Bu komut, `tb_musteri` tablosundaki yalnızca `ad` ve `soyad` sütunlarının istatistiklerini toplar.

#### 2. `VACUUM` ve `ANALYZE` Birlikte Kullanımı

PostgreSQL'de, `VACUUM` komutu genellikle veritabanı bakımı için kullanılır ve veritabanını temizlerken, `ANALYZE` komutunu da otomatik olarak çalıştırabilir.

```sql
VACUUM ANALYZE tb_musteri;
```

Bu komut, `tb_musteri` tablosunu temizler ve ardından istatistiklerini toplar.

### `ANALYZE` Komutunun Çıktısı

`ANALYZE` komutu çalıştırıldığında, PostgreSQL sorgu planlayıcı için aşağıdaki türde istatistikleri toplar:

- **Tablodaki Satır Sayısı**: Tablo kaç satır içeriyor.
- **Veri Dağılımı**: Belirli sütunların veri değerlerinin dağılımı.
- **Boşluk Bilgisi**: Tablodaki boş alan miktarı ve veri yerleşimi.
- **Tablo ve Sütun Boyutu**: Tablonun ve sütunların fiziksel boyutları.

### `ANALYZE`'ın Sorgu Performansına Etkisi

Sorgu planlayıcısı, sorguları optimize etmek için topladığı istatistikleri kullanır. Bu istatistikler olmadan veya güncel değilse, sorgu planlayıcı yanlış yürütme planları seçebilir ve bu da sorgu performansını olumsuz etkileyebilir. `ANALYZE` komutunu düzenli olarak çalıştırmak, sorguların daha verimli bir şekilde çalışmasını sağlar.

### İstatistiklerin Yönetimi

PostgreSQL, istatistiklerin toplanmasını ve yönetilmesini sağlayan çeşitli parametreler sunar. Bu parametreler, `postgresql.conf` dosyasında veya `ALTER TABLE` komutu ile ayarlanabilir.

#### 1. `default_statistics_target`

Bu parametre, toplamak istediğiniz varsayılan istatistik ayrıntı seviyesini kontrol eder. Varsayılan değeri genellikle 100'dür, ancak bu değer belirli tablolar veya sütunlar için artırılabilir veya azaltılabilir.

**Varsayılan Değeri Ayarlama**:

```sql
SET default_statistics_target = 100;
```

**Belirli Bir Tablo veya Sütun İçin Ayarlama**:

```sql
ALTER TABLE tb_musteri ALTER COLUMN ad SET STATISTICS 200;
```

Bu komut, `ad` sütunu için daha ayrıntılı istatistikler toplar.

#### 2. Otomatik `ANALYZE` (Auto-Vacuum)

PostgreSQL, `autovacuum` adı verilen bir mekanizma kullanarak tabloları otomatik olarak analiz eder ve vakumlar. Bu, veritabanı yöneticilerinin manuel müdahale gerektirmeden istatistikleri güncel tutmasına yardımcı olur.

`autovacuum` yapılandırma parametreleri şunlardır:

- **`autovacuum`**: `ON` olarak ayarlandığında, otomatik `VACUUM` ve `ANALYZE` işlemleri etkinleştirilir.
- **`autovacuum_analyze_threshold`**: Bir tabloya uygulanacak minimum satır değişiklik sayısı.
- **`autovacuum_analyze_scale_factor`**: Bir tabloya uygulanacak ek bir ölçek faktörü.

**Örnek Konfigürasyon**:

```conf
autovacuum = on
autovacuum_analyze_threshold = 50
autovacuum_analyze_scale_factor = 0.02
```
VACUUM ANALYZE tb_musteri;

Bu ayarlar, `autovacuum` özelliğini etkinleştirir ve `ANALYZE` işleminin, tabloda %2 oranında bir değişiklik veya en az 50 satır değişikliği olduğunda çalışmasını sağlar.

- **`ANALYZE` Komutu**: Tabloların ve sütunların istatistiklerini toplar ve günceller.
- **Sorgu Planlayıcı**: Bu istatistikleri kullanarak en iyi sorgu yürütme planını belirler.
- **Düzenli Kullanım**: `ANALYZE`'ı düzenli olarak çalıştırmak, veritabanı performansını optimize etmeye yardımcı olur.
- **Otomatik `ANALYZE`**: PostgreSQL'in `autovacuum` mekanizması, tabloları otomatik olarak analiz eder ve güncel tutar.
- **Ayarlar ve İstatistik Hedefleri**: `default_statistics_target` gibi ayarlarla, toplamak istediğiniz istatistiklerin ayrıntı seviyesini belirleyebilirsiniz.

### default_statistics_target

```sql
ALTER TABLE tb_musteri ALTER COLUMN ad SET STATISTICS 200;
ALTER TABLE sales ALTER COLUMN amount SET STATISTICS 300;
```

#### Bellek Kullanımı ve Performans Dengelemesi

Daha Yüksek Değerler: Daha ayrıntılı istatistikler toplamak, sorgu planlayıcının daha iyi performans göstermesini sağlayabilir, ancak bu daha fazla bellek ve işlemci kaynakları tüketir.
Daha Düşük Değerler: Daha az ayrıntılı istatistikler, kaynak kullanımını azaltabilir, ancak sorgu planlayıcının performansı üzerinde olumsuz etkisi olabilir.

## LOCK ETKİSİ

- **`VACUUM`**: Tabloda `SHARE UPDATE EXCLUSIVE` kilidi alır. DDLler engellenir.
- **`ANALYZE`**: Tabloda `ACCESS SHARE` kilidi alır.

## CREATE STATISTICS

1. **Kombine İstatistikler**:
   - `CREATE STATISTICS`, birden fazla sütun için kombine istatistikler toplar. Bu, özellikle birlikte filtrelenen veya sorgulanan sütunlar için faydalıdır.
   - Örneğin, `WHERE` koşulunda sıklıkla birden fazla sütun kullanılıyorsa, bu sütunlar arasındaki ilişkileri ve bağımlılıkları anlamak sorgu planlayıcı için faydalıdır.

2. **Bağımsızlık Varsayımı**:
   - PostgreSQL sorgu planlayıcısı, sütunlar arasındaki bağımlılığı varsayımsal olarak bağımsız kabul eder. Bu, çoğu zaman doğru tahminler yapmasını zorlaştırabilir. `CREATE STATISTICS` ile sütunlar arasındaki bağımlılıkları belirleyerek bu sorunu aşabilirsiniz.

3. **Farklı Türde İstatistikler**:
   - `CREATE STATISTICS`, n-distinct (NDISTINCT), dependencies (DEPENDENCIES), ve diğer türlerde istatistikler oluşturabilir.
   - **NDISTINCT**: Belirtilen sütun kombinasyonunda farklı değerlerin sayısını tahmin eder.
   - **DEPENDENCIES**: Sütunlar arasındaki bağımlılıkları belirler ve bu bağımlılıkları kullanarak daha iyi selektör (seçici) tahminleri sağlar.

```sql
CREATE STATISTICS stat_name (ndistinct, dependencies)
ON column1, column2
FROM table_name;
```

https://www.postgresql.org/docs/current/sql-createstatistics.html

### `CREATE STATISTICS` vs `ANALYZE` Farkları

| Özellik                          | `CREATE STATISTICS`                           | `ANALYZE`                                      |
|----------------------------------|-----------------------------------------------|------------------------------------------------|
| **Amaç**                         | Birden fazla sütun arasındaki ilişkileri anlamak ve optimize etmek | Tablolar ve sütunlar için genel istatistikler toplamak |
| **Kullanım Alanı**               | Birden fazla sütunun birlikte kullanıldığı veya bağımlı olduğu durumlar | Tek sütunlu istatistikler ve genel tablo optimizasyonu |
| **İstatistik Türleri**           | Kombine istatistikler: n-distinct, dependencies | Temel istatistikler: veri dağılımı, histogramlar |
| **Hedef Sütunlar**               | Belirtilen sütun kombinasyonları               | Tüm sütunlar veya belirtilen sütunlar          |
| **Komut Kullanımı**              | `CREATE STATISTICS` komutu ile                | `ANALYZE` komutu ile                           |