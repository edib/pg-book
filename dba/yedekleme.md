# Yedekleme

## mantıksal Yedekleme

```
pg_dumpall -r > roller.sql
create database  yeniyeri;
pg_dump -d eskidb -f eskidb.sql
cat eskidb.sql | psql -d yeniyeri
```

* pg_dump ve akrabaları
  * custom (-Fc)
  * directory (-Fd)
  * tar (-Ft)

```
# text dump alır
pg_dump {vt_adi} > dump.dosyasi.dmp

## yada
pg_dump {vt_adi} -f dump.dosyasi.dmp

# binary formatta alır, sıkıştırır sadece `pg_restore` komutuyla restore edilebilir.

pg_dump {vt_adi} -Fc dump.dosyasi.dmp

# sadece yapı
pg_dump {vt_adi} -Fc -s yapi.dump.dosyasi.dmp

# sadece veri
pg_dump {vt_adi} -Fc -a veri.dump.dosyasi.dmp

# clusterdaki herşeyi alır
pg_dumpall {vt_adi} -f all.dump.dosyasi.dmp


# replikalardan yedek almak için (db seviyesinde tutarsızlık olabilir.)

pg_dump -Fd -f <BACKUP_DIR> -j 20 <DB_ADI> -t <TABLO1>  -t <TABLO2> --no-synchronized-snapshots

pg_dump -Fd -f <BACKUP_DIR> -j 20 <DB_ADI> \
 -n <SCHEMA1>       \
 -n <SCHEMA2>  \
 -n <SCHEMA3> 


# bir dbyi restore
pg_restore --help
pg_restore -Fd <BACKUP_DIR> -d degerlidb -v
$ pg_restore -j 5 -c -d degerlidb dosya.db


-- Dizin dumptan sadece bir tablo alarak başka bir yere yüklemek istersek
-- pg_restore komutunu aşağıdaki şekilde çalıştırıyoruz ve dosya nolarının hangi tablonun verisi olduğu bilgisini görüyoruz. 
pg_restore -Fd <dizin_adi> -l | grep <tablo_adi> 
207; 1259 339841 TABLE <schema_adi> <tablo_adi> 

-- db ye gidip tablonun definition'ı çalıştırıp tabloyu create ediyoruz. 
create table ....;

-- sonrasında yukarıda bulduğumuz sıkıştılmış dosyası copy komutuna kaynak olarak veriyoruz. 

COPY <tablo_adi> from PROGRAM 'zcat /<path>/<dosya_no>.dat.gz' 

# doğrudan dizin yedeği, db servisinin kapalı olması gerek.
tar cvfz /tmp/yedek.tar.gz /var/lib/pgsql/11/data/

```



* restore
```
psql {vt_adi} < text.sql

pg_restore -d {vt_adi} dump.dosyasi.dump

```




  * Bir sonraki:
  [Örnek Veri](ornek_veri.md)


