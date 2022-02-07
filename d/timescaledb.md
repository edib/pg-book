# timescaledb

## mimari 

### ts verisi nedir?

```
Name:    CPU

Tags:    Host=MyServer, Region=West

Data:
2017-01-01 01:02:00    70
2017-01-01 01:03:00    71
2017-01-01 01:04:00    72
2017-01-01 01:05:01    68

```

```
Metrics: CPU, free_mem, net_rssi, battery

Tags:    Host=MyServer, Region=West

Data:
2017-01-01 01:02:00    70    500    -40    80
2017-01-01 01:03:00    71    400    -42    80
2017-01-01 01:04:00    72    367    -41    80
2017-01-01 01:05:01    68    750    -54    79

```
# ts özellikleri

* **Zaman merkezli**: Veri kayıtlarının her zaman bir zaman damgası vardır.
* **Append-only**: Veriler neredeyse sadece INSERT'lerden oluşur.
* **Güncel**: Güncel veriyle uğraşırız. Geriye dönük işlemler çok azdır. 

* **Sıklık** ve **düzenlilik** ikincil öncelikli, milisaniyerlerle de veri toplanabilir, saatlerle de. Düzenli de toplanabilir ve bir olay olduğu anda da. 


Nerelerde kullanılabilir? 

* **Bilgisayar sistemlerini izleme**: VM, sunucu, kapsayıcı ölçümleri (CPU, boş bellek, net/disk IOP'leri), hizmet ve uygulama ölçümleri (istek oranları, istek gecikmesi).

* **Finansal ticaret sistemleri**: Klasik menkul kıymetler, daha yeni kripto para birimleri, ödemeler, işlem olayları.

* **Nesnelerin İnterneti**: Endüstriyel makineler ve ekipmanlar, giyilebilir cihazlar, araçlar, fiziksel konteynerler, paletler, akıllı evler için tüketici cihazları vb. üzerindeki sensörlerden gelen veriler.

* **Etkinlik uygulamaları**: Tıklama akışları, sayfa görüntülemeler, oturum açmalar, kayıtlar vb. gibi kullanıcı/müşteri etkileşim verileri.

* **İş zekası**: Temel ölçümleri ve işletmenin genel durumunu izleme.

* **Çevresel izleme**: Sıcaklık, nem, basınç, pH, polen sayısı, hava akışı, karbon monoksit (CO), nitrojen dioksit (NO2), partikül madde (PM10).

## Neden TimescaleDB?

* TimescaleDB, zaman serisi verileri için ilişkisel bir veritabanıdır.
* PostgreSQL'in bir uzantısı olarak uygulanır.
* Zaman serisi veri yönetimi için 
  * yeni yetenekler, 
  * veri analizi için yeni işlevler, 
  * yeni sorgu planlayıcı 
  * sorgu yürütme için yeni özellikler 
  * Daha uygun maliyetli ve performanslı analitik için optimizasyonlar
  * yeni depolama mekanizmaları. 
* pgye gelen zaman serisi işlemleri TimescaleDB tarafından işlenir.
* pgden çıkmamış oluyorsunuz. 
  * düşük bakım maliyeti (pg yöneten, timescaledb de yönetebilir)
  * pg özellikleri ve kalitesi
  * sql standardı
  * bir sürü extension (pg_stat_statements, fdw)
  * pg veri tipleri (diğer zaman serisi dblerden daha esnek)
  * bir çok index çeşidi
  * ileri düzey ilişkisel db şemaları
  * ileri düzey sorgu planları
  * postgis 


### TimescaleDB Katkıları

* **Şeffaf ve otomatik zaman bölümlendirme**: Zaman serisi tablolarının otomatik ve sürekli olarak daha küçük aralıklara parçalanır. 

* **Kolon sıkıştırması**: Raporlanmış %94-97 sıkıştırılma ve daha hızlı sorgular (Analitik sorgu, sıralı aynı tür) Bellek SATA diskten 400k daha hızlı. 
* **Sürekli ve gerçek zamanlı toplamalar(aggregate)**: Materialized view gibi gerçek zamanlı toplar. 

* **otomatikleştirilmiş zaman serisi veri yönetimi**: Açık veya ilke tabanlı veri saklama ilkeleri, veri yeniden sıralama ilkeleri, toplama ve sıkıştırma ilkeleri, altörnekleme ilkeleri vb.
* **veritabanı içi iş zamanlama**: SQL veya PL/pgSQLde de yazılabilir db işleri. (batch ve zamanlanmış işler)

* **çok nodlu yatay ölçeklendirme**: İstemci tek sql nesnesi görürken, arkada yatayda bir çok makinaya ölçeklendirme.

### Hypertables

* Birbirine bağlı birçok parçadan oluşsa da, hipertabloya yapılan komutlar, değişiklikleri o hipertabloya ait tüm parçalara otomatik olarak yayar.
* İki adımlı bir işlemdir; standart bir PostgreSQL tablosu oluşturmanız ve ardından bunu bir TimescaleDB hiper tablosuna dönüştürmeniz gerekir. Çok düğümlü bir kümede dağıtılmış hiper tablo oluşturma yöntemi benzerdir.
* 

* tsdb soyutlama birimi
```
CREATE TABLE ...
SELECT create_hypertable()

CREATE TABLE conditions (
   time        TIMESTAMPTZ       NOT NULL,
   location    TEXT              NOT NULL,
   temperature DOUBLE PRECISION  NULL,
   humidity    DOUBLE PRECISION  NULL
);

SELECT create_hypertable('conditions', 'time');

```

* `create_hypertable` işlevinde kullanılan zaman sütunu, zaman damgası, tarih veya tamsayı türlerini destekler; bu nedenle, artabildiği sürece açıkça zamana dayalı olmayan bir parametre kullanabilirsiniz. Örneğin, id seqeuence.
* Var olan bir tablodan hiper tabloya veri taşımanız gerekiyorsa, `create_hypertable` işlevini çağırırken `migrate_data` bağımsız değişkenini true olarak ayarlayın. [*](https://docs.timescale.com/timescaledb/latest/how-to-guides/migrate-data/)
* tabloyu değiştirmek pgdeki gibidir. 

```
ALTER TABLE TABLE_NAME
  ADD COLUMN humidity DOUBLE PRECISION NULL;
```


### chunks (bölümler)

* tsdb yukarda soyutlayarak küçük parçalara ayırır ve burada tutar. 
* partitionlardır. alt tablolardır. asıl tablo hypertable'dır.
* Bir hypertable verilerinin bir (veya potansiyel olarak birden çok) boyuta bölünmesiyle oluşturulur.
* Bölümler zaman değerine göre yapılır. örneğin ['2020-07-01 00:00:00+00', '2020-07-02 00:00:00+00')
* Verinin sayısına/sıkılığına göre bölümlerin sayısı artırılabilir.
* Aynı zaman aralığında gelen verilen aynı bölümde tutulur. 
* Bölümler otomatik oluşturulur.
* Yüke göre ilerde bölümlerin sınırları değiştirilebilir. (1 günden 6 saate indirmek gibi.)
* hypertablelar ek kolonlara göre bölümlenebilirler. (device id vb.) (hash buckets)
* select sorguları chuckların sınırlarını bilir ve belirlenen chunck dışında arama yapmaz. `time > now() - interval '1 week'`

#### dağıtılmış hiper tablolar
* bir araç (device) gelen verinin zamanın dışında alt bölmelere ayrılır ve farklı nodelara dağıtılır.insertler bu sayede paralelleştirilir. (? geliştirilecek)
* çok nodunuz yoksa dağıtık hipertablo komutu başarısız olur. 

```
CREATE TABLE conditions (
  time        TIMESTAMPTZ       NOT NULL,
  location    TEXT              NOT NULL,
  temperature DOUBLE PRECISION  NULL,
  humidity    DOUBLE PRECISION  NULL
);

SELECT create_distributed_hypertable('conditions', 'time', 'location');

```

## Hypertables ve Chunks Faydaları

* **In-memory data**: yeni gelenler ve indexleri bellekte durur. pgnin lru bellek temizleme kurallarına tabidir. 
* **local indexler**: her bölümün indexi datayla birlikte tutulur. bölüme insert gelince index de birlikte güncellenir. 
* **Easy data retention**: kullanıcılar bir veri saklama politikası oluşturabilir. Eski verileri silmek ek iş çıkarmayacak. Bölüm temelli silme.
* **Yaşa dayalı sıkıştırma, verileri yeniden sıralama**: geçmiş dataları sıkıştırır ve columnar benzeri hale getirir. asenkron bir şekilde varolan indexe göre sıralar. 
*  **Instant multi-node elasticity**: yeni sunucuların esnek eklenmesi ve çıkarılması. yeni oluşturulan bölümler yeni sunucuda oluşturulur ve asenkron bir şekilde rebalance edilir. 
*  **veri kopyalama**: chunklar, dağıtık bir hipertablo üzerinde bir çoğaltma faktörü yapılandırılarak (insert zamanında bir 2PC işleminin parçası olarak gerçekleşir) veya çoğaltma faktörünü artırmak için bir düğümden diğerine eski bir chunk kopyalanarak, işlemsel olarak düğümler arasında ayrı ayrı çoğaltılabilir, örn. , bir düğüm hatasından sonra (**yakında**).
* **Veri göçü**: chunklar, transactional olarak ayrı ayrı taşınabilir. örneğin, eski verileri daha ucuz depolamaya taşımak.

### TimescaleDB'yi Ölçeklendirme

#### Tekil node 
#### Streaming replication
#### Çok düğümlü TimescaleDB ve dağıtılmış hiper tablolar
- dağıtılmış hiper tablolar: chunkın altkümesi
- çok düğümde 2 role var: (yazılım aynı)
  - access node: dağıtık kümenin yapısını, dağıtık olmayan hypertableları ve standart pg tablolalarını tutar. istemciler buradan erişirler.  görevleri data nodelarına dağıtır. 
  - data node: büyük resmi tutmazlar, kendi başlarına tsdb gibi davranırlar. aggregateler burada yapılır. merge için access node'a gönderilir.

#### Dağıtılmış hiper tabloları yapılandırma

* En iyi performansı sağlamak için, dağıtılmış bir hiper tabloyu hem zamana hem de alana göre bölümlere ayırmanız gerekir.
* Verileri yalnızca zamana göre bölümlerseniz, access node bir sonraki chunk'ı depolamak için başka bir data node seçmeden önce bu chunkın doldurulması gerekir, bu nedenle en son aralığa yapılan tüm yazma işlemleri tek bir data node tarafından işlenir, yük dengelemesi yapılamz. 
* Ek olarak bir alan chunk belirtirseniz, access node, time chunk aralığı için birden çok space chunk da oluşturulacak ve parçaları alan bölümüne dayalı olarak birden çok data nodea arasında dağıtır ve küme boyunca yük dengelemesi yapılmış olacaktır.

#### Dağıtılmış hiper tabloları ölçeklendirme
* yeni data node eklenince space partitionlar ona göre düzenlenir. 
* eskiler değişmez ama yeni eklenen chuncklar yeni nodlara dağıtılır.
  

### Sıkıştırma

* TimescaleDB, hiper tablolarda depolanan verileri native olarak sıkıştırma yeteneğini destekler.
* Zaman serisi verilerini sıkıştırmak, verilerinizin depolama gereksinimini önemli ölçüde azaltabilir ve çoğu durumda, geçmiş, sıkıştırılmış veriler üzerindeki sorguların yanıt verme süresini hızlandırabilir.
* TimescaleDB'nin yerleşik iş zamanlayıcı tarafından yapılır. 
* Asenkron bir şekilde, tablolar satır tabanlı bir formdan sütunlu bir forma dönüştürülür. Kullanıcılar standart bir satır tabanlı şema görmeye devam ederler. 
* Sorgu zamanında sıkıştırılmış veri açılarak sorguya cevap verilir. 

### Sürekli toplamlar

* Büyük miktarda zaman serisi verisine dokunan toplu sorguların `(min(), max(), avg()...)` hesaplanması uzun zaman alabilir çünkü sistemin her sorgu yürütmesinde büyük miktarda veriyi taraması gerekir. 
* Bu tür sorguları daha hızlı hale getirmek için, sürekli bir toplama, hesaplanan toplamaları `materialize` yapar ve düşük ek yük ile bunları sürekli güncel tutar.
* Sürekli toplamalar, PostgreSQL'in `materialized view` özelliğine biraz benzer, ancak burada viewler sürekli güncellenir. 
* Güncelleme, manuel olarak veya arka planda çalışan bir politika ile  yapılabilir, **sürekli toplamın** tamamını veya yalnızca belirli bir zaman aralığını kapsayabilir. Her iki durumda da, yenileme yalnızca son yenilemeden bu yana değişen toplu paketleri yeniden hesaplar.

* Örnek:

```
CREATE TABLE conditions (
      time TIMESTAMPTZ NOT NULL,
      device INTEGER NOT NULL,
      temperature FLOAT NOT NULL,
      PRIMARY KEY(time, device)
);
SELECT * FROM create_hypertable('conditions', 'time', 'device', 3);

INSERT INTO conditions
SELECT time, (random()*30)::int, random()*80 - 40
FROM generate_series(TIMESTAMP '2020-01-01 00:00:00',
                 TIMESTAMP '2020-06-01 00:00:00',
             INTERVAL '10 min') AS time;

INSERT 0 21889


CREATE MATERIALIZED VIEW conditions_summary_hourly
WITH (timescaledb.continuous) AS
SELECT device,
       time_bucket(INTERVAL '1 hour', time) AS bucket,
       AVG(temperature),
       MAX(temperature),
       MIN(temperature)
FROM conditions
GROUP BY device, bucket;


SELECT add_continuous_aggregate_policy('conditions_summary_hourly',
    start_offset => INTERVAL '1 month',
    end_offset => INTERVAL '1 h',
    schedule_interval => INTERVAL '1 h');


SELECT bucket, avg
  FROM conditions_summary_hourly
 WHERE device = 1 AND bucket BETWEEN '2020-01-01' AND '2020-03-31'
ORDER BY bucket;    

```

* `SUM`, `AVG` toplamları paralelleştilir. 
* `ORDER BY`, `DISTINCT` ve `FILTER` paralelleştirilemez.
* `timescaledb.materialized_only=true` sürekli güncellemeyi kapatmak için
* `refresh_continuous_aggregate`: elle güncellemeyi sağlar.

### veri saklama

* ts verisinde eski verinin silinmesi gerekir. 


```
CREATE TABLE conditions(
    time TIMESTAMPTZ NOT NULL,
    device INTEGER,
    temperature FLOAT
);

SELECT * FROM create_hypertable('conditions', 'time',
       chunk_time_interval => INTERVAL '1 day');

```
* 30 günden sonrasında işine yaramıyor.
* pgde delete sevimli değil. (fklarda bitmiyor)
* manuel silinebilir.

```
SELECT drop_chunks('conditions', INTERVAL '24 hours');
```
#### **veri saklama politikaları**

* yukarıdakini zamana göre yapar. 

```
-- yapı
SELECT add_retention_policy('<relation>',drop_after<interval|integer> );

-- örnek
SELECT add_retention_policy('conditions', INTERVAL '6 months');

# kaldırmak için
SELECT remove_retention_policy('conditions');
```

# Tutorial

[NYC Taxi](https://docs.timescale.com/timescaledb/latest/tutorials/nyc-taxi-cab/)


## kurulum

* [*](https://docs.timescale.com/install/latest/self-hosted/installation-debian/)



