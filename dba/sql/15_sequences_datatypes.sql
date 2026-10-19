-- =====================================================================
-- 15_sequences_datatypes.sql
-- Sequence tükenme riski ve veri tipi taşma riskleri
--   * sequence doluluk oranı (kendi max_value'su VE bağlı kolon tipi)
--     Tuzak: bigint sequence -> int4 (integer) kolon. Sequence 2,1 milyarı
--     aştığında INSERT'ler "integer out of range" hatası verir.
--   * integer PK kolonlarının mevcut maksimum değeri
-- Çalıştırma: psql -X -d <db> -f 15_sequences_datatypes.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\echo '--- 15.1 Sequence doluluk oranı (ilk 30) ---'
WITH seq AS (
  SELECT s.schemaname,
         s.sequencename,
         s.data_type::text                               AS seq_type,
         s.last_value,
         s.max_value,
         s.increment_by,
         s.cycle,
         col.attrelid::regclass                          AS owned_by_table,
         col.attname                                     AS owned_by_column,
         format_type(col.atttypid, col.atttypmod)        AS column_type,
         LEAST(s.max_value,
               CASE col.atttypid
                 WHEN 'int2'::regtype THEN 32767
                 WHEN 'int4'::regtype THEN 2147483647
                 ELSE s.max_value END)                   AS effective_max
  FROM pg_sequences s
  JOIN pg_namespace sn ON sn.nspname = s.schemaname
  JOIN pg_class sc     ON sc.relname = s.sequencename AND sc.relnamespace = sn.oid
  LEFT JOIN pg_depend d ON d.objid = sc.oid AND d.classid = 'pg_class'::regclass
                       AND d.refclassid = 'pg_class'::regclass AND d.deptype IN ('a', 'i')
  LEFT JOIN pg_attribute col ON col.attrelid = d.refobjid AND col.attnum = d.refobjsubid
  WHERE s.increment_by > 0
)
SELECT schemaname || '.' || sequencename                AS sequence,
       seq_type,
       owned_by_table,
       owned_by_column,
       column_type,
       last_value,
       effective_max,
       round(100.0 * coalesce(last_value, 0) / effective_max, 2) AS used_pct,
       effective_max - coalesce(last_value, 0)          AS remaining,
       cycle,
       CASE WHEN seq_type = 'bigint' AND column_type = 'integer'
            THEN 'DİKKAT: bigint sequence -> integer kolon' END   AS note
FROM seq
ORDER BY coalesce(last_value, 0)::numeric / effective_max DESC
LIMIT 30;
-- Not: last_value NULL ise sequence hiç kullanılmamıştır.
-- Önlem: kolonu bigint'e çevirmek (ALTER TABLE ... TYPE bigint tabloyu yeniden
-- yazar; büyük tablolarda yeni kolon + tetikleyici/backfill ile çevrimiçi yapılır).

\echo '--- 15.2 integer / smallint tipli PK kolonları ve tablo boyutu ---'
SELECT c.conrelid::regclass                          AS table_name,
       a.attname                                     AS pk_column,
       format_type(a.atttypid, a.atttypmod)          AS type,
       pg_size_pretty(pg_relation_size(c.conrelid))  AS table_size,
       (SELECT reltuples::bigint FROM pg_class WHERE oid = c.conrelid) AS est_rows
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
WHERE c.contype = 'p'
  AND cardinality(c.conkey) = 1
  AND a.atttypid IN ('int2'::regtype, 'int4'::regtype)
  AND c.connamespace NOT IN ('pg_catalog'::regnamespace, 'information_schema'::regnamespace)
ORDER BY pg_relation_size(c.conrelid) DESC
LIMIT 20;
-- Büyük ve hızlı büyüyen tablolarda int4 PK ileride taşma riski taşır;
-- gerçek max değeri görmek için: SELECT max(<pk>) FROM <tablo>;
