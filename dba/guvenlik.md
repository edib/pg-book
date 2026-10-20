# PostgreSQL Sıkılaştırma (Hardening): Kapsamlı Rehber

PostgreSQL sıkılaştırması tek bir ayar dosyasıyla bitmez. İşletim sistemi, ağ, kimlik doğrulama, yetkilendirme, şifreleme, denetim, yedekleme ve yama yönetimi birlikte ele alınmalıdır. Uygunluk değerlendirmesinde genellikle iki referans kullanılır:

- **CIS PostgreSQL Benchmark**: Sürüme özel; her kontrol için denetim (audit) ve düzeltme (remediation) adımı içerir. Kurum politikalarının çoğu bunun üzerine kurulur.
- **DISA STIG (PostgreSQL)**: Daha katıdır; kamu ve finans sektöründe referans alınır.

Aşağıdaki başlıklar bu iki kaynağın ortak kapsamını izler. Her başlıkta **ne yapılmalı** ve **nasıl doğrulanır** birlikte verilmiştir.

---

## 1. Kurulum ve İşletim Sistemi Katmanı

**Kontroller:**
- PostgreSQL resmi depodan (PGDG) veya dağıtım paketinden kurulmalı. Kaynaktan derleme ancak kontrollü bir süreçle yapılmalı.
- Servis, ayrıcalıksız `postgres` kullanıcısıyla çalışmalı. Bu kullanıcının interaktif shell'i kısıtlanabilir.
- Veri dizini (`PGDATA`) `0700`, sahibi `postgres:postgres` olmalı.
- `postgresql.conf`, `pg_hba.conf` ve `pg_ident.conf` dosyaları `0600` veya `0640` izinli olmalı.
- Unix soket dizini (`unix_socket_directories`) ve izinleri (`unix_socket_permissions = 0770` veya daha kısıtlı) kontrol edilmeli.
- `umask 077` önerilir.
- SELinux enforcing modda, `postgresql_t` bağlamıyla çalışmalı.
- `initdb` sırasında `--data-checksums` açık olmalı. Bu ayar veri bütünlüğü içindir; PG 18'de varsayılan olarak açıktır.
- Gereksiz paketler (contrib altındaki kullanılmayan eklentiler, PL dilleri) kurulmamalı.
- `~/.psql_history` dosyası parola gibi hassas veri sızdırabilir. Yönetici hesaplarında `HISTFILE=/dev/null` değerlendirilebilir.
- `.pgpass` dosyası `0600` izinli olmalı.

**Doğrulama:**
```bash
stat -c '%a %U:%G %n' $PGDATA $PGDATA/postgresql.conf $PGDATA/pg_hba.conf
ps -o user,cmd -C postgres
psql -c "SHOW data_checksums;"
```

---

## 2. Ağ Katmanı

**Kontroller:**
- `listen_addresses` asla `'*'` olmamalı. Yalnızca gereken arayüz IP'leri yazılmalı. Yerel erişim yeterliyse `'localhost'` kullanılmalı.
- Port (5432) değiştirmek bir güvenlik önlemi değildir. Sadece gürültüyü azaltır.
- Host firewall (firewalld/nftables) ve ağ segmentasyonu ile yalnızca uygulama sunucuları ile bastion/jump host erişebilmeli.
- Bağlantı havuzlayıcı (PgBouncer, Pgpool) kullanılıyorsa onun da TLS ve kimlik doğrulama ayarları aynı sıkılıkta olmalı.
- `tcp_keepalives_*` ve `authentication_timeout` (örneğin `30s`) değerleri ayarlanmalı.
- `max_connections` gerçekçi bir değere çekilmeli. Bu, kaynak tüketme saldırılarına (DoS) karşı da önlemdir.

---

## 3. Kimlik Doğrulama (`pg_hba.conf`)

Değerlendirmede en çok bulgu çıkan alan budur.

