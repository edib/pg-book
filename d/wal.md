# WAL

* **Transaction log**, pgnin önemli bir parçasıdır, 
* RDBMS'in, bir sistem arızası meydana geldiğinde bile herhangi bir veriyi kaybetmemesi gerekir. 
* Hiçbir verinin kaybolmamasını sağlamak için bir veritabanı sistemindeki tüm değişikliklerin ve eylemlerin geçmiş günlüğüdür. 
* Günlük zaten yürütülen her işlem hakkında yeterli bilgi içerdiğinden, veritabanı sunucusu, sunucu çökmesi durumunda işlem günlüğündeki değişiklikleri ve eylemleri yeniden yürüterek veritabanı kümesini kurtarabilmelidir.
* Point-in-Time Recovery (PITR)'de kullanılır.
* Streaming Replication (SR)'da kullanılır. 


[Wal olmadan yazma işlemleri](https://www.interdb.jp/pg/img/fig-9-01.png)

* pg 7.1'den önce insert ve update işlemlerinde her page değişikliğinde diske sync call gönderirdi.


### Akış 
* **wal buffer**: memory
* **wal segment**: kalıcı disk
* **LSN**: unique _log sequence number_  kullanılıyor. (izlemek için bu terim çok kullanılıyor.)
* **redo point**: recover ederken _checkpoint_ olmuş ve diske buraya yazılmış buradan itibaren kurtarılacak.
* recovery checkpoint ile sıkı bir şekilde ilgilidir. 

* [Wal nasıl yazılır?](https://www.interdb.jp/pg/img/fig-9-02.png)
* [WAL'dan recovery](https://www.interdb.jp/pg/img/fig-9-03.png)


## WAL Mimarisi

```
SELECT pg_walfile_name(pg_current_wal_lsn()), pg_current_wal_lsn();
     pg_walfile_name      | pg_current_wal_lsn
--------------------------+--------------------
 000000010000000300000081 | 3/812FCF08
(1 row)
 
 
select * from pg_walfile_name_offset(pg_current_wal_lsn());
  file_name | file_offset
--------------------------+-------------
 000000010000000000000001 | 8866032
(1 row)
```

### WAL Yapısı

WAL dosyasının adını 3 parçaya ayırarak okumak gerekir. 

```
00000001|00000003|00000081
```

*   1-8: zaman çizgisi (timeline) (restore operasyonlarında anlamlı)
*   9-16: mantıksal WAL dosyalarını göster
*   17-24: fiziksel  WAL'ı ifade eder. PostgreSQL bu kısmı **segment** olarak adlandırır. Her biri varsayılan olarak 16MB boyuttadır. 

* Her bir mantıksal WAL, 255 tane dosyadan(fiziksel WAL) oluşan 4080 MB toplamı olan bir dosyalar bütünüdür.
* Yeni kurulmuş bir sistem, `000000010000000100000001`den başlar. `0000000100000001000000FF`'e kadar gider, sonra, `000000010000000200000000`'a geçer. 


Yukarıdaki `SELECT pg_current_wal_lsn();` sorgusundan dönen _3/812FCF08_ çıktı 2 parçaya ayrılır.

1.  WAL dosyasının mantıksal WAL'daki yerini söyler. 
2.  Bu mantıksal dosyanın başından itibaren ne kadar ilerde (offset) olduğunu gösterir. Bu rakamlar birbirlerinden mantıksal ve fiziksel yeri çıkarabilmektedir. WAL'ın yeri,  WAL dosyalarının recovery ve replication işlemlerindeki rolünden dolayı kritiktir. 

Her biri 16MB dir. Dolunca yenisine geçer. Ellede tetiklenebilir. _"select pg_switch_wal()"_ yazılmakta olan segmenti geçerek diğer wal segment dosyasına geçer.

* [WAL sayfalarının yapısı(8k)](https://www.interdb.jp/pg/img/fig-9-07.png)

### wal, xlog ya da transaction loglarının görevleri

*   recovery (Sunucu ya da servis aniden kapanmışsa db dosyalarını kullanılabilir duruma getirmek için master servisi wal dosyalarını okuyarak db'yi stabil hale getirir.)
*   sunucu başlangıcında (wal'ın kaldığı yeri db tutarlılığı ile kontrol eder.)
*   replikasyonda (streaming replication wal dosyalarını aktararak yapılır.)
*   incremental yedekleme (repmgr vb backup yazılımları doğrudan wal dosyalarını aktarır ve wal içerisindeki bir transactiona a dönebilir. )  

### WAL ile  config parametreleri

```sh
wal_level = minimal # minimal, replica, or logical
 # minimal sadece servis çakılırsa ve acil kapatmada kullanılabilir
 # replica read only replika sunucuyu beslemek ya da pitr yapma işine yarar.
 # logical ise logical replikasyon da kullanılabilir.
wal_sync_method = fsync # the default is the first option
 # fsync olmazsa diske yazmadan ok dönebilir. Bu vt bozulması riski oluşturur.
 # fsync off olursa "wal_sync_method" parametresi geçersiz olur.
 # fdatasync eski sürümlerde sadece
wal_compression = off 
 # sıkıştırmayı etkinleştirir. 
wal_log_hints = off  
 # also do full page writes of non-critical updates
wal_buffers = -1 # min 32kB, -1 sets based on shared_buffers
 # -1 shared buffera göre oto yapsın
wal_writer_delay = 200ms # 1-10000 milliseconds
 # ne kadar sıklıkla wal diske flash edilsin. Büyük değerler disk performansını olumsuz etkileyebilir. 
wal_writer_flush_after = 1MB 
 # bu kadar boyuttan sonra diske flush edilsin. birim yoksa page olarak ölçülür, 0 anında diske flush eder. 
max_wal_size = 1GB 
 # toplam wal miktarı bu rakama çıkabilir. Çok aktif sistemlerde bu rakama ulaşınca checkpoint yapar. 
min_wal_size = 80MB
 # bunun altında sistem wal dosyalarını silmez, geri dönüştürür. 
max_wal_senders = 10 
 # max wal sender process sayısı, standby serverlarda sayı primaryden düşük olamaz. 
wal_sender_timeout = 60s 
 # Wal replikasyonunu beklemek için maksimum zamanı ayarlar
```
## Checkpoint

* Checkpoint dirty durumdaki bellekte duran verinin topluca diske yazılma işlemidir.

Bu olay sırasında DB aşağıdaki 3 olayı gerçekleştirir.

1.  **Shared buffer**'daki tüm dirty (değiştirilmiş) blockları bulur.
2.  Tüm bu veriyi dosya sistemi belliğine yazar.
3.  Fiziksel diske yazmak için _**fsync()**_ çalıştırır.

4 şekilde çalışır:

1.  Elle komut olarak çalıştırma.
2.  Başka bir komutun ihtiyaç duymasından dolayı çalışma (`pg_start_backup('<backup_adi>')`, `CREATE DATABASE`, ya da `pg_ctl stop|restart`  gibi.)
3.  Son **_checkpoint'_**ten sonra belirlenmiş zamanın geçmesi  
  *   `Belirli aralık`: **`checkpoint_timeout` (seconds) **ile belirleriz.
4.  Son **_checkpoint'_**ten sonra belirlenmiş miktarda _WAL_ üretilmiş olması. 

  * `Belirli miktar` **`max_wal_size` (GB)** olarak belirlenmektedir. Her bir WAL 16MB olduğundan WAL dosyası sayısı = `max_wal_size` / WAL boyutu olarak düşünebiliriz. 

  * Checkpointlerin WAL miktarına değil de zamana bağlı olarak gerçekleştiriliyor olması istenen bir durumdur. Eğer WAL miktarından dolayı gerçekleşiyorsa `max_wal_size` parametresinin büyütülmesi tavsiye edilmektedir.

Ayrıca `checkpoint_completion_target` (0-1 arasında float)  bir sonraki checkpointin diğeriyle arasındaki mesafenin ne kadar zamanda bitmesi gerektiğini belirler. Yani bir sonraki **CHECKPOINT** 10 dk sonra ise 0.5 değeri checkpoint işlemini 5 dk'ya dağıtarak bitirmesini zorlar. 0.9 %90 zamanında bitirmesini sağlar. Bu sayede checkpointten kaynaklanan io yükselmeleri zamana dağıtılarak performans kazancı sağlanır.


### pg_control

* pg_control dosyası, **checkpoint** temel bilgilerini içerdiğinden, veritabanı kurtarma için kesinlikle gereklidir. Bozuk veya okunamıyorsa, bir başlangıç ​​noktası elde edemediğinden kurtarma işlemi başlatılamaz. 
* 40 satırdan fazla bilgi saklar. 

```
/usr/lib/postgresql/14/bin/pg_controldata -D <PG_DATA>
```

### WAL Dosyaları Yönetimi

* WAL segment denir. 
* pg_wal içinde tutulur. 
* 16 MBtır
* 3 durumda yenisine geçer:
  * dolunca
  * `select pg_switch_wal()` ile
  * `archive_mode` etkinken `archive_timeout` gerçekleşirse
* [WAL geri dönüşümü](https://www.interdb.jp/pg/img/fig-9-17.png)
* WAL dosyaları `max_wal_size` aşarsa, bir **checkpoint** başlatılır.
* `wal_keep_size` ve **replication slots** özelliği de WAL segmenti dosyalarının sayısını etkiler.

### Sürekli arşivleme

* **archiver** işlemi yapar. 
* her dosya değişikliğinde dosya başka bir yere arşivlenir.
* Aktarılan dosyaya **archive log** denir.
* Yedekleme ve replikasyon için kullanılır. 

```
# /home/postgres/archives/ altında arşivler
archive_command = 'cp %p /home/postgres/archives/%f'

```
* Bir yedekleme yazılımıyla yönetin. 


