-- =====================================================================
-- 03_connections_activity.sql
-- Bağlantılar ve oturum aktivitesi
--   * max_connections kullanımı, duruma / kullanıcıya / uygulamaya göre dağılım
--   * uzun süren sorgular, idle in transaction oturumları
--   * en eski transaction'lar ve vacuum'u engelleyen backend_xmin sahipleri
--   * bekleme olayları (wait event) anlık görüntüsü
-- Çalıştırma: psql -X -d postgres -f 03_connections_activity.sql
-- Uzun sorgu eşiği: psql -v long_query='5 minutes' ... (varsayılan 3 dk)
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'
\if :{?long_query}
\else
  \set long_query '3 minutes'
\endif

\echo '--- 3.1 Bağlantı kullanımı ---'
SELECT count(*) FILTER (WHERE backend_type = 'client backend')         AS client_conns,
       count(*)                                                        AS all_backends,
       current_setting('max_connections')::int                        AS max_connections,
       current_setting('superuser_reserved_connections')::int         AS su_reserved,
       round(100.0 * count(*) FILTER (WHERE backend_type = 'client backend')
             / current_setting('max_connections')::int, 1)            AS usage_pct
FROM pg_stat_activity;

\echo '--- 3.2 Duruma göre dağılım ---'
SELECT coalesce(state, '<' || backend_type || '>') AS state, count(*)
FROM pg_stat_activity
GROUP BY 1
ORDER BY 2 DESC;

\echo '--- 3.3 Veritabanı / kullanıcı / uygulama / istemci bazında ---'
SELECT datname, usename, application_name, client_addr,
       count(*)                                         AS total,
       count(*) FILTER (WHERE state = 'active')         AS active,
       count(*) FILTER (WHERE state = 'idle')           AS idle,
       count(*) FILTER (WHERE state LIKE 'idle in%')    AS idle_in_tx,
       date_trunc('second', max(now() - backend_start)) AS oldest_conn_age
FROM pg_stat_activity
WHERE backend_type = 'client backend'
GROUP BY 1, 2, 3, 4
ORDER BY total DESC
LIMIT 30;

\echo '--- 3.4 Backend türleri (arka plan süreçleri dahil) ---'
SELECT backend_type, count(*)
FROM pg_stat_activity
GROUP BY 1
ORDER BY 2 DESC;

\echo '--- 3.5 Uzun süren aktif sorgular (eşik: ' :long_query ') ---'
SELECT pid,
       datname,
       usename,
       application_name,
       client_addr,
       query_start,
       date_trunc('second', now() - query_start) AS query_time,
       wait_event_type,
       wait_event,
       left(regexp_replace(query, '\s+', ' ', 'g'), 150) AS query
FROM pg_stat_activity
WHERE state = 'active'
  AND backend_type = 'client backend'
  AND pid <> pg_backend_pid()
  AND now() - query_start > :'long_query'::interval
ORDER BY query_start;

\echo '--- 3.6 idle in transaction oturumları ---'
-- state_change: transaction'ın boşta beklemeye başladığı an
-- xact_start  : transaction'ın başladığı an
SELECT pid,
       datname,
       usename,
       application_name,
       client_addr,
       state,
       date_trunc('second', now() - xact_start)   AS xact_duration,
       date_trunc('second', now() - state_change) AS idle_duration,
       left(regexp_replace(query, '\s+', ' ', 'g'), 120) AS last_query
FROM pg_stat_activity
WHERE state IN ('idle in transaction', 'idle in transaction (aborted)')
ORDER BY xact_start NULLS LAST;

\echo '--- 3.7 En eski 15 açık transaction ---'
SELECT pid, datname, usename, application_name, state,
       date_trunc('second', now() - xact_start) AS xact_age,
       backend_xid,
       backend_xmin,
       age(backend_xmin) AS xmin_age,
       left(regexp_replace(query, '\s+', ' ', 'g'), 100) AS query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
  AND pid <> pg_backend_pid()
ORDER BY xact_start
LIMIT 15;

\echo '--- 3.8 Bekleme olayları (anlık) ---'
SELECT wait_event_type, wait_event, count(*)
FROM pg_stat_activity
WHERE state = 'active' AND wait_event IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;

\echo '--- 3.9 Çalışan bakım işlemleri (progress) ---'
SELECT 'vacuum' AS op, p.pid, p.datname, p.relid::regclass::text AS rel, p.phase,
       round(100.0 * p.heap_blks_scanned / NULLIF(p.heap_blks_total, 0), 1) AS pct,
       date_trunc('second', now() - a.query_start) AS running
FROM pg_stat_progress_vacuum p JOIN pg_stat_activity a USING (pid)
UNION ALL
SELECT 'create index', p.pid, p.datname, p.relid::regclass::text, p.phase,
       round(100.0 * p.blocks_done / NULLIF(p.blocks_total, 0), 1),
       date_trunc('second', now() - a.query_start)
FROM pg_stat_progress_create_index p JOIN pg_stat_activity a USING (pid)
UNION ALL
SELECT 'analyze', p.pid, p.datname, p.relid::regclass::text, p.phase,
       round(100.0 * p.sample_blks_scanned / NULLIF(p.sample_blks_total, 0), 1),
       date_trunc('second', now() - a.query_start)
FROM pg_stat_progress_analyze p JOIN pg_stat_activity a USING (pid)
UNION ALL
SELECT 'cluster/vacuum full', p.pid, p.datname, p.relid::regclass::text, p.phase,
       round(100.0 * p.heap_blks_scanned / NULLIF(p.heap_blks_total, 0), 1),
       date_trunc('second', now() - a.query_start)
FROM pg_stat_progress_cluster p JOIN pg_stat_activity a USING (pid)
UNION ALL
SELECT 'basebackup', p.pid, NULL, NULL, p.phase,
       round(100.0 * p.backup_streamed / NULLIF(p.backup_total, 0), 1),
       date_trunc('second', now() - a.backend_start)
FROM pg_stat_progress_basebackup p JOIN pg_stat_activity a USING (pid);

-- ---------------------------------------------------------------------
-- Müdahale (gerekirse, elle):
--   SELECT pg_cancel_backend(<pid>);     -- yalnızca sorguyu iptal eder
--   SELECT pg_terminate_backend(<pid>);  -- bağlantıyı tamamen keser
-- Belirli süredir idle-in-transaction olanları toplu kesmek:
--   SELECT pg_terminate_backend(pid) FROM pg_stat_activity
--   WHERE state = 'idle in transaction' AND now() - state_change > interval '30 minutes';
-- ---------------------------------------------------------------------