**Kontroller:**
- **`trust` yöntemi hiçbir satırda olmamalı.** Yerel soket için de geçerlidir.
- **`password` (düz metin) yöntemi kullanılmamalı.**
- **`md5` yerine `scram-sha-256` kullanılmalı.** `password_encryption = scram-sha-256` (PG 14'ten itibaren varsayılan) olmalı ve eski MD5 hash'li parolalar yenilenmeli. PG 18'de MD5 parola desteği deprecated durumdadır ve uyarı verir.
- Uzak bağlantılar `host` yerine **`hostssl`** ile tanımlanmalı. Şifresiz kanalı kapatmak için `hostnossl ... reject` satırı eklenebilir.
- Geniş ağ blokları (`0.0.0.0/0`, `all all`) kullanılmamalı. Satırlar veritabanı, kullanıcı ve kaynak IP bazında dar tutulmalı. Kurallar yukarıdan aşağı ilk eşleşmeyle çalışır, bu yüzden sıralamaya dikkat edilmeli.
- Mümkünse merkezi kimlik doğrulama kullanılmalı: **LDAP/AD**, **Kerberos/GSSAPI** veya **istemci sertifikası (`cert`, `clientcert=verify-full`)**.
- `postgres` süper kullanıcısının uzaktan girişi kapatılmalı. Yalnızca yerel `peer` ile girebilmeli.
- Replikasyon satırları (`replication`) yalnızca replika IP'lerine ve ayrı bir replikasyon rolüne açık olmalı.

**Örnek sıkı `pg_hba.conf`:**
```
# TYPE    DATABASE   USER        ADDRESS          METHOD
local     all        postgres                     peer
local     all        all                          scram-sha-256
hostssl   appdb      app_user    10.10.20.0/24    scram-sha-256
hostssl   replication repl_user  10.10.30.11/32   scram-sha-256
hostssl   all        +dba_grp    10.10.5.10/32    cert clientcert=verify-full
host      all        all         0.0.0.0/0        reject
host      all        all         ::/0             reject
```

**Doğrulama:**
```sql
SELECT type, database, user_name, address, auth_method
FROM pg_hba_file_rules
WHERE auth_method IN ('trust','password','md5')
   OR address IN ('0.0.0.0','::') AND auth_method <> 'reject';

-- MD5 hash'li parolalar (superuser gerekir)
SELECT rolname FROM pg_authid WHERE rolpassword LIKE 'md5%';
```

**Parola politikası:** PostgreSQL'in yerleşik karmaşıklık veya geçmiş kontrolü yoktur. Bu açık şu yollarla kapatılır:
- `passwordcheck` modülü (temel düzeyde)
- `credcheck` eklentisi (karmaşıklık, yeniden kullanım, başarısız giriş sonrası kilitleme)
- Kimlik doğrulamayı LDAP/AD'ye devretmek. Bu durumda parola politikası oradan gelir.

Rollere `VALID UNTIL` ile son kullanma tarihi verilebilir. Brute-force koruması için `auth_delay` modülü kullanılabilir.

---

## 4. Yetkilendirme ve Rol Yönetimi

**En az yetki ilkesi** burada uygulanır.

**Kontroller:**
- **Süper kullanıcı sayısı minimumda olmalı.** Uygulamalar asla superuser ile bağlanmamalı.
- `CREATEROLE`, `CREATEDB`, `REPLICATION` ve `BYPASSRLS` yetkileri yalnızca gerekli rollerde bulunmalı.
- Rol modeli şöyle kurulmalı: **sahip rolü** (nesnelerin sahibi, `NOLOGIN`), **uygulama rolü** (yalnızca DML), **salt okunur rol**, **yönetici rolleri** (kişisel hesaplar, paylaşılan hesap olmamalı).
- **`PUBLIC` yetkileri kısıtlanmalı:**
  ```sql
  REVOKE ALL ON DATABASE appdb FROM PUBLIC;
  REVOKE CREATE ON SCHEMA public FROM PUBLIC;  -- PG 15+ varsayılan
  REVOKE ALL ON SCHEMA public FROM PUBLIC;
  ```
- `template1` veritabanında gereksiz nesne veya yetki bulunmamalı. Yeni veritabanları buradan kopyalanır.
- Hazır rollerden (`pg_read_server_files`, `pg_write_server_files`, `pg_execute_server_program`) dosya sistemine erişim sağlayanlar kimseye verilmemeli. Bu roller `COPY ... FROM PROGRAM` ile komut çalıştırmaya kadar gider.
- Gerekli durumlarda yerleşik izleme ve bakım rolleri (`pg_monitor`, `pg_read_all_stats`, `pg_maintain` (PG 17+), `pg_checkpoint`) kullanılmalı. Bunlar superuser verme ihtiyacını ortadan kaldırır.
- `SECURITY DEFINER` fonksiyonlarında `SET search_path = pg_catalog, pg_temp` tanımlı olmalı. Aksi halde search_path ele geçirme saldırısı mümkündür.
- Hassas tablolar için **Row Level Security (RLS)** ve sütun bazlı `GRANT` kullanılmalı.
- `ALTER DEFAULT PRIVILEGES` ile yeni oluşturulan nesnelerin yetkileri öngörülebilir hale getirilmeli.

**Doğrulama:**
```sql
-- Yetkili roller
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolreplication, rolbypassrls, rolcanlogin, rolvaliduntil
FROM pg_roles WHERE rolname !~ '^pg_' ORDER BY rolsuper DESC;

-- Tehlikeli hazır rol üyelikleri
SELECT r.rolname AS role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname IN ('pg_read_server_files','pg_write_server_files','pg_execute_server_program');

-- search_path tanımsız SECURITY DEFINER fonksiyonlar
SELECT n.nspname, p.proname
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.prosecdef AND (p.proconfig IS NULL OR NOT EXISTS
  (SELECT 1 FROM unnest(p.proconfig) c WHERE c LIKE 'search_path=%'))
  AND n.nspname NOT IN ('pg_catalog','information_schema');

-- PUBLIC'e açık şema yetkileri
SELECT nspname, nspacl FROM pg_namespace WHERE nspacl::text LIKE '%=U%' OR nspacl::text LIKE '%=UC%';
```

Yeni user oluşturma kuralları

```
-- ===== Superuser olarak, herhangi bir DB'den =====
REVOKE ALL ON DATABASE appdb     FROM PUBLIC;
REVOKE ALL ON DATABASE postgres  FROM PUBLIC;
REVOKE ALL ON DATABASE template1 FROM PUBLIC;

CREATE ROLE appuser LOGIN PASSWORD '...'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

GRANT CONNECT ON DATABASE appdb TO appuser;

-- ===== appdb'ye bağlanarak (\c appdb) =====
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- Tablo/fonksiyonları oluşturan rol (örn. owner) için varsayılanlar
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- Kullanıcıya gereken yetkiler
GRANT USAGE ON SCHEMA public TO appuser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO appuser;

-- Gelecekte app_owner'ın oluşturacağı nesneler için
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO appuser;
```

---

## 5. Şifreleme

### Aktarım halindeki veri (TLS)
```ini
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file  = 'server.key'      # 0600, sahibi postgres
ssl_ca_file   = 'root.crt'
ssl_min_protocol_version = 'TLSv1.2'   # mümkünse TLSv1.3
ssl_ciphers = 'HIGH:!aNULL:!MD5:!3DES:!RC4'
ssl_prefer_server_ciphers = on
```
- Self-signed yerine kurumsal CA'dan alınmış sertifika kullanılmalı.
- İstemci tarafında `sslmode=verify-full` olmalı. `require` modu sunucu kimliğini doğrulamaz ve MITM'e açıktır.
- Replikasyon bağlantıları (`primary_conninfo`) da TLS kullanmalı.

**Doğrulama:**
```sql
SELECT ssl, version, cipher, usename, client_addr
FROM pg_stat_ssl JOIN pg_stat_activity USING (pid);
```

### Durağan veri (at rest)
- Topluluk sürümü PostgreSQL'de yerleşik **TDE yoktur**. Seçenekler şunlardır:
  - Disk veya volume düzeyinde şifreleme (LUKS, depolama şifrelemesi, bulut KMS)
  - TDE sunan dağıtımlar (EDB, Percona pg_tde, Cybertec PGEE)
  - Sütun düzeyinde şifreleme (`pgcrypto`). Bu durumda anahtar yönetimi uygulama tarafında olmalı, anahtar veritabanında tutulmamalı.
- **Yedekler, WAL arşivleri ve geçici dosyalar da şifrelenmeli.** Bu nokta sık atlanır.

---

## 6. Loglama ve Denetim (Audit)

Uygunluk değerlendirmesinin ikinci büyük alanı budur. KVKK gibi mevzuatlar açısından da kritiktir.

**Temel log ayarları:**
```ini
logging_collector = on
log_destination = 'stderr'        # veya csvlog/jsonlog (PG 15+), syslog
log_directory = 'log'
log_file_mode = 0600
log_rotation_age = 1d
log_connections = on               # PG 18'de ayrıntı seçenekleriyle genişletildi
log_disconnections = on
log_line_prefix = '%m [%p] %q%u@%d %r app=%a '
log_statement = 'ddl'              # 'all' genelde fazla; pgaudit tercih edilir
log_min_duration_statement = 1000  # yavaş sorgular
log_lock_waits = on
log_temp_files = 0
log_checkpoints = on
log_error_verbosity = default
log_min_error_statement = error
```

**Dikkat edilecekler:**
- `log_statement = 'all'` ve `log_min_duration_statement = 0` ayarları **parolaları ve kişisel verileri loglara yazabilir.** `ALTER ROLE ... PASSWORD '...'` gibi ifadeler düz metin olarak görünür. Parolaları istemci tarafında `\password` ile değiştirmek bu riski ortadan kaldırır.
- Loglar sunucudan merkezi SIEM'e veya log sistemine aktarılmalı ve değiştirilemez şekilde saklanmalı.

**pgaudit:** Kurumsal denetim için fiilen standarttır.
```ini
shared_preload_libraries = 'pgaudit'
pgaudit.log = 'ddl, role, write'     # read de eklenebilir ama hacim yüksek olur
pgaudit.log_catalog = off
pgaudit.log_parameter = off          # hassas veri sızmasını önler
pgaudit.log_relation = on
```
- **Session audit:** sınıf bazlı loglama (DDL, ROLE, WRITE, READ...)
- **Object audit:** Belirli bir audit rolüne `GRANT SELECT ON hassas_tablo TO auditor` verilir. Böylece yalnızca o tabloya yapılan erişim loglanır.

**Ek olarak:**
- `pg_stat_statements` ile sorgu envanteri tutulabilir. Bu bir audit aracı değildir ama anomali tespitinde işe yarar.
- `log_connections` loglarından başarısız giriş denemeleri izlenip alarm kurulmalı.

---

## 7. Güvenlikle İlgili Diğer Parametreler

| Parametre | Önerilen | Neden |
|---|---|---|
| `password_encryption` | `scram-sha-256` | MD5 zayıftır |
| `ssl` | `on` | Aktarım şifrelemesi |
| `listen_addresses` | belirli IP'ler | Saldırı yüzeyini daraltır |
| `authentication_timeout` | `30s` | Yarım bırakılan bağlantılar |
| `statement_timeout` | uygulamaya göre (rol bazında) | Kaçak sorgular / DoS |
| `idle_in_transaction_session_timeout` | örn. `10min` | Kilit tutan oturumlar |
| `idle_session_timeout` | rol bazında | Terk edilmiş oturumlar |
| `row_security` | `on` | RLS'nin atlanmaması |
| `log_file_mode` | `0600` | Log gizliliği |
| `shared_preload_libraries` | yalnızca gerekenler | Gereksiz kod yüklenmez |
| `fsync`, `full_page_writes` | `on` | Bütünlük (asla kapatılmamalı) |
| `wal_level` | `replica` (veya `logical`) | PITR ve denetim izi |
| `track_activities` | `on` | İzleme |
| `dynamic_library_path` | varsayılan | Keyfi kütüphane yüklenmesini önler |

Rol bazlı ayar örneği:
```sql
ALTER ROLE app_user SET statement_timeout = '30s';
ALTER ROLE app_user SET idle_in_transaction_session_timeout = '60s';
```

**Doğrulama:** Değerin nereden geldiği (`source`) de raporlanmalı.
```sql
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('ssl','password_encryption','listen_addresses','log_connections',
               'log_disconnections','logging_collector','log_file_mode',
               'shared_preload_libraries','ssl_min_protocol_version');
```

---

## 8. Eklentiler, Diller ve Fonksiyonlar

- **Güvenilmeyen (untrusted) diller** (`plpython3u`, `plperlu`) işletim sistemine erişim verir. Kurulmamalı veya yalnızca superuser'da kalmalı.
- `dblink`, `postgres_fdw`, `file_fdw`, `adminpack` gibi dış erişim sağlayan eklentiler envantere alınmalı ve gerekçelendirilmeli. `adminpack` PG 17'de kaldırıldı.
- PG 13+ sürümlerde "trusted extension" kavramı var. Superuser olmayan veritabanı sahiplerinin hangi eklentileri kurabildiği gözden geçirilmeli.
- `lo_import` ve `lo_export` sunucu tarafı fonksiyonları dosya sistemine erişir. Varsayılan olarak superuser'a kısıtlıdır ve öyle kalmalıdır.

```sql
SELECT extname, extversion FROM pg_extension;
SELECT lanname, lanpltrusted FROM pg_language;
```

---

## 9. Yedekleme, Kurtarma ve Yüksek Erişilebilirlik

Bu başlık bütünlük ve erişilebilirlik açısından sıkılaştırmanın parçasıdır.
- Düzenli ve **test edilmiş** yedekleme ile PITR (WAL arşivi) olmalı. Araç olarak pgBackRest, Barman veya WAL-G kullanılabilir.
- Yedekler şifrelenmeli, ayrı bir lokasyonda tutulmalı ve erişimleri kısıtlı olmalı.
- Restore testleri belgelenmeli. Denetimlerde "yedek var" değil, "restore edildi ve doğrulandı" kanıtı istenir.
- Replikasyon rolü ayrı olmalı, superuser kullanılmamalı.
- Replikasyon slotlarının şişmesi disk dolmasına, dolayısıyla DoS'a yol açar. `max_slot_wal_keep_size` ile sınır konmalı.

---

## 10. Yama ve Sürüm Yönetimi

- **Desteklenen bir major sürüm** kullanılmalı. PostgreSQL her major sürümü yaklaşık 5 yıl destekler. Desteği bitmiş sürüm doğrudan bulgudur.
- Minor güncellemeler (örneğin 16.x) güvenlik düzeltmesi içerir ve genellikle yalnızca binary değişimiyle uygulanır. Üç ayda bir yayımlanan sürümler takip edilmeli.
- PostgreSQL güvenlik duyuruları (CVE'ler) izlenmeli. Eklentiler ve havuzlayıcılar da yama kapsamına alınmalı.

```sql
SELECT version();
```

---

## 11. İzleme ve Operasyonel Güvenlik

- Kim, ne zaman, nereden bağlanıyor: `pg_stat_activity` izlenmeli ve anormal IP veya uygulama adı için alarm kurulmalı.
- Başarısız giriş, yetki hatası (`permission denied`) ve DDL olayları için SIEM kuralları tanımlanmalı.
- Ayar değişikliklerinin kaydı tutulmalı. Bunun için `ALTER SYSTEM` yerine yapılandırma yönetimi (Ansible/GitOps) kullanmak daha iyidir. PG 17'de `allow_alter_system = off` ile `ALTER SYSTEM` kapatılabilir.
- Yönetici erişimi bastion ve PAM (ayrıcalıklı erişim yönetimi) üzerinden, kişisel hesaplarla yapılmalı.

---

## Uygunluk Değerlendirmesi Nasıl Yapılır?

**1. Politikayı tanımlayın.** CIS Benchmark'ın ilgili sürümü temel alınır ve kurumun istisnaları (gerekçeleriyle) belgelenir. Level 1 temel kontrollerdir, Level 2 daha katıdır.

**2. Kontrolleri otomatikleştirin.** Seçenekler:
- **pgdsat** (PostgreSQL Database Security Assessment Tool): CIS kontrollerinin büyük kısmını çalıştırıp HTML/metin rapor üretir. Hızlı bir başlangıç için idealdir.
- **CIS-CAT Pro**: CIS'in resmi tarama aracıdır (lisanslı).
- **InSpec / Chef**: `postgres-baseline` profili (dev-sec) kod olarak uyumluluk sağlar ve CI'ya entegre edilebilir.
- **Ansible**: `dev-sec` hardening rolleriyle hem tarama (check mode) hem düzeltme yapılabilir.
- **OpenSCAP**: OS tarafı için. PostgreSQL için STIG içerikleri mevcuttur.
- Bunlara ek olarak yukarıdaki SQL sorgularından oluşan kendi kontrol scriptiniz.

**3. Her kontrol için kanıt toplayın.** Komut çıktısı, ayar değeri, `source` bilgisi ve tarih kaydedilir.

**4. Bulguları sınıflandırın.** Kritik / Yüksek / Orta / Düşük. Tipik kritik bulgular:
- `pg_hba.conf` içinde `trust` veya geniş IP blokları
- Uygulamanın superuser ile bağlanması
- TLS olmaması veya istemcide `verify-full` kullanılmaması
- Desteklenmeyen sürüm
- Audit logunun olmaması veya loglarda parola bulunması
- MD5 parola hash'leri

**5. Düzeltme ve tekrar tarama.** Düzeltmeler yapılandırma yönetimiyle uygulanır ve tarama periyodik hale getirilir (örneğin aylık). Böylece "bir kerelik sıkılaştırma" yerine süregelen uyumluluk (drift tespiti) elde edilir.

---

### Özet Kontrol Listesi

| Alan | Temel Kontrol |
|---|---|
| OS | Dosya izinleri 0700/0600, ayrıcalıksız servis kullanıcısı, SELinux |
| Ağ | `listen_addresses` dar, firewall, segmentasyon |
| Kimlik doğrulama | `trust`/`password`/`md5` yok, `scram-sha-256`, `hostssl`, dar IP kuralları |
| Parola | credcheck veya LDAP, `VALID UNTIL`, `auth_delay` |
| Yetki | Minimum superuser, PUBLIC revoke, rol modeli, tehlikeli hazır roller verilmemiş |
| Fonksiyonlar | SECURITY DEFINER + search_path, untrusted diller kapalı |
| Şifreleme | TLS 1.2+, kurumsal sertifika, disk ve yedek şifreleme |
| Denetim | pgaudit, bağlantı logları, log izinleri, SIEM'e aktarım |
| Parametreler | Timeout'lar, `fsync` açık, `ALTER SYSTEM` kontrolü |
| Yedekleme | PITR, şifreli yedek, restore testi |
| Yama | Desteklenen major sürüm, güncel minor sürüm |

İsterseniz bu kontrolleri tek seferde çalıştırıp rapor üreten bir SQL + bash denetim scripti veya şirket içi politika dokümanı formatında bir kontrol listesi hazırlayabilirim.