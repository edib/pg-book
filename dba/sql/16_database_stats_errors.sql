-- =====================================================================
-- 16_database_stats_errors.sql
-- Veritabanı düzeyinde iş yükü ve hata göstergeleri (küme geneli)
--   * commit / rollback, tuple işlemleri
--   * deadlock, temp dosya, checksum hatası, recovery conflict
--   * oturum istatistikleri (PG14+): kopan, öldürülen, hatayla kapanan oturumlar
-- Çalıştırma: psql -X -d postgres -f 16_database_stats_errors.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'
SELECT current_setting('server_version_num')::int >= 140000 AS pg14 \gset

\echo '--- 16.1 İş yükü ve hata sayaçları (veritabanı başına) ---'
SELECT datname,
       numbackends                                                     AS conns,
       xact_commit,
       xact_rollback,
       round(100.0 * xact_rollback / NULLIF(xact_commit + xact_rollback, 0), 2) AS rollback_pct,
       tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted,
       deadlocks,
       temp_files,
       pg_size_pretty(temp_bytes)                                      AS temp_bytes,
       conflicts,
       checksum_failures,
       checksum_last_failure,
       stats_reset
FROM pg_stat_database
WHERE datname IS NOT NULL
ORDER BY xact_commit + xact_rollback DESC;
-- rollback_pct yüksek  -> uygulama hataları / ORM davranışı
-- deadlocks > 0        -> log'da "deadlock detected" satırlarını inceleyin
-- temp_bytes yüksek    -> work_mem yetersiz; 14_top_queries.sql 14.5'e bakın
-- checksum_failures > 0 -> disk / depolama bozulması; ACİL inceleme

\if :pg14
\echo '--- 16.2 Oturum istatistikleri (PG14+) ---'
SELECT datname,
       sessions,
       sessions_abandoned,   -- istemci bağlantıyı kapatmadan koptu
       sessions_fatal,       -- FATAL hata ile sonlandı
       sessions_killed,      -- operatör tarafından sonlandırıldı
       round((session_time / 1000 / 3600)::numeric, 1)              AS session_hours,
       round((active_time / 1000 / 3600)::numeric, 1)               AS active_hours,
       round((idle_in_transaction_time / 1000 / 3600)::numeric, 1)  AS idle_in_tx_hours,
       round(100 * idle_in_transaction_time / NULLIF(session_time, 0))::int AS idle_in_tx_pct
FROM pg_stat_database
WHERE datname IS NOT NULL
ORDER BY sessions DESC;
-- sessions_abandoned yüksek -> ağ sorunları, uygulama crash'leri, timeout'lar
-- idle_in_tx_pct yüksek     -> uygulama transaction yönetimi hatalı
\endif

\echo '--- 16.3 Standby recovery conflict''leri ---'
SELECT datname, confl_tablespace, confl_lock, confl_snapshot, confl_bufferpin, confl_deadlock
FROM pg_stat_database_conflicts
WHERE datname IS NOT NULL
ORDER BY confl_snapshot + confl_lock + confl_bufferpin DESC;
-- Standby'da confl_snapshot yüksek -> uzun okuma sorguları iptal ediliyor;
-- max_standby_streaming_delay veya hot_standby_feedback değerlendirilmeli.
