## Ayar ve Servis Yönetimi

```
-- Config Dosyası içeriği
select * from pg_file_settings;
-- buradaki her değer show ile çağrılabilir.
show {birdeğer};
-- config dosyasını değiştiriyoruz.
alter system set work_mem='32MB';
-- confige bakınca göreceğiz.
select * from pg_file_settings;
-- sistemde aktif olmamış
show work_mem;
-- reload
select pg_reload_conf();
-- ancak reload sonrası görebiliriz.
show work_mem;

-- https://www.postgresql.org/docs/11/sql-show.html
```

## postgresql servisinin yönetimi
```
# postgres yöntemi
pg_ctl -D /var/lib/pgsql/11/data/ ${action}

# systemd yöntemi
systemctl ${action} postgresql.service

```
## Çalışan Servisler
* postgres servisinui çalıştıran postgres kullanıcısıdır. Paket kurulunda yaratılır.

```
ps aux | grep postgres
postgres  2567     1  0 09:51 ?        00:00:00 /usr/pgsql-11/bin/postmaster -D /var/lib/pgsql/11/data/
postgres  2579  2567  0 09:51 ?        00:00:00 postgres: logger
postgres  2599  2567  0 09:51 ?        00:00:00 postgres: checkpointer
postgres  2600  2567  0 09:51 ?        00:00:00 postgres: background writer
postgres  2601  2567  0 09:51 ?        00:00:00 postgres: walwriter
postgres  2602  2567  0 09:51 ?        00:00:00 postgres: autovacuum launcher
postgres  2603  2567  0 09:51 ?        00:00:00 postgres: archiver
postgres  2604  2567  0 09:51 ?        00:00:00 postgres: stats collector
postgres  2605  2567  0 09:51 ?        00:00:00 postgres: logical replication launcher
```

## Postgresql Mimarisi
* [Örnek-1](http://rachbelaid.com/introduction-to-postgres-physical-storage/)
* [Örnek-2](http://www.interdb.jp/pg/)

* `database cluster`, Veritabanlarının bulunduğu, postgres servisinin çalıştığı disk alanı.
* `tuple`: satır
* `relation` tablo
* `filenode` table ya da index'in dosya gösterimi
* [`block`](http://www.interdb.jp/pg/pgsql01.html#_1.3.) ya da [`page`](http://www.interdb.jp/pg/img/fig-1-04.png): 8kb postgres depolama birimi
* `CTID` tablodaki kayıt sürümünü verir.
* `OID`: nesnelerin obje tanımlayıcısı
* `VACUUM`, eski kayıtları temizleme işlemi

## Process Mimarisi
* [Buffer Manager](http://www.interdb.jp/pg/img/fig-8-02.png)

### logger
* db olay kayıtlarını yazar
```
--psql
show log_directory;
show log_filename;
```

### background writer
* `dirty page`: bellekteki değişenler
* Devamlı dirty page'leri diske yazar.`parametreler`

### checkpointer
* dirty page'leri belli aralıklarla yazar.[1](http://www.interdb.jp/pg/pgsql09.html#_9.7.)

### walwriter
* transaction log [1](http://www.interdb.jp/pg/pgsql09.html#_9.9.)
* sıralı yazma

### autovacuum launcher
* temizlik işleri
* otomatik özelliği kaldırılabilir.
### archiver
* transaction logları yedeklemek

### stats collector
* planner
### logical replication launcher
* replikasyon

### `tablespace` işlemleri
temp işlemlerini asıl dizinden ayırmak istersek, postgres linux kullanıcısında

```
tempdir="/var/lib/pgsql/11/temp"
mkdir -p $tempdir
chmod -R 700 postgres. $tempdir
```

Veritabanına psql ile giriş yapıyoruz.

```
--örnek dizin
create tablespace temp location '/var/lib/pgsql/11/temp';
```

`postgresql.conf` içerisine giriş yapıyoruz.

```
# bu satırı
temp_tablespaces = ''

# buna değiştiriyoruz.
temp_tablespaces = 'temp'


```

PostgreSQL'i reload ediyoruz.
```
# root yetkisindeyken
systemctl reload postgresql-11
# ya da
psql -c "select pg_reload_conf()"

```
`pg_tblspc` içerisine girip bakalım.

* Tablespaceler içerisine
temp, [database](https://www.postgresql.org/docs/11/sql-createdatabase.html), [tablo](https://www.postgresql.org/docs/11/sql-createtable.html) ya da [index](https://www.postgresql.org/docs/11/sql-createindex.html) konulabilir. Tablespaceler o cluster olmadan işe yaramazlar. [[+]](https://www.postgresql.org/docs/11/sql-createtablespace.html)

* Bir sonraki:
[performans](performans.md)
