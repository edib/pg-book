# Yedekleme
## pgbackrest
### DB ve Backup aynı sunucu üzerinde:  
İki seçenekli kurulum vardır.
a. db-master üzerinde pgbackrest ile kendi üzerine yedek almak. 
pgbackrest i kuruyoruz. 

```
yum install pgbackrest
```
db-server:/etc/pgbackrest.conf, Backrest her bir postgrsql cluster yedeğine "stanza" adını vermektedir. ilk tanımlamadan sonra devamlı aynı stanza adına referans vermek zorundayız. Bu ad "/var/lib/pgbackrest" içerisindeki bütün klasörlerde ve config dosyalarında geçecektir. 
```
[test]
pg1-path=/var/lib/pgsql/11/data

[global]
repo1-path=/var/lib/pgbackrest
```

db-server:``/var/lib/pgsql/11/data/postgresql.conf`` içerisinde aşağıdaki değişiklikleri yapıp postgresql servisini restart ediyoruz. stanza adının yukarıdakiyle aynı olması gerekir.
```
archive_command = 'pgbackrest --stanza=test archive-push %p'
archive_mode = on
listen_addresses = '*'
max_wal_senders = 3
wal_level = replica
```

#### stanza oluşturmak
```
pgbackrest --stanza=main --log-level-console=info stanza-create
```
### oluşturulan stanzadaki configurasyon ve diğer ayarların doğruluğunu kontrol etmek
```
pgbackrest --stanza=test --log-level-console=info check
```
### backup almak (ilk backup lar full olacaktır.)
```
pgbackrest --stanza=test --log-level-console=info backup
```
### backupların listesini görmek
```
pgbackrest --stanza=test --log-level-console=info info
stanza: test
    status: ok
    wal archive min/max: 00000001000000000000001E / 000000010000000000000029

    full backup: 20170703-115303F
        timestamp start/stop: 2017-07-03 11:50:20 / 2017-07-03 11:53:03
        wal start/stop: 00000001000000000000001E / 00000001000000000000001E
        database size: 132.6MB, backup size: 132.6MB
        repository size: 16.3MB, repository backup size: 16.3MB

    incr backup: 20170703-115303F_20170703-121130I
        timestamp start/stop: 2017-07-03 12:08:55 / 2017-07-03 12:11:30
        wal start/stop: 000000010000000000000024 / 000000010000000000000024
        database size: 132.7MB, backup size: 47.3MB
        repository size: 16.3MB, repository backup size: 6MB
        backup reference list: 20170703-115303F

    incr backup: 20170703-115303F_20170703-121319I
        timestamp start/stop: 2017-07-03 12:13:13 / 2017-07-03 12:13:19
        wal start/stop: 000000010000000000000026 / 000000010000000000000026
        database size: 56.4MB, backup size: 10.1MB
        repository size: 7.5MB, repository backup size: 1.8MB
        backup reference list: 20170703-115303F, 20170703-115303F_20170703-121130I

```

## Backup farklı sunucu üzerinde
### Kurulum
PostgreSQL sunucusu için gerekli olan pgdg deposunun kurulu olması gerekir. VT ve backup sunucularına birden aşağıdaki paketi kurun.
```
#centos
yum install pgbackrest

```
### ssh key değişimi
pgbackrest, ssh üzerinden çalıştığı için vt sunucusunun ve backup sunucusunun postgres (varsayılan) kullanıcılarının ssh üzerinden birbirlerine parolasız erişmeleri gerekmektedir.
2 makinde de postgres kullanıcılarının ssh key oluşturmadığını varsayacağız.
vt sunucusunda postgres kullanıcısındayken,
```
su - postgres
# Enter'a basarak geçin.
ssh-keygen
```
* `/var/lib/pgsql/.ssh/id_rsa.pub` dosyasının içeriğini
backup sunucusundaki `.ssh/authorized_keys` dosyanına ekleyin.

* backup sunucusunda
```
su - postgres
# Enter'a basarak geçin.
ssh-keygen
```
* `/var/lib/pgsql/.ssh/id_rsa.pub` dosyasının içeriğini
VT sunucusundaki `.ssh/authorized_keys` dosyanına ekleyin.

* test edin.
```
# vt sunucusu
su - postgres
# otomatik bağlanması gerekir.
ssh {backupserverip}
```
```
# backup sunucusu
su - postgres
# otomatik bağlanması gerekir.
ssh {backupserverip}
```

