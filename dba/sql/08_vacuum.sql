-- =====================================================================
-- 08_vacuum.sql
-- Vacuum / autovacuum sağlığı (bağlanılan veritabanı için)
--   * ölü satır (dead tuple) oranları
--   * autovacuum eşiğini geçmiş ama vacuum'lanmamış tablolar
--   * son vacuum / analyze zamanları
--   * tabloya özel autovacuum ayarları
--   * çalışan autovacuum worker'ları
-- Çalıştırma: psql -X -d <db> -f 08_vacuum.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\echo '--- 8.1 Autovacuum ayarları ---'
SELECT name, setting, unit
FROM pg_settings
WHERE name LIKE 'autovacuum%' OR name IN ('vacuum_cost_limit', 'vacuum_cost_delay',
       'vacuum_freeze_min_age', 'vacuum_freeze_table_age', 'vacuum_failsafe_age',
       'vacuum_multixact_failsafe_age', 'maintenance_work_mem', 'log_autovacuum_min_duration')
ORDER BY name;

\echo '--- 8.2 En çok ölü satıra sahip 20 tablo ---'
SELECT schemaname,
       relname,
       n_live_tup,
       n_dead_tup,
       round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS dead_pct,
       n_mod_since_analyze,
       n_ins_since_vacuum,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       last_autoanalyze,
       vacuum_count,
       autovacuum_count
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20;

\echo '--- 8.3 Autovacuum eşiğini geçmiş tablolar (vacuum / analyze bekleyen) ---'
-- eşik = threshold + scale_factor * reltuples ; tablo bazlı reloptions dikkate alınır.
WITH opts AS (
  SELECT c.oid,
         c.reltuples,
         coalesce((SELECT split_part(o, '=', 2) FROM unnest(c.reloptions) o
                   WHERE o LIKE 'autovacuum_vacuum_threshold=%'),
                  current_setting('autovacuum_vacuum_threshold'))::numeric      AS v_thr,
         coalesce((SELECT split_part(o, '=', 2) FROM unnest(c.reloptions) o
                   WHERE o LIKE 'autovacuum_vacuum_scale_factor=%'),
                  current_setting('autovacuum_vacuum_scale_factor'))::numeric   AS v_sf,
         coalesce((SELECT split_part(o, '=', 2) FROM unnest(c.reloptions) o
                   WHERE o LIKE 'autovacuum_analyze_threshold=%'),
                  current_setting('autovacuum_analyze_threshold'))::numeric     AS a_thr,
         coalesce((SELECT split_part(o, '=', 2) FROM unnest(c.reloptions) o
                   WHERE o LIKE 'autovacuum_analyze_scale_factor=%'),
                  current_setting('autovacuum_analyze_scale_factor'))::numeric  AS a_sf,
         coalesce((SELECT split_part(o, '=', 2) FROM unnest(c.reloptions) o
                   WHERE o LIKE 'autovacuum_enabled=%'), 'true')                AS av_enabled
  FROM pg_class c
  WHERE c.relkind IN ('r', 'm')
)
SELECT s.schemaname,
       s.relname,
       s.n_dead_tup,
       round(o.v_thr + o.v_sf * greatest(o.reltuples, 0))  AS vacuum_threshold,
       s.n_mod_since_analyze,
       round(o.a_thr + o.a_sf * greatest(o.reltuples, 0))  AS analyze_threshold,
       o.av_enabled,
       greatest(s.last_autovacuum, s.last_vacuum)          AS last_vacuum_any,
       CASE WHEN s.n_dead_tup > o.v_thr + o.v_sf * greatest(o.reltuples, 0)
            THEN 'VACUUM BEKLİYOR' END                     AS vacuum_due,
       CASE WHEN s.n_mod_since_analyze > o.a_thr + o.a_sf * greatest(o.reltuples, 0)
            THEN 'ANALYZE BEKLİYOR' END                    AS analyze_due
FROM pg_stat_user_tables s
JOIN opts o ON o.oid = s.relid
WHERE s.n_dead_tup > o.v_thr + o.v_sf * greatest(o.reltuples, 0)
   OR s.n_mod_since_analyze > o.a_thr + o.a_sf * greatest(o.reltuples, 0)
ORDER BY s.n_dead_tup DESC
LIMIT 30;
-- Eşiği geçmiş tablolar uzun süre listede kalıyorsa autovacuum yetişemiyor:
-- autovacuum_max_workers, autovacuum_vacuum_cost_limit, cost_delay gözden geçirilmeli
-- veya vacuum'u engelleyen uzun transaction / slot / prepared xact aranmalı (09_wraparound.sql).

\echo '--- 8.4 En uzun süredir vacuum / analyze görmeyen 20 tablo ---'
SELECT schemaname,
       relname,
       n_live_tup,
       greatest(last_vacuum, last_autovacuum)   AS last_vacuum_any,
       greatest(last_analyze, last_autoanalyze) AS last_analyze_any,
       date_trunc('day', now() - greatest(last_analyze, last_autoanalyze)) AS analyze_age
FROM pg_stat_user_tables
WHERE n_live_tup > 0
ORDER BY greatest(last_analyze, last_autoanalyze) NULLS FIRST
LIMIT 20;

\echo '--- 8.5 Tabloya özel ayarlar (reloptions) ---'
SELECT n.nspname, c.relname, c.reloptions
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.reloptions IS NOT NULL AND c.relkind IN ('r', 'm', 'p')
ORDER BY 1, 2;
-- autovacuum_enabled=false olan tablolar özellikle incelenmeli.

\echo '--- 8.6 Çalışan autovacuum worker''ları ---'
SELECT a.pid,
       a.datname,
       date_trunc('second', now() - a.xact_start) AS running,
       p.relid::regclass AS relation,
       p.phase,
       round(100.0 * p.heap_blks_scanned / NULLIF(p.heap_blks_total, 0), 1) AS scanned_pct,
       p.index_vacuum_count,
       a.wait_event_type,
       a.wait_event,
       left(a.query, 100) AS query
FROM pg_stat_activity a
LEFT JOIN pg_stat_progress_vacuum p ON p.pid = a.pid
WHERE a.backend_type = 'autovacuum worker'
ORDER BY a.xact_start;
-- query içinde "(to prevent wraparound)" görülüyorsa bu agresif / zorunlu
-- bir wraparound vacuum'udur; iptal edilmemeli.

\echo '--- 8.7 Toplam vacuum / analyze sayıları (bu veritabanı) ---'
SELECT sum(vacuum_count)      AS manual_vacuum,
       sum(autovacuum_count)  AS autovacuum,
       sum(analyze_count)     AS manual_analyze,
       sum(autoanalyze_count) AS autoanalyze
FROM pg_stat_user_tables;
