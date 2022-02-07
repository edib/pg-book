## Ayar Yönetimi

* 200'den fazla ayar var. 
* [topluluk çalışması](https://postgresqlco.nf/doc/en/param/)
* 40 farklı kategori [Tüm parametre listesi](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_parametreler.html)
* [Nostaljik](https://github.com/jberkus/annotated.conf/blob/master/extra.10.conf)
* [Ansiklopedi](https://pgpedia.info/ )

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

```


* [show komutu](https://www.postgresql.org/docs/11/sql-show.html)
* [PostgreSQL Configuration for Humans](https://www.youtube.com/watch?v=IFIXpm73qtk)

* Bir sonraki:
[performans](performans.md)
