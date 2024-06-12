# PERFORMANS

## İstatistik tabloları

### 0. `pg_stat_statements`

`pg_stat_statements` PostgreSQL'in bir uzantısı olup, veritabanı sorgularının performansını izlemek ve analiz etmek için kullanılan güçlü bir araçtır. Bu uzantı, PostgreSQL'deki tüm SQL sorgularının performans verilerini toplar ve saklar. Bu veriler, sorguların ne kadar süre çalıştığı, kaç kez çalıştırıldığı, ve kaynak tüketimi gibi bilgileri içerir. Bu bilgiler, performans sorunlarını teşhis etmek ve optimize etmek için kullanılır.

### `pg_stat_statements` Uzantısının Kurulumu ve Kullanımı

#### 1. Uzantının Kurulumu

Öncelikle, `pg_stat_statements` uzantısının PostgreSQL'de yüklü ve etkinleştirilmiş olması gerekir. Aşağıdaki adımlar, uzantıyı kurmak ve etkinleştirmek için gereklidir:

**a. Uzantıyı Etkinleştirme**

Uzantıyı etkinleştirmek için PostgreSQL süper kullanıcısı olarak oturum açın ve aşağıdaki komutu çalıştırın:

```sql
CREATE EXTENSION pg_stat_statements;
```

**b. PostgreSQL Ayar Dosyasını (postgresql.conf) Güncelleme**

`pg_stat_statements` uzantısının etkin olması için PostgreSQL ayar dosyasına (`postgresql.conf`) bazı ayarların eklenmesi gerekebilir. Bu dosyada aşağıdaki ayarları bulun veya ekleyin:

```conf
shared_preload_libraries = 'pg_stat_statements'  # Bu ayar PostgreSQL'i yeniden başlatmanızı gerektirir
pg_stat_statements.track = all                   # Tüm sorgu türlerini izlemek için
```

Ayarları yaptıktan sonra PostgreSQL sunucusunu yeniden başlatmanız gerekecektir.

```bash
sudo systemctl restart postgresql
```

#### 2. `pg_stat_statements` Görünümünü Kullanma

Uzantı etkinleştirildikten sonra, `pg_stat_statements` görünümünü kullanarak sorgu istatistiklerini görüntüleyebilirsiniz.

```sql
SELECT * FROM pg_stat_statements;
```

Bu sorgu, veritabanındaki tüm izlenen sorgular hakkında ayrıntılı bilgi döndürecektir.

### `pg_stat_statements` Görünümündeki Önemli Sütunlar

`pg_stat_statements` görünümü, çeşitli performans ölçümlerini sağlar. İşte bazı önemli sütunlar:

- **`userid`**: Sorguyu çalıştıran kullanıcının kimliği.
- **`dbid`**: Sorgunun çalıştırıldığı veritabanının kimliği.
- **`query`**: Normalleştirilmiş sorgu metni.
- **`calls`**: Sorgunun kaç kez çalıştırıldığı.
- **`total_time`**: Sorgunun toplam çalıştırma süresi (milisaniye cinsinden).
- **`min_time`**: Sorgunun en kısa çalıştırma süresi.
- **`max_time`**: Sorgunun en uzun çalıştırma süresi.
- **`mean_time`**: Sorgunun ortalama çalıştırma süresi.
- **`stddev_time`**: Sorgu çalıştırma süresinin standart sapması.
- **`rows`**: Sorgu tarafından döndürülen toplam satır sayısı.
- **`shared_blks_hit`**: Paylaşılan bellek bloklarına yapılan başarılı erişim sayısı (cache hits).
- **`shared_blks_read`**: Paylaşılan bellek bloklarına yapılan diskten okuma sayısı.
- **`shared_blks_written`**: Paylaşılan bellek bloklarına yapılan yazma sayısı.
- **`shared_blks_dirtied`**: Paylaşılan bellek bloklarının kirletildiği (dirtied) sayısı.
- **`temp_blks_read`**: Geçici bellek bloklarına yapılan okuma sayısı.
- **`temp_blks_written`**: Geçici bellek bloklarına yapılan yazma sayısı.
- **`blk_read_time`**: Blok okuma işlemlerinin toplam süresi (milisaniye cinsinden).
- **`blk_write_time`**: Blok yazma işlemlerinin toplam süresi (milisaniye cinsinden).