### /etc/pgbackrest.conf ayarları

Bir postgresql database makinesi (db-master) ve bir de backup makinesi (db-backup) gerekmektedir. 2 makine postgres kulllanıcısı ile parolasız bir şekilde birbirlerine erişmesi gerekmektedir. Yukarıdakinden farklı olarak pgbackrest.conf dosyası aşağıdaki şekilde olmalıdır.

** db-master:/etc/pgbackrest.conf **

```
[stanza-adi]
pg1-path=/var/lib/postgresql/11/<clusteradi>
pg1-port=5432

[global]
repo1-path=/path/pgbackrest
repo1-retention-full=3
repo1-host=backupserverip
repo1-host-user=postgres
spool-path=/some/spool/path
archive-async=y
log-level-file=detail

# *** birçok process başlatarak backupı alır. Bu önemli bir özellikltir. ***
[global:archive-get]
process-max=8

[global:archive-push]
process-max=8
```

**db-backup:/etc/pgbackrest.conf**
```
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=3
start-fast=y
log-level-file=detail
process-max=3


[test]
pg1-path=/var/lib/postgresql/11/<clusteradi>
pg1-host=master_ip
pg1-host-user=postgres
```
**db-master:**`/var/lib/pgsql/11/data/postgresql.conf` dosyası yukarı ile aynıdır. 
```
archive_command = 'pgbackrest --stanza=test archive-push %p'
archive_mode = on
listen_addresses = '*'
log_line_prefix = ''
max_wal_senders = 3
wal_level = hot_standby
```

**1. adımdaki stanza oluşturma kısmı aynen uygulanır.**

## Restore
restore opsiyonu sadece 2 yerde çalışır. Master ve backup sunucusunda. 
**Varsayılan ayarlarda restore edildiği zaman streaming replikasyon gibi son ana restore eder.**
```
sudo -u postgres pgbackrest --stanza=test --log-level-console=info restore
```
Başka path'e restore etmek için "--pg1-path" parametresi belirleyebiliyoruz. Aşağıdaki komutu <baska_dizin> dizinini 700 yetkisiyle oluşturduktan sonra çalıştırırsak bu dizine son backup'ı restore eder.
```
sudo -u postgres pgbackrest --stanza=test  --pg1-path=/[baska]/[dizin]  --log-level-console=info restore
```
* Eğer cluster üzerinde tablespaceler varsa bu tablespace pathlerini elle oluşturmak ve adreslemek gerekmektedir.
* Sonrasında restore edilmiş sunucu da postgresql.conf içerisinde sistemin kaynaklarına uygun gerekli ayarlar yapılmalıdır.
* Zaman belirtilirse __kesinlikle__ verilen zamandan bir önceki **backup set**inin belirtilmesi gerekmektedir. Yoksa restore point olarak **son backup noktası** alır. 
```
pgbackrest --stanza=mystsanza --type time "--target=YYYY-mm-dd h:d:s" \
--set=[backup_adı] --db-include=[restore_etmek_istediğim_db] \
--pg1-path=/[geriyukleme]/[dizini] --log-level-console=info restore
```

Configleri komut satırında elle tanımlamak için
```
pgbackrest --stanza=mystsanza --db-include=[bir_db] --repo1-path=/[pgbackrest]/[dizini] --pg1-path=/[geriyukleme]/[dizini] --log-level-console=info restore
```
Eskisinin üstüne sadece değişen yerleri aktarsın istersek, delta parametresi local restorelar içinde kullanılabilir. Master postgres servisinin kapalı olması gerekir.

```
pgbackrest --stanza=test --delta --log-level-console=info restore
```

### Notlar:
* __Eğer local backup servera dönmek istiyorsak__
```
pgbackrest --stanza=test --reset-pg1-host --repo1-path=/[pgbackrest]/[dizini] \
--pg1-path=/[geriyukleme]/[dizini] --log-level-console=info restore
```
Bazı durumlarda archive-push ve archive-get komutlarını doğrudan kullanmak gerekebilir.
```
pgbackrest --log-level-console=info --stanza=test (archive-push|archive-get) /$PG_HOME/pg_wal/wal_dosyasi
```
* __pgbackrest master VT sunucusu hariç uzak sunucuya restore etmeyi desteklemez.__

  Bunun için nfs kullanılabilir.

  * Bir sonraki:
  [Veritabanı Nesneler](nesneler.md)
