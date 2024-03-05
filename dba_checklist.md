# DBA Checklist

## Temel RDBMS terimlerini ve kavramlarını öğrenin

- [ ] **Object model**: data types, columns, rows, tables, schemas, databases, queries.
- [ ] **Relational model**: domains, attributes, tuples, relations, constraints, NULL.
- [ ] **Databases high-level concepts**: ACID, MVCC, transactions, write-ahead log, query processing.

### Kaynaklar
*   [Postgres Glossary](https://www.postgresql.org/docs/13/glossary.html)
*   SQL and Relational Theory - Christopher J. Date, 2009
*   Database Design and Relational Theory - Christopher J. Date, 2012

## PostgreSQL'i nasıl kuracağınızı ve çalıştıracağınızı öğrenin

- [ ] Using package managers (APT, YUM, etc.)
- [ ] Using docker.
- [ ] Using kubernetes operators
- [ ] Managing Postgres service using systemd (start, stop, restart, reload).
- [ ] Managing Postgres service using pg_ctl, or OS-specific tools (like pg_ctlcluster).
- [ ] Connect to Postgres using psql.
- [ ] Deploy database service in cloud environment (AWS, GCE, Azure, Heroku, DigitalOcean, etc...).

### Kaynaklar
*   [Official download and install instructions](https://www.postgresql.org/download/)
*   [Official Docker images](https://hub.docker.com/_/postgres)

## SQL Kavramlarını öğrenin

- [ ] psql client
- [ ] Understand basic data types.
- [ ] DML queries: querying data, modifying data, filtering data, joining tables.
- [ ] Advanced topics: transactions, CTE, subqueries, lateral join, grouping, set operations.
- [ ] DDL queries: managing tables and schemas (create, alter, drop).
- [ ] Import and export data using COPY. [1](https://github.com/kamranahmedse/developer-roadmap/blob/master/src/data/roadmaps/postgresql-dba/content/104-learn-sql-concepts/102-import-export-using-copy.md)

### Kaynaklar
*   [DB Fiddle](https://www.db-fiddle.com/)
*   [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
*   [PostgreSQL SQL Getting Started](https://www.postgresql.org/docs/current/tutorial-sql.html)
*   [The SQL Language](https://www.postgresql.org/docs/current/sql.html)
## Postgres'i nasıl yapılandıracağınızı öğrenin

* postgresql.conf
* pg_hba.conf

- [ ]    Resources usage
- [ ]    Write-ahead Log
- [ ]    Checkpoints and Background Writer
- [ ]    Cost-based vacuum and auto-vacuum
- [ ]    Replication
- [ ]    Query planner
- [ ]    Reporting, logging and statistics

### Kaynaklar
* [Postgresqlco.nf](http://postgresqlco.nf/)
* [pgPedia](https://pgpedia.info/)


## Postgres güvenlik kavramlarını öğrenin
Temel güvenlik kavramları ve güvenli yapılandırmaları kullanmanın yöntemleri

- [ ] Authentication models, roles, pg_hba.conf, SSL settings.
- [ ] Objects privileges: grant/revoke, default privileges.
- [ ] Advanced topics - row-level security, selinux.

### Kaynaklar
*   [Client authentication](https://www.postgresql.org/docs/current/client-authentication.html)
*   [Roles and users managements](https://www.postgresql.org/docs/current/user-manag.html)

# VT Altyapı becerileri geliştirin
Postgres kurulumlarının ve 3. taraf Postgres ekosistem yazılımının nasıl kullanılacağını öğrenin.

* [ ]  **Replication**: streaming replication, logical replication
* [ ]   **Backup/recovery tools**:
    * [ ]   Built-in: `pg_dump`, `pg_dumpall`, `pg_restore`, `pg_basebackup`
    * [ ]   3rd-party: `barman`, `pgbackrest`, `pg_probackup`, `WAL-G`
    * [ ]  Backup validation procedures
* [ ]   **Upgrading procedures**
    * [ ]   Minor and major upgrades using `pg_upgrade`
    * [ ]  Upgrades using logical replication
* [ ]   **Connection pooling**:
    * [ ]   `Pgbouncer`
    * [ ]  Alternatives: `Pgpool-II`, `Odyssey`, `Pgagroal`
* [ ]   **Infrastructure monitoring**: `Prometheus`, `Zabbix`, other favourite monitoring solution
* [ ]  **High availability and cluster management tools**:
    * [ ]   `Patroni`
    * [ ]  **Alternatives**: `Repmgr`, `Stolon`, `pg_auto_failover`, `PAF`
* [ ]   **Applications Load Balancing and Service Discovery**: `Haproxy`, `Keepalived`, `Consul`, `Etcd`
* [ ]  **Deploy Postgres on `Kubernetes`**: Simple `StatefulSet` setup, `HELM`, operators
* [ ]  Resource usage and provisioning, capacity planning

## Rutinleri nasıl otomatikleştireceğinizi öğrenin
Pratik beceriler edinin, otomasyon araçlarını öğrenin ve mevcut rutin görevleri otomatikleştirin.

* [ ] Automation using shell scripts or any other favourite language (`Bash`, `Python`, `Perl`, etc)
* [ ] Configuration management: `Ansible`, `Salt`, `Chef`, `Puppet`

## Uygulama DBA becerilerini geliştirin
Uygulamaların Postgres ile nasıl çalışması gerektiğine dair teori öğrenin ve pratik beceriler edinin

* [ ] **Migrations**:
  * [ ] practical patterns and antipatterns
  * [ ] tools: `liquibase`, `sqitch`, `Bytebase`, language-specific tools
* [ ] Data import/export, bulk loading and processing
* [ ] **Queues**:
  * [ ]   practical patterns and anti-patterns
* [ ]   Data partitioning and sharding patterns.
* [ ]   Database normalization and normal forms.

### Kaynaklar
  *   The Art of PostgreSQL - Dimitri Fontaine, 2020


## Postgres ileri düzey konularını öğrenin
Postgres hakkında mevcut bilgileri sürekli olarak genişletmek ve geliştirmek burada önemlidir.

* [ ]  **Low level internals**:
  * [ ]     Processes and memory architecture
  * [ ]     Vacuum processing
  * [ ]     Buffer management
  * [ ]     Lock management
  * [ ]     [Physical storage and file layout](https://www.postgresql.org/docs/current/storage.html)
  * [ ]     [System catalog](https://www.postgresql.org/docs/current/catalogs.html)
* [ ]  **Fine-grained tuning**:
  * [ ]     Per-user, per-database settings
  * [ ]     [Storage parameters](https://www.postgresql.org/docs/current/sql-createtable.html#SQL-CREATETABLE-STORAGE-PARAMETERS)
   * [ ]    Workload-dependant tuning: OLTP, OLAP, HTAP
* [ ]  **Advanced SQL topics**:
    * [ ]   PL/pgSQL, procedures and functions, triggers
    * [ ]   Aggregate and window functions
    * [ ]   Recursive CTE

### Kaynaklar
  * [The Internals of PostgreSQL](http://www.interdb.jp/pg/index.html) for database administrators and system developers
  *   [PL/pgSQL Guide](https://www.postgresql.org/docs/current/plpgsql.html)

## Postgres sorun giderme tekniklerini öğrenin
Sorun giderme araçları hakkında temel bilgiler edinin ve sorunların nasıl tespit edilip çözüleceğine ilişkin pratik beceriler edinin.

* [ ]    **Operating system tools**
    * [ ]   `top` (`htop`, `atop`)
    * [ ]   `sysstat`
    * [ ]   `iotop`
* [ ]   **Postgres system views**
    * [ ]   `pg_stat_activity`
    * [ ]   `pg_stat_statements`
* [ ]   **Postgres tools**
    * [ ]   `pgcenter` - _personal recommendation_
* [ ]   **Query analyzing**:
    * [ ]   [EXPLAIN](https://www.postgresql.org/docs/current/sql-explain.html)
    * [ ]   [Depesz](https://explain.depesz.com/) online EXPLAIN visualization tool
    * [ ]   [PEV](https://tatiyants.com/pev/#/plans) online EXPLAIN visualization tool
    * [ ]   [Tensor](https://explain.tensor.ru/) online EXPLAIN visualization tool, RU language only
* [ ]   **Log analyzing**:
    * [ ]   `pgBadger`
    * [ ]   Ad-hoc analyzing using `grep`, `awk`, `sed`, etc.
* [ ]   **External tracing/profiling tools**: `gdb`, `strace`, `perf-tools`, `ebpf`, core dumps
* [ ]   **Troubleshooting methods**: USE, RED, Golden signals

### Kaynaklar
* [Linux Performance](http://www.brendangregg.com/linuxperf.html) by Brendan Gregg
* [USE Method](http://www.brendangregg.com/usemethod.html)

## SQL optimizasyon tekniklerini öğrenin
SQL sorgularının nasıl optimize edileceğine dair anlayış ve pratik beceriler edinin.

* [ ]   **Indexes, and their use cases**: B-tree, Hash, GiST, SP-GiST, GIN, BRIN
* [ ]   SQL queries patterns and anti-patterns
* [ ]   SQL schema design patterns and anti-patterns
* [ ]   **Links**:
    * [ ]   [Use the Index, Luke](https://use-the-index-luke.com/) - a Guide to Database Performance for Developers

### Kaynaklar
* [ ]   SQL Antipatterns: Avoiding the Pitfalls of Database Programming - Bill Karwin, 2010

## Mimar becerilerini geliştirmek
Postgres kullanım durumlarını ve Postgres'in uygun olup olmadığını daha iyi anlayın.

* [ ]   **Postgres forks and extensions**: `Greenplum`, `Timescaledb`, `Citus`, `Postgres-XL`, `PostGIS` etc.
*  [ ]   RDBMS in general, benefits and limitations
*  [ ]  Differences between Postgres and other RDBMS and NoSQL databases

## Postgres Hacker becerilerini geliştirin
Postgres topluluğuna katılın ve Postgres'e katkıda bulunun; Postgres'in ve açık kaynak topluluğunun faydalı bir üyesi olmak; diğer insanlara yardım etmek için kişisel deneyiminizi kullanın.

* [ ]  Daily reading and answering in [mailing lists](https://www.postgresql.org/list/)
    * [ ]  pgsql-general
    * [ ]  pgsql-admin
    * [ ]  pgsql-performance
    * [ ]  pgsql-hackers
    * [ ]  pgsql-bugs
* [ ]  Reviewing patches
* [ ]  Writing patches, attending in [Commitfests](https://commitfest.postgresql.org/)
