-- =====================================================================
-- 02_instance_config.sql
-- Instance bilgisi ve konfigürasyon incelemesi
--   * sürüm, uptime, dizinler, rol (primary/standby)
--   * performans ve güvenilirlik açısından kritik parametreler
--   * varsayılandan farklı ayarlar ve kaynakları
--   * restart bekleyen ayarlar, hatalı config satırları
-- Çalıştırma: psql -X -d postgres -f 02_instance_config.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\echo '--- 2.1 Instance bilgisi ---'
SELECT version()                                              AS version,
       current_setting('server_version_num')                  AS version_num,
       pg_postmaster_start_time()                             AS started_at,
       date_trunc('second', now() - pg_postmaster_start_time()) AS uptime,
       pg_conf_load_time()                                    AS conf_loaded_at,
       CASE WHEN pg_is_in_recovery() THEN 'standby' ELSE 'primary' END AS role,
       current_setting('data_directory')                      AS data_directory,
       current_setting('config_file')                         AS config_file,
       current_setting('hba_file')                            AS hba_file,
       current_setting('data_checksums')                      AS data_checksums,
       current_setting('block_size')                          AS block_size,
       current_setting('wal_segment_size')                    AS wal_segment_size;

\echo '--- 2.2 Kritik parametreler ---'
SELECT name,
       setting,
       unit,
       CASE WHEN unit IN ('8kB', 'kB', 'MB', 'B') THEN
            pg_size_pretty(setting::numeric *
              CASE unit WHEN '8kB' THEN 8192 WHEN 'kB' THEN 1024 WHEN 'MB' THEN 1048576 ELSE 1 END)
       END AS human,
       source,
       pending_restart
FROM pg_settings
WHERE name IN (
  -- bellek
  'shared_buffers', 'effective_cache_size', 'work_mem', 'maintenance_work_mem',
  'autovacuum_work_mem', 'huge_pages', 'temp_buffers', 'hash_mem_multiplier',
  -- bağlantı
  'max_connections', 'superuser_reserved_connections', 'reserved_connections',
  'idle_in_transaction_session_timeout', 'idle_session_timeout', 'statement_timeout',
  'lock_timeout', 'tcp_keepalives_idle',
  -- WAL / checkpoint
  'wal_level', 'max_wal_size', 'min_wal_size', 'checkpoint_timeout',
  'checkpoint_completion_target', 'wal_buffers', 'wal_compression', 'synchronous_commit',
  'fsync', 'full_page_writes', 'wal_keep_size', 'max_slot_wal_keep_size',
  -- replikasyon / arşiv
  'archive_mode', 'archive_command', 'archive_library', 'archive_timeout',
  'max_wal_senders', 'max_replication_slots', 'hot_standby', 'hot_standby_feedback',
  'synchronous_standby_names', 'max_standby_streaming_delay', 'wal_receiver_timeout',
  -- autovacuum
  'autovacuum', 'autovacuum_max_workers', 'autovacuum_naptime',
  'autovacuum_vacuum_scale_factor', 'autovacuum_vacuum_threshold',
  'autovacuum_vacuum_insert_scale_factor', 'autovacuum_analyze_scale_factor',
  'autovacuum_vacuum_cost_limit', 'autovacuum_vacuum_cost_delay',
  'autovacuum_freeze_max_age', 'autovacuum_multixact_freeze_max_age',
  'vacuum_freeze_min_age', 'vacuum_failsafe_age', 'log_autovacuum_min_duration',
  -- planlayıcı / I/O
  'random_page_cost', 'seq_page_cost', 'effective_io_concurrency', 'default_statistics_target',
  'max_worker_processes', 'max_parallel_workers', 'max_parallel_workers_per_gather', 'jit',
  -- istatistik / loglama
  'track_counts', 'track_activities', 'track_io_timing', 'track_wal_io_timing',
  'track_activity_query_size', 'shared_preload_libraries', 'log_min_duration_statement',
  'log_checkpoints', 'log_lock_waits', 'log_temp_files', 'log_connections', 'log_disconnections',
  'logging_collector', 'log_directory', 'log_line_prefix', 'deadlock_timeout',
  'listen_addresses', 'ssl', 'password_encryption'
)
ORDER BY name;

\echo '--- 2.3 Varsayılandan farklı tüm ayarlar ---'
SELECT name, setting, unit, source, sourcefile, sourceline
FROM pg_settings
WHERE source NOT IN ('default', 'override', 'client')
ORDER BY source, name;

\echo '--- 2.4 Restart bekleyen ayarlar (değiştirilmiş ama uygulanmamış) ---'
SELECT name, setting, unit, sourcefile
FROM pg_settings
WHERE pending_restart;

\echo '--- 2.5 Konfigürasyon dosyasındaki hatalı / uygulanmamış satırlar ---'
SELECT sourcefile, sourceline, name, setting, applied, error
FROM pg_file_settings
WHERE error IS NOT NULL OR NOT applied
ORDER BY sourcefile, sourceline;

\echo '--- 2.6 pg_hba.conf hatalı satırlar ---'
SELECT line_number, type, database, user_name, address, auth_method, error
FROM pg_hba_file_rules
WHERE error IS NOT NULL;

\echo '--- 2.7 Bellek boyutlandırma özeti ---'
-- En kötü durumda work_mem * max_connections RAM tüketimi (kaba üst sınır,
-- her sorgu birden fazla work_mem kullanabilir).
SELECT pg_size_pretty(pg_size_bytes(current_setting('shared_buffers')))       AS shared_buffers,
       pg_size_pretty(pg_size_bytes(current_setting('effective_cache_size'))) AS effective_cache_size,
       pg_size_pretty(pg_size_bytes(current_setting('work_mem')))             AS work_mem,
       pg_size_pretty(pg_size_bytes(current_setting('maintenance_work_mem'))) AS maintenance_work_mem,
       current_setting('max_connections')                                     AS max_connections,
       pg_size_pretty(pg_size_bytes(current_setting('work_mem'))
                      * current_setting('max_connections')::bigint)           AS work_mem_x_conn_worst_case;

\echo '--- 2.8 Yüklü uzantılar (bu veritabanında) ---'
SELECT e.extname, e.extversion, a.default_version AS available_version,
       CASE WHEN e.extversion <> a.default_version THEN 'GÜNCELLENEBİLİR' ELSE '' END AS note,
       n.nspname AS schema
FROM pg_extension e
JOIN pg_namespace n ON n.oid = e.extnamespace
LEFT JOIN pg_available_extensions a ON a.name = e.extname
ORDER BY e.extname;
