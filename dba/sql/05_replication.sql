-- =====================================================================
-- 05_replication.sql
-- Replikasyon ve replikasyon slotları
--   * Primary'de: bağlı replikalar, lag (byte ve süre), senkron durum
--   * Standby'da: WAL receiver, receive/replay LSN, replay gecikmesi
--   * Her iki tarafta: replikasyon slotları ve tuttukları WAL miktarı
-- Script sunucunun rolünü kendisi algılar.
-- Çalıştırma: psql -X -d postgres -f 05_replication.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

SELECT pg_is_in_recovery() AS is_standby,
       current_setting('server_version_num')::int >= 160000 AS pg16 \gset

\echo '--- 5.1 Rol ve temel replikasyon ayarları ---'
SELECT CASE WHEN pg_is_in_recovery() THEN 'STANDBY' ELSE 'PRIMARY' END AS role,
       current_setting('wal_level')                  AS wal_level,
       current_setting('max_wal_senders')            AS max_wal_senders,
       current_setting('max_replication_slots')      AS max_replication_slots,
       current_setting('synchronous_standby_names')  AS synchronous_standby_names,
       current_setting('synchronous_commit')         AS synchronous_commit,
       current_setting('hot_standby_feedback')       AS hot_standby_feedback,
       current_setting('wal_keep_size')              AS wal_keep_size,
       current_setting('max_slot_wal_keep_size')     AS max_slot_wal_keep_size;

\if :is_standby
-- ===================== STANDBY =====================
\echo '--- 5.2 [STANDBY] Recovery durumu ---'
SELECT pg_is_in_recovery()                AS is_standby,
       pg_last_wal_receive_lsn()          AS receive_lsn,
       pg_last_wal_replay_lsn()           AS replay_lsn,
       pg_size_pretty(greatest(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()), 0))
                                          AS receive_replay_gap,
       pg_last_xact_replay_timestamp()    AS last_replayed_xact_time,
       date_trunc('second', now() - pg_last_xact_replay_timestamp()) AS replay_delay,
       pg_is_wal_replay_paused()          AS replay_paused;
-- DİKKAT: primary'de hiç yazma olmuyorsa replay_delay doğal olarak büyür.
-- Gerçek gecikme için primary'de 5.4 sorgusuna (replay_lag) bakın veya
-- receive_replay_gap ~ 0 ise standby güncel kabul edilir.

\echo '--- 5.3 [STANDBY] WAL receiver ---'
SELECT pid, status, sender_host, sender_port, slot_name,
       receive_start_lsn, written_lsn, flushed_lsn, latest_end_lsn,
       latest_end_time, last_msg_send_time, last_msg_receipt_time,
       date_trunc('second', now() - last_msg_receipt_time) AS since_last_msg
FROM pg_stat_wal_receiver;
-- Satır yoksa standby primary'ye bağlı DEĞİL (arşivden besleniyor ya da kopuk).

\echo '--- 5.3b [STANDBY] Recovery conflict nedeniyle iptal edilen sorgular ---'
SELECT datname, confl_tablespace, confl_lock, confl_snapshot, confl_bufferpin, confl_deadlock
FROM pg_stat_database_conflicts
WHERE confl_tablespace + confl_lock + confl_snapshot + confl_bufferpin + confl_deadlock > 0;

\else
-- ===================== PRIMARY =====================
\echo '--- 5.4 [PRIMARY] Bağlı replikalar ve gecikme ---'
SELECT pid,
       application_name,
       client_addr,
       state,
       sync_state,
       sync_priority,
       sent_lsn,
       replay_lsn,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn))   AS send_lag,
       pg_size_pretty(pg_wal_lsn_diff(sent_lsn, flush_lsn))              AS flush_lag_bytes,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replay_lag_bytes,
       write_lag,
       flush_lag,
       replay_lag,
       backend_xmin,
       date_trunc('second', now() - backend_start) AS connected_for,
       reply_time
FROM pg_stat_replication
ORDER BY application_name;
-- Yorum:
--   send_lag büyük      -> ağ / walsender darboğazı
--   flush_lag büyük     -> replikanın disk yazımı yavaş
--   replay_lag büyük    -> replikada replay yavaş veya conflict nedeniyle bekliyor
--   backend_xmin dolu   -> hot_standby_feedback açık; replikadaki uzun sorgular
--                          primary'de vacuum'u geciktirebilir

\echo '--- 5.5 [PRIMARY] Senkron replikasyon kontrolü ---'
SELECT current_setting('synchronous_standby_names') AS synchronous_standby_names,
       count(*) FILTER (WHERE sync_state IN ('sync', 'quorum')) AS sync_replicas,
       count(*) FILTER (WHERE sync_state = 'potential')         AS potential,
       count(*) FILTER (WHERE sync_state = 'async')             AS async,
       CASE WHEN current_setting('synchronous_standby_names') <> ''
             AND count(*) FILTER (WHERE sync_state IN ('sync', 'quorum')) = 0
            THEN 'KRİTİK: senkron replika yok, COMMIT''ler bekleyebilir!'
            ELSE 'OK' END AS durum
FROM pg_stat_replication;
\endif

\echo '--- 5.6 Replikasyon slotları ---'
SELECT slot_name,
       slot_type,
       plugin,
       database,
       active,
       active_pid,
       temporary,
       wal_status,
       pg_size_pretty(safe_wal_size) AS safe_wal_size,
       restart_lsn,
       confirmed_flush_lsn,
       pg_size_pretty(pg_wal_lsn_diff(
         CASE WHEN pg_is_in_recovery() THEN pg_last_wal_receive_lsn()
              ELSE pg_current_wal_lsn() END, restart_lsn))  AS retained_wal,
       xmin,
       catalog_xmin,
       age(xmin)         AS xmin_age,
       age(catalog_xmin) AS catalog_xmin_age
FROM pg_replication_slots
ORDER BY pg_wal_lsn_diff(
           CASE WHEN pg_is_in_recovery() THEN pg_last_wal_receive_lsn()
                ELSE pg_current_wal_lsn() END, restart_lsn) DESC NULLS LAST;
-- wal_status:
--   reserved   -> normal
--   extended   -> max_wal_size aşıldı ama wal_keep_size / slot ile tutuluyor
--   unreserved -> max_slot_wal_keep_size sınırında, WAL silinmek üzere (risk)
--   lost       -> gerekli WAL silinmiş, slot kullanılamaz (yeniden kurulum gerekir)
-- Pasif ve WAL biriktiren slot, diskin dolmasının en sık nedenidir.
-- Kullanılmayan slotu silmek: SELECT pg_drop_replication_slot('<slot_name>');

\echo '--- 5.7 Mantıksal (logical) slot istatistikleri ---'
SELECT slot_name, spill_txns, pg_size_pretty(spill_bytes) AS spill_bytes,
       stream_txns, pg_size_pretty(stream_bytes) AS stream_bytes,
       total_txns, pg_size_pretty(total_bytes) AS total_bytes, stats_reset
FROM pg_stat_replication_slots;
-- spill_bytes yüksek -> logical_decoding_work_mem yetersiz olabilir

\echo '--- 5.8 Yayınlar ve abonelikler (logical replication) ---'
SELECT 'publication' AS kind, pubname AS name, puballtables::text AS detail FROM pg_publication
UNION ALL
SELECT 'subscription', subname, subenabled::text FROM pg_subscription;

SELECT subname, pid, received_lsn, latest_end_lsn,
       date_trunc('second', now() - last_msg_receipt_time) AS since_last_msg
FROM pg_stat_subscription;
