# İşlem ve Bellek Mimarisi

## İşlem Mimarisi

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

* `postmaster/postgres`: anaata servisi
* `postgres`: backend, istemciden gelen sorgulara bakarlar, her tcp bağlantısına bir tane açılır. bağlantı kapatılınca ölür. Her biri tek bir db ile uğraşır. `max_connections`, `pgbouncer`
* `background writer`: `shared buffers` havuzundaki `dirty pages`, düzenli ve kademeli olarak kalıcı bir depolamaya yazılır.
* `checkpointer`: dirty durumdaki bellekte duran verinin topluca diske yazılma işlemidir.
* `autovacuum`: Block temizlik işlemlerini yapar. 
* `wal writer`: WAL arabellekleri, her işlem commit olduğunda diske yazar.
* `stats collector`: sunucu etkinliği hakkındaki bilgilerin toplanması ve raporlanması.
* `logical replication launcher`: logical replication işlemini yürütür. 
* `archiver`: WAL dosyası dolunca bu verileri segment dosyası yeniden kullanım için geri dönüştürülmeden önce bir yere kaydeder.

## Bellek Mimarisi

* Yerel bellek: her bir işlem kullanır.
* Ortak bellek: tüm server kullanır. 

[Yapısı](https://www.interdb.jp/pg/img/fig-2-02.png)

### Yerel bellek alanı

`work_mem`: Sayfaları, ORDER BY ve DISTINCT işlemlerine göre sıralamak ve merge-join ve hash-join işlemleriyle tabloları birleştirmek için kullanır.
`maintenance_work_mem`: VACUUM, REINDEX işlemlerinde kullanılır. 
`temp_buffers`: temp tablo işlemlerinde kullanır.

### Paylaşılan bellek alanı

`shared_buffers`: PostgreSQL, kalıcı bir depolamadan buraya tablolar ve dizinler içindeki sayfaları yükler ve bunları doğrudan çalıştırır.
`wal buffer`: kalıcı bir depolamaya yazmadan önce WAL verilerinin arabelleğe alma alanı.
`commit log`: Concurrency Control (CC) mekanizması için tüm işlemlerin (örneğin, in_progress, committed, aborted) durumlarını tutar.


### Buffer Yönetimi 

[Buffer storage ve backend ilişkisi](https://www.interdb.jp/pg/img/fig-8-01.png)
[Buffer manager](https://www.interdb.jp/pg/img/fig-8-02.png)


 * **clock sweep**: page replacement algorithms. Dolan buffer'ı temizlemek için 
* **LRU**: Least Recently Used
**checkpointer** ve **background writer** temizleme işini yapar. 


### Tampon Yöneticisi Kilitleri

**BufMappingLock**, tüm arabellek tablosunun veri bütünlüğünü korur. Hem paylaşımlı hem de özel modlarda kullanılabilen hafif bir kilittir. Arabellek tablosunda bir kayıt ararken, bir backend işlemi, paylaşılan bir **BufMappingLock** tutar. Kayıt eklerken veya silerken, bir backend işlemi **exclusivelock** tutar.


**Ring Buffer**: Büyük bir tabloyu okurken veya yazarken PostgreSQL, arabellek havuzu yerine bir **halka arabelleği** kullanır. Halka arabelleği, küçük ve geçici bir arabellek alanıdır. 16MB, yada 256KB, bir tablo shared_buffers/4 kadarsa, bulk yazma yapılırsa, vacuum sırasında.