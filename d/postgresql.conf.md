# PostgreSQL Server Configuration Parameters
## Database Connection Parameters
```
listen_addresses
max_connections
```
## Logging Parameters
```
log_directory = log
log_filename = 'postgresql-%a.log'
log_rotation_age = 1d

# detaylı bak
log_line_prefix='%t:%r:%u@%d:[%p]: '

# none, ddl, mod, all
log_statement = all
log_duration = on
log_min_duration_statement = 1
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 1
log_autovacuum_min_duration = 1

```
## [Memory Parameters](http://www.interdb.jp/pg/pgsql02.html#_2.2.)
```
shared_buffers # shared, duble buffer
work_mem # non shared
wal_buffers # non shared
temp_buffers # non sharerd
maintenance_work_mem # shared
```
## WAL Parameters
## Memory for Locks / Lock Space
```
max_locks_per_transaction
max_pred_locks_per_transaction
```
## Query Tuning Parameters
```
autovacuum_max_workers
autovacuum_work_mem
```



Kaynaklar
```
https://www.postgresql.fastware.com/blog/back-to-basics-with-postgresql-memory-components
https://severalnines.com/blog/become-postgresql-dba-postgresql-server-configuration-parameters
https://postgresqlco.nf/en/doc/param/

```
