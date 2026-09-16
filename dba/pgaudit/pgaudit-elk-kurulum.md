# PostgreSQL + pgAudit + Filebeat + Elasticsearch Kurulum Rehberi

Bu doküman şu akışı kapsar: PostgreSQL üzerinde bir veritabanı oluşturma, `pgaudit` eklentisinin kurulup etkinleştirilmesi, audit loglarının CSV formatında diske yazılması, Filebeat ile bu CSV loglarının okunup parse edilmesi ve Elasticsearch'e gönderilmesi.

Ortam varsayımları: Ubuntu/Debian tabanlı sunucu, PostgreSQL 15/16, Elastic Stack 8.x. Sürüm farklıysa paket adlarını (`postgresql-16-pgaudit` gibi) kendi PG sürümünüze göre değiştirin.

---

## 1. PostgreSQL'de veritabanı oluşturma

```bash
sudo -u postgres psql -c "CREATE DATABASE appdb;"
sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD 'change-me';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;"
```

Bağlantıyı doğrulayın:

```bash
psql -h localhost -U appuser -d appdb -c "SELECT current_database();"
```

---

## 2. pgAudit kurulumu

### Paket ile kurulum (önerilen)

```bash
sudo apt update
sudo apt install -y postgresql-18-pgaudit
```

Paket adı PostgreSQL major sürümüne göre değişir (`postgresql-15-pgaudit`, `postgresql-16-pgaudit` vb.). PGDG apt reposu ekli değilse önce onu tanımlamanız gerekir.

### Kaynaktan derleme (paket yoksa)

```bash
sudo apt install -y postgresql-server-dev-16 make gcc
git clone https://github.com/pgaudit/pgaudit.git
cd pgaudit
git checkout REL_16_STABLE   # PG sürümünüze uygun branch
make USE_PGXS=1
sudo make USE_PGXS=1 install
```

---

## 3. pgAudit'i etkinleştirme

`pgaudit`, `shared_preload_libraries` üzerinden yüklenmesi gereken bir eklentidir, bu yüzden restart gerekir.

### 3.1 postgresql.conf ayarları

```bash
sudo -u postgres psql -c "ALTER SYSTEM SET shared_preload_libraries = 'pgaudit';"
sudo -u postgres psql -c "ALTER SYSTEM SET pgaudit.log = 'read, write, ddl, role';"
sudo -u postgres psql -c "ALTER SYSTEM SET pgaudit.log_catalog = off;"
sudo -u postgres psql -c "ALTER SYSTEM SET pgaudit.log_parameter = on;"
sudo -u postgres psql -c "ALTER SYSTEM SET pgaudit.log_relation = on;"
```

Alanların anlamı:

- `pgaudit.log`: hangi statement sınıflarının denetleneceği (`read`, `write`, `function`, `role`, `ddl`, `misc`, `all` vb.)
- `pgaudit.log_catalog`: sistem katalog sorgularının loglanıp loglanmayacağı (genelde kapatılır, gürültü çok fazladır)
- `pgaudit.log_parameter`: sorgu parametrelerinin (değerlerinin) loglanması
- `pgaudit.log_relation`: her tablo için ayrı satır loglanması

PostgreSQL'i yeniden başlatın (`shared_preload_libraries` sadece restart ile devreye girer):

```bash
sudo systemctl restart postgresql
```

### 3.2 Eklentiyi veritabanında oluşturma

```bash
sudo -u postgres psql -d appdb -c "CREATE EXTENSION IF NOT EXISTS pgaudit;"
```

Her veritabanı için ayrı ayrı `CREATE EXTENSION` çalıştırmanız gerekir.

### 3.3 Doğrulama

```bash
sudo -u postgres psql -d appdb -c "SHOW pgaudit.log;"
psql -h localhost -U appuser -d appdb -c "SELECT * FROM pg_extension WHERE extname = 'pgaudit';"
```

