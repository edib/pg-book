# DBA Checklist

## Temel RDBMS terimlerini ve kavramlarını öğrenin

- [ ] **Object model**: data types, columns, rows, tables, schemas, databases, queries.
- [ ] **Relational model**: domains, attributes, tuples, relations, constraints, NULL.
- [ ] **Databases high-level concepts**: ACID, MVCC, transactions, write-ahead log, query processing.

### Kaynaklar
<ul><li><a href="https://www.postgresql.org/docs/13/glossary.html" target="_blank" rel="nofollow">Postgres Glossary</a></li><li>SQL and Relational Theory - Christopher J. Date, 2009</li><li>Database Design and Relational Theory - Christopher J. Date, 2012</li></ul>

## PostgreSQL'i nasıl kuracağınızı ve çalıştıracağınızı öğrenin

- [ ] Using package managers (APT, YUM, etc.)
- [ ] Using docker.
- [ ] Managing Postgres service using systemd (start, stop, restart, reload).
- [ ] Managing Postgres service using pg_ctl, or OS-specific tools (like pg_ctlcluster).
- [ ] Connect to Postgres using psql.
- [ ] Deploy database service in cloud environment (AWS, GCE, Azure, Heroku, DigitalOcean, etc...).

### Kaynaklar
<ul><li><a href="https://www.postgresql.org/download/" target="_blank" rel="nofollow">Official download and install instructions</a></li><li><a href="https://hub.docker.com/_/postgres" target="_blank" rel="nofollow">Official Docker images</a></li></ul>

## SQL Kavramlarını öğrenin

- [ ] psql client
- [ ] Understand basic data types.
- [ ] DML queries: querying data, modifying data, filtering data, joining tables.
- [ ] Advanced topics: transactions, CTE, subqueries, lateral join, grouping, set operations.
- [ ] DDL queries: managing tables and schemas (create, alter, drop).
- [ ] Import and export data using COPY.

### Kaynaklar
<ul><li><a href="https://www.db-fiddle.com/" target="_blank" rel="nofollow">DB Fiddle</a></li><li><a href="https://www.postgresqltutorial.com/" target="_blank" rel="nofollow">PostgreSQL Tutorial</a></li><li><a href="https://www.postgresql.org/docs/current/tutorial-sql.html" target="_blank" rel="nofollow">PostgreSQL SQL Getting Started</a></li><li><a href="https://www.postgresql.org/docs/current/sql.html" target="_blank" rel="nofollow">The SQL Language</a></li></ul>

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
<ul><li><a href="http://postgresqlco.nf/" target="_blank" rel="nofollow">Postgresqlco.nf</a></li></ul>

