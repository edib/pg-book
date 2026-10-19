-- =====================================================================
-- 90_rate_sample.sql
-- ANLIK HIZ ÖRNEKLEMESİ: iki ölçüm arasında (varsayılan 60 sn) farkı alıp
-- saniye başına değerleri hesaplar. Kümülatif sayaçlar ("reset'ten beri")
-- yerine şu anki yükü görmek için kullanılır.
--   * TPS (commit + rollback), satır okuma/yazma hızı
--   * WAL üretim hızı (primary)
--   * diskten blok okuma, temp dosya hızı
--   * checkpoint sayısı
-- Çalıştırma: psql -X -d postgres -v interval=60 -f 90_rate_sample.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'
\if :{?interval}
\else
  \set interval 60
\endif

SELECT current_setting('server_version_num')::int >= 170000 AS pg17,
       pg_is_in_recovery() AS is_standby \gset

-- ---- 1. ölçüm ----
SELECT extract(epoch FROM clock_timestamp())        AS t1,
       sum(xact_commit)   AS c1,  sum(xact_rollback) AS r1,
       sum(tup_returned + tup_fetched)              AS rd1,
       sum(tup_inserted + tup_updated + tup_deleted) AS wr1,
       sum(blks_read)     AS br1, sum(blks_hit)      AS bh1,
       sum(temp_bytes)    AS tb1
FROM pg_stat_database \gset
\if :is_standby
SELECT pg_last_wal_replay_lsn() AS lsn1 \gset
\else
SELECT pg_current_wal_lsn() AS lsn1 \gset
\endif
\if :pg17
SELECT num_timed + num_requested AS ck1 FROM pg_stat_checkpointer \gset
\else
SELECT checkpoints_timed + checkpoints_req AS ck1 FROM pg_stat_bgwriter \gset
\endif

\echo 'Örnekleme yapılıyor:' :interval 'saniye bekleniyor...'
SELECT pg_sleep(:interval) \g /dev/null

-- ---- 2. ölçüm ----
SELECT extract(epoch FROM clock_timestamp())        AS t2,
       sum(xact_commit)   AS c2,  sum(xact_rollback) AS r2,
       sum(tup_returned + tup_fetched)              AS rd2,
       sum(tup_inserted + tup_updated + tup_deleted) AS wr2,
       sum(blks_read)     AS br2, sum(blks_hit)      AS bh2,
       sum(temp_bytes)    AS tb2
FROM pg_stat_database \gset
\if :is_standby
SELECT pg_last_wal_replay_lsn() AS lsn2 \gset
\else
SELECT pg_current_wal_lsn() AS lsn2 \gset
\endif
\if :pg17
SELECT num_timed + num_requested AS ck2 FROM pg_stat_checkpointer \gset
\else
SELECT checkpoints_timed + checkpoints_req AS ck2 FROM pg_stat_bgwriter \gset
\endif

\echo '--- 90.1 Saniye başına değerler ---'
WITH d AS (SELECT (:t2 - :t1)::numeric AS sec)
SELECT round(sec, 1)                                          AS sample_sec,
       round((:c2 - :c1 + :r2 - :r1) / sec, 1)                AS tps,
       round((:r2 - :r1) / sec, 2)                            AS rollbacks_per_sec,
       round((:rd2 - :rd1) / sec)                             AS rows_read_per_sec,
       round((:wr2 - :wr1) / sec)                             AS rows_written_per_sec,
       pg_size_pretty(((:br2 - :br1) * current_setting('block_size')::numeric / sec)::bigint)
                                                              AS disk_read_per_sec,
       round(100.0 * (:bh2 - :bh1) / NULLIF((:bh2 - :bh1) + (:br2 - :br1), 0), 2) AS hit_pct_now,
       pg_size_pretty((pg_wal_lsn_diff(:'lsn2', :'lsn1') / sec)::bigint)      AS wal_per_sec,
       pg_size_pretty((pg_wal_lsn_diff(:'lsn2', :'lsn1') / sec * 3600)::bigint) AS wal_per_hour_est,
       pg_size_pretty(((:tb2 - :tb1) / sec)::bigint)          AS temp_per_sec,
       :ck2 - :ck1                                            AS checkpoints_in_sample
FROM d;
-- Standby'da wal_per_sec, replay hızını gösterir.
-- wal_per_hour_est, max_wal_size ve arşiv/yedek alanı planlaması için kullanılır.