### Örnek Sorgular

#### En Çok Çalıştırılan Sorguları Görüntüleme

En sık çalıştırılan sorguları görmek için:

```sql
SELECT query, calls
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```

Bu sorgu, en çok çalıştırılan 10 sorguyu döndürecektir.

#### En Uzun Süren Sorguları Görüntüleme

En uzun süren sorguları görmek için:

```sql
SELECT query, total_time, calls, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

Bu sorgu, toplam çalışma süresi en yüksek olan 10 sorguyu döndürecektir.

#### Sorgu Performansını Detaylandırma

Sorgu performansını daha detaylı incelemek için:

```sql
SELECT query, calls, mean_time, min_time, max_time, stddev_time, rows
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

Bu sorgu, ortalama çalışma süresi en yüksek olan 10 sorguyu döndürecektir.

### Verilerin Temizlenmesi (Resetleme)

`pg_stat_statements` görünümündeki istatistikleri sıfırlamak (resetlemek) için:

```sql
SELECT pg_stat_statements_reset();
```

### 1. `pg_stat_activity`

Bu görünüm, veritabanındaki tüm aktif bağlantılar hakkında bilgi sağlar.

```sql
SELECT * FROM pg_stat_activity;
```

- **Kullanım Alanı**: Mevcut veritabanı bağlantılarını izler, hangi kullanıcıların hangi sorguları çalıştırdığını ve bu sorguların ne kadar süredir çalıştığını gösterir.


PostgreSQL'de `pg_stat_activity` görünümü, veritabanındaki mevcut tüm aktif bağlantıları ve çalışan sorguları gösterir. Bazen, uzun süren veya performansı olumsuz etkileyen sorguları durdurmanız gerekebilir. PostgreSQL, bu tür sorguları iptal etmek (`CANCEL`) veya bağlantıları sonlandırmak (`TERMINATE`) için komutlar sağlar.

### Sorguları İptal Etmek ve Bağlantıları Sonlandırmak

#### 1. `pg_stat_activity` Görünümünden PID Bilgisi Almak

Öncelikle, iptal etmek veya sonlandırmak istediğiniz sorgunun PID'sini (Process ID) bulmanız gerekecek. `pg_stat_activity` görünümünü kullanarak bu bilgiyi alabilirsiniz.

**Örnek Sorgu**:
```sql
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity;
```

Bu sorgu, tüm aktif bağlantıları ve onların PID'lerini, kullanıcı adlarını, uygulama adlarını, istemci adreslerini, bağlantı durumlarını ve çalışan sorguları döndürecektir.

**Özel bir sorguyu bulmak için**:
Belirli bir durumu veya kullanıcıyı filtrelemek isterseniz, sorgunuzu daraltabilirsiniz:

```sql
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity
WHERE usename = 'target_username';
```

Bu sorgu, sadece belirli bir kullanıcı (`target_username`) tarafından çalıştırılan sorguları gösterir.

#### 2. Sorguyu İptal Etmek (`CANCEL`)

Sorguyu iptal etmek, yalnızca belirli bir sorgunun çalışmasını durdurur. Bu, bağlantıyı sonlandırmaz; sadece belirtilen sorguyu durdurur.

```sql
SELECT pg_cancel_backend(pid);
```

Burada, `pid` değeri, iptal etmek istediğiniz sorgunun PID'sidir.

**Örnek**:
```sql
SELECT pg_cancel_backend(12345);
```

Bu komut, PID'si `12345` olan sorguyu iptal eder. Bu komutun yürütülmesi, bağlantının kendisini etkilemez; yalnızca bu bağlantının çalışmakta olan sorgusunu durdurur.

#### 3. Bağlantıyı Sonlandırmak (`TERMINATE`)

Bağlantıyı sonlandırmak, belirtilen PID'ye sahip bağlantıyı tamamen kapatır. Bu, o bağlantı üzerinden çalışan tüm işlemleri durdurur ve bağlantıyı sonlandırır.

**Komut**:
```sql
SELECT pg_terminate_backend(pid);
```

Burada, `pid` değeri, sonlandırmak istediğiniz bağlantının PID'sidir.

**Örnek**:
```sql
SELECT pg_terminate_backend(12345);
```

