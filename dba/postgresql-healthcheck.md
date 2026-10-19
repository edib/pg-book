# PostgreSQL Healthcheck Rehberi

Çalışan bir PostgreSQL ortamının sağlık durumunu sistematik olarak değerlendirmek için kontrol listesi, yorumlama rehberi, eşik değerleri, SQL sorguları ve otomasyon scriptleri.

Rehber; işletim sistemi, servis, konfigürasyon, bağlantılar, kilitler, replikasyon, WAL/checkpoint, arşiv/yedek, depolama, vacuum, wraparound, bloat, indeksler, önbellek/I/O, sorgu performansı, sequence'ler, hata sayaçları, loglar ve temel güvenlik başlıklarını kapsar.

> **Uyumluluk:** PostgreSQL 13 – 18. Sürüme göre değişen görünümler (`pg_stat_checkpointer`, `pg_stat_io`, `pg_stat_wal`, oturum istatistikleri vb.) SQL dosyalarında `\if` ile otomatik seçilir.

---

## İçindekiler

0. [Dosya yapısı ve hızlı başlangıç](#0-dosya-yapısı-ve-hızlı-başlangıç)
1. [Özet kontroller ve eşik değerleri](#1-özet-kontroller-ve-eşik-değerleri)
2. [İşletim sistemi](#2-i̇şletim-sistemi)
3. [Servis ve instance bilgisi](#3-servis-ve-instance-bilgisi)
4. [Konfigürasyon incelemesi](#4-konfigürasyon-incelemesi)
5. [Bağlantılar ve oturum aktivitesi](#5-bağlantılar-ve-oturum-aktivitesi)
6. [Kilitler ve bloklanan sorgular](#6-kilitler-ve-bloklanan-sorgular)
7. [Replikasyon ve replikasyon slotları](#7-replikasyon-ve-replikasyon-slotları)
8. [WAL ve checkpoint](#8-wal-ve-checkpoint)
9. [Arşivleme ve yedekleme](#9-arşivleme-ve-yedekleme)
10. [Depolama ve boyutlar](#10-depolama-ve-boyutlar)
11. [Vacuum ve autovacuum](#11-vacuum-ve-autovacuum)
12. [Transaction ID (XID) wraparound](#12-transaction-id-xid-wraparound)
13. [Tablo ve indeks bloat](#13-tablo-ve-indeks-bloat)
14. [İndeks sağlığı](#14-i̇ndeks-sağlığı)
15. [Önbellek, I/O ve tarama davranışı](#15-önbellek-io-ve-tarama-davranışı)
16. [Sorgu performansı (pg_stat_statements)](#16-sorgu-performansı-pg_stat_statements)
17. [Sequence ve veri tipi taşma riski](#17-sequence-ve-veri-tipi-taşma-riski)
18. [Hata sayaçları ve veritabanı istatistikleri](#18-hata-sayaçları-ve-veritabanı-istatistikleri)
19. [Log kontrolü](#19-log-kontrolü)
20. [Hızlı güvenlik kontrolü](#20-hızlı-güvenlik-kontrolü)
21. [Anlık yük ölçümü](#21-anlık-yük-ölçümü)
22. [Otomasyon ve izleme entegrasyonu](#22-otomasyon-ve-izleme-entegrasyonu)
23. [Raporlama ve bulgu sınıflandırma](#23-raporlama-ve-bulgu-sınıflandırma)
24. [Özet kontrol listesi](#24-özet-kontrol-listesi)

---

## 0. Dosya yapısı ve hızlı başlangıç

```
postgres-healthcheck/
├── README.md                          ← bu doküman
├── scripts/
│   ├── pg_healthcheck.sh              ← tüm SQL kontrollerini çalıştırır, rapor + çıkış kodu üretir
│   └── os_healthcheck.sh              ← işletim sistemi düzeyi kontroller (DB sunucusunda)
└── sql/
    ├── 00_cluster_summary.sql         ← küme özeti: OK / WARN / CRIT
    ├── 01_database_summary.sql        ← veritabanı özeti: OK / WARN / CRIT (her DB için)
    ├── 02_instance_config.sql
    ├── 03_connections_activity.sql
    ├── 04_locks.sql
    ├── 05_replication.sql
    ├── 06_wal_checkpoint_archive.sql
    ├── 07_sizes.sql
    ├── 08_vacuum.sql
    ├── 09_wraparound.sql
    ├── 10_table_bloat.sql
    ├── 11_index_bloat.sql
    ├── 12_index_health.sql
    ├── 13_cache_io_scans.sql
    ├── 14_top_queries.sql
    ├── 15_sequences_datatypes.sql
    ├── 16_database_stats_errors.sql
    ├── 17_security_quick.sql
    └── 90_rate_sample.sql             ← iki ölçüm arası anlık hız (TPS, WAL/sn ...)
```

### Kapsam: küme mi, veritabanı mı?

PostgreSQL istatistiklerinin bir kısmı **küme geneli** (bağlantılar, replikasyon, WAL, `pg_database`), bir kısmı ise **bağlanılan veritabanına özeldir** (`pg_stat_user_tables`, indeksler, sequence'ler, bloat). Veritabanına özel dosyaların her veritabanında ayrı çalıştırılması gerekir; `pg_healthcheck.sh` bunu otomatik yapar.

| Kapsam | Dosyalar |
|---|---|
| Küme (bir kez) | 00, 02, 03, 04, 05, 06, 14, 16, 17, 90 |
| Veritabanı (her DB) | 01, 07, 08, 09, 10, 11, 12, 13, 15 |

### Yetki

Tam sonuç için **superuser** veya **`pg_monitor`** rolüne üye bir kullanıcı gerekir. `pg_monitor` olmadan başka kullanıcıların sorgu metinleri (`<insufficient privilege>`), `pg_ls_waldir()` ve bazı istatistikler görünmez.

```sql
CREATE ROLE healthcheck LOGIN PASSWORD '***' IN ROLE pg_monitor;
-- pg_hba.conf'ta bu kullanıcıya yalnızca izleme sunucusundan erişim verin.
```

### Hızlı başlangıç

```bash
# 1) Sadece özet (hızlı; izleme / günlük kontrol)
./scripts/pg_healthcheck.sh -h db01 -U healthcheck -m summary

# 2) Tam rapor (tüm detaylar, tüm veritabanları)
./scripts/pg_healthcheck.sh -h db01 -U healthcheck -m full -o /var/tmp/hc

# 3) Belirli veritabanları, değiştirilmiş eşiklerle
PSQL_VARS="-v conn_warn=60 -v xid_warn=300000000" \
  ./scripts/pg_healthcheck.sh -h db01 -D "appdb,reportdb"

# 4) İşletim sistemi kontrolü (DB sunucusunda)
sudo ./scripts/os_healthcheck.sh -p 5432

# 5) Tek bir SQL dosyasını elle çalıştırma
psql -X -d appdb -f sql/08_vacuum.sql
```

Rapor dizini: `reports/<host>_<port>_<tarih>/` altında `summary.txt`, `report.txt` ve her kontrol için ayrı bir `.txt` dosyası oluşur.

### Kontrol sıklığı önerisi

| Sıklık | Kontroller |
|---|---|
| **Sürekli (izleme sistemi)** | servis, bağlantı kullanımı, replikasyon lag, slot WAL birikimi, arşiv hatası, disk doluluğu, XID yaşı, uzun transaction, kilit bekleme |
| **Günlük** | `pg_healthcheck.sh -m summary`, `os_healthcheck.sh`, son yedek durumu, loglardaki FATAL/PANIC |
| **Haftalık** | `-m full` rapor: vacuum, bloat, top queries, cache hit, checkpoint davranışı |
| **Aylık** | kullanılmayan / mükerrer indeksler, sequence doluluğu, büyüme trendi, konfigürasyon ve güvenlik incelemesi, restore testi |

---

## 1. Özet kontroller ve eşik değerleri

İki özet dosyası her kontrol için **değer, uyarı eşiği, kritik eşik ve durum** (`OK` / `WARN` / `CRIT` / `INFO` / `N/A`) üretir:

- 📄 [`sql/00_cluster_summary.sql`](sql/00_cluster_summary.sql) — küme düzeyi
- 📄 [`sql/01_database_summary.sql`](sql/01_database_summary.sql) — veritabanı düzeyi

`N/A`, kontrolün o sunucu için geçerli olmadığını gösterir (örneğin primary'de standby kontrolleri, `archive_mode=off` iken arşiv kontrolleri).

### Eşik tablosu

Eşikler varsayılandır; ortamınıza göre `psql -v <değişken>=<değer>` ile değiştirilebilir.

| Kontrol | Uyarı | Kritik | Değişken | Açıklama |
|---|---|---|---|---|
| Bağlantı kullanımı | %70 | %90 | `conn_warn`, `conn_crit` | `max_connections`'a oranla client backend sayısı |
| En uzun idle in transaction | 5 dk | 30 dk | `idle_tx_warn_sec`, `idle_tx_crit_sec` | Kilit tutar, vacuum'u engeller |
| En uzun aktif sorgu | 5 dk | 30 dk | `query_warn_sec`, `query_crit_sec` | Raporlama/ETL ortamında yükseltin |
| En eski açık transaction | 30 dk | 2 sa | `xact_warn_sec`, `xact_crit_sec` | xmin horizon'u geride tutar |
| Kilit bekleyen oturum | 1 | 10 | — | Anlık |
| Prepared xact (>5 dk) | — | 1 | — | Unutulmuş 2PC |
| XID yaşı | 500 M | 1 milyar | `xid_warn`, `xid_crit` | Üst sınır ~2,1 milyar |
| MultiXact yaşı | 500 M | 1 milyar | aynı | |
| Replay lag (byte) | 100 MB | 1 GB | `lag_warn_bytes`, `lag_crit_bytes` | |
| Replay lag (süre) | 60 sn | 300 sn | `lag_warn_sec`, `lag_crit_sec` | |
| Senkron replika yok | — | 1 | — | `synchronous_standby_names` dolu iken commit'ler bekler |
| Pasif replikasyon slotu | 1 | — | — | WAL biriktirir |
| Slotun tuttuğu WAL | 1 GB | 10 GB | `slot_warn_bytes`, `slot_crit_bytes` | |
| `wal_status` lost/unreserved | — | 1 | — | |
| pg_wal / `max_wal_size` | 2 kat | 4 kat | — | |
| Requested checkpoint oranı | %20 | %50 | — | En az 10 checkpoint varsa değerlendirilir |
| Arşivleme hatası | — | 1 | — | Son hata > son başarı |
| Son arşivden beri | 1 sa | 6 sa | — | Yazma olmayan sistemlerde yanlış alarm verebilir |
| `.ready` WAL dosyası | 10 | 100 | — | Arşiv geride kalıyor |
| Cache hit oranı | < %99 | < %95 | `hit_warn`, `hit_crit` | OLAP'ta düşük olması normaldir |
| Rollback oranı | %5 | %20 | — | |
| Deadlock | 1 | — | — | Reset'ten beri |
| Checksum hatası | — | 1 | — | Depolama bozulması |
| fsync / full_page_writes / autovacuum / track_counts kapalı | — | 1 | — | |
| Ölü satır oranı (10k+ satır) | %20 | %50 | `dead_warn`, `dead_crit` | DB özeti |
| Sequence doluluğu | %75 | %90 | `seq_warn`, `seq_crit` | Kolon tipi dikkate alınır |
| INVALID indeks | — | 1 | — | |
| Mükerrer indeks / indeksiz FK | 1 | — | — | |

Örnek çıktı (kısaltılmış):

```
 Kategori   |                Kontrol                |        Değer        |  Uyarı  |  Kritik  | Durum
------------+---------------------------------------+---------------------+---------+----------+-------
 Genel      | Rol                                   | PRIMARY             | -       | -        | INFO
 Bağlantı   | Bağlantı kullanımı (%)                | 84 / 100            | 70      | 90       | WARN
 Kilit      | Kilit bekleyen (bloklanan) oturum     | 0                   | 1       | 10       | OK
 Slot       | Pasif replikasyon slotu               | 1                   | 1       | -        | WARN
 Arşiv      | Arşivleme hatada mı                   | başarısız: 12 ...   | -       | 1        | CRIT
```

---

## 2. İşletim sistemi

📄 Script: [`scripts/os_healthcheck.sh`](scripts/os_healthcheck.sh) — DB sunucusunda root veya postgres kullanıcısıyla çalıştırılır.

| Alan | Ne kontrol edilir | Beklenen / öneri |
|---|---|---|
| Süreç ve servis | postmaster, `pg_isready`, systemd birimleri (postgres, patroni, pgbouncer, pgbackrest) | Hepsi aktif |
| Yük | load average / çekirdek sayısı, iowait, CPU steal | load15 < çekirdek, iowait < %20, steal < %10 |
| Bellek | MemAvailable, swap kullanımı, aktif swap in/out | MemAvailable > %10, aktif swapping yok |
| Kernel | `vm.swappiness`, `vm.overcommit_memory`, dirty ayarları, THP, HugePages | swappiness 1–10, overcommit 2, THP `never`, büyük `shared_buffers` için `huge_pages=on` |
| Disk | PGDATA, pg_wal, tablespace'ler: doluluk ve inode | < %80 uyarı, < %90 kritik |
| WAL | pg_wal boyutu, `.ready` dosya sayısı | `.ready` birikmiyor |
| Mount | noatime/relatime, nobarrier | nobarrier **kullanılmamalı** |
| İzinler | PGDATA `0700` veya `0750` | |
| Limitler | postmaster açık dosya limiti, `oom_score_adj` | nofile ≥ 65536; postmaster için -1000 |
| Kernel log | OOM killer, disk/dosya sistemi I/O hataları (7 gün) | Kayıt yok |
| Zaman | NTP senkronizasyonu | Senkronize |
| PostgreSQL log | PANIC/FATAL/ERROR sayıları, kritik desenler, en sık hata mesajları | PANIC yok |

Elle kontrol için kısa komutlar:

```bash
df -h; df -i                                    # disk ve inode
du -sh $PGDATA/{base,pg_wal,pg_xact,pg_replslot}
ls $PGDATA/pg_wal/archive_status/*.ready | wc -l # arşivlenmeyi bekleyen WAL
free -m; vmstat 1 5                             # bellek, swap, iowait
iostat -x 1 5                                   # disk gecikmesi (await) ve doluluk (%util)
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /proc/$(head -1 $PGDATA/postmaster.pid)/limits | grep "open files"
journalctl -k --since "-7d" | grep -i -E "oom|i/o error"
```

**Disk gecikmesi yorumu (`iostat -x`):** SSD/NVMe için `r_await`/`w_await` birkaç ms'nin üzerine sürekli çıkıyorsa ve `%util` %90+ ise depolama darboğazdır. PostgreSQL tarafında `track_io_timing = on` ile `blk_read_time` değerleri de izlenebilir.

---

## 3. Servis ve instance bilgisi

📄 [`sql/02_instance_config.sql`](sql/02_instance_config.sql) — bölüm 2.1

```bash
systemctl status postgresql          # dağıtıma göre: postgresql-16, postgresql@16-main ...
pg_isready -h localhost -p 5432      # 0 = bağlantı kabul ediyor, 1 = reddediyor, 2 = yanıt yok
```

```sql
SELECT version(),
       pg_postmaster_start_time()                              AS started_at,
       date_trunc('second', now() - pg_postmaster_start_time()) AS uptime,
       pg_conf_load_time()                                     AS conf_loaded_at,
       pg_is_in_recovery()                                     AS is_standby;
```

**Yorum:**
- Beklenmeyen kısa uptime → crash veya planlanmamış restart; logda `server process ... was terminated by signal` ve `database system was interrupted` satırlarını arayın.
- `conf_loaded_at` son reload zamanıdır; yapılan değişikliğin yüklenip yüklenmediğini doğrular.
- Sürümün destek süresi ve en güncel minor sürüm olup olmadığı kontrol edilmeli (minor güncellemeler güvenlik ve veri bozulması düzeltmeleri içerir).

---

## 4. Konfigürasyon incelemesi

📄 [`sql/02_instance_config.sql`](sql/02_instance_config.sql)

| Bölüm | İçerik |
|---|---|
| 2.2 | Bellek, bağlantı, WAL, replikasyon, autovacuum, planlayıcı, loglama parametreleri; değer, birim, insan okunur boyut, kaynak |
| 2.3 | Varsayılandan farklı tüm ayarlar ve hangi dosya/satırdan geldikleri |
| 2.4 | Restart bekleyen ayarlar (`pending_restart`) |
| 2.5 | `postgresql.conf` içindeki hatalı / uygulanmamış satırlar |
| 2.6 | `pg_hba.conf` hatalı satırlar |
| 2.7 | Bellek boyutlandırma özeti (`work_mem × max_connections` en kötü durum) |
| 2.8 | Kurulu uzantılar ve güncellenebilir sürümler |

Restart bekleyen ve hatalı ayarlar:

```sql
SELECT name, setting, sourcefile FROM pg_settings WHERE pending_restart;
SELECT sourcefile, sourceline, name, error FROM pg_file_settings WHERE error IS NOT NULL;
```

### Başlangıç değerleri için genel referans (OLTP)

| Parametre | Genel yaklaşım | Not |
|---|---|---|
| `shared_buffers` | RAM'in %25'i | Çok büyük değerlerde `huge_pages` önemli |
| `effective_cache_size` | RAM'in %50–75'i | Yalnızca planlayıcı tahmini, bellek ayırmaz |
| `work_mem` | 4–64 MB | Sorgu başına, her sort/hash için ayrı ayrı; temp dosya üretimine göre ayarlanır |
| `maintenance_work_mem` | 256 MB – 2 GB | VACUUM, CREATE INDEX |
| `max_connections` | Gerçek ihtiyaç + pay | Yüksek değer yerine PgBouncer tercih edilmeli |
| `max_wal_size` | Checkpoint'ler çoğunlukla `timed` olacak şekilde | Bkz. bölüm 8 |
| `checkpoint_completion_target` | 0.9 | PG14+ varsayılan |
| `random_page_cost` | SSD için 1.1–1.5 | Varsayılan 4 HDD içindir |
| `effective_io_concurrency` | SSD için 200 | |
| `idle_in_transaction_session_timeout` | 5–30 dk | Unutulmuş transaction'lara karşı |
| `log_min_duration_statement` | 500 ms – 2 sn | Yavaş sorgu logu |
| `log_checkpoints`, `log_lock_waits`, `log_autovacuum_min_duration` | on / on / 0–10 sn | Teşhis için |
| `track_io_timing` | on | I/O sürelerini görünür kılar; düşük maliyetli |

> Bu değerler başlangıç noktasıdır; kesin değerler iş yüküne ve ölçüme göre belirlenmelidir.

---

## 5. Bağlantılar ve oturum aktivitesi

📄 [`sql/03_connections_activity.sql`](sql/03_connections_activity.sql)

| Bölüm | İçerik |
|---|---|
| 3.1 | `max_connections` kullanım oranı |
| 3.2 | Duruma göre dağılım (active, idle, idle in transaction ...) |
| 3.3 | Veritabanı / kullanıcı / uygulama / istemci IP bazında dağılım |
| 3.4 | Backend türleri (autovacuum, walsender, checkpointer ...) |
| 3.5 | Uzun süren aktif sorgular (eşik `-v long_query='5 minutes'`, varsayılan 3 dk) |
| 3.6 | idle in transaction oturumları |
| 3.7 | En eski 15 açık transaction ve `backend_xmin` yaşı |
| 3.8 | Bekleme olayları (wait event) anlık görüntüsü |
| 3.9 | Çalışan VACUUM / CREATE INDEX / ANALYZE / CLUSTER / basebackup ilerlemesi |

Hızlı kontrol:

```sql
SELECT count(*) AS conns,
       current_setting('max_connections')::int AS max_conn,
       round(100.0 * count(*) / current_setting('max_connections')::int, 1) AS usage_pct
FROM pg_stat_activity WHERE backend_type = 'client backend';

SELECT state, count(*) FROM pg_stat_activity GROUP BY state ORDER BY 2 DESC;
```

### Yorumlama

| Gözlem | Anlamı | Aksiyon |
|---|---|---|
| Kullanım %90+ | Yeni bağlantılar `too many clients` hatası alacak | Bağlantı havuzu (PgBouncer, uygulama pool boyutları), sızıntı yapan uygulamayı bul (3.3) |
| Çok sayıda `idle` | Uygulama havuzları büyük | Pool boyutlarını küçült; idle bağlantı da bellek tüketir |
| `idle in transaction` uzun süreli | Uygulama transaction'ı açık bırakıyor | Kilit ve vacuum sorunu; `idle_in_transaction_session_timeout` |
| `idle in transaction (aborted)` | Hata almış ama ROLLBACK edilmemiş transaction | Uygulama hata yönetimi |
| Wait event `Lock` yoğun | Kilit çakışması | Bölüm 6 |
| Wait event `LWLock` / `BufferMapping`, `WALWrite` | İç kaynak çekişmesi, WAL yazımı | Disk, `wal_buffers`, eşzamanlılık |
| Wait event `IO` / `DataFileRead` | Disk okuma bekleniyor | Cache hit, indeks, disk performansı |
| Wait event `Client` / `ClientRead` | Sunucu istemciyi bekliyor | Genelde normal; idle in tx ile birlikteyse uygulama |

`state_change` ile `xact_start` farkı: `xact_start` transaction'ın başladığı, `state_change` mevcut duruma girildiği andır. idle in transaction süresi için `now() - state_change`, transaction'ın toplam yaşı için `now() - xact_start` kullanılır.

### Müdahale

```sql
SELECT pg_cancel_backend(<pid>);     -- yalnızca çalışan sorguyu iptal eder
SELECT pg_terminate_backend(<pid>);  -- bağlantıyı keser, açık transaction rollback olur

-- 30 dakikadan uzun idle in transaction olanları kesmek
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - state_change > interval '30 minutes';
```

> `autovacuum worker` sorgusunda `(to prevent wraparound)` ifadesi varsa iptal etmeyin; tekrar başlayacaktır ve wraparound riskini artırırsınız.

---

## 6. Kilitler ve bloklanan sorgular

📄 [`sql/04_locks.sql`](sql/04_locks.sql)

| Bölüm | İçerik |
|---|---|
| 4.1 | Bloklanan ↔ bloklayan oturum çiftleri |
| 4.2 | **Kök bloklayıcılar** — kendisi beklemeyen ama başkalarını bloklayan oturumlar |
| 4.3 | Verilmemiş (bekleyen) kilitler |
| 4.4 | Kilit modu dağılımı |
| 4.5 | `AccessExclusiveLock` tutan oturumlar (DDL, VACUUM FULL, LOCK TABLE) |
| 4.6 | Advisory lock kullanımı |
| 4.7 | Prepared (2PC) transaction'lar |

Bloklanan oturumlar:

```sql
SELECT blocked.pid  AS blocked_pid,  left(blocked.query, 80)  AS blocked_query,
       blocking.pid AS blocking_pid, left(blocking.query, 80) AS blocking_query,
       now() - blocked.query_start AS blocked_for
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocking.pid = ANY (pg_blocking_pids(blocked.pid))
ORDER BY blocked_for DESC;
```

### Yorumlama

- **Kilit zinciri:** A, B'yi; B, C'yi bloklar. Müdahale edilmesi gereken genelde zincirin başındaki (4.2) oturumdur. Sık görülen senaryo: `idle in transaction` bekleyen bir uygulama oturumu bir satırı veya tabloyu kilitli tutar.
- **DDL kuyruğu:** `ALTER TABLE` gibi bir DDL, uzun süren bir SELECT'i beklerken `AccessExclusiveLock` talebi nedeniyle **sonra gelen tüm sorguları da** bloklar. DDL'leri `SET lock_timeout = '5s'` ile çalıştırın.
- **Deadlock:** PostgreSQL `deadlock_timeout` (varsayılan 1 sn) sonrası birini iptal eder. Sayı `pg_stat_database.deadlocks` ile izlenir, ayrıntı logda `deadlock detected` olarak yer alır.
- **`pg_blocking_pids()`** maliyetlidir; çok yoğun sistemlerde saniyelik izleme döngülerinde kullanmayın.
- `log_lock_waits = on`, `deadlock_timeout`'tan uzun bekleyen kilitleri loglar; teşhis için açık olmalıdır.

Unutulmuş prepared transaction temizliği:

```sql
SELECT gid, prepared, owner, database FROM pg_prepared_xacts;
COMMIT PREPARED '<gid>';    -- veya
ROLLBACK PREPARED '<gid>';
```

---

## 7. Replikasyon ve replikasyon slotları

📄 [`sql/05_replication.sql`](sql/05_replication.sql) — sunucunun primary veya standby olduğunu kendisi algılar.

### Primary üzerinde

```sql
SELECT application_name, client_addr, state, sync_state,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replay_lag_bytes,
       write_lag, flush_lag, replay_lag
FROM pg_stat_replication;
```

| Kolon / gözlem | Anlamı |
|---|---|
| `state = streaming` | Normal; `catchup` replikanın geride olup yetiştiğini, `backup` basebackup'ı gösterir |
| `send_lag` büyük | Ağ veya walsender darboğazı |
| `flush_lag` büyük | Replikanın diski yavaş |
| `replay_lag` büyük | Replikada replay yavaş veya recovery conflict nedeniyle bekliyor |
| `sync_state` | `sync` / `quorum` senkron, `potential` yedek senkron aday, `async` asenkron |
| `backend_xmin` dolu | `hot_standby_feedback = on`; replikadaki uzun sorgular primary'de vacuum'u geciktirir |

> **Kritik:** `synchronous_standby_names` dolu iken hiç senkron replika bağlı değilse, primary'deki COMMIT'ler **süresiz bekler**. Özet dosyası bunu ayrıca kontrol eder.

### Standby üzerinde

```sql
SELECT pg_is_in_recovery()             AS is_standby,
       pg_last_wal_receive_lsn()       AS receive_lsn,
       pg_last_wal_replay_lsn()        AS replay_lsn,
       pg_last_xact_replay_timestamp() AS last_replay_ts,
       now() - pg_last_xact_replay_timestamp() AS replay_delay,
       pg_is_wal_replay_paused()       AS paused;

SELECT status, sender_host, slot_name, last_msg_receipt_time FROM pg_stat_wal_receiver;
```

**Dikkat:** primary'de hiç yazma yoksa `replay_delay` doğal olarak büyür (son replay edilen transaction eskidir). Bu durumda `receive_lsn = replay_lsn` ise standby günceldir. Gerçek gecikme için primary'deki `replay_lag` daha güvenilirdir.

`pg_stat_wal_receiver` boşsa standby primary'ye **bağlı değildir** (arşivden besleniyor veya bağlantı kopuk).

### Replikasyon slotları

```sql
SELECT slot_name, slot_type, active, wal_status,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal,
       pg_size_pretty(safe_wal_size) AS safe_wal_size
FROM pg_replication_slots;
```

| `wal_status` | Anlamı |
|---|---|
| `reserved` | Normal |
| `extended` | `max_wal_size` aşıldı, WAL slot veya `wal_keep_size` nedeniyle tutuluyor |
| `unreserved` | `max_slot_wal_keep_size` sınırında; WAL silinmek üzere |
| `lost` | Gerekli WAL silinmiş; slot kullanılamaz, replika/abonelik yeniden kurulmalı |

**Pasif ve WAL biriktiren slot, `pg_wal` dizininin dolmasının en sık nedenidir.** Disk dolarsa primary durur. Önlemler:

- `max_slot_wal_keep_size` ile üst sınır koyun (PG13+).
- Kullanılmayan slotu silin: `SELECT pg_drop_replication_slot('<slot_name>');`
- Logical slotların `catalog_xmin` değeri katalog vacuum'unu da engeller (bölüm 12).

Logical replikasyon için 5.7–5.8: `pg_stat_replication_slots` içinde `spill_bytes` yüksekse `logical_decoding_work_mem` yetersizdir.

---

## 8. WAL ve checkpoint

📄 [`sql/06_wal_checkpoint_archive.sql`](sql/06_wal_checkpoint_archive.sql)

### Checkpoint davranışı

PG17 ve sonrasında checkpoint istatistikleri `pg_stat_checkpointer`, öncesinde `pg_stat_bgwriter` içindedir; dosya doğru görünümü otomatik seçer.

```sql
-- PG17+
SELECT num_timed, num_requested,
       round(100.0 * num_requested / NULLIF(num_timed + num_requested, 0), 1) AS requested_pct
FROM pg_stat_checkpointer;

-- PG16 ve öncesi
SELECT checkpoints_timed, checkpoints_req,
       round(100.0 * checkpoints_req / NULLIF(checkpoints_timed + checkpoints_req, 0), 1) AS requested_pct
FROM pg_stat_bgwriter;
```

| Gözlem | Anlamı | Aksiyon |
|---|---|---|
| `requested` oranı > %20 | Checkpoint'ler `max_wal_size` dolduğu için zorla tetikleniyor | `max_wal_size`'ı artırın |
| Ortalama checkpoint aralığı ≪ `checkpoint_timeout` | Aynı | Aynı |
| Logda `checkpoints are occurring too frequently` | Aynı | Aynı |
| `buffers_backend` yüksek (PG ≤16) / `pg_stat_io` client backend `writes` yüksek (PG16+) | Backend'ler kirli sayfaları kendileri yazıyor | `shared_buffers`, bgwriter ayarları |
| `maxwritten_clean` sürekli artıyor | bgwriter tur başı limitine takılıyor | `bgwriter_lru_maxpages` artırılabilir |
| Checkpoint `sync_time` yüksek | Depolama fsync'te yavaş | Disk performansı |

`log_checkpoints = on` ile her checkpoint'in süresi, yazılan buffer sayısı ve tetiklenme nedeni loga düşer.

### WAL üretimi

`pg_stat_wal` (PG14+) toplam WAL hacmini, full page image (FPI) sayısını ve `wal_buffers_full` değerini verir. Dosya ayrıca istatistik sıfırlanmasından bu yana **ortalama saatlik / günlük WAL** hesaplar.

- FPI oranı yüksek → checkpoint'ler sık, her checkpoint sonrası ilk değişiklikte tam sayfa yazılıyor. `max_wal_size` artışı ve `wal_compression` (PG15+: `lz4`/`zstd`) değerlendirilebilir.
- `wal_buffers_full` artıyor → `wal_buffers` artırılabilir.
- Anlık WAL hızı için bkz. [bölüm 21](#21-anlık-yük-ölçümü).

### pg_wal dizini

```sql
SELECT count(*) AS files, pg_size_pretty(sum(size)) AS total FROM pg_ls_waldir();
```

pg_wal normalde `max_wal_size` civarında kalır. Kalıcı olarak çok üzerindeyse nedenler (sık görülme sırasıyla):

1. WAL biriktiren replikasyon slotu (bölüm 7)
2. Başarısız veya yavaş arşivleme (bölüm 9)
3. `wal_keep_size` yüksek ayarlanmış
4. Yoğun yazma sırasında checkpoint'in geride kalması

> pg_wal içindeki dosyaları **asla elle silmeyin**; nedeni giderin, PostgreSQL bir sonraki checkpoint'te kendisi temizler.

Detaylar için bkz. [Write Ahead Log](wal.md).

---

## 9. Arşivleme ve yedekleme

📄 [`sql/06_wal_checkpoint_archive.sql`](sql/06_wal_checkpoint_archive.sql) — bölüm 6.6 ve 6.7

```sql
SELECT archived_count, last_archived_wal, last_archived_time,
       failed_count, last_failed_wal, last_failed_time,
       CASE WHEN last_failed_time > coalesce(last_archived_time, '-infinity')
            THEN 'ARŞİVLEME HATADA' ELSE 'OK' END AS durum
FROM pg_stat_archiver;
```

**Yorum:**
- `archived_count` artıyor, `failed_count` sabit kalıyor olmalı.
- `failed_count`'un geçmişte artmış olması tek başına sorun değildir; önemli olan **son hatanın son başarıdan yeni olup olmadığıdır**.
- `.ready` dosya sayısı (`pg_ls_archive_statusdir()`) sürekli artıyorsa arşiv komutu yavaş veya başarısızdır; pg_wal dolacaktır. Logda `archive command failed` satırlarına bakın.
- `last_archived_time` yazma yükü olmayan sistemlerde uzun süre değişmeyebilir; `archive_timeout` ile periyodik WAL geçişi sağlanabilir.

### Yedekleme kontrolü

Yedeğin "var" olması yeterli değildir; **son başarılı yedeğin tarihi, boyutu, tutarlılığı ve geri dönüş testi** kontrol edilmelidir.

**pgBackRest:**

```bash
pgbackrest --stanza=<stanza> check            # arşiv ve repo erişimi uçtan uca test
pgbackrest --stanza=<stanza> info             # yedek listesi, tarihler, boyutlar, WAL aralığı
pgbackrest --stanza=<stanza> info --output=json | jq '.[0].backup[-1] | {label, type, timestamp}'
pgbackrest --stanza=<stanza> verify           # repo içeriğinin bütünlük doğrulaması
```

**Barman:**

```bash
barman check <server>                         # tüm kontroller (WAL, yedek, bağlantı)
barman list-backups <server>
barman status <server>
barman verify-backup <server> latest
```

| Kontrol | Beklenen |
|---|---|
| Son full yedek | Yedekleme politikasındaki süreden (ör. 7 gün) eski değil |
| Son incremental / diff | Politika süresi içinde (ör. 24 sa) |
| WAL sürekliliği | Son yedekten bugüne kesintisiz (PITR mümkün) |
| `check` komutu | Hatasız |
| Restore testi | Son 30 günde başarılı ve belgelenmiş |
| Yedek deposu doluluğu | Retention için yeterli alan |

Detaylar için bkz. [pgBackRest](pgbackrest.md) / [Barman](barman.md).

---

## 10. Depolama ve boyutlar

📄 [`sql/07_sizes.sql`](sql/07_sizes.sql)

| Bölüm | İçerik |
|---|---|
| 7.1 | Tablespace boyutları ve konumları |
| 7.2 | Veritabanı boyutları, encoding, collation |
| 7.3 | Şema boyutları |
| 7.4 | En büyük 20 tablo: tablo, indeks, TOAST ayrı ayrı ve indeks oranı |
| 7.5 | Partitioned tabloların toplam boyutu |
| 7.6 | En büyük 20 indeks ve kullanım sayısı |
| 7.7 | İndeks seti tablodan büyük olan tablolar (>100 MB) |

Kısa sorgular:

```sql
SELECT spcname, pg_size_pretty(pg_tablespace_size(spcname)) AS size FROM pg_tablespace;

SELECT datname, pg_size_pretty(pg_database_size(oid)) AS db_size
FROM pg_database ORDER BY pg_database_size(oid) DESC;
```

**Boyut fonksiyonları:**

| Fonksiyon | İçerdiği |
|---|---|
| `pg_relation_size(t)` | Yalnızca ana tablo (heap) |
| `pg_table_size(t)` | Heap + TOAST + FSM/VM |
| `pg_indexes_size(t)` | Tablonun tüm indeksleri |
| `pg_total_relation_size(t)` | Hepsi |

**Trend takibi:** Boyutlar periyodik olarak bir tabloya kaydedilmeli; aylık büyüme oranı disk kapasite planlamasının temelidir.

```sql
-- örnek: günlük snapshot tablosu
CREATE TABLE IF NOT EXISTS dba.size_history (
  snap_date date DEFAULT current_date, datname name, bytes bigint);
INSERT INTO dba.size_history (datname, bytes)
SELECT datname, pg_database_size(oid) FROM pg_database WHERE datallowconn;
```

---

## 11. Vacuum ve autovacuum

📄 [`sql/08_vacuum.sql`](sql/08_vacuum.sql)

| Bölüm | İçerik |
|---|---|
| 8.1 | Autovacuum ve vacuum ayarları |
| 8.2 | En çok ölü satıra sahip 20 tablo; son vacuum/analyze zamanları |
| 8.3 | **Autovacuum eşiğini geçmiş tablolar** (tablo bazlı `reloptions` dikkate alınır) |
| 8.4 | En uzun süredir vacuum / analyze görmeyen tablolar |
| 8.5 | Tabloya özel autovacuum ayarları |
| 8.6 | Çalışan autovacuum worker'ları ve ilerlemesi |
| 8.7 | Toplam vacuum / analyze sayıları |

Hızlı kontrol:

```sql
SELECT schemaname, relname, n_live_tup, n_dead_tup,
       round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS dead_pct,
       last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;
```

### Autovacuum ne zaman tetiklenir?

```
vacuum eşiği  = autovacuum_vacuum_threshold  + autovacuum_vacuum_scale_factor  × reltuples
analyze eşiği = autovacuum_analyze_threshold + autovacuum_analyze_scale_factor × reltuples
insert eşiği  = autovacuum_vacuum_insert_threshold + autovacuum_vacuum_insert_scale_factor × reltuples  (PG13+)
```

Varsayılan `scale_factor = 0.2` → 100 milyon satırlık tabloda vacuum için 20 milyon ölü satır birikmesi gerekir. Büyük tablolarda tablo bazlı ayar önerilir:

```sql
ALTER TABLE big_table SET (autovacuum_vacuum_scale_factor = 0.01,
                           autovacuum_analyze_scale_factor = 0.005);
```

### Yorumlama

| Gözlem | Olası neden | Aksiyon |
|---|---|---|
| Ölü satır oranı yüksek, `last_autovacuum` yeni | Vacuum çalışıyor ama satırları temizleyemiyor | **xmin horizon'u tutan kaynak var** → bölüm 12, sorgu 9.4 |
| Ölü satır oranı yüksek, `last_autovacuum` eski/boş | Autovacuum yetişemiyor veya kapalı | `autovacuum_max_workers`, `autovacuum_vacuum_cost_limit` artırılması; tablo bazlı `autovacuum_enabled=false` kontrolü |
| 8.3'te aynı tablolar sürekli listeleniyor | Worker'lar büyük tablolarla meşgul | Worker sayısı, cost limit, tablo bazlı ayar |
| `last_analyze` / `last_autoanalyze` boş | İstatistik yok, kötü plan riski | `ANALYZE schema.tablo;` |
| Autovacuum sorgusunda `(to prevent wraparound)` | Zorunlu freeze vacuum'u | İptal etmeyin, bitmesini bekleyin |
| Insert-only tablo hiç vacuum görmüyor (PG <13) | Visibility map güncellenmiyor, index-only scan verimsiz | Manuel/periyodik VACUUM |

> `VACUUM FULL` tabloyu `AccessExclusiveLock` ile yeniden yazar ve süre boyunca okuma/yazmayı engeller. Çevrimiçi alternatif: `pg_repack` uzantısı.

`log_autovacuum_min_duration = 0` (veya birkaç saniye) ile autovacuum'un ne kadar sürdüğü ve kaç satır temizleyemediği (`tuples: ... are dead but not yet removable`) loglanır. "dead but not yet removable" sayısı yüksekse horizon sorunu vardır.

---

## 12. Transaction ID (XID) wraparound

📄 [`sql/09_wraparound.sql`](sql/09_wraparound.sql)

PostgreSQL transaction ID'leri 32 bittir ve dairesel karşılaştırılır; bir satırın XID'i ~2,1 milyar transaction eskiyse "gelecekte" görünür. Bunu önlemek için VACUUM eski satırları **freeze** eder. Freeze yetişmezse PostgreSQL veri kaybını önlemek için **yeni XID vermeyi durdurur ve yazmaya kapanır.**

### Yorum tablosu

| XID yaşı | Durum | Açıklama |
|---|---|---|
| < 200 M | Normal | Varsayılan `autovacuum_freeze_max_age` = 200 M |
| 200 M – 500 M | Normal / izle | Autovacuum zorunlu freeze yapıyor olmalı |
| 500 M – 1 B | **Dikkat** | Freeze yetişmiyor; nedeni bulun |
| 1 B – 1,5 B | **Risk** | Manuel `VACUUM (FREEZE)` planlayın |
| > 1,6 B | **Acil** | `vacuum_failsafe_age` devrede; autovacuum maliyet sınırlarını yok sayar |
| ~2,1 B − 3 M | **Kapanma** | Yeni XID verilmez, veritabanı yazmaya kapanır |

Veritabanı ve tablo bazında yaş:

```sql
SELECT datname, age(datfrozenxid) AS xid_age, mxid_age(datminmxid) AS mxid_age,
       round(100.0 * age(datfrozenxid) / 2147483648, 2) AS pct_to_wraparound
FROM pg_database ORDER BY 2 DESC;

SELECT n.nspname, c.relname, age(c.relfrozenxid) AS xid_age,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS size
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'm', 't')
ORDER BY 3 DESC LIMIT 30;
```

### xmin horizon: vacuum'u engelleyenler

Bölüm 9.4, VACUUM'un ölü satırları ve eski XID'leri temizlemesini engelleyen **tüm kaynakları** tek listede toplar:

| Kaynak | Örnek | Çözüm |
|---|---|---|
| Uzun süreli transaction | Unutulmuş `BEGIN`, uzun rapor sorgusu | Oturumu sonlandır, `idle_in_transaction_session_timeout` |
| Replikasyon slotu (`xmin`/`catalog_xmin`) | Pasif logical slot | Slotu sil veya tüketiciyi düzelt |
| Prepared transaction | Unutulmuş 2PC | `COMMIT/ROLLBACK PREPARED` |
| Standby feedback | `hot_standby_feedback=on` + replikada uzun sorgu | Replikadaki sorguyu sonlandır |

En üstteki satır horizon'u belirler; o giderilmeden VACUUM ne kadar çalışırsa çalışsın sorun çözülmez.

### MultiXact

Birden fazla transaction aynı satırı paylaşımlı kilitlediğinde (`SELECT ... FOR SHARE`, foreign key kontrolleri) MultiXact ID kullanılır. Aynı wraparound mantığı geçerlidir (`mxid_age(datminmxid)`, `autovacuum_multixact_freeze_max_age`). Yoğun FK kontrolleri olan sistemlerde ayrıca izlenmelidir.

### Acil müdahale

```sql
-- 1) 9.4'teki engelleyiciyi kaldırın.
-- 2) En yaşlı tablolardan başlayın:
VACUUM (FREEZE, VERBOSE) schema.tablo;
-- 3) Çok büyük tablolarda, acil durumda (PG14+) indeks temizliğini atlayarak:
VACUUM (FREEZE, INDEX_CLEANUP OFF, VERBOSE) schema.tablo;
```

Veritabanı yazmaya kapanmışsa (`database is not accepting commands to avoid wraparound data loss`), sürümünüzün resmi dokümanındaki "Preventing Transaction ID Wraparound Failures" prosedürünü izleyin.

**XID tüketim hızı:** `SELECT txid_current();` sorgusunu 24 saat arayla çalıştırıp farkı alın (bu fonksiyonun kendisi bir XID tüketir, standby'da çalışmaz). Günlük tüketim ile kalan kapasite, freeze için ne kadar zamanınız olduğunu gösterir.

---

## 13. Tablo ve indeks bloat

📄 [`sql/10_table_bloat.sql`](sql/10_table_bloat.sql) — tablo bloat tahmini
📄 [`sql/11_index_bloat.sql`](sql/11_index_bloat.sql) — B-tree indeks bloat tahmini

Bloat, MVCC nedeniyle güncellenen/silinen satırların bıraktığı ve yeniden kullanılmayan alandır. Bu iki sorgu **istatistik tabanlı tahmindir**: tabloyu okumaz, hızlıdır ama kesin değildir.

**Önkoşullar ve sınırlamalar:**
- Tablonun güncel `ANALYZE`'ı olmalıdır.
- `Is N/A = TRUE` satırlar güvenilmez (`name` tipi kolon, eksik istatistik).
- Tablo sorgusu varsayılan olarak bloat oranı %10'dan büyük tabloları listeler: `psql -v bloat_min=20 -f sql/10_table_bloat.sql`
- İndeks sorgusu yalnızca geçerli B-tree indeksleri, en büyük 50 indeks olarak listeler.

**Kesin ölçüm (`pgstattuple` uzantısı):**

```sql
CREATE EXTENSION IF NOT EXISTS pgstattuple;

SELECT * FROM pgstattuple_approx('schema.tablo');   -- hızlı, visibility map kullanır
SELECT * FROM pgstattuple('schema.tablo');          -- kesin, tam tarama (büyük tablolarda yavaş)
SELECT avg_leaf_density, leaf_fragmentation
FROM pgstatindex('schema.indeks');                  -- avg_leaf_density < ~%50–60 → şişmiş
```

### Ne zaman müdahale edilmeli?

| Durum | Öneri |
|---|---|
| Tablo bloat %20–30, tablo küçük | Genelde müdahale gerekmez; autovacuum ayarlarını kontrol edin |
| Tablo bloat > %40–50 ve tablo büyük | `pg_repack` ile çevrimiçi yeniden yazma |
| İndeks bloat > %40–50 | `REINDEX INDEX CONCURRENTLY schema.indeks;` (PG12+) |
| Bloat sürekli tekrarlıyor | Kök neden: horizon (bölüm 12), autovacuum ayarları (bölüm 11), düşük HOT oranı (bölüm 15) |

> `VACUUM` alanı işletim sistemine iade etmez (tablo sonundaki boş sayfalar hariç), yalnızca yeniden kullanılabilir hale getirir. Disk alanı geri kazanımı için `VACUUM FULL` (kilitli) veya `pg_repack` (çevrimiçi) gerekir.

Detaylı bloat analizi için bkz. [İzleme](izleme.md).

---

## 14. İndeks sağlığı

📄 [`sql/12_index_health.sql`](sql/12_index_health.sql)

| Bölüm | İçerik | Aksiyon |
|---|---|---|
| 12.1 | İstatistik toplama süresi | Kısaysa "kullanılmıyor" sonucu güvenilmez |
| 12.2 | Hiç kullanılmamış indeksler (UNIQUE, constraint, ifade, partition indeksleri hariç) ve tanımları | `DROP INDEX CONCURRENTLY` |
| 12.3 | Az kullanılan büyük indeksler (>100 MB, <50 tarama) | Gözden geçirin |
| 12.4 | Mükerrer indeksler (aynı kolon, opclass, collation, ifade, koşul) | Birini kaldırın (constraint destekleyeni tutun) |
| 12.5 | Önek olarak örtüşen B-tree indeksler: `(a)` ve `(a, b)` | `(a)` genelde gereksiz |
| 12.6 | INVALID indeksler | `REINDEX INDEX CONCURRENTLY` veya drop + create |
| 12.7 | İndeksi olmayan foreign key'ler ve önerilen `CREATE INDEX` | Parent DELETE/UPDATE'te seq scan ve kilit sorunları |
| 12.8 | 10+ indeksli tablolar | Yazma maliyeti |

### Kullanılmayan indeksleri kaldırmadan önce

1. **İstatistik penceresi:** `pg_stat_database.stats_reset` yeni ise bekleyin. Ay sonu, yıl sonu, çeyrek kapanış gibi seyrek işleri kapsayacak süre geçmeli.
2. **Tüm node'lar:** `idx_scan` her node'a özeldir. Replikalardan okuma yapılıyorsa indeks primary'de kullanılmıyor görünse de standby'da kullanılıyor olabilir. **Tüm node'larda kontrol edin.**
3. **Tanımı saklayın:** 12.2 çıktısındaki `definition` kolonu geri dönüş için gereklidir.
4. **Kilitlemeden kaldırın:** `DROP INDEX CONCURRENTLY schema.indeks;`

Hızlı INVALID kontrolü:

```sql
SELECT indexrelid::regclass AS index, indrelid::regclass AS table
FROM pg_index WHERE NOT indisvalid;
```

---

## 15. Önbellek, I/O ve tarama davranışı

📄 [`sql/13_cache_io_scans.sql`](sql/13_cache_io_scans.sql)

| Bölüm | İçerik |
|---|---|
| 13.1 | Veritabanı bazında cache hit oranı, okuma/yazma süreleri |
| 13.2 | En çok diskten okunan tablolar ve okuma hacmi |
| 13.3 | En çok diskten okunan indeksler |
| 13.4 | Seq scan baskın tablolar ve seq scan başına ortalama satır |
| 13.5 | Seçilen tablolar için tarama durumu: `-v tables='orders,customers'` |
| 13.6 | HOT update oranı ve fillfactor |
| 13.7 | `pg_stat_io` (PG16+): backend türü ve nesneye göre I/O |
| 13.8 | `shared_buffers` içeriği (`pg_buffercache` kuruluysa) |

```sql
SELECT datname,
       round(blks_hit::numeric / NULLIF(blks_hit + blks_read, 0) * 100, 2) AS hit_pct
FROM pg_stat_database
WHERE datname NOT IN ('template0', 'template1');
```

### Yorumlama

- **Cache hit oranı** PostgreSQL `shared_buffers` isabetini ölçer. "read" olarak sayılan blokların bir kısmı OS page cache'ten gelir; gerçek disk okuması daha düşük olabilir.
  - OLTP'de **%99+** beklenir. Düşükse: `shared_buffers` yetersiz, eksik indeks nedeniyle büyük seq scan'ler veya çalışma seti RAM'den büyük.
  - OLAP / raporlama / büyük taramalarda %90'ın altı normal olabilir; eşikleri iş yüküne göre ayarlayın.
- **Seq scan baskın tablolar (13.4):** `avg_rows_per_seq_scan` büyük ve `seq_scan` sayısı yüksekse eksik indeks adayıdır. Küçük tablolarda seq scan normaldir. İlgili sorguyu bulmak için bölüm 16.
- **HOT update oranı (13.6):** HOT (Heap-Only Tuple) güncellemeler indeks güncellemesi gerektirmez. Oran düşükse güncellenen kolonlarda indeks vardır veya sayfada boş yer yoktur; `fillfactor` 80–90'a düşürülmesi değerlendirilebilir.
- **`pg_stat_io` (13.7):** `client backend` satırında `writes` yüksekse backend'ler kirli sayfa yazmak zorunda kalıyor; checkpointer/bgwriter yetişemiyor. `evictions` yüksekse `shared_buffers` baskı altında.

Belirli tablolar için:

```bash
psql -X -d appdb -v tables='orders,order_items' -f sql/13_cache_io_scans.sql
```

---

## 16. Sorgu performansı (pg_stat_statements)

📄 [`sql/14_top_queries.sql`](sql/14_top_queries.sql)

**Önkoşul:**

```ini
# postgresql.conf (restart gerekir)
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = top
track_io_timing = on
```

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

| Bölüm | Sıralama ölçütü | Neyi bulur |
|---|---|---|
| 14.0 | — | Takip edilen sorgu sayısı, `dealloc` (yetersiz `max` göstergesi), son sıfırlama |
| 14.1 | Toplam süre | Sistemi en çok meşgul eden sorgular — optimizasyonun en çok fayda sağladığı yer |
| 14.2 | Ortalama süre (≥10 çağrı) | Tekil olarak yavaş sorgular |
| 14.3 | Çağrı sayısı | N+1 sorunları, gereksiz tekrarlar, cache'lenebilecek sorgular |
| 14.4 | `shared_blks_read` | En çok diskten okuyan sorgular |
| 14.5 | `temp_blks_written` | `work_mem` yetersizliği nedeniyle diske sort/hash yapan sorgular |
| 14.6 | `wal_bytes` | En çok WAL üreten yazma işlemleri |
| 14.7 | Ortalama planlama süresi | `track_planning = on` ise |

```sql
SELECT round(total_exec_time::numeric / 1000, 1) AS total_sec,
       calls, round(mean_exec_time::numeric, 2) AS mean_ms,
       left(query, 100) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 10;
```

**Notlar:**
- İstatistikler küme genelidir; `dbid` / `userid` ile ayrıştırılır (dosya veritabanı ve rol adını gösterir).
- Ölçüm penceresini belirlemek için periyodik sıfırlama yapılabilir: `SELECT pg_stat_statements_reset();` — sıfırlamadan önce çıktıyı saklayın.
- Bulunan sorguyu `EXPLAIN (ANALYZE, BUFFERS)` ile inceleyin. Üretimde `auto_explain` (`auto_explain.log_min_duration`) yavaş sorguların planlarını otomatik loglar.

---

## 17. Sequence ve veri tipi taşma riski

📄 [`sql/15_sequences_datatypes.sql`](sql/15_sequences_datatypes.sql)

Sequence doluluğu yalnızca sequence'ın kendi `max_value`'suna göre değil, **bağlı olduğu kolonun tipine** göre de hesaplanır.

> **Sık görülen tuzak:** `bigint` sequence, `integer` kolona bağlı. Sequence 2.147.483.647'yi geçtiğinde INSERT'ler `integer out of range` hatası verir; sequence'ın kendisi dolmadığı için klasik kontroller bunu yakalamaz.

| Bölüm | İçerik |
|---|---|
| 15.1 | Sequence doluluk oranı, kalan değer, bağlı tablo/kolon ve tipi, tip uyuşmazlığı uyarısı |
| 15.2 | `integer`/`smallint` PK kolonlu en büyük tablolar |

**Eşikler:** %75 uyarı, %90 kritik. Büyüme hızına göre kalan süre hesaplanmalıdır.

**Çözüm:** Kolonu `bigint`'e çevirmek. `ALTER TABLE ... ALTER COLUMN ... TYPE bigint` tabloyu yeniden yazar ve kilitler; büyük tablolarda yeni kolon ekleyip tetikleyici + parça parça backfill ile çevrimiçi geçiş yapılır.

---

## 18. Hata sayaçları ve veritabanı istatistikleri

📄 [`sql/16_database_stats_errors.sql`](sql/16_database_stats_errors.sql)

| Gösterge | Kaynak | Yorum |
|---|---|---|
| Rollback oranı | `xact_rollback / (commit + rollback)` | > %5 uygulama hataları veya ORM davranışı |
| `deadlocks` | `pg_stat_database` | > 0 ise logda `deadlock detected` |
| `temp_files`, `temp_bytes` | `pg_stat_database` | Yüksekse `work_mem` yetersiz; bölüm 16 / 14.5 |
| `checksum_failures` | `pg_stat_database` (checksum açıksa) | > 0 → **depolama bozulması; acil inceleme** |
| `conflicts` | `pg_stat_database_conflicts` | Standby'da iptal edilen sorgular |
| `sessions_abandoned` | PG14+ | İstemci bağlantıyı kapatmadan koptu: ağ sorunları, crash, timeout |
| `sessions_fatal`, `sessions_killed` | PG14+ | Hata ile kapanan / operatörce sonlandırılan oturumlar |
| `idle_in_transaction_time` oranı | PG14+ | Yüksekse uygulama transaction yönetimi hatalı |

**Standby recovery conflict'leri:**

| Kolon | Neden | Seçenek |
|---|---|---|
| `confl_snapshot` | Primary'de vacuum'un sildiği satırları standby sorgusu hâlâ görüyor | `hot_standby_feedback=on` (primary'de bloat riski) veya `max_standby_streaming_delay` artırımı |
| `confl_lock` | Primary'deki `AccessExclusiveLock` (DDL, truncate) | DDL zamanlaması |
| `confl_bufferpin` | Standby sorgusu bir buffer'ı tutuyor | Uzun sorgular |

**Data checksums:** `SHOW data_checksums;` kapalıysa sayfa bozulmaları tespit edilemez. PG12+ `pg_checksums --enable` (sunucu kapalıyken) ile açılabilir; PG18'de yeni `initdb` için varsayılan olarak açıktır.

---

## 19. Log kontrolü

`os_healthcheck.sh` (bölüm 10) log dosyasının son satırlarında PANIC/FATAL/ERROR sayılarını, kritik desenleri ve **en sık 10 hata mesajını** (sayılar ve isimler normalize edilerek) raporlar.

```bash
tail -n 2000 $PGDATA/log/postgresql-*.log | grep -E "PANIC|FATAL|ERROR"
```

| Desen | Anlamı | Önem |
|---|---|---|
| `PANIC` | Sunucu kendini durdurdu | **Kritik** |
| `No space left on device`, `could not write` | Disk dolu | **Kritik** |
| `invalid page`, `checksum`, `corrupt` | Veri bozulması | **Kritik** |
| `must be vacuumed within`, `wraparound` | XID wraparound yaklaşıyor | **Kritik** |
| `out of memory`, `could not fork` | Bellek / süreç limiti | Yüksek |
| `archive command failed` | Arşivleme hatası | Yüksek |
| `too many clients`, `remaining connection slots` | Bağlantı limiti | Yüksek |
| `checkpoints are occurring too frequently` | `max_wal_size` düşük | Orta |
| `terminating connection due to conflict with recovery` | Standby conflict | Orta |
| `deadlock detected` | Deadlock | Orta |
| `password authentication failed`, `no pg_hba.conf entry` | Kimlik doğrulama hataları / tarama girişimi | Güvenlik |

**Önerilen log ayarları:**

```ini
log_line_prefix = '%m [%p] %q%u@%d app=%a client=%h '
log_min_duration_statement = 1000
log_checkpoints = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 10s
log_connections = on
log_disconnections = on
```

Periyodik ve görsel analiz için **pgBadger** önerilir:

```bash
pgbadger -j 4 -o report.html $PGDATA/log/postgresql-*.log
```

Detaylı log analizi için bkz. [Loglar](logs.md).

---

## 20. Hızlı güvenlik kontrolü

📄 [`sql/17_security_quick.sql`](sql/17_security_quick.sql)

Healthcheck kapsamında yalnızca temel göstergeler kontrol edilir; ayrıntılı değerlendirme için ayrı sıkılaştırma (hardening) dokümanını ve CIS PostgreSQL Benchmark'ı kullanın.

| Bölüm | İçerik |
|---|---|
| 17.1 | Ayrıcalıklı roller (superuser, createrole, replication, bypassrls) |
| 17.2 | Bağlı oturumlarda SSL kullanımı ve TLS sürümü |
| 17.3 | Güvenlikle ilgili temel ayarlar |
| 17.4 | `pg_hba.conf` riskli kurallar: `trust`, `password`, `md5`, geniş ağ blokları *(superuser)* |
| 17.5 | MD5 hash'li parolalar *(superuser)* |
| 17.6 | Parolasız oturum açabilen roller *(superuser)* |
| 17.7 | PUBLIC'e CREATE yetkisi verilmiş şemalar |

---

## 21. Anlık yük ölçümü

📄 [`sql/90_rate_sample.sql`](sql/90_rate_sample.sql)

`pg_stat_*` görünümlerinin çoğu **istatistik sıfırlanmasından bu yana kümülatiftir**; aylar öncesinin ortalamasını gösterir. Şu anki yükü görmek için iki ölçüm arasındaki farkı alan bu dosyayı kullanın:

```bash
psql -X -d postgres -v interval=60 -f sql/90_rate_sample.sql
```

Çıktı: TPS, saniyedeki rollback, okunan/yazılan satır, diskten okuma hacmi, **anlık** cache hit oranı, saniyelik ve saatlik tahmini WAL üretimi, temp dosya hızı ve örnek süresince checkpoint sayısı.

Kullanım alanları:
- Olay anında "sistem şu an ne yapıyor?" sorusu
- `max_wal_size`, arşiv deposu ve yedek alanı planlaması (saatlik WAL hacmi)
- Değişiklik öncesi/sonrası karşılaştırma

---

## 22. Otomasyon ve izleme entegrasyonu

### Çıkış kodları

Her iki script de izleme sistemlerinin anlayacağı çıkış kodları döndürür:

| Kod | `pg_healthcheck.sh` | `os_healthcheck.sh` |
|---|---|---|
| 0 | Tüm kontroller OK | OK |
| 1 | En az bir WARN | En az bir WARN |
| 2 | En az bir CRIT | En az bir CRIT |
| 3 | Bağlantı / çalışma hatası | — |

### Cron örneği

```cron
# Her sabah 07:00 özet; haftalık pazar 03:00 tam rapor
0 7 * * *  postgres /opt/pg-healthcheck/scripts/pg_healthcheck.sh -m summary -q -o /var/log/pg-hc || mail -s "PG healthcheck: $(hostname) kod=$?" dba@example.com < /dev/null
0 3 * * 0  postgres /opt/pg-healthcheck/scripts/pg_healthcheck.sh -m full -q -o /var/log/pg-hc
# 30 günden eski raporları temizle
0 4 * * *  postgres find /var/log/pg-hc -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +
```

### Nagios / Icinga / Zabbix

`pg_healthcheck.sh -m summary -q` doğrudan check komutu olarak kullanılabilir; çıkış kodu durumu belirler, rapor dizinindeki `summary.txt` ayrıntıyı içerir.

### Sürekli izleme

Healthcheck periyodik bir değerlendirmedir; sürekli izlemenin yerini tutmaz. Prometheus `postgres_exporter` veya benzeri bir araçla en azından şunlar için alarm tanımlanmalıdır:

| Metrik | Alarm |
|---|---|
| `pg_up` | 0 |
| Bağlantı kullanımı | > %80 (5 dk) |
| Replikasyon lag (byte / sn) | Bölüm 1 eşikleri |
| Slot retained WAL / pasif slot | > 1 GB veya pasif > 30 dk |
| `pg_stat_archiver` son hata > son başarı | Anında |
| XID yaşı | > 500 M |
| En eski transaction yaşı | > 30 dk |
| Disk doluluğu (PGDATA, pg_wal) | > %80 |
| Deadlock artışı | > 0 / 5 dk |
| Checksum hatası | > 0 |

---

## 23. Raporlama ve bulgu sınıflandırma

Healthcheck sonucunda bulgular önem derecesine göre sınıflandırılmalı ve her biri için aksiyon, sorumlu ve hedef tarih belirlenmelidir.

| Seviye | Tanım | Örnekler | Hedef süre |
|---|---|---|---|
| **Kritik** | Hizmet kesintisi veya veri kaybı riski | Arşivleme hatada, XID > 1 B, disk > %90, senkron replika yok, checksum hatası, `lost` slot, `fsync=off` | Hemen |
| **Yüksek** | Kısa vadede sorun yaratacak | Bağlantı > %80, pasif slot WAL biriktiriyor, sequence > %90, replika kopuk, son yedek politika dışı | 1–7 gün |
| **Orta** | Performans / verimlilik | Yüksek bloat, requested checkpoint oranı, indeksiz FK, düşük cache hit, yüksek temp kullanımı | Planlı bakım |
| **Düşük** | İyileştirme | Kullanılmayan / mükerrer indeksler, loglama ayarları, güncellenebilir uzantılar | Fırsat buldukça |

### Rapor şablonu

```markdown
# PostgreSQL Healthcheck — <sunucu> — <tarih>

## Ortam
Sürüm / rol / uptime / veritabanları ve boyutları / replikalar

## Özet
CRIT: n   WARN: n   (summary.txt)

## Bulgular
| # | Seviye | Alan | Bulgu | Kanıt | Aksiyon | Sorumlu | Hedef |
|---|---|---|---|---|---|---|---|
| 1 | Kritik | Arşiv | archive_command 3 saattir hata veriyor | 06_...txt / 6.6 | Hedef depo erişimi düzeltilecek | DBA | Bugün |

## Önceki rapora göre değişim
Büyüme, çözülen / yeni bulgular

## Ekler
reports/<host>_<port>_<tarih>/
```

---

## 24. Özet kontrol listesi

### Servis ve sistem
- [ ] Servis ayakta, `pg_isready` OK, beklenmeyen restart yok (uptime)
- [ ] Load, iowait, CPU steal normal
- [ ] Kullanılabilir bellek yeterli, aktif swapping yok, OOM killer kaydı yok
- [ ] THP `never`, swappiness düşük, açık dosya limiti yeterli
- [ ] Disk ve inode doluluğu güvenli (PGDATA, **pg_wal**, tablespace'ler)
- [ ] Kernel log'da disk/dosya sistemi hatası yok, NTP senkronize

### Konfigürasyon
- [ ] `fsync`, `full_page_writes`, `autovacuum`, `track_counts` açık
- [ ] Restart bekleyen veya hatalı parametre yok
- [ ] Bellek parametreleri (`shared_buffers`, `work_mem`) kaynaklarla uyumlu
- [ ] Sürüm destekleniyor ve güncel minor sürümde

### Bağlantı ve aktivite
- [ ] Bağlantı sayısı `max_connections`'a yakın değil
- [ ] Uzun süreli `idle in transaction` yok
- [ ] Uzun süren sorgu ve eski transaction yok
- [ ] Bloklanan oturum ve unutulmuş prepared transaction yok

### Replikasyon ve WAL
- [ ] Tüm replikalar `streaming`, lag kabul edilebilir
- [ ] Senkron replikasyon tanımlıysa senkron replika bağlı
- [ ] Pasif veya WAL biriktiren slot yok; `wal_status` lost/unreserved yok
- [ ] pg_wal boyutu `max_wal_size` civarında
- [ ] Checkpoint'ler çoğunlukla `timed`

### Arşiv ve yedek
- [ ] Arşivleme hatasız, `.ready` birikmesi yok
- [ ] Son full / incremental yedek politika süresi içinde, `check` / `verify` başarılı
- [ ] Son restore testi belgelenmiş ve güncel

### Bakım ve depolama
- [ ] Ölü satır oranları normal, autovacuum eşiği geçmiş tablo birikmiyor
- [ ] Tüm dolu tablolar analyze edilmiş
- [ ] XID ve MultiXact yaşı güvenli; horizon'u tutan kaynak yok
- [ ] Ciddi tablo / indeks bloat'ı yok
- [ ] Büyüme trendi kapasite planıyla uyumlu

### İndeks ve sorgu
- [ ] INVALID indeks yok
- [ ] Mükerrer indeks ve indeksiz foreign key yok
- [ ] Kullanılmayan büyük indeksler (tüm node'larda) gözden geçirildi
- [ ] Cache hit oranı iş yüküne uygun (OLTP ~%99+)
- [ ] En pahalı sorgular (pg_stat_statements) incelendi; temp dosya kullanımı makul

### Bütünlük ve hata
- [ ] Data checksums açık, checksum hatası yok
- [ ] Deadlock ve rollback oranları normal
- [ ] Loglarda PANIC / bozulma / disk dolu / wraparound uyarısı yok
- [ ] Sequence doluluğu ve int4 PK taşma riski kontrol edildi

### Güvenlik (hızlı)
- [ ] `trust` / `md5` / geniş ağ blokları yok, uzak bağlantılar SSL
- [ ] Gereksiz superuser / ayrıcalıklı rol yok

---

## İlgili dokümanlar

- [İzleme](izleme.md)
- [Write Ahead Log](wal.md)
- [pgBackRest](pgbackrest.md)
- [Barman](barman.md)
- [Loglar](logs.md)
