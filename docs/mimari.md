# Mimari

## Çalışan Servisler
* postgres servisini çalıştıran postgres kullanıcısıdır. Paket kurulunda yaratılır.

```
ps aux | grep postgres
postgres  2567     1  0 09:51 ?        00:00:00 /usr/pgsql-14/bin/postmaster -D /var/lib/pgsql/14/data/
postgres  2579  2567  0 09:51 ?        00:00:00 postgres: logger
postgres  2599  2567  0 09:51 ?        00:00:00 postgres: checkpointer
postgres  2600  2567  0 09:51 ?        00:00:00 postgres: background writer
postgres  2601  2567  0 09:51 ?        00:00:00 postgres: walwriter
postgres  2602  2567  0 09:51 ?        00:00:00 postgres: autovacuum launcher
postgres  2603  2567  0 09:51 ?        00:00:00 postgres: archiver
postgres  2604  2567  0 09:51 ?        00:00:00 postgres: stats collector
postgres  2605  2567  0 09:51 ?        00:00:00 postgres: logical replication launcher
```

* [Görsel Mimari](http://www.interdb.jp/pg/pgsql01.html)
* [Terimler](http://rachbelaid.com/introduction-to-postgres-physical-storage/)

* `database cluster`: Veritabanlarının bulunduğu, postgres servisinin çalıştığı disk alanı.
* `tuple`: satır
* `relation`: tablo
* `filenode`: table ya da index'in dosya gösterimi
* `database`: Cluster içerisindeki diskteki fiziksel alan ve cluster seviyesinde mantıksal ayrık alan, sql bağlantılarının ilk karşılandığı yer. Bir cluster içerisinde birden çok veri tabanı olabilir. Bir VT oluştururken bir template kullanmak gerekir. Eğer belirtilmezse template1 i kullanır. Standart database postgrestir. 2 adet template vt vardır. template0 ve template1. template1 erişilebilir ve değiştirilebilirdir, template0 değildir.

```sh
createdb vt_adi;
dropdb vt_adi;
```
* [`block`](http://www.interdb.jp/pg/pgsql01.html#_1.3.) ya da [`page`](http://www.interdb.jp/pg/img/fig-1-04.png): 8kb postgres depolama birimi
* `CTID`: tablodaki kayıt sürümünü verir.

```psql
create table tablom (alanım int);
insert into tablom SELECT sayım FROM generate_series(1,10) sayım;
select ctid,* from tablom ;
update tablom set alanım=11 where alanım between 5 and 8;


```
* `OID`: nesnelerin obje tanımlayıcısı
* `VACUUM`: eski kayıtları temizleme işlemi
* `tablespace`: Tablo, veritabanı gibi nesneleri dosya sistemi içerisinde farklı yerlere koymaya yarayan fiziksel yapı.  Her bir nesne sadece bir tablespacete olabilir. Her bir ts bir dizindir. Farklı VT'lerdeki nesneler aynı TS'de olabilir. Standart TS'ler pg_default, pg_global'dir. 
* `schema`: Veri tabanı içerisindeki içerisindeki mantıksal alan. Klasörlere benzer, fiziksel bir geçerliliği yoktur ve hiyerarşik değildir. Default schema "public"'tir. Temp şemalar oluşturulabilir. 
* ``

TSleri aşağıdaki komutla listeleyebiliriz. 
```psql
SELECT * FROM pg_tablespace;
\db
```
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



# İşletim sistemi açısından

```sql
CREATE DATABASE degerlidb;
CREATE DATABASE

-- veritabanların dizini
SELECT datname, oid FROM pg_database WHERE datname = 'degerlidb';
 datname |  oid  
---------+-------
 degerlidb    | 80957
(1 row)


\c degerlidb

-- tabloların gerçek dizinleri  
CREATE TABLE degerlitablo(i int);
CREATE TABLE

SELECT pg_relation_filepath('degerlitablo');
-[ RECORD 1 ]--------+-----------------
pg_relation_filepath | base/80957/16384

```

* TRUNCATE, REINDEX, CLUSTER komutları tablolaların oidlerini ve filenode değiştirir.
* filenode'lar 1GB büyük olamaz. olursa arka tarafta numaralandırır. (relfilnode, relfilnode.1 şeklinde)