Bir test sorgusu çalıştırıp log dosyasında `AUDIT:` satırı görünüyor mu kontrol edin (log formatını CSV'ye çevirmeden önce plain text ile de test edebilirsiniz).

---

## 4. Audit loglarını CSV formatında kaydetme

PostgreSQL'in yerleşik `csvlog` log formatını kullanacağız; pgaudit ayrı bir dosyaya yazmaz, PostgreSQL'in kendi log altyapısını kullanır.

```sql

ALTER SYSTEM SET logging_collector = on;
ALTER SYSTEM SET log_destination = 'csvlog';
ALTER SYSTEM SET log_directory = 'log';
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log';
ALTER SYSTEM SET log_rotation_age = '1d';
ALTER SYSTEM SET log_rotation_size = '100MB';


```

```bash
sudo systemctl restart postgresql
```

`log_directory` göreceli verilirse `PGDATA` altına yazılır (örn. `/var/lib/postgresql/16/main/log`). Filebeat için tam yolu netleştirmek isterseniz mutlak yol verin, örn. `/var/log/postgresql/csv`.

Log dosyası uzantısı `.csv` olarak da oluşur (`postgresql-....csv`), `csvlog` seçildiğinde PostgreSQL aynı isimle hem `.log` hem `.csv` üretmez — `log_filename` şablonuna otomatik `.csv` eklenir. Filebeat konfigürasyonunda bu dosyaları hedefleyeceğiz.

### CSV log kolon sırası (PostgreSQL 13+)

Filebeat'te parse ederken referans olması için CSV kolonları sırasıyla:

```
log_time, user_name, database_name, process_id, connection_from, session_id,
session_line_num, command_tag, session_start_time, virtual_transaction_id,
transaction_id, error_severity, sql_state_code, message, detail, hint,
internal_query, internal_query_pos, context, query, query_pos, location,
application_name, backend_type, leader_pid, query_id
```

pgaudit satırları bu formatta `message` kolonunda `AUDIT: ...` ile başlar ve kendi içinde şu alt alanları virgülle ayırır:

```
AUDIT_TYPE, STATEMENT_ID, SUBSTATEMENT_ID, CLASS, COMMAND, OBJECT_TYPE, OBJECT_NAME, STATEMENT, PARAMETER
```

---

## 5. Filebeat ile CSV loglarını okuma

### 5.1 Kurulum

```bash
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.15.0-amd64.deb
sudo dpkg -i filebeat-8.15.0-amd64.deb
```

Elastic Stack sürümünüzle uyumlu Filebeat sürümünü kullanın.

### 5.2 `filebeat.yml` konfigürasyonu — ⚠️ bilinen sorun

> **Bu alt bölümdeki yöntem üretimde kırılıyor, kullanmayın.** pgaudit'in çok satırlı `STATEMENT` alanları (örn. çok satırlı `CREATE TABLE`, `WHERE` koşuluyla devam eden `DELETE`) Filebeat'in `type: log` input'u tarafından satır satır okunuyor; embedded newline içeren bir CSV kaydı birden fazla fiziksel satıra bölündüğü için Filebeat bunun sadece ilk satırını "tam bir olay" sanıp `message`'ı yarım bırakıyor. Sonuç: `decode_csv_fields`/script/`drop_event` processor'ları çalışsa da bozuk/kırpılmış veriyi işliyor. Gerçek kullanım için **5.2b** bölümündeki Python parser yöntemine geçin.

`log` input + `decode_csv_fields` processor ile PostgreSQL CSV loglarını yapılandırılmış alanlara ayırma denemesi (yalnızca tek satırlık statement'lar için çalışır):

```yaml
filebeat.inputs:
  - type: filestream
    id: pgaudit-csv
    enabled: true
    paths:
      - /var/lib/postgresql/18/main/log/*.csv   # kendi csv log yolunla degistir

    # pgaudit satirlarindaki SQL sorgulari icinde newline gecebiliyor;
    # bu ayar, timestamp ile baslamayan satirlari bir onceki kaydin
    # devami sayarak CSV kaydinin bolunmesini engeller.
    parsers:
      - multiline:
          type: pattern
          pattern: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          negate: true
          match: after

    # Ayristirmayi Elasticsearch ingest pipeline'i yapiyor.
    pipeline: pgaudit-csv

output.elasticsearch:
  hosts: ["https://your-es-host:9200"]
  username: "filebeat_writer"
  password: "${FILEBEAT_ES_PASSWORD}"
  index: "pgaudit-%{+yyyy.MM.dd}"
setup.template.name: "pgaudit"
setup.template.pattern: "pgaudit-*"
setup.ilm.enabled: false
```

Notlar:

- `decode_csv_fields` sadece CSV satırını diziye çevirir; ikinci adım (script processor) kolonlara isim veriyor. Elastic Agent'ta hazır bir `postgresql` modülü de var; `filebeat modules enable postgresql` ile module bazlı kuruluma da geçebilirsiniz, ancak module varsayılan olarak pgaudit'e özel `AUDIT:` alt-alanlarını parse etmez, üstteki custom pipeline daha esnek.
- `drop_event` ile sadece pgaudit satırlarını (mesajı `AUDIT:` ile başlayanları) tutup diğer PostgreSQL loglarını (bağlantı, hata vb.) filtreleyebilirsiniz; tüm logları da tutmak isterseniz bu kısmı kaldırın.
- Parola gibi sırları `filebeat.yml` içine düz yazmak yerine `${FILEBEAT_ES_PASSWORD}` gibi ortam değişkeni veya Filebeat keystore (`filebeat keystore add FILEBEAT_ES_PASSWORD`) kullanın.

## 6. Elasticsearch tarafında doğrulama

```bash
curl -u elastic:changeme -k "https://your-es-host:9200/pgaudit-*/_search?pretty&size=5"
```

Kibana üzerinde `pgaudit-*` index pattern'i (data view) oluşturup `pg.message`, `pg.database_name`, `pg.user_name` alanlarıyla Discover/Dashboard kurabilirsiniz.

İsteğe bağlı iyileştirmeler:

- **ILM policy**: `pgaudit-*` index'leri için rotation/retention politikası tanımlayın (`setup.ilm.enabled: true` + policy).
- **Index template / mapping**: `pg.log_time` alanını `date` tipine, `pg.error_severity` gibi alanları `keyword` tipine sabitlemek için özel bir index template oluşturun.
- **Ingest pipeline**: Script processor yerine Elasticsearch tarafında bir ingest pipeline (`grok`/`csv` processor) kullanmak isterseniz, Filebeat'te ham satırı gönderip parse işini ES'e devredebilirsiniz — `output.elasticsearch.pipeline: pgaudit-pipeline` ile.

---

## 7. Örnek: appdb'de CREATE TABLE ve CRUD işlemlerinin log çıktısı

`appdb` üzerinde çalıştırılan aşağıdaki SQL'ler ile bunların csvlog'daki `message` kolonunda nasıl göründüğüne dair örnekler.

### 7.1 Çalıştırılan SQL

```sql
-- CREATE
CREATE TABLE customers (
    id      serial PRIMARY KEY,
    name    text NOT NULL,
    email   text UNIQUE NOT NULL
);

-- INSERT (CREATE/write)
INSERT INTO customers (name, email)
VALUES ('Ayşe Yılmaz', 'ayse@example.com');

-- SELECT (READ)
SELECT id, name, email
FROM customers
WHERE email = 'ayse@example.com';

-- UPDATE
UPDATE customers
SET email = 'ayse.yilmaz@example.com'
WHERE id = 1;

-- DELETE
DELETE FROM customers
WHERE id = 1;
```

### 7.2 pgAudit log çıktısı (örnek)

Her satır, csvlog'daki tam satırın `message` kolonuna karşılık gelir. pgAudit kendi içinde şu formatı kullanır:

```
AUDIT: SESSION,<statement_id>,<substatement_id>,<CLASS>,<COMMAND>,<OBJECT_TYPE>,<OBJECT_NAME>,<STATEMENT>,<PARAMETER>
```

CREATE TABLE (DDL):

```
2026-09-16 10:12:03.114 +03,"appuser","appdb",18421,"127.0.0.1:53210",68c9a1a3.47f5,1,"CREATE TABLE",2026-09-16 10:11:59 +03,3/121,0,LOG,00000,"AUDIT: SESSION,1,1,DDL,CREATE TABLE,TABLE,public.customers,""CREATE TABLE customers (
    id      serial PRIMARY KEY,
    name    text NOT NULL,
    email   text UNIQUE NOT NULL
);"",<none>",,,,,,,,"psql","client backend",,
```

INSERT (WRITE):

```
2026-09-16 10:12:10.552 +03,"appuser","appdb",18421,"127.0.0.1:53210",68c9a1a3.47f5,2,"INSERT",2026-09-16 10:11:59 +03,3/122,101,LOG,00000,"AUDIT: SESSION,2,1,WRITE,INSERT,TABLE,public.customers,""INSERT INTO customers (name, email)
VALUES ('Ayşe Yılmaz', 'ayse@example.com');"",<none>",,,,,,,,"psql","client backend",,
```

SELECT (READ):

```
2026-09-16 10:12:17.203 +03,"appuser","appdb",18421,"127.0.0.1:53210",68c9a1a3.47f5,3,"SELECT",2026-09-16 10:11:59 +03,3/123,0,LOG,00000,"AUDIT: SESSION,3,1,READ,SELECT,TABLE,public.customers,""SELECT id, name, email
FROM customers
WHERE email = 'ayse@example.com';"",<none>",,,,,,,,"psql","client backend",,
```

UPDATE (WRITE):

```
2026-09-16 10:12:24.887 +03,"appuser","appdb",18421,"127.0.0.1:53210",68c9a1a3.47f5,4,"UPDATE",2026-09-16 10:11:59 +03,3/124,102,LOG,00000,"AUDIT: SESSION,4,1,WRITE,UPDATE,TABLE,public.customers,""UPDATE customers
SET email = 'ayse.yilmaz@example.com'
WHERE id = 1;"",<none>",,,,,,,,"psql","client backend",,
```

DELETE (WRITE):

```
2026-09-16 10:12:31.409 +03,"appuser","appdb",18421,"127.0.0.1:53210",68c9a1a3.47f5,5,"DELETE",2026-09-16 10:11:59 +03,3/125,103,LOG,00000,"AUDIT: SESSION,5,1,WRITE,DELETE,TABLE,public.customers,""DELETE FROM customers
WHERE id = 1;"",<none>",,,,,,,,"psql","client backend",,
```

### 7.3 Dikkat edilmesi gerekenler

- Çok satırlı statement'lar (`CREATE TABLE`, çok satırlı `INSERT`/`UPDATE`) `message` kolonu içinde **literal newline** olarak kalır; CSV alanı çift tırnak (`"..."`) ile quote'landığı için bu geçerli bir CSV'dir, ama satır bazlı okuyan (`type: log`) bir Filebeat input'u bunu **tek olay** olarak değil, birden fazla satır olarak algılayabilir. Bu yüzden Filebeat tarafında `multiline` ayarı (örn. `type: log` altında `multiline.pattern: '^\d{4}-\d{2}-\d{2}'`, `multiline.negate: true`, `multiline.match: after`) eklemek gerekebilir.
- `pgaudit.log_parameter = on` olduğunda, statement'taki değerler ayrıca `PARAMETER` alanına da (bind edilen sorgularda) yazılır; yukarıdaki örneklerde literal değerler statement içinde geçtiği için `<none>` görünüyor.
- `OBJECT_NAME` alanı şema-nitelikli (`public.customers`) gelir; Kibana'da filtreleme yaparken bunu göz önünde bulundurun.
- `SESSION_ID` (`68c9a1a3.47f5`) ve `session_line_num` (1, 2, 3...) birlikte aynı bağlantı içindeki işlemleri sıralamak için kullanılabilir.

---

## Özet akış

1. `CREATE DATABASE` / `CREATE USER` → uygulama veritabanı
2. `postgresql-pgaudit` paketi kurulumu
3. `shared_preload_libraries = 'pgaudit'` + `pgaudit.log` ayarları + restart + `CREATE EXTENSION pgaudit`
4. `log_destination = csvlog`, `logging_collector = on` → CSV audit logları diske yazılır
5. Filebeat `log` input + `decode_csv_fields` + script processor → CSV satırlarını yapılandırılmış JSON'a çevirir
6. `output.elasticsearch` → veriler Elasticsearch'e akar, Kibana'da görüntülenir
