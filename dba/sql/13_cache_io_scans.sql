-- =====================================================================
-- 13_cache_io_scans.sql
-- Önbellek (cache hit), I/O ve tarama (seq/index scan) davranışı
--   * veritabanı / tablo / indeks bazında cache hit oranı
--   * pg_stat_io (PG16+) — backend türüne göre okuma/yazma
--   * seq scan baskın tablolar (eksik indeks adayları)
--   * belirli tablolar için tarama durumu (-v tables=...)
-- Not: "hit" PostgreSQL shared_buffers isabetidir. Diskten okunan ("read")
-- blokların bir kısmı OS page cache'ten gelir; yani gerçek disk I/O
-- daha düşük olabilir. OLAP / büyük taramalı iş yüklerinde %99 beklenmez.
-- Çalıştırma: psql -X -d <db> -v tables='orders,customers' -f 13_cache_io_scans.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'
\if :{?tables}
\else
  \set tables ''
\endif
SELECT current_setting('server_version_num')::int >= 160000 AS pg16,
       EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_buffercache') AS has_buffercache \gset

\echo '--- 13.1 Veritabanı bazında cache hit oranı ---'
SELECT datname,
       blks_read,
       blks_hit,
       round(blks_hit::numeric / NULLIF(blks_hit + blks_read, 0) * 100, 2) AS hit_pct,
       round(blk_read_time::numeric / 1000, 1)  AS read_time_sec,   -- track_io_timing=on gerekir
       round(blk_write_time::numeric / 1000, 1) AS write_time_sec
FROM pg_stat_database
WHERE datname IS NOT NULL AND datname NOT IN ('template0', 'template1')
ORDER BY blks_read DESC;

\echo '--- 13.2 En çok diskten okunan 15 tablo (heap) ---'
SELECT schemaname,
       relname                                                      AS tablename,
       heap_blks_read,
       heap_blks_hit,
       round(heap_blks_hit::numeric / NULLIF(heap_blks_hit + heap_blks_read, 0) * 100, 2) AS hit_pct,
       pg_size_pretty(heap_blks_read * current_setting('block_size')::bigint) AS disk_read_volume,
       pg_size_pretty(pg_relation_size(relid))                      AS table_size
FROM pg_statio_user_tables
WHERE heap_blks_read + heap_blks_hit > 0
ORDER BY heap_blks_read DESC
LIMIT 15;

\echo '--- 13.3 En çok diskten okunan 15 indeks ---'
SELECT schemaname, relname AS tablename, indexrelname AS indexname,
       idx_blks_read, idx_blks_hit,
       round(idx_blks_hit::numeric / NULLIF(idx_blks_hit + idx_blks_read, 0) * 100, 2) AS hit_pct
FROM pg_statio_user_indexes
WHERE idx_blks_read + idx_blks_hit > 0
ORDER BY idx_blks_read DESC
LIMIT 15;

\echo '--- 13.4 Seq scan baskın tablolar (5.000+ satır, en çok seq scan) ---'
SELECT schemaname,
       relname,
       n_live_tup,
       pg_size_pretty(pg_relation_size(relid)) AS table_size,
       seq_scan,
       seq_tup_read,
       idx_scan,
       round(seq_tup_read::numeric / NULLIF(seq_scan, 0)) AS avg_rows_per_seq_scan,
       CASE WHEN coalesce(idx_scan, 0) = 0 THEN 'Hiç index scan yok!'
            WHEN seq_scan > idx_scan       THEN 'Seq scan baskın'
            ELSE 'Index scan baskın (normal)'
       END AS durum
FROM pg_stat_user_tables
WHERE n_live_tup > 5000
ORDER BY seq_tup_read DESC
LIMIT 20;
-- avg_rows_per_seq_scan büyük ve seq_scan sayısı yüksekse eksik indeks
-- adayıdır; pg_stat_statements (14_top_queries.sql) ile sorguyu bulun.

\if :{?tables}
SELECT :'tables' <> '' AS has_tables \gset
\if :has_tables
\echo '--- 13.5 Seçilen tablolar için tarama durumu ---'
SELECT schemaname,
       relname AS tablename,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       pg_size_pretty(pg_relation_size(relid))       AS table_size,
       pg_size_pretty(pg_indexes_size(relid))        AS index_size,
       seq_scan,
       seq_tup_read,
       idx_scan,
       idx_tup_fetch,
       n_tup_ins, n_tup_upd, n_tup_hot_upd, n_tup_del
FROM pg_stat_user_tables
WHERE relname = ANY (string_to_array(replace(:'tables', ' ', ''), ','))
ORDER BY pg_total_relation_size(relid) DESC;
\endif
\endif

\echo '--- 13.6 HOT update oranı (yüksek UPDATE alan tablolar) ---'
-- Düşük HOT oranı: güncellenen kolonlarda indeks var veya sayfada boş yer yok
-- (fillfactor düşürülmesi değerlendirilebilir).
SELECT schemaname, relname, n_tup_upd, n_tup_hot_upd,
       round(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd, 0), 1) AS hot_pct,
       (SELECT split_part(o, '=', 2) FROM pg_class c, unnest(c.reloptions) o
        WHERE c.oid = relid AND o LIKE 'fillfactor=%') AS fillfactor
FROM pg_stat_user_tables
WHERE n_tup_upd > 10000
ORDER BY n_tup_upd DESC
LIMIT 15;

\if :pg16
\echo '--- 13.7 pg_stat_io: backend türü ve nesneye göre I/O (PG16+) ---'
SELECT backend_type, object, context,
       reads, writes, extends, hits, evictions, reuses, fsyncs,
       round(100.0 * hits / NULLIF(hits + reads, 0), 2) AS hit_pct
FROM pg_stat_io
WHERE coalesce(reads, 0) + coalesce(writes, 0) + coalesce(hits, 0) > 0
ORDER BY coalesce(reads, 0) + coalesce(writes, 0) DESC
LIMIT 25;
-- "client backend" satırında writes yüksekse backend'ler kirli sayfa yazmak
-- zorunda kalıyor (bgwriter/checkpointer yetişemiyor).
\endif

\if :has_buffercache
\echo '--- 13.8 shared_buffers içeriği (pg_buffercache, ilk 15 nesne) ---'
SELECT c.relname,
       count(*)                                                         AS buffers,
       pg_size_pretty(count(*) * current_setting('block_size')::bigint) AS buffered,
       round(100.0 * count(*) / (SELECT setting::int FROM pg_settings WHERE name = 'shared_buffers'), 1)
                                                                        AS pct_of_shared_buffers,
       round(100.0 * count(*) FILTER (WHERE b.isdirty) / count(*), 1)   AS dirty_pct
FROM pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
WHERE b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database())
GROUP BY c.relname
ORDER BY 2 DESC
LIMIT 15;
\endif
