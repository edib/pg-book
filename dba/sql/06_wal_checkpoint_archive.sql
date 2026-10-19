-- =====================================================================
-- 06_wal_checkpoint_archive.sql
-- WAL üretimi, checkpoint davranışı ve WAL arşivleme
--   * checkpoint istatistikleri (PG17+ pg_stat_checkpointer, öncesi pg_stat_bgwriter)
--   * background writer etkinliği
--   * WAL üretim hacmi ve ortalama hız (pg_stat_wal, PG14+)
--   * pg_wal dizin boyutu, arşiv durumu, arşivlenmeyi bekleyen dosyalar
-- Çalıştırma: psql -X -d postgres -f 06_wal_checkpoint_archive.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

SELECT current_setting('server_version_num')::int >= 170000 AS pg17,
       current_setting('server_version_num')::int >= 140000 AS pg14,
       has_function_privilege('pg_ls_waldir()', 'EXECUTE') AS can_ls_wal \gset

\echo '--- 6.1 Checkpoint istatistikleri ---'
\if :pg17
SELECT num_timed,
       num_requested,
       round(100.0 * num_requested / NULLIF(num_timed + num_requested, 0), 1) AS requested_pct,
       round(write_time::numeric / 1000, 1) AS write_time_sec,
       round(sync_time::numeric  / 1000, 1) AS sync_time_sec,
       buffers_written,
       stats_reset,
       round(extract(epoch FROM now() - stats_reset) / 60
             / NULLIF(num_timed + num_requested, 0), 1) AS avg_minutes_between_ckpt
FROM pg_stat_checkpointer;

\echo '--- 6.2 Background writer ---'
SELECT buffers_clean, maxwritten_clean, buffers_alloc, stats_reset
FROM pg_stat_bgwriter;
\else
SELECT checkpoints_timed,
       checkpoints_req,
       round(100.0 * checkpoints_req / NULLIF(checkpoints_timed + checkpoints_req, 0), 1) AS requested_pct,
       round(checkpoint_write_time::numeric / 1000, 1) AS write_time_sec,
       round(checkpoint_sync_time::numeric  / 1000, 1) AS sync_time_sec,
       buffers_checkpoint,
       stats_reset,
       round(extract(epoch FROM now() - stats_reset) / 60
             / NULLIF(checkpoints_timed + checkpoints_req, 0), 1) AS avg_minutes_between_ckpt
FROM pg_stat_bgwriter;

\echo '--- 6.2 Background writer / backend yazımları ---'
-- buffers_backend yüksekse backend'ler kendi kirli sayfalarını yazmak
-- zorunda kalıyor: shared_buffers / bgwriter ayarları gözden geçirilmeli.
SELECT buffers_checkpoint, buffers_clean, maxwritten_clean,
       buffers_backend, buffers_backend_fsync, buffers_alloc,
       round(100.0 * buffers_backend
             / NULLIF(buffers_checkpoint + buffers_clean + buffers_backend, 0), 1) AS backend_write_pct
FROM pg_stat_bgwriter;
\endif
-- Yorum:
--   requested_pct > %20 -> checkpoint'ler max_wal_size dolduğu için tetikleniyor;
--                         max_wal_size artırılmalı (checkpoint_timeout ile dengeli).
--   avg_minutes_between_ckpt << checkpoint_timeout -> aynı sonuç.
--   maxwritten_clean sürekli artıyor -> bgwriter_lru_maxpages düşük.

\echo '--- 6.3 Checkpoint / WAL ayarları ---'
SELECT name, setting, unit
FROM pg_settings
WHERE name IN ('checkpoint_timeout', 'checkpoint_completion_target', 'max_wal_size',
               'min_wal_size', 'wal_buffers', 'wal_compression', 'wal_writer_delay',
               'bgwriter_delay', 'bgwriter_lru_maxpages', 'bgwriter_lru_multiplier',
               'log_checkpoints')
ORDER BY name;

\if :pg14
\echo '--- 6.4 WAL üretimi (pg_stat_wal) ---'
SELECT wal_records,
       wal_fpi,
       pg_size_pretty(wal_bytes) AS wal_bytes,
       round(100.0 * wal_fpi / NULLIF(wal_records, 0), 2) AS fpi_pct,
       wal_buffers_full,
       stats_reset,
       pg_size_pretty((wal_bytes / NULLIF(extract(epoch FROM now() - stats_reset), 0) * 3600)::bigint)
                                 AS avg_wal_per_hour,
       pg_size_pretty((wal_bytes / NULLIF(extract(epoch FROM now() - stats_reset), 0) * 86400)::bigint)
                                 AS avg_wal_per_day
FROM pg_stat_wal;
-- fpi_pct yüksek  -> checkpoint'ler sık; full page write hacmi artar
-- wal_buffers_full > 0 ve artıyor -> wal_buffers artırılabilir
-- Anlık hız için: sql/90_rate_sample.sql
\endif

\echo '--- 6.5 pg_wal dizini ---'
\if :can_ls_wal
SELECT count(*)                         AS wal_files,
       pg_size_pretty(sum(size))        AS total_size,
       current_setting('max_wal_size')  AS max_wal_size,
       min(modification)                AS oldest_file,
       max(modification)                AS newest_file
FROM pg_ls_waldir();
\else
\echo 'pg_ls_waldir() için yetki yok (superuser veya pg_monitor gerekir)'
\endif

\echo '--- 6.6 Arşivleme ---'
SELECT current_setting('archive_mode')    AS archive_mode,
       current_setting('archive_command') AS archive_command,
       current_setting('archive_timeout') AS archive_timeout,
       archived_count,
       last_archived_wal,
       last_archived_time,
       date_trunc('second', now() - last_archived_time) AS since_last_archive,
       failed_count,
       last_failed_wal,
       last_failed_time,
       CASE WHEN last_failed_time > coalesce(last_archived_time, '-infinity')
            THEN 'KRİTİK: arşivleme şu an hata veriyor'
            ELSE 'OK' END AS durum,
       stats_reset
FROM pg_stat_archiver;

\if :can_ls_wal
\echo '--- 6.7 Arşivlenmeyi bekleyen WAL dosyaları (.ready) ---'
SELECT count(*) FILTER (WHERE name LIKE '%.ready') AS ready_to_archive,
       count(*) FILTER (WHERE name LIKE '%.done')  AS done,
       min(modification) FILTER (WHERE name LIKE '%.ready') AS oldest_ready
FROM pg_ls_archive_statusdir();
-- .ready sayısı sürekli artıyorsa archive_command başarısız veya yavaş;
-- pg_wal dolacaktır. Sunucu logundaki "archive command failed" satırlarına bakın.
\endif
