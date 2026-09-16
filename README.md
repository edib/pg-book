# [PostgreSQL DBA](https://roadmap.sh/postgresql-dba) 
- [DBA Checklist](dba_checklist.md)

## Kurulum ve Yapılandırma
* [Kurulum](dba/kurulum.md)
* [Özel Ayarlar (initdb)](dba/ozel_ayarlar.md)
* [postgresql.conf](dba/postgresql.conf.md)
* [pg_hba.conf](dba/pg_hba.conf.md)

## Veritabanı Yönetimi
* [Veritabanı Yönetimi](dba/veritabani-yonetimi.md)
* [Veritabanı Kümesi, Veritabanları ve Tablolar](dba/veritabani-yapisi.md)
* [Tablespaces](dba/tablespaces.md)

## Erişim ve Güvenlik
* [Erişim ve Yetkiler](dba/erisim-yetkiler.md)
* [Roller ve Yetkiler](dba/yetkiler.md)
* [pgAudit + elastic](dba/pgaudit/pgaudit-elk-kurulum.md)

## Mimari ve İşlem Yönetimi
* [İşlem ve Bellek Mimarisi](dba/bellek-islem-mimarisi.md)
* [Sorgu İşleme](dba/sorgu-isleme.md)
* [Eşzamanlılık Kontrolü](dba/concurrency.md)
* [MVCC](dba/mvcc.md)
* [Vacuum İşlemleri](dba/vacuum.md)
* [Write Ahead Log](dba/wal.md)

## Yüksek Erişilebilirlik ve Ölçeklenebilirlik
* [Streaming Replication](dba/replikasyon.md)
* [Patroni](dba/patroni.md)
* [pgbouncer](dba/pgbouncer.md)
* [Foreign Data Wrapper](dba/fdw.md)
* [TimescaleDB](dba/timescaledb.md)

## Yedekleme
* [Yedekleme](dba/yedekleme.md)
* [pgBackRest](dba/pgbackrest.md)
* [Barman](dba/barman.md)

## Bakım ve Yükseltme
* [Sürüm Yükseltme (Upgrade)](dba/upgrade.md)
* [Konteynerda pg_upgrade kullanımı](docs/docker_pg_upgrade.md)

## İzleme ve Performans
* [İzleme](dba/izleme.md)
* [Loglar](dba/logs.md)
* [Explain](https://tubitak-bilgem-yte.github.io/pg-yonetici/docs/08-performans/explain/)

--------- 

# [PostgreSQL Developer](developers/giris.md)

## Temel Kavramlar
* [Giriş](developers/giris.md)
* [Veritabanı Nesneleri](developers/nesneler.md)
* [Veri Tipleri](developers/veri_tipleri.md)
* [Neden BigInteger](developers/para-tipi.md)

## SQL
* [Temel Sorgular](developers/sql.md)
* [Join Türleri](developers/joins.md)
* [CTE](developers/cte.md)
* [WITH Sorgular (Recursive)](developers/with-recursive.md)
* [Grouping Sets](developers/grouping_sets.md)
* [CASE](developers/case.md)
* [CAST](developers/casting.md)
* [JSON](developers/json.md)
* [pgvector](developers/pgvector.md)
* [Full Text Search](developers/full-text-search.md)
* [Upsert (INSERT ON CONFLICT)](developers/upsert.md)
* [İleri Düzey Konular](developers/sql-advanced.md)

## Veritabanı Tasarımı
* [Constraints (Kısıtlar)](developers/constraints.md)
* [Custom Types](developers/custom-types.md)
* [İndeksler](developers/indexing.md)
* [Partitioning](developers/partitioning.md)
* [Views](developers/views.md)

## Programlama
* [Functions](developers/functions.md)
* [Transactions](developers/transactions.md)
* [Kilitler](developers/lock-deadlock.md)
* [Deadlock](developers/dead-lock.md)

## Güvenlik
* [Sütun Güvenliği](developers/column_guvenligi.md)

## Performans
* [Analyze](developers/analyze.md)
* [Explain](developers/explain.md)
* [Performans](developers/performans.md)


 ## Yardımcı
* [linux](docs/linux.md)
* [libvirt](docs/vagrant_n_libvirt.md)
* [Bilgi Siteleri](docs/bilgi_siteleri.md)