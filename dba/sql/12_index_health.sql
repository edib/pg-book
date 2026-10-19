-- =====================================================================
-- 12_index_health.sql
-- İndeks sağlığı (bağlanılan veritabanı için)
--   * kullanılmayan indeksler (istatistik sıfırlama tarihiyle birlikte)
--   * mükerrer (duplicate) indeksler
--   * geçersiz (INVALID) indeksler — başarısız CREATE INDEX CONCURRENTLY
--   * indeksi olmayan foreign key'ler
--   * çok seyrek kullanılan büyük indeksler
-- ÖNEMLİ: idx_scan sayaçları her node'a özeldir. Replikalarda okuma
-- yapılıyorsa bir indeks primary'de "kullanılmıyor" görünse de standby'da
-- kullanılıyor olabilir. Silmeden önce TÜM node'larda kontrol edin.
-- Çalıştırma: psql -X -d <db> -f 12_index_health.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\echo '--- 12.1 İstatistik toplama süresi (kullanılmayan indeks yorumu için) ---'
SELECT datname,
       stats_reset,
       date_trunc('day', now() - coalesce(stats_reset, pg_postmaster_start_time())) AS stats_window
FROM pg_stat_database
WHERE datname = current_database();
-- stats_window birkaç günse "kullanılmıyor" sonucu güvenilir değildir;
-- ay sonu / yıl sonu raporları gibi seyrek iş yüklerini kapsayacak süre bekleyin.

\echo '--- 12.2 Hiç kullanılmamış indeksler ---'
SELECT s.schemaname,
       s.relname                                        AS tablename,
       s.indexrelname                                   AS indexname,
       pg_size_pretty(pg_relation_size(s.indexrelid))   AS index_size,
       s.idx_scan,
       pg_get_indexdef(s.indexrelid)                    AS definition
