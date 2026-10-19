-- =====================================================================
-- 14_top_queries.sql
-- Sorgu performansı — pg_stat_statements
--   * toplam süreye, ortalama süreye, çağrı sayısına göre en ağır sorgular
--   * en çok disk okuyan, en çok temp dosya yazan, en çok WAL üreten sorgular
-- Ön koşul:
--   shared_preload_libraries = 'pg_stat_statements'  (restart gerekir)
--   CREATE EXTENSION pg_stat_statements;              (ilgili veritabanında)
--   track_io_timing = on  -> blk_read_time / shared_blk_read_time dolar
-- Not: pg_stat_statements küme genelidir; sorgular tüm veritabanlarından gelir.
-- Sıfırlama: SELECT pg_stat_statements_reset();
-- Çalıştırma: psql -X -d <eklentinin kurulu olduğu db> -f 14_top_queries.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'
\if :{?top}
\else
  \set top 15
\endif

SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') AS has_pss,
       current_setting('server_version_num')::int >= 140000 AS pg14 \gset

\if :has_pss

\if :pg14
\echo '--- 14.0 pg_stat_statements durumu ---'
SELECT dealloc, stats_reset,
       current_setting('pg_stat_statements.max') AS pss_max,
       (SELECT count(*) FROM pg_stat_statements) AS tracked
FROM pg_stat_statements_info;
-- dealloc sürekli artıyorsa pg_stat_statements.max yetersiz; nadir
-- sorgular istatistikten düşüyor (öneri: 10000+).
\endif

\echo '--- 14.1 Toplam çalışma süresine göre ilk' :top 'sorgu ---'
SELECT round(total_exec_time::numeric / 1000, 1)                          AS total_sec,
       round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 1) AS pct_total,
       calls,
       round(mean_exec_time::numeric, 2)                                  AS mean_ms,
       round(stddev_exec_time::numeric, 2)                                AS stddev_ms,
       rows,
       round(100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0), 1) AS hit_pct,
       d.datname,
       r.rolname,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140)                 AS query
FROM pg_stat_statements s
LEFT JOIN pg_database d ON d.oid = s.dbid
LEFT JOIN pg_roles r    ON r.oid = s.userid
ORDER BY total_exec_time DESC
LIMIT :top;

\echo '--- 14.2 Ortalama süreye göre en yavaş sorgular (en az 10 çağrı) ---'
SELECT round(mean_exec_time::numeric, 1) AS mean_ms,
       round(max_exec_time::numeric, 1)  AS max_ms,
       calls,
       round(total_exec_time::numeric / 1000, 1) AS total_sec,
       round(rows::numeric / NULLIF(calls, 0), 1) AS rows_per_call,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS query
FROM pg_stat_statements
WHERE calls >= 10
ORDER BY mean_exec_time DESC
LIMIT :top;

\echo '--- 14.3 En sık çağrılan sorgular ---'
SELECT calls,
       round(mean_exec_time::numeric, 3) AS mean_ms,
       round(total_exec_time::numeric / 1000, 1) AS total_sec,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS query
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT :top;

\echo '--- 14.4 En çok diskten okuyan sorgular (shared_blks_read) ---'
SELECT shared_blks_read,
       pg_size_pretty(shared_blks_read * current_setting('block_size')::bigint) AS read_volume,
       round(100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0), 1) AS hit_pct,
       calls,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS query
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT :top;

\echo '--- 14.5 En çok temp dosya yazan sorgular (work_mem yetersizliği) ---'
SELECT pg_size_pretty(temp_blks_written * current_setting('block_size')::bigint) AS temp_written,
       calls,
       round(mean_exec_time::numeric, 1) AS mean_ms,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS query
FROM pg_stat_statements
WHERE temp_blks_written > 0
ORDER BY temp_blks_written DESC
LIMIT :top;

\echo '--- 14.6 En çok WAL üreten sorgular ---'
SELECT pg_size_pretty(wal_bytes::bigint) AS wal_bytes,
       wal_fpi,
       calls,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS query
FROM pg_stat_statements
ORDER BY wal_bytes DESC
LIMIT :top;

\echo '--- 14.7 Planlama süresi yüksek sorgular (pg_stat_statements.track_planning=on ise) ---'
SELECT round(mean_plan_time::numeric, 2) AS mean_plan_ms,
       round(mean_exec_time::numeric, 2) AS mean_exec_ms,
       plans,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS query
FROM pg_stat_statements
WHERE plans > 0
ORDER BY mean_plan_time DESC
LIMIT 10;

\else
\echo 'pg_stat_statements bu veritabanında kurulu değil.'
\echo 'Kurulum: shared_preload_libraries += pg_stat_statements (restart), ardından CREATE EXTENSION pg_stat_statements;'
\endif