[Farklı kullanımları](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_postgresql_yedekleme.html#pg_restore)

## pgbackrest

* Parallel Backup & Restore 
* Local or Remote Operation 
* Multiple Repositories
* Full, Incremental, & Differential Backups 
* Backup Rotation & Archive Expiration
* Backup Integrity
  * Checksums
  * Fast restore
* Page Checksums 
* Backup Resume 
* Streaming Compression & Checksums
* Delta Restore 
* Parallel, Asynchronous WAL Push & Get
* Tablespace & Link Support 
* S3 compatible
* Encryption

### Yedekleme Yapısı

![image](/images/pgb-backup.png) 

* Full
* Differential
* Incremental

### Restore Yapısı
* Backup ve WAL Dosyaları gereklidir. 

### WAL


* node1: db primary
* node2: pgbackrest repo

* [node1: pg kurulumu](https://www.postgresql.org/download/linux/ubuntu/)
* node1: pgbackrest kurulumu
```
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" >/etc/apt/sources.list.d/pgdg.list'

apt-get install wget ca-certificates

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt-get update && apt-get install pgbackrest -y 

```
* archive ayarları: /etc/postgresql/14/main/postgresql.conf ve postgresql servisini restart ediyoruz. 

```
archive_command = 'pgbackrest --stanza=main archive-push %p'
archive_mode = on
listen_addresses = '*'

```
* ssh key tanımlama
  
```
ssh-keygen -t rsa

# postgres'in parolası olmadığı için 

touch ~/.ssh/authorized_keys 
chmod 600 ~/.ssh/authorized_keys


node2 deki ~/.ssh/id_rsa.pub içeriğini buraya yapıştır.
vi ~/.ssh/authorized_keys 

```


* node2: pgbackrest kurulumu
```
apt-get update && apt-get install pgbackrest -y 
```

* ssh key tanımlama
  
```
ssh-keygen -t rsa

# postgres'in parolası olmadığı için 

# eğer yoksa
touch ~/.ssh/authorized_keys 
chmod 600 ~/.ssh/authorized_keys

node1 deki ~/.ssh/id_rsa.pub içeriğini buraya yapıştır.
vi ~/.ssh/authorized_keys 

```

* ssh  parolasız çalışıyor mu teyit edelim

```
# node1 den 
ssh node2 

# node2 den 
ssh node1

```

* node1: /etc/pgbackrest.conf'u değiştiriyoruz

```
[global]
repo1-path=/var/lib/pgbackrest
retention-full=2
repo1-host= <repo-ip>

[main]
pg1-path=/var/lib/postgresql/14/main/
pg1-port=5432
pg1-host-user=postgres

```

* node2: /etc/pgbackrest.conf'u değiştiriyoruz

```
[global]
repo1-path=/var/lib/pgbackrest
retention-full=2
backup-user=postgres
start-fast=y
log-level-file=detail

[main]
pg1-path=/var/lib/postgresql/14/main/
pg1-host=<primary-ip>
pg1-port=5432
```

* node2 den bir depo oluşturuyoruz.

```
pgbackrest --stanza=main --log-level-console=info stanza-create

```
* herşey yolunda mı kontrol ediyoruz. Başarılı bir mesaj dönecektir. 

```
pgbackrest --stanza=main  --log-level-console=info check
```

### backup

```
# backup almak (ilk backup lar full olacaktır.)
pgbackrest --stanza=main --log-level-console=info backup
# backupların listesini görmek
pgbackrest --stanza=main --log-level-console=info info

```

* /etc/pgbackrest.conf ayarları

```
# *** birçok process başlatarak backupı alır. Bu önemli bir özellikltir. ***
[global:archive-get]
process-max=8

[global:archive-push]
process-max=8

# backup işleminde kaç pgbackrest işlemi kullansın
[global]
process-max=3

```

### restore

* restore opsiyonu sadece 2 yerde çalışır. Master ve backup sunucusunda. 
* Tehlikelidir. (delta restore için geçerlidir)
* Varolan veriniz gider.  (delta restore için geçerlidir)
* kurallar:
* dbnin kapalı olması ya da dizinin boş olması gerek. yoksa hata verir. 
* `--delta` özelliği vardır. 
* type bilgisi
  * --type=time  --type=lsn : hangisi kullanılırsa ona göre time yada lsn verilmesi gerekir. 

#### delta
* varolan kümenin üzerine yazar. 
```
pgbackrest --stanza=main --delta \
--type=time "--target=2019-07-28 17:30:00.000000+00" \
--target-action=promote restore
```  
* `--target-action=promote` restore bitince recovery modetan çıksın ve master olsun demektir. 

* Varsayılan ayarlarda restore edildiği zaman streaming replikasyon gibi son ana restore eder.

```
pgbackrest --stanza=main --log-level-console=info restore

```
Başka path'e restore etmek için "--pg1-path" parametresi belirleyebiliyoruz. Aşağıdaki komutu <baska_dizin> dizinini 700 yetkisiyle oluşturduktan sonra çalıştırırsak bu dizine son backup'ı restore eder.

```
sudo -u postgres pgbackrest --stanza=main  --pg1-path=/[baska]/[dizin]  --log-level-console=info restore
```

* Eğer cluster üzerinde tablespaceler varsa bu tablespace pathlerini elle oluşturmak ve adreslemek gerekmektedir.

```
--tablespace-map-all=/yeni/dizin/<tablescapedizini>
https://pgbackrest.org/configuration.html#section-restore/option-tablespace-map
```

* Sonrasında restore edilmiş sunucu da postgresql.conf içerisinde sistemin kaynaklarına uygun gerekli ayarlar yapılmalıdır.
* Zaman belirtilirse __kesinlikle__ verilen zamandan bir önceki **backup set**inin belirtilmesi gerekmektedir. Yoksa restore point olarak **son backup noktası** alır. 

```
pgbackrest --stanza=mystsanza --type time "--target=YYYY-mm-dd h:d:s" \
--set=[backup_adı] --db-include=[restore_etmek_istediğim_db] \
--pg1-path=/[geriyukleme]/[dizini] --log-level-console=info restore

```

* Configleri komut satırında elle tanımlamak
* sadece bir db dönmek
```
pgbackrest --stanza=main --db-include=[bir_db] --repo1-path=/[pgbackrest]/[dizini] --pg1-path=/[geriyukleme]/[dizini] --log-level-console=info restore
```
Eskisinin üstüne sadece değişen yerleri aktarsın istersek, delta parametresi local restorelar içinde kullanılabilir. Master postgres servisinin kapalı olması gerekir.

```
pgbackrest --stanza=main --delta --log-level-console=info restore
```
* Eğer restore'u backup servera dönmek istiyorsak:
  
```
pgbackrest --stanza=test --reset-pg1-host --repo1-path=/[pgbackrest]/[dizini] \
--pg1-path=/[geriyukleme]/[dizini] --log-level-console=info restore

```
* Bazı durumlarda archive-push ve archive-get komutlarını doğrudan kullanmak gerekebilir.

```
pgbackrest --log-level-console=info --stanza=test (archive-push|archive-get) /$PG_HOME/pg_wal/wal_dosyasi

```
* Uzak Makineye Restore Yapma

```
pgbackrest --stanza=main --delta restore \
                            --recovery-option=recovery_target=immediate

```
* `--recovery-option=recovery_target=immediate`: en yakın zamana dön

* [php restore script]

* [pgbackrest-check](https://github.com/edib/pgscripts/blob/master/pgbackrest_check.php)
* [referans](https://pgbackrest.org/configuration.html#section-restore)

### Diğer Konular
* https://pgbackrest.org/user-guide.html#replication
* https://pgbackrest.org/user-guide.html#async-archiving
* https://pgbackrest.org/user-guide.html#standby-backup

## [barman](https://github.com/edib/pg-dba-egitim/blob/master/dba/barman.md)