FROM pg_catalog.pg_stat_user_indexes s
JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan = 0                -- hiç taranmamış
  AND 0 <> ALL (i.indkey)           -- ifade (expression) indeksi değil
  AND NOT i.indisunique             -- UNIQUE değil
  AND NOT EXISTS                    -- bir constraint'i desteklemiyor
        (SELECT 1 FROM pg_catalog.pg_constraint c WHERE c.conindid = s.indexrelid)
  AND NOT EXISTS                    -- partition indeksi değil
        (SELECT 1 FROM pg_catalog.pg_inherits inh WHERE inh.inhrelid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;
-- Güvenli kaldırma:  DROP INDEX CONCURRENTLY schema.indeks;
-- (Önce tanımı yukarıdaki definition kolonundan saklayın.)

\echo '--- 12.3 Az kullanılan büyük indeksler (>100 MB, < 50 tarama) ---'
SELECT s.schemaname, s.relname, s.indexrelname,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan,
       t.seq_scan + coalesce(t.idx_scan, 0) AS table_total_scans
FROM pg_stat_user_indexes s
JOIN pg_stat_user_tables t ON t.relid = s.relid
JOIN pg_index i ON i.indexrelid = s.indexrelid
WHERE pg_relation_size(s.indexrelid) > 100 * 1024 * 1024
  AND s.idx_scan < 50
  AND NOT i.indisunique
ORDER BY pg_relation_size(s.indexrelid) DESC;

\echo '--- 12.4 Mükerrer indeksler (aynı tablo, kolon, operatör sınıfı, ifade, koşul) ---'
SELECT indrelid::regclass                                      AS table_name,
       pg_size_pretty(sum(pg_relation_size(indexrelid)))       AS total_size,
       array_agg(indexrelid::regclass ORDER BY indexrelid)     AS duplicate_indexes
FROM pg_index
GROUP BY indrelid, indkey::text, indclass::text, indcollation::text,
         coalesce(indexprs::text, ''), coalesce(indpred::text, '')
HAVING count(*) > 1
ORDER BY sum(pg_relation_size(indexrelid)) DESC;
-- Biri constraint (PK/UNIQUE) destekliyorsa onu tutun, diğerini kaldırın.

\echo '--- 12.5 Önek (prefix) olarak örtüşen indeksler — biri diğerini kapsıyor ---'
-- Örn: (a) ve (a, b) indeksleri; (a) çoğu durumda gereksizdir.
SELECT a.indrelid::regclass                         AS table_name,
       a.indexrelid::regclass                       AS redundant_index,
       pg_size_pretty(pg_relation_size(a.indexrelid)) AS redundant_size,
       b.indexrelid::regclass                       AS covered_by
FROM pg_index a
JOIN pg_index b ON a.indrelid = b.indrelid
               AND a.indexrelid <> b.indexrelid
               AND a.indnatts < b.indnatts
               AND (b.indkey::int2[])[0:a.indnatts - 1] = (a.indkey::int2[])[0:a.indnatts - 1]
WHERE NOT a.indisunique AND NOT a.indisprimary
  AND a.indpred IS NULL AND b.indpred IS NULL
  AND a.indexprs IS NULL AND b.indexprs IS NULL
  AND (SELECT amname FROM pg_class c JOIN pg_am m ON m.oid = c.relam WHERE c.oid = a.indexrelid) = 'btree'
  AND (SELECT amname FROM pg_class c JOIN pg_am m ON m.oid = c.relam WHERE c.oid = b.indexrelid) = 'btree'
  AND a.indrelid NOT IN (SELECT oid FROM pg_class WHERE relnamespace = 'pg_catalog'::regnamespace)
ORDER BY pg_relation_size(a.indexrelid) DESC;

\echo '--- 12.6 Geçersiz (INVALID) indeksler ---'
-- Genelde başarısız CREATE/REINDEX CONCURRENTLY sonucu oluşur. Yazma
-- maliyeti vardır ama sorgularda kullanılmaz.
SELECT n.nspname, c.relname AS index_name, t.relname AS table_name,
       pg_size_pretty(pg_relation_size(c.oid)) AS size,
       i.indisvalid, i.indisready, i.indislive
FROM pg_index i
JOIN pg_class c     ON c.oid = i.indexrelid
JOIN pg_class t     ON t.oid = i.indrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT i.indisvalid OR NOT i.indisready OR NOT i.indislive;
-- Giderme: REINDEX INDEX CONCURRENTLY <indeks>;  veya
--          DROP INDEX CONCURRENTLY <indeks>; ardından yeniden oluşturma

\echo '--- 12.7 İndeksi olmayan foreign key''ler ---'
-- Parent tablodan DELETE/UPDATE yapıldığında child tabloda seq scan ve
-- uzun kilitlere neden olur.
SELECT c.conrelid::regclass                          AS child_table,
       c.conname                                     AS fk_name,
       c.confrelid::regclass                         AS parent_table,
       (SELECT string_agg(a.attname, ', ' ORDER BY x.n)
        FROM unnest(c.conkey) WITH ORDINALITY x(attnum, n)
        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = x.attnum) AS fk_columns,
       pg_size_pretty(pg_relation_size(c.conrelid))  AS child_size,
       'CREATE INDEX CONCURRENTLY ON ' || c.conrelid::regclass || ' ('
         || (SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY x.n)
             FROM unnest(c.conkey) WITH ORDINALITY x(attnum, n)
             JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = x.attnum)
         || ');'                                     AS suggested_ddl
FROM pg_constraint c
WHERE c.contype = 'f'
  AND NOT EXISTS (
        SELECT 1 FROM pg_index i
        WHERE i.indrelid = c.conrelid
          AND (i.indkey::int2[])[0:cardinality(c.conkey) - 1] @> c.conkey
          AND (i.indkey::int2[])[0:cardinality(c.conkey) - 1] <@ c.conkey)
ORDER BY pg_relation_size(c.conrelid) DESC;

\echo '--- 12.8 Tablo başına indeks sayısı (10+ indeksli tablolar) ---'
SELECT schemaname, relname, count(*) AS index_count,
       pg_size_pretty(sum(pg_relation_size(indexrelid))) AS total_index_size
FROM pg_stat_user_indexes
GROUP BY 1, 2
HAVING count(*) >= 10
ORDER BY 3 DESC;