Bu komut, PID'si `12345` olan bağlantıyı sonlandırır. Bağlantıyı sonlandırmak, o bağlantının çalışmakta olan tüm sorgularını durdurur ve bağlantıyı kapatır.

1. **İzinler**
2. **Etki**:
   - `pg_cancel_backend` sadece belirtilen sorguyu durdurur ve bağlantı devam eder.
   - `pg_terminate_backend` ise bağlantıyı tamamen sonlandırır ve tüm işlemleri durdurur. Bu, uzun süreli veya kritik işlemler için dikkatli kullanılmalıdır.

### Pratik Kullanım Senaryoları

1. **Uzun Süren Sorguları İptal Etmek**:

   Eğer veritabanınızda çok uzun süren veya performansı düşüren bir sorgu varsa, bu sorguyu iptal edebilirsiniz:

   ```sql
   SELECT pid, query, state, now() - query_start AS duration
   FROM pg_stat_activity
   WHERE state = 'active' AND now() - query_start > interval '5 minutes';
   ```

   Bu sorgu, 5 dakikadan uzun süredir çalışan tüm aktif sorguları listeleyecektir. Daha sonra bu sorguların PID'sini kullanarak iptal edebilirsiniz:

   ```sql
   SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE pid = 12345;
   ```

2. **Belirli Bir Uygulamanın Bağlantılarını Sonlandırmak**:

   Eğer belirli bir uygulamanın tüm bağlantılarını sonlandırmanız gerekiyorsa:

   ```sql
   SELECT pid FROM pg_stat_activity WHERE application_name = 'my_app';
   ```

   Bu sorgu, `my_app` adındaki uygulamanın tüm bağlantılarının PID'lerini listeler. Ardından bu PID'leri kullanarak bağlantıları sonlandırabilirsiniz:

   ```sql
   SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'my_app';
   
   ```

### 2. `pg_stat_database`

Bu görünüm, her bir veritabanının genel istatistiklerini sağlar.

```sql
SELECT * FROM pg_stat_database;
```

- **Kullanım Alanı**: Veritabanı düzeyinde bağlantı sayıları, sorgu sayıları, hata sayıları ve toplam işlem sayıları gibi genel performans ölçümlerini içerir.

### 3. `pg_stat_user_tables`

Bu görünüm, her kullanıcı tablosu için istatistiksel bilgi sağlar.

```sql
SELECT * FROM pg_stat_user_tables;
```

- **Kullanım Alanı**: Tablo düzeyinde, okuma/yazma işlemleri, dizin kullanımı, sıralama (vacuum), dizinlerin yeniden düzenlenmesi (analyze) gibi işlemlerin sayısını gösterir.

- **Kullanım Alanı**: Sistemdeki tüm tabloların performans ölçümlerini içerir. Bu, sistem tabloları dahil olmak üzere tüm tablolara genel bir bakış sağlar.


- **Kullanım Alanı**: Dizinlerin kullanım sıklığını, sıralama işlemlerini ve dizinlerin yeniden düzenlenmesi (analyze) gibi işlemleri izler.

### 6. `pg_stat_user_indexes`

Bu görünüm, kullanıcı tarafından oluşturulan dizinler hakkında bilgi sağlar.

```sql
SELECT * FROM pg_stat_user_indexes;
```

- **Kullanım Alanı**: Kullanıcı tabanlı dizinlerin performansını izler. Hangi dizinlerin ne sıklıkta kullanıldığını ve dizinlerin ne kadar etkili olduğunu anlamak için kullanılır.

### 7. `pg_stat_bgwriter`

Bu görünüm, arka plan yazıcı işleminin (background writer process) performansını izler.

```sql
SELECT * FROM pg_stat_bgwriter;
```

- **Kullanım Alanı**: PostgreSQL'in arka plan yazıcı işleminin ne kadar sık ve ne tür disk yazma işlemleri gerçekleştirdiğini gösterir. Bu, disk I/O performansını optimize etmek için kullanılır.

### 8. `pg_stat_replication`

Bu görünüm, replikasyon sürecindeki durum ve performans hakkında bilgi sağlar.

```sql
SELECT * FROM pg_stat_replication;
```

- **Kullanım Alanı**: Replikasyon bağlantılarını izler ve hangi veritabanlarının replikasyon yaptığı, bu replikasyonun ne kadar ilerlediği ve replikasyon sırasında karşılaşılan olası sorunları gösterir.

