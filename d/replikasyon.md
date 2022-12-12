# Streaming Replication

* Postgresql'de başka paket kurmadan hazır olarak replication gelmektedir. Bu replikasyon active-passive/master/slave çalışmaktadır ve istenildiği zaman multiple slave mimariye dönüştürülebilmektedir.

* masterda
  * replication kullanıcısı 

```
create user repuser password 'reppassword' replication;

```
/etc/postgresql/14/main/pg_hba.conf dosyasının en altına gerekli değişiklikleri yaparak ekliyoruz.
```
# satırı
host    replication     all             127.0.0.1/32            scram-sha-256

# bununla değiştirin
host    replication     all             <replicaip>/32          scram-sha-256
host    replication     all             127.0.0.1/32            scram-sha-256

```

* Replica olacak sunucuda: servisi durduruyoruz ve data klasörünü rename ediyoruz(silebilir de). 

```
# erişilebiliyor mu?
psql -U <replicauser> -h <primary> \
  -c "IDENTIFY_SYSTEM" \
  replication=1

systemctl stop  postgresql
mv  <postgresql_data_directory> old_<postgresql_data_directory>
```

postgresql kullanıcı hesabına geçerek pg_basebackup başlatıyoruz. Aşağıdaki script database protokolü üzerinden vt dosyalarını ve transaction loglarını slave sunucusuna aktaracaktır. Vt cluster'ınının büyüklüğüne göre zaman alacaktır. Eğer uzaktan bağlanıyorsak öncesinde "screen" komutuyla varolan bağlantıdan ayırmamız gerekmektedir.

* session ı ayırmak için
```
screen
pg_basebackup -h <ipofmaster> -p 5432 -U <replicationuser> -D <postgresql_data_directory> -R -C -S <a replication slot name> -X stream -P -v > log 2>&1; date;
```
Eğer cluster üzerindeki tablespace'i başka bir dizine adreslemek istersek aşağıdaki parametreyi ekliyoruz.
```
--tablespace-mapping=<ESKI_DIZIN>=<YENI_DIZI>
```


İşlem bittikten sonra bulunulan klasördeki log dosyasını herhangi bir hata için incelemekte yarar var. <postgresql_data_directory> içerisinde postgresql.auto.conf içinde bir tanım oluşacaktır. Bir şey değiştirmeye gerek yoktur.
```
primary_conninfo = 'user=<replicationuser> host=<ipofmaster> port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres'
primary_slot_name = '<a replication slot name>'
```

### başlat

```
systemctl start postgreql
```

replica sunucusu tüm transaction logları işleyip açılınca aşağıdaki sorgu t olarak dönecektir. primary sunucusunda f olarak dönecektir.
```
select pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 t
(1 row)

```

primary sunucuda aşağıki sorgular çalıştırılarak replikasyonun çalışıp çalışmadığı kontrol edilebilir.

```
select * from pg_replication_slots ;
-[ RECORD 1 ]-------+----------
slot_name           | r1
plugin              |
slot_type           | physical
datoid              |
database            |
active              | t
active_pid          | 28152
xmin                |
catalog_xmin        |
restart_lsn         | 0/3006D00
confirmed_flush_lsn |


select * from pg_stat_replication ;
-[ RECORD 1 ]----+------------------------------
pid              | 28152
usesysid         | 16384
usename          | repuser
application_name | walreceiver
client_addr      | <ip_address>
client_hostname  |
client_port      | 54362
backend_start    | 2017-02-14 23:43:44.850637+03
backend_xmin     |
state            | streaming
sent_location    | 0/3006D00
write_location   | 0/3006D00
flush_location   | 0/3006D00
replay_location  | 0/3006D00
sync_priority    | 0
sync_state       | async
```
Replica sunucularının byte olarak ne kadar geride olduklarıyla ilgili bilgi almak için (master sunucusunda):
```
SELECT client_hostname, client_addr,
pg_wal_lsn_diff(pg_stat_replication.sent_lsn,
pg_stat_replication.replay_lsn) AS byte_lag
FROM pg_stat_replication;

-[ RECORD 1 ]---+-----------
client_hostname | 
client_addr     | <ip_address>
byte_lag        | 0

```
Slotu kaldırmak için
```
select pg_drop_replication_slot('<slotname>');
```

Özel-1: Eğer [senkron replikasyon](https://www.postgresql.org/docs/current/runtime-config-replication.html) yapmak istiyorsak

1- replikada recovery.conf içerisindeki aşağıdaki satıra ```application_name``` tanımı ekleyeceğiz.
```
primary_conninfo = 'user=<username> host=<primary_ip> application_name=<replika_adi>'
```
sonra postgresql.conf içerisindeki aşağıdaki satırı etkin hale getiriyoruz.
```
synchronous_standby_names = '<replika_adi>'
```

```
psql -c "select application_name,client_addr,state,sent_location,write_location,flush_location,replay_location
 from pg_catalog.pg_stat_replication order by 1"
psql  -c "select slot_name,active,xmin,restart_lsn from pg_catalog.pg_replication_slots"
psql -c "SELECT * from pg_stat_archiver;"

psql -c "SELECT pg_current_wal_lsn(), 
pg_walfile_name(pg_current_wal_insert_lsn()) insert_location, 
pg_walfile_name(pg_current_wal_lsn()) write_location, 
pg_walfile_name(pg_current_wal_flush_lsn()) flush_location;"

```
