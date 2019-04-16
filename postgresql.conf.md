# PostgreSQL Server Configuration Parameters
## Database Connection Parameters
```
listen_addresses
max_connections
```
## Logging Parameters
```
log_line_prefix='%t:%r:%u@%d:[%p]: '
log_statement
log_min_duration_statement
```
## Memory Parameters
```
shared_buffers # shared, duble buffer
work_mem # non shared
wal_buffers # shared
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