### 9. `pg_stat_wal_receiver`

Bu görünüm, WAL (Write-Ahead Logging) alıcılarının durumunu izler.

```sql
SELECT * FROM pg_stat_wal_receiver;
```

- **Kullanım Alanı**: WAL alıcılarının (replication receiver) durumu ve performansını izler. Replikasyon sırasında WAL segmentlerinin ne kadar hızlı alındığını ve uygulandığını gösterir.

### 10. `pg_stat_progress_vacuum`

Bu görünüm, VACUUM işlemlerinin ilerlemesini izler.

```sql
SELECT * FROM pg_stat_progress_vacuum;
```

- **Kullanım Alanı**: VACUUM işleminin ne kadar ilerlediğini ve hangi tablolar üzerinde çalışıldığını izler. VACUUM, PostgreSQL'de veri yapısını optimize eden bir işlemdir.

### 11. `pg_stat_slru`

Bu görünüm, SLRU (Simple LRU) tamponları hakkında istatistikler sağlar.

```sql
SELECT * FROM pg_stat_slru;
```

- **Kullanım Alanı**: PostgreSQL'de kullanılan çeşitli LRU (Least Recently Used) tamponların durumu ve performansı hakkında bilgi verir. Bu tamponlar genellikle MVCC (Multi-Version Concurrency Control) için kullanılır.

### 12. `pg_statio_all_tables`

Bu görünüm, tablo seviyesindeki I/O istatistiklerini sağlar.

```sql
SELECT * FROM pg_statio_all_tables;
```

- **Kullanım Alanı**: Tabloların veri ve dizinlerinin ne sıklıkla diskten okunduğu veya bellekte tutulduğu hakkında bilgi verir. I/O performansını optimize etmek için kullanılır.

### 13. `pg_stat_sys_tables`

Bu görünüm, sistem tabloları için istatistiksel bilgi sağlar.

```sql
SELECT * FROM pg_stat_sys_tables;
```

- **Kullanım Alanı**: PostgreSQL'in dahili sistem tablolarının performans ölçümlerini içerir.

### 14. `pg_stat_archiver`

Bu görünüm, WAL arşivleme işleminin durumu ve performansı hakkında bilgi sağlar.

```sql
SELECT * FROM pg_stat_archiver;
```

- **Kullanım Alanı**: PostgreSQL'de WAL dosyalarının arşivleme sürecini izler ve başarısız arşivleme denemeleri gibi bilgileri sağlar.

### 15. `pg_stat_user_functions`

Bu görünüm, kullanıcı tarafından tanımlanmış fonksiyonlar hakkında istatistiksel bilgi sağlar.

```sql
SELECT * FROM pg_stat_user_functions;
```

- **Kullanım Alanı**: Kullanıcı tarafından tanımlanmış SQL ve PL/pgSQL fonksiyonlarının ne kadar süre çalıştığını ve kaç kez çağrıldığını izler.

### Kullanım Senaryoları

- **Performans İzleme**: `pg_stat_activity` ve `pg_stat_database` görünümleri, veritabanı etkinliğini ve genel performansı izlemek için kullanılır.
- **Replikasyon Durumunu İzleme**: `pg_stat_replication` ve `pg_stat_wal_receiver` görünümleri, veri replikasyonunun sağlığını ve ilerlemesini kontrol etmek için kullanılır.
- **Dizin Kullanımını Analiz Etme**: `pg_stat_user_indexes` görünümleri, dizinlerin performansını ve kullanımını anlamak için kullanılır.
- **I/O Performansını Analiz Etme**: `pg_stat_bgwriter` görünümleri, disk I/O işlemlerinin performansını optimize etmek için kullanılır.
- **Arka Plan İşlemlerini İzleme**: `pg_stat_bgwriter` ve `pg_stat_progress_vacuum` görünümleri, arka plan işlemlerinin verimliliğini ve etkisini değerlendirmek için kullanılır.


## powa
  * https://github.com/powa-team/pg_qualstats
  * hypopg

## pg_activity: console izlemek için

```bash
apt install pg-activity

https://github.com/dalibo/pg_activity

```

#  pgbench: benchmark

```sql
# pgbench dbsi oluştur
createdb pgbench


pgbench --help

pgbench -i -s 50 postgres

pgbench -c 10 -j 100 -t 1000 postgres


```