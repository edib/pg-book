-- =====================================================================
-- 07_sizes.sql
-- Depolama: tablespace, veritabanı, şema, tablo, indeks ve TOAST boyutları
-- Tablespace/veritabanı bölümleri küme geneli; diğerleri bağlanılan
-- veritabanına aittir.
-- Çalıştırma: psql -X -d <db> -f 07_sizes.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\echo '--- 7.1 Tablespace boyutları ---'
SELECT spcname,
       pg_tablespace_location(oid)             AS location,
       pg_size_pretty(pg_tablespace_size(oid)) AS size
FROM pg_tablespace
ORDER BY pg_tablespace_size(oid) DESC;

\echo '--- 7.2 Veritabanı boyutları ---'
SELECT datname,
       pg_size_pretty(pg_database_size(oid)) AS db_size,
       datconnlimit,
       datallowconn,
       pg_encoding_to_char(encoding)         AS encoding,
       datcollate
FROM pg_database
ORDER BY pg_database_size(oid) DESC;

\echo '--- 7.3 Şema boyutları (bu veritabanı) ---'
SELECT n.nspname                                  AS schema,
       count(*) FILTER (WHERE c.relkind IN ('r','p')) AS tables,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))
                      FILTER (WHERE c.relkind IN ('r','m'))) AS total_size
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname NOT LIKE 'pg_toast%'
GROUP BY 1
ORDER BY sum(pg_total_relation_size(c.oid)) FILTER (WHERE c.relkind IN ('r','m')) DESC NULLS LAST;

\echo '--- 7.4 En büyük 20 tablo (tablo + indeks + TOAST) ---'
SELECT n.nspname                                   AS schemaname,
       c.relname                                   AS tablename,
       c.reltuples::bigint                         AS est_rows,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
       pg_size_pretty(pg_relation_size(c.oid))     AS table_size,
       pg_size_pretty(pg_indexes_size(c.oid))      AS index_size,
       pg_size_pretty(coalesce(pg_total_relation_size(c.reltoastrelid), 0)) AS toast_size,
       round(pg_indexes_size(c.oid)::numeric
             / NULLIF(pg_total_relation_size(c.oid), 0) * 100, 1)          AS index_pct
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND c.relkind IN ('r', 'm')
ORDER BY pg_total_relation_size(c.oid) DESC
LIMIT 20;

\echo '--- 7.5 Partitioned tablolar (tüm partition toplamı) ---'
SELECT p.oid::regclass                                       AS parent,
       count(*)                                              AS partitions,
       pg_size_pretty(sum(pg_total_relation_size(t.relid)))  AS total_size
FROM pg_class p
CROSS JOIN LATERAL pg_partition_tree(p.oid) t
WHERE p.relkind = 'p' AND NOT p.relispartition AND t.isleaf
GROUP BY p.oid
ORDER BY sum(pg_total_relation_size(t.relid)) DESC;

\echo '--- 7.6 En büyük 20 indeks ---'
SELECT s.schemaname, s.relname AS tablename, s.indexrelname AS indexname,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan
FROM pg_stat_user_indexes s
ORDER BY pg_relation_size(s.indexrelid) DESC
LIMIT 20;

\echo '--- 7.7 Tablodan büyük indeks setine sahip tablolar ---'
-- Aşırı indeksleme veya indeks bloat'ı işareti olabilir
SELECT schemaname, relname,
       pg_size_pretty(pg_relation_size(relid)) AS table_size,
       pg_size_pretty(pg_indexes_size(relid))  AS index_size,
       round(pg_indexes_size(relid)::numeric / NULLIF(pg_relation_size(relid), 0), 1) AS index_to_table
FROM pg_stat_user_tables
WHERE pg_relation_size(relid) > 100 * 1024 * 1024
  AND pg_indexes_size(relid) > pg_relation_size(relid)
ORDER BY pg_indexes_size(relid) DESC;
