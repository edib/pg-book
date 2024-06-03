# PostgreSQL Developer Eğitimi

## PostgreSQL Tarihçesi ve Yapısı

* güçlü, açık kaynaklı nesne ilişkisel veritabanı sistemi.
* https://db-engines.com/en/ranking_trend
* https://www.postgresql.org/docs/current/intro-whatis.html
* https://github.com/postgres/postgres
* https://www.postgresql.org/community/user-groups/
* https://www.postgresql.org/about/events/
* https://wiki.postgresql.org/wiki/PostgreSQL_derived_databases
* https://www.postgresql.org/support/versioning/

### Destek

* Mail listeleri http://www.postgresql.org/list/ 
* pgsql-tr-genel@postgresql.org 
* http://dba.stackexchange.com/questions/tagged/postgresql 
* http://postgresql.org
* https://www.postgresql.org/docs/current/static/index.html
* http://www.postgresqltutorial.com/
* Slack - postgresqltr.slack.com 
* Kurumsal Destek

### Özellikleri

* Dünyanın en gelişmiş açık kaynak geo-aware (GIS) veritabanı
* PostgreSQL Vakfı’na ait. Bir firmaya değil.
* Kod altyapısı olarak türetmeye çok uygun.
* Üzerinde eklenti geliştirme kolay
* Kodu alıp yeni bir veritabanı geliştirme (fork)
* Çok Gelişmiş Index Altyapısı
* Farklı veri tiplerinin indexlenebilmesi (JSON, XML, Spatial, Custom types…) 
* Native JSON desteği
* Native Partitioning desteği
* Geniş Programlama Dili desteği
* Java, .NET, PHP, Python, C, Node.js, Ruby, ODBC)
* Farklı dillerde stored procedure yazma
* ANSI-SQL 2008 / 2011 standartlarına uyum, ACID
* Dokümantasyon-Dokümansız kod kabul edilmez.
* Kolay kurulum (5 dk) 
* Çoklu platform Desteği (Linux, UNIX (AIX, BSD, HP-UX, SGI IRIX, Mac OS X, Solaris, Tru64) ve Windows)
* Postgresql Feature Matrix (https://www.postgresql.org/about/featurematrix/)
* Veri Tutarlılığı 
  * UNIQUE, NOT NULL)
  * Primary Keys
  * Foreign Keys
  * Exclusion Constraints
  * Explicit Locks, Advisory Locks
* Foreign data wrappers: (PostgreSQL, Oracle, MSSql, Mysql)
* Eklentiler (ek özellikler, örn. PostGIS,Timescaledb)
* Indexing: B-tree, Multicolumn, Expressions, Partial
* Advanced Indexing: GiST, SP-Gist, KNN Gist, GIN, BRIN, Bloom filters
* Sophisticated query planner / optimizer, index-only scans, multicolumn statistics
* Transactions, Nested Transactions (via savepoints)
* Multi-Version concurrency Control (MVCC)
* Parallelization of read queries
* Table partitioning
* Rransaction isolation levels
* Write-ahead Logging (WAL)
* Replication: Asynchronous / Synchronous, Physical / Logical, Cascaded
* Point-in-time-recovery (PITR), active / passive standbys
* Tablespaces
* Pgpool, Repmgr ve patroni ya da pacemaker

### Data Types

* Primitives: Integer, Numeric, String, Boolean
* Structured: Date/Time, Interval, Array, Range, UUID
* Document: JSON/JSONB, XML, Key-value (Hstore)
* Geometry: Point, Line, Circle, Polygon
* Customizations: Composite, Custom Types


## [PostgreSQL Kurulumu](/home/iek/development/postgres/pg-book/dba/kurulum.md)

## PostgreSQL Konfigürasyonu