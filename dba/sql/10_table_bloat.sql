-- =====================================================================
-- 10_table_bloat.sql
-- Tablo bloat TAHMİNİ (istatistik tabanlı, pg_stats kullanır)
--   * Kaynak: ioguix/pgsql-bloat-estimation yaklaşımı
--   * Tabloyu okumaz, hızlıdır; ancak bir TAHMİNDİR.
--   * Doğruluk için tablonun güncel ANALYZE'ı olmalıdır.
--   * "Is N/A" = TRUE ise (name tipi kolon, eksik istatistik) sonuç güvenilmez.
--   * Varsayılan olarak bloat oranı %10'dan büyük tabloları listeler;
--     eşik: psql -v bloat_min=20 ...
-- Kesin ölçüm için (tabloyu tarar, büyük tablolarda yavaştır):
--   CREATE EXTENSION IF NOT EXISTS pgstattuple;
--   SELECT * FROM pgstattuple_approx('schema.tablo');   -- hızlı yaklaşık
--   SELECT * FROM pgstattuple('schema.tablo');          -- kesin, tam tarama
-- Çalıştırma: psql -X -d <db> -f 10_table_bloat.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'
\if :{?bloat_min}
\else
  \set bloat_min 10
\endif

\echo '--- 10.1 Tablo bloat tahmini (bloat oranı > %' :bloat_min ') ---'
with step1 as (
  select
    tbl.oid tblid,
    ns.nspname as schema_name,
    tbl.relname as table_name,
    tbl.reltuples,
    tbl.relpages as heappages,
    coalesce(toast.relpages, 0) as toastpages,
    coalesce(toast.reltuples, 0) as toasttuples,
    coalesce(substring(array_to_string(tbl.reloptions, ' ') from '%fillfactor=#"__#"%' for '#')::int2, 100) as fillfactor,
    current_setting('block_size')::numeric as bs,
    case when version() ~ 'mingw32|64-bit|x86_64|ppc64|ia64|amd64' then 8 else 4 end as ma, -- NS: TODO: check it
    24 as page_hdr,
    23 + case when max(coalesce(null_frac, 0)) > 0 then (7 + count(*)) / 8 else 0::int end
      + case when bool_or(att.attname = 'oid' and att.attnum < 0) then 4 else 0 end as tpl_hdr_size,
    sum((1 - coalesce(s.null_frac, 0)) * coalesce(s.avg_width, 1024)) as tpl_data_size,
    bool_or(att.atttypid = 'pg_catalog.name'::regtype)
      or sum(case when att.attnum > 0 then 1 else 0 end) <> count(s.attname) as is_na
  from pg_attribute as att
  join pg_class as tbl on att.attrelid = tbl.oid and tbl.relkind = 'r'
  join pg_namespace as ns on ns.oid = tbl.relnamespace
  join pg_stats as s on s.schemaname = ns.nspname and s.tablename = tbl.relname and not s.inherited and s.attname = att.attname
  left join pg_class as toast on tbl.reltoastrelid = toast.oid
  where not att.attisdropped and s.schemaname not in ('pg_catalog', 'information_schema')
  group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
  order by 2, 3
), step2 as (
  select
    *,
    (
      4 + tpl_hdr_size + tpl_data_size + (2 * ma)
      - case when tpl_hdr_size % ma = 0 then ma else tpl_hdr_size % ma end
      - case when ceil(tpl_data_size)::int % ma = 0 then ma else ceil(tpl_data_size)::int % ma end
    ) as tpl_size,
    bs - page_hdr as size_per_block,
    (heappages + toastpages) as tblpages
  from step1
), step3 as (
  select
      *,
    ceil(reltuples / ((bs - page_hdr) / tpl_size)) + ceil(toasttuples / 4) as est_tblpages,
    ceil(reltuples / ((bs - page_hdr) * fillfactor / (tpl_size * 100))) + ceil(toasttuples / 4) as est_tblpages_ff
    -- , stattuple.pgstattuple(tblid) as pst
  from step2
), step4 as (
  select
    *,
    tblpages * bs as real_size,
    (tblpages - est_tblpages) * bs as extra_size,
    case when tblpages - est_tblpages > 0 then 100 * (tblpages - est_tblpages) / tblpages::float else 0 end as extra_ratio,
    (tblpages - est_tblpages_ff) * bs as bloat_size,
    case when tblpages - est_tblpages_ff > 0 then 100 * (tblpages - est_tblpages_ff) / tblpages::float else 0 end as bloat_ratio
    -- , (pst).free_percent + (pst).dead_tuple_percent as real_frag
  from step3
  left join pg_stat_user_tables su on su.relid = tblid
  -- WHERE NOT is_na
  --   AND tblpages*((pst).free_percent + (pst).dead_tuple_percent)::float4/100 >= 1
)
select
  case is_na when true then 'TRUE' else '' end as "Is N/A",
  coalesce(nullif(schema_name, 'public') || '.', '') || table_name as "Table",
  pg_size_pretty(real_size::numeric) as "Size",
  case
    when extra_size::numeric >= 0
      then '~' || pg_size_pretty(extra_size::numeric)::text || ' (' || round(extra_ratio::numeric, 2)::text || '%)'
    else null
  end  as "Extra",
  case
    when bloat_size::numeric >= 0
      then '~' || pg_size_pretty(bloat_size::numeric)::text || ' (' || round(bloat_ratio::numeric, 2)::text || '%)'
    else null
  end as "Bloat estimate",
  case
    when bloat_size::numeric >= 0
      then  round(bloat_ratio::numeric, 2)
    else null
  end as "Bloat100",
  case
    when (real_size - bloat_size)::numeric >=0
      then '~' || pg_size_pretty((real_size - bloat_size)::numeric)
 else null
   end as "Live",
  greatest(last_autovacuum, last_vacuum)::timestamp(0)::text
    || case greatest(last_autovacuum, last_vacuum)
      when last_autovacuum then ' (auto)'
    else '' end as "Last Vacuum",
  (
    select
      coalesce(substring(array_to_string(reloptions, ' ') from 'fillfactor=([0-9]+)')::smallint, 100)
    from pg_class
    where oid = tblid
  ) as "Fillfactor"
from step4
where round(bloat_ratio::numeric, 2) > :bloat_min  -- eşikten büyük bloat'ları ver
order by bloat_size desc nulls last
;
