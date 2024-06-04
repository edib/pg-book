# PostgreSQL Server Configuration Parameters

## [Kaynak Tüketimi](https://tubitak-bilgem-yte.github.io/pg-yonetici/docs/02-veritabani-yapilandirmasi/kaynak_tuketimi/)
## [Memory Parameters](http://www.interdb.jp/pg/pgsql02.html#_2.2.)

### shared_buffers # shared, duble buffer
`shared_buffers` parametresi, sıkça erişilen verileri bellekte önbelleğe almak için kullanılan paylaşılan bellek tamponları için ayrılan bellek miktarını belirler. `shared_buffers` için daha büyük bir değer, disk erişimini en aza indirerek performansı artırabilir, ancak daha fazla RAM tüketir. Mevcut RAM'in yaklaşık olarak %25-50'si civarında bir değer hedefleyin.

### work_mem # non shared
`work_mem` parametresi, sorgu yürütme sırasında geçici depolama için ayrılan belleği kontrol eder. `work_mem` için daha büyük bir değer, karmaşık sorgular için performansı artırabilir, ancak daha fazla RAM tüketir. Orta düzeyde bir değerle başlayın ve ardından iş yükünüzün bellek gereksinimlerine göre ayarlayın.


```ini

SET work_mem='128MB';

```

### wal_buffers # non shared

wal_buffers parametresi, WAL log kayıtları için ayrılan bellek miktarını belirler. Bu tamponlar, disk I/O işlemlerini azaltarak veri yazma işlemlerinin performansını artırır.
WAL logları, her türlü veri değişikliğini kaydeder ve bu değişiklikler önce bellek tamponlarına yazılır. Daha sonra bu tamponlar diske yazılır. 16 MB-64 MB arası idealdir.

### temp_buffers # non sharerd

`temp_buffers` parametresi, bir veritabanı oturumunun kullanabileceği geçici bellek miktarını belirler. Geçici veriler genellikle geçici tablolar ve geçici dizinler tarafından kullanılır.
Geçici tablolar, bir oturum boyunca var olan ve oturum sona erdiğinde otomatik olarak silinen tablolardır. Bu tablolarda saklanan veriler, `temp_buffers` parametresi tarafından belirlenen bellek havuzunda saklanır.

```ini

# postgresql.conf dosyasını açın ve aşağıdaki satırı ekleyin veya düzenleyin
temp_buffers = 16MB

```

* oturumda set edilebilir

```ini

SET temp_buffers = '16MB';

```

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



Kaynaklar
```
https://www.postgresql.fastware.com/blog/back-to-basics-with-postgresql-memory-components
https://severalnines.com/blog/become-postgresql-dba-postgresql-server-configuration-parameters
https://postgresqlco.nf/en/doc/param/

```
