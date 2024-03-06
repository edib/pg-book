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

### shared_buffers # shared, duble buffer
`shared_buffers` parametresi, sıkça erişilen verileri bellekte önbelleğe almak için kullanılan paylaşılan bellek tamponları için ayrılan bellek miktarını belirler. `shared_buffers` için daha büyük bir değer, disk erişimini en aza indirerek performansı artırabilir, ancak daha fazla RAM tüketir. Mevcut RAM'in yaklaşık olarak %25-50'si civarında bir değer hedefleyin.

### work_mem # non shared
`work_mem` parametresi, sorgu yürütme sırasında geçici depolama için ayrılan belleği kontrol eder. `work_mem` için daha büyük bir değer, karmaşık sorgular için performansı artırabilir, ancak daha fazla RAM tüketir. Orta düzeyde bir değerle başlayın ve ardından iş yükünüzün bellek gereksinimlerine göre ayarlayın.

### wal_buffers # non shared

Increasing the value of wal_buffers can improve performance, especially in write-heavy workloads, by reducing the frequency of disk writes for WAL data. However, setting it too high can increase memory usage per backend, potentially leading to excessive memory consumption, especially in systems with many concurrent database connections.

### temp_buffers # non sharerd

### maintenance_work_mem # shared

`maintenance_work_mem` parametresinin değeri, bu tür bakım işlemleri sırasında kullanılan geçici belleğin miktarını belirler. Daha yüksek bir maintenance_work_mem değeri, bakım işlemlerinin daha hızlı çalışmasına ve daha büyük veri kümeleriyle daha etkili bir şekilde başa çıkmasına olanak tanır.

### effective_cache_size

`effective_cache_size` parametresi, işletim sistemi tarafından disk önbelleğine ayrılan tahmini bellek miktarını temsil eder. PostgreSQL, bu değeri tampon önbelleği ve diğer bellek ile ilgili parametrelerin uygun boyutunu belirlemek için kullanır. Optimal bellek kullanımını sağlamak için `effective_cache_size` için doğru bir değer hedefleyin.


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
