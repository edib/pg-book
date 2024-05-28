# izleme

# loglar

* [log dokümanı](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_postgresql_loglari.html)


## sistemi izleme
```
top
df -h
iftop
atop
```

* postgres istatistikler
  [trac_activity](https://postgresqlco.nf/doc/en/param/track_activity_query_size/)
```

select * from pg_stat_*;

SELECT * FROM pg_stat_database;
SELECT * FROM pg_stat_user_indexes;
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_locks;

select pg_cancel_backend(<pid>);
select pg_terminate_backend(<pid>);

```
* en büyük vtler
```
SELECT
   pg_database.datname AS "database_name",
   pg_size_pretty(pg_database_size(pg_database.datname))
   FROM pg_database
   ORDER by 2 DESC;
```

* en büyük tablolar/indexler

```
SELECT
  relname AS objectname,
  relkind AS objecttype,
  pg_size_pretty(relpages::bigint*8*1024) AS size
  FROM pg_class
  ORDER BY relpages DESC
  LIMIT 10;
```

* en çok zaman harcayan sorgular (çok çeşitli kullanılabilir.)

```
SELECT LEFT(query,50) AS query,
       calls, total_time, rows, shared_blks_hit
FROM pg_stat_statements;

```

* [pg_activity](https://github.com/dalibo/pg_activity)
* [pgcenter](https://github.com/lesovsky/pgcenter)
  
* zabbix
  * [zabbix-agent2](https://www.zabbix.com/integrations/postgresql)
  * [mamonsu](https://github.com/postgrespro/mamonsu)
* [gprometheus, postgresql_exporter, grafana](https://github.com/prometheus-community/postgres_exporter)

* **pgstattuple** bir ilişkinin fiziksel uzunluğunu, 'dead' kayıtların yüzdesini ve diğer bilgileri döndürür. vakum gerekli olup olmadığını belirlemelerine yardımcı olabilir. 
```
create extension pgstattuple;

SELECT * FROM pgstattuple('<schema>.<table>');
-[ RECORD 1 ]------+-------
table_len          | 458752
tuple_count        | 1470
tuple_len          | 438896
tuple_percent      | 95.67
dead_tuple_count   | 11
dead_tuple_len     | 3157
dead_tuple_percent | 0.69
free_space         | 8932
free_percent       | 1.95

```
* pg_buffercache: shared_bufferdaki tabloların boyutlarını verir. 

```
SELECT c.relname, count(*) AS buffers
             FROM pg_buffercache b INNER JOIN pg_class c
             ON b.relfilenode = pg_relation_filenode(c.oid) AND
                b.reldatabase IN (0, (SELECT oid FROM pg_database
                                      WHERE datname = current_database()))
             GROUP BY c.relname
             ORDER BY 2 DESC
             LIMIT 10;
```
