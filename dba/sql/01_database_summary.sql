-- =====================================================================
-- 01_database_summary.sql
-- VERİTABANI düzeyinde ÖZET sağlık kontrolü. Tablo/indeks/sequence
-- istatistikleri veritabanına özeldir; bu dosya HER veritabanında
-- ayrı ayrı çalıştırılmalıdır (pg_healthcheck.sh bunu otomatik yapar).
--
-- Çalıştırma : psql -X -d <veritabani> -f 01_database_summary.sql
-- Yetki      : superuser veya pg_monitor (+ katalog okuma)
-- Uyumluluk  : PostgreSQL 13 – 18
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\if :{?dead_warn}
\else
  \set dead_warn 20
\endif
\if :{?dead_crit}
\else
  \set dead_crit 50
\endif
\if :{?seq_warn}
\else
  \set seq_warn 75
\endif
\if :{?seq_crit}
\else
  \set seq_crit 90
\endif
\if :{?xid_warn}
\else
  \set xid_warn 500000000
\endif
\if :{?xid_crit}
\else
  \set xid_crit 1000000000
\endif

SELECT current_database() AS dbname \gset
\echo ''
\echo '================ VERİTABANI ÖZETİ:' :dbname '================'

WITH
tbl AS (
  SELECT s.*, c.reltuples
  FROM pg_stat_user_tables s
  JOIN pg_class c ON c.oid = s.relid
),
-- 10.000+ satırlı tablolarda en yüksek ölü satır oranı
dead AS (
  SELECT schemaname || '.' || relname AS t,
         round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS ratio
  FROM tbl
  WHERE n_live_tup + n_dead_tup >= 10000
  ORDER BY 2 DESC NULLS LAST
  LIMIT 1
),
xid AS (
  SELECT n.nspname || '.' || c.relname AS t, age(c.relfrozenxid) AS a
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind IN ('r', 'm', 't')
  ORDER BY 2 DESC
  LIMIT 1
),
-- sequence doluluk oranı (sequence'ın kendi max değerine ve
-- bağlı olduğu kolonun tipine göre; int4 kolona bağlı bigint sequence tuzağı)
seqs AS (
  SELECT s.schemaname || '.' || s.sequencename AS seq,
         round(100.0 * coalesce(s.last_value, s.start_value)::numeric /
               LEAST(s.max_value,
                     CASE col.atttypid
                       WHEN 'int2'::regtype THEN 32767
                       WHEN 'int4'::regtype THEN 2147483647
                       ELSE s.max_value END), 2) AS pct
  FROM pg_sequences s
  JOIN pg_namespace sn      ON sn.nspname = s.schemaname
  JOIN pg_class sc          ON sc.relname = s.sequencename AND sc.relnamespace = sn.oid
  LEFT JOIN pg_depend d    ON d.objid = sc.oid AND d.classid = 'pg_class'::regclass
                           AND d.refclassid = 'pg_class'::regclass AND d.deptype IN ('a', 'i')
  LEFT JOIN pg_attribute col ON col.attrelid = d.refobjid AND col.attnum = d.refobjsubid
  WHERE s.increment_by > 0
  ORDER BY 2 DESC NULLS LAST
  LIMIT 1
),
fk_noidx AS (
  SELECT count(*) AS n
  FROM pg_constraint c
  WHERE c.contype = 'f'
    AND NOT EXISTS (
      SELECT 1 FROM pg_index i
      WHERE i.indrelid = c.conrelid
        AND (i.indkey::int2[])[0:cardinality(c.conkey) - 1] @> c.conkey
        AND (i.indkey::int2[])[0:cardinality(c.conkey) - 1] <@ c.conkey)
),
dup_idx AS (
  SELECT count(*) AS n FROM (
    SELECT indrelid, indkey::text, indclass::text, coalesce(indexprs::text, ''), coalesce(indpred::text, '')
    FROM pg_index
    GROUP BY 1, 2, 3, 4, 5
    HAVING count(*) > 1) x
),
unused AS (
  SELECT count(*) AS n, coalesce(sum(pg_relation_size(s.indexrelid)), 0) AS bytes
  FROM pg_stat_user_indexes s
  JOIN pg_index i ON i.indexrelid = s.indexrelid
  WHERE s.idx_scan = 0 AND NOT i.indisunique AND NOT i.indisprimary
    AND NOT EXISTS (SELECT 1 FROM pg_constraint c WHERE c.conindid = s.indexrelid)
),
checks (sira, kontrol, n, gosterim, uyari, kritik, yon) AS (
  SELECT 1, 'Veritabanı boyutu', NULL::numeric,
         pg_size_pretty(pg_database_size(current_database())), NULL::numeric, NULL::numeric, 'info'
  UNION ALL
  SELECT 2, 'Kullanıcı tablo sayısı', count(*), count(*)::text, NULL, NULL, 'info' FROM tbl
  UNION ALL
  SELECT 3, 'En yüksek ölü satır oranı (%) [10k+ satır]',
         (SELECT ratio FROM dead),
         coalesce((SELECT ratio || '%  ' || t FROM dead), '-'),
         :dead_warn, :dead_crit, 'gt'
  UNION ALL
  SELECT 4, 'Ölü satır oranı > %20 olan tablo sayısı', count(*), count(*)::text, 1, NULL, 'gt'
  FROM tbl
  WHERE n_live_tup + n_dead_tup >= 10000
    AND n_dead_tup > 0.2 * (n_live_tup + n_dead_tup)
  UNION ALL
  SELECT 5, 'Hiç analyze edilmemiş dolu tablo', count(*), count(*)::text, 1, NULL, 'gt'
  FROM tbl
  WHERE n_live_tup > 0 AND last_analyze IS NULL AND last_autoanalyze IS NULL
  UNION ALL
  SELECT 6, 'En yüksek tablo XID yaşı',
         (SELECT a FROM xid),
         (SELECT to_char(a, 'FM999G999G999G999') || '  ' || t FROM xid),
         :xid_warn, :xid_crit, 'gt'
  UNION ALL
  SELECT 7, 'Geçersiz (INVALID) indeks', count(*), count(*)::text, NULL, 1, 'gt'
  FROM pg_index WHERE NOT indisvalid
  UNION ALL
  SELECT 8, 'Mükerrer (duplicate) indeks grubu', n, n::text, 1, NULL, 'gt' FROM dup_idx
  UNION ALL
  SELECT 9, 'Hiç kullanılmamış indeks (sayı / boyut)', n,
         n || ' adet / ' || pg_size_pretty(bytes), NULL, NULL, 'info' FROM unused
  UNION ALL
  SELECT 10, 'İndeksi olmayan foreign key', n, n::text, 1, NULL, 'gt' FROM fk_noidx
  UNION ALL
  SELECT 11, 'Primary key''i olmayan tablo', count(*), count(*)::text, NULL, NULL, 'info'
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind IN ('r', 'p') AND NOT c.relispartition
    AND n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg_toast%'
    AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'p')
  UNION ALL
  SELECT 12, 'En dolu sequence (%)',
         (SELECT pct FROM seqs),
         coalesce((SELECT pct || '%  ' || seq FROM seqs), 'sequence yok'),
         :seq_warn, :seq_crit, 'gt'
  UNION ALL
  SELECT 13, 'pg_stat_statements kurulu mu', NULL,
         CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')
              THEN 'evet' ELSE 'hayır' END, NULL, NULL, 'info'
)
SELECT current_database()          AS "DB",
       kontrol                     AS "Kontrol",
       gosterim                    AS "Değer",
       coalesce(uyari::text, '-')  AS "Uyarı",
       coalesce(kritik::text, '-') AS "Kritik",
       CASE
         WHEN yon = 'info'                         THEN 'INFO'
         WHEN n IS NULL                            THEN 'N/A'
         WHEN yon = 'gt' AND kritik IS NOT NULL AND n >= kritik THEN 'CRIT'
         WHEN yon = 'gt' AND uyari  IS NOT NULL AND n >= uyari  THEN 'WARN'
         ELSE 'OK'
       END                         AS "Durum"
FROM checks
ORDER BY sira;
