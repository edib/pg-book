-- =====================================================================
-- 00_cluster_summary.sql
-- Küme (instance) düzeyinde ÖZET sağlık kontrolü.
-- Her kontrol için değer, uyarı/kritik eşiği ve OK / WARN / CRIT / INFO
-- durumu üretir. Herhangi bir veritabanından çalıştırılabilir.
--
-- Çalıştırma : psql -X -d postgres -f 00_cluster_summary.sql
-- Eşik değiştirme: psql -X -v conn_warn=60 -v conn_crit=85 -f ...
-- Yetki      : superuser veya pg_monitor rolü
-- Uyumluluk  : PostgreSQL 13 – 18
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

-- ---------------------------------------------------------------------
-- Eşik varsayılanları (komut satırından -v ile ezilebilir)
-- ---------------------------------------------------------------------
\if :{?conn_warn}
\else
  \set conn_warn 70
\endif
\if :{?conn_crit}
\else
  \set conn_crit 90
\endif
\if :{?idle_tx_warn_sec}
\else
  \set idle_tx_warn_sec 300
\endif
\if :{?idle_tx_crit_sec}
\else
  \set idle_tx_crit_sec 1800
\endif
\if :{?query_warn_sec}
\else
  \set query_warn_sec 300
\endif
\if :{?query_crit_sec}
\else
  \set query_crit_sec 1800
\endif
\if :{?xact_warn_sec}
\else
  \set xact_warn_sec 1800
\endif
\if :{?xact_crit_sec}
\else
  \set xact_crit_sec 7200
\endif
\if :{?xid_warn}
\else
  \set xid_warn 500000000
\endif
\if :{?xid_crit}
\else
  \set xid_crit 1000000000
\endif
\if :{?lag_warn_bytes}
\else
  \set lag_warn_bytes 104857600
\endif
\if :{?lag_crit_bytes}
\else
  \set lag_crit_bytes 1073741824
\endif
\if :{?lag_warn_sec}
\else
  \set lag_warn_sec 60
\endif
\if :{?lag_crit_sec}
\else
  \set lag_crit_sec 300
\endif
\if :{?slot_warn_bytes}
\else
  \set slot_warn_bytes 1073741824
\endif
\if :{?slot_crit_bytes}
\else
  \set slot_crit_bytes 10737418240
\endif
\if :{?hit_warn}
\else
  \set hit_warn 99
\endif
\if :{?hit_crit}
\else
  \set hit_crit 95
\endif

-- ---------------------------------------------------------------------
-- Sürüme ve yetkiye bağlı değerleri önceden topla
-- ---------------------------------------------------------------------
SELECT current_setting('server_version_num')::int >= 170000 AS pg17 \gset

\if :pg17
SELECT num_timed AS ckpt_timed, num_requested AS ckpt_req FROM pg_stat_checkpointer \gset
\else
SELECT checkpoints_timed AS ckpt_timed, checkpoints_req AS ckpt_req FROM pg_stat_bgwriter \gset
\endif

-- pg_ls_waldir / pg_ls_archive_statusdir: superuser veya pg_monitor gerekir
SELECT CASE WHEN has_function_privilege('pg_ls_waldir()', 'EXECUTE')
            THEN (SELECT coalesce(sum(size), 0) FROM pg_ls_waldir()) END AS wal_dir_bytes,
       CASE WHEN has_function_privilege('pg_ls_archive_statusdir()', 'EXECUTE')
            THEN (SELECT count(*) FROM pg_ls_archive_statusdir() WHERE name LIKE '%.ready') END AS ready_files
\gset

\echo ''
\echo '================ KÜME ÖZETİ (CLUSTER SUMMARY) ================'

WITH
act AS (
  SELECT * FROM pg_stat_activity WHERE pid <> pg_backend_pid()
),
dbs AS (
  SELECT sum(blks_hit)          AS hit,
         sum(blks_read)         AS rd,
         sum(xact_commit)       AS cm,
         sum(xact_rollback)     AS rb,
         sum(deadlocks)         AS dl,
         sum(temp_bytes)        AS tb,
         sum(checksum_failures) AS cf,
         min(stats_reset)       AS sr
  FROM pg_stat_database
),
rep AS (
  SELECT CASE WHEN NOT pg_is_in_recovery() THEN
           (SELECT max(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) FROM pg_stat_replication)
         END AS max_lag_bytes,
         (SELECT extract(epoch FROM max(replay_lag)) FROM pg_stat_replication) AS max_lag_sec,
         (SELECT count(*) FROM pg_stat_replication) AS replicas,
         (SELECT count(*) FROM pg_stat_replication WHERE sync_state IN ('sync', 'quorum')) AS sync_replicas
),
slots AS (
  SELECT count(*) FILTER (WHERE NOT active)                       AS inactive,
         count(*) FILTER (WHERE wal_status IN ('lost','unreserved')) AS lost,
         max(pg_wal_lsn_diff(
               CASE WHEN pg_is_in_recovery() THEN pg_last_wal_receive_lsn()
                    ELSE pg_current_wal_lsn() END,
               restart_lsn))                                       AS max_retained
  FROM pg_replication_slots
),
arc AS (
  SELECT *,
         current_setting('archive_mode') <> 'off' AS enabled
  FROM pg_stat_archiver
),
checks (sira, kategori, kontrol, n, gosterim, uyari, kritik, yon) AS (
  -- ---------------- Genel ----------------
  SELECT 1, 'Genel', 'Sunucu sürümü', NULL::numeric,
         current_setting('server_version'), NULL::numeric, NULL::numeric, 'info'
  UNION ALL
  SELECT 2, 'Genel', 'Rol', NULL,
         CASE WHEN pg_is_in_recovery() THEN 'STANDBY' ELSE 'PRIMARY' END, NULL, NULL, 'info'
  UNION ALL
  SELECT 3, 'Genel', 'Uptime', NULL,
         date_trunc('second', now() - pg_postmaster_start_time())::text, NULL, NULL, 'info'
  UNION ALL
  SELECT 4, 'Genel', 'İstatistik sıfırlanmasından bu yana (gün)',
         round(extract(epoch FROM now() - sr) / 86400, 1),
         coalesce(round(extract(epoch FROM now() - sr) / 86400, 1)::text, 'hiç sıfırlanmamış'),
         NULL, NULL, 'info'
  FROM dbs
  UNION ALL
  -- ---------------- Kritik ayarlar ----------------
  SELECT 10, 'Ayar', 'fsync kapalı mı', (current_setting('fsync') = 'off')::int,
         current_setting('fsync'), NULL, 1, 'gt'
  UNION ALL
  SELECT 11, 'Ayar', 'full_page_writes kapalı mı', (current_setting('full_page_writes') = 'off')::int,
         current_setting('full_page_writes'), NULL, 1, 'gt'
  UNION ALL
  SELECT 12, 'Ayar', 'autovacuum kapalı mı', (current_setting('autovacuum') = 'off')::int,
         current_setting('autovacuum'), NULL, 1, 'gt'
  UNION ALL
  SELECT 13, 'Ayar', 'track_counts kapalı mı', (current_setting('track_counts') = 'off')::int,
         current_setting('track_counts'), NULL, 1, 'gt'
  UNION ALL
  SELECT 14, 'Ayar', 'Restart bekleyen parametre sayısı', count(*),
         count(*)::text, 1, NULL, 'gt'
  FROM pg_settings WHERE pending_restart
  UNION ALL
  SELECT 15, 'Ayar', 'Hatalı satır (pg_file_settings)', count(*),
         count(*)::text, NULL, 1, 'gt'
  FROM pg_file_settings WHERE error IS NOT NULL
  UNION ALL
  -- ---------------- Bağlantı ----------------
  SELECT 20, 'Bağlantı', 'Bağlantı kullanımı (%)',
         round(100.0 * (SELECT count(*) FROM act WHERE backend_type = 'client backend')
               / current_setting('max_connections')::int, 1),
         (SELECT count(*) FROM act WHERE backend_type = 'client backend')::text
           || ' / ' || current_setting('max_connections'),
         :conn_warn, :conn_crit, 'gt'
  UNION ALL
  SELECT 21, 'Bağlantı', 'En uzun idle in transaction (sn)',
         coalesce(max(extract(epoch FROM now() - state_change)), 0)::numeric(12,0),
         coalesce(date_trunc('second', max(now() - state_change))::text, 'yok'),
         :idle_tx_warn_sec, :idle_tx_crit_sec, 'gt'
  FROM act WHERE state LIKE 'idle in transaction%'
  UNION ALL
  SELECT 22, 'Bağlantı', 'En uzun aktif sorgu (sn)',
         coalesce(max(extract(epoch FROM now() - query_start)), 0)::numeric(12,0),
         coalesce(date_trunc('second', max(now() - query_start))::text, 'yok'),
         :query_warn_sec, :query_crit_sec, 'gt'
  FROM act WHERE state = 'active' AND backend_type = 'client backend'
  UNION ALL
  SELECT 23, 'Bağlantı', 'En eski açık transaction (sn)',
         coalesce(max(extract(epoch FROM now() - xact_start)), 0)::numeric(12,0),
         coalesce(date_trunc('second', max(now() - xact_start))::text, 'yok'),
         :xact_warn_sec, :xact_crit_sec, 'gt'
  FROM act WHERE xact_start IS NOT NULL AND backend_type = 'client backend'
  UNION ALL
  SELECT 24, 'Kilit', 'Kilit bekleyen (bloklanan) oturum', count(*),
         count(*)::text, 1, 10, 'gt'
  FROM act WHERE wait_event_type = 'Lock'
  UNION ALL
  SELECT 25, 'Kilit', 'Unutulmuş prepared transaction (>5 dk)', count(*),
         count(*)::text, NULL, 1, 'gt'
  FROM pg_prepared_xacts WHERE prepared < now() - interval '5 minutes'
  UNION ALL
  -- ---------------- Wraparound ----------------
  SELECT 30, 'Wraparound', 'En yüksek XID yaşı (datfrozenxid)', max(age(datfrozenxid)),
         to_char(max(age(datfrozenxid)), 'FM999G999G999G999')
           || ' (' || round(100.0 * max(age(datfrozenxid)) / 2147483648, 1) || '%)',
         :xid_warn, :xid_crit, 'gt'
  FROM pg_database
  UNION ALL
  SELECT 31, 'Wraparound', 'En yüksek MultiXact yaşı (datminmxid)', max(mxid_age(datminmxid)),
         to_char(max(mxid_age(datminmxid)), 'FM999G999G999G999'),
         :xid_warn, :xid_crit, 'gt'
  FROM pg_database
  UNION ALL
  -- ---------------- Replikasyon ----------------
  SELECT 40, 'Replikasyon', 'Bağlı replika sayısı', replicas, replicas::text, NULL, NULL, 'info'
  FROM rep
  UNION ALL
  SELECT 41, 'Replikasyon', 'Senkron replika eksik (sync_standby_names dolu)',
         CASE WHEN current_setting('synchronous_standby_names') <> '' AND NOT pg_is_in_recovery()
              THEN (sync_replicas = 0)::int ELSE 0 END,
         CASE WHEN current_setting('synchronous_standby_names') = '' THEN 'senkron replikasyon yok'
              ELSE sync_replicas || ' senkron replika' END,
         NULL, 1, 'gt'
  FROM rep
  UNION ALL
  SELECT 42, 'Replikasyon', 'Maks. replay lag (byte, primary)', max_lag_bytes,
         coalesce(pg_size_pretty(max_lag_bytes), '-'), :lag_warn_bytes, :lag_crit_bytes, 'gt'
  FROM rep
  UNION ALL
  SELECT 43, 'Replikasyon', 'Maks. replay lag (sn, primary)', round(max_lag_sec::numeric, 1),
         coalesce(round(max_lag_sec::numeric, 1)::text, '-'), :lag_warn_sec, :lag_crit_sec, 'gt'
  FROM rep
  UNION ALL
  -- Primary'de yazma yoksa bu yaş doğal olarak büyür; alınan WAL'ın tamamı
  -- replay edilmişse (receive <= replay) standby güncel kabul edilir ve 0 sayılır.
  SELECT 44, 'Replikasyon', 'Standby: son replay edilen tx yaşı (sn)',
         CASE WHEN pg_is_in_recovery() THEN
           CASE WHEN pg_last_wal_receive_lsn() <= pg_last_wal_replay_lsn()
                 AND EXISTS (SELECT 1 FROM pg_stat_wal_receiver WHERE status = 'streaming') THEN 0
                ELSE round(extract(epoch FROM now() - pg_last_xact_replay_timestamp())::numeric, 1) END
         END,
         CASE WHEN pg_is_in_recovery()
              THEN coalesce(date_trunc('second', now() - pg_last_xact_replay_timestamp())::text, 'henüz replay yok')
                   || CASE WHEN pg_last_wal_receive_lsn() <= pg_last_wal_replay_lsn()
                            AND EXISTS (SELECT 1 FROM pg_stat_wal_receiver WHERE status = 'streaming')
                           THEN ' (güncel: tüm alınan WAL replay edilmiş)' ELSE '' END
              ELSE '-' END,
         :lag_warn_sec, :lag_crit_sec, 'gt'
  UNION ALL
  SELECT 45, 'Replikasyon', 'Standby: alınan ama replay edilmemiş WAL (byte)',
         CASE WHEN pg_is_in_recovery()
              THEN greatest(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()), 0) END,
         CASE WHEN pg_is_in_recovery()
              THEN coalesce(pg_size_pretty(greatest(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()), 0)), '-')
              ELSE '-' END,
         :lag_warn_bytes, :lag_crit_bytes, 'gt'
  UNION ALL
  SELECT 46, 'Replikasyon', 'Standby: replay duraklatılmış mı',
         CASE WHEN pg_is_in_recovery() THEN pg_is_wal_replay_paused()::int END,
         CASE WHEN pg_is_in_recovery() THEN pg_is_wal_replay_paused()::text ELSE '-' END,
         NULL, 1, 'gt'
  UNION ALL
  SELECT 47, 'Slot', 'Pasif replikasyon slotu', inactive, inactive::text, 1, NULL, 'gt'
  FROM slots
  UNION ALL
  SELECT 48, 'Slot', 'WAL''ı kaybolmuş/riskli slot (lost/unreserved)', lost, lost::text, NULL, 1, 'gt'
  FROM slots
  UNION ALL
  SELECT 49, 'Slot', 'Slotun tuttuğu en fazla WAL (byte)', max_retained,
         coalesce(pg_size_pretty(max_retained), '-'), :slot_warn_bytes, :slot_crit_bytes, 'gt'
  FROM slots
  UNION ALL
  -- ---------------- WAL / Arşiv ----------------
  SELECT 50, 'WAL', 'pg_wal dizin boyutu / max_wal_size (kat)',
         round(NULLIF(:'wal_dir_bytes', '')::numeric
               / pg_size_bytes(current_setting('max_wal_size')), 2),
         coalesce(pg_size_pretty(NULLIF(:'wal_dir_bytes', '')::numeric), 'yetki yok')
           || ' / ' || current_setting('max_wal_size'),
         2, 4, 'gt'
  UNION ALL
  SELECT 51, 'WAL', 'Zorunlu (requested) checkpoint oranı (%)',
         -- 10'dan az checkpoint varsa oran anlamlı değil -> N/A
         CASE WHEN :ckpt_timed + :ckpt_req >= 10
              THEN round(100.0 * :ckpt_req / (:ckpt_timed + :ckpt_req), 1) END,
         :ckpt_req || ' requested / ' || :ckpt_timed || ' timed',
         20, 50, 'gt'
  UNION ALL
  SELECT 52, 'Arşiv', 'Arşivleme hatada mı (son hata > son başarı)',
         CASE WHEN enabled THEN (last_failed_time > coalesce(last_archived_time, '-infinity'))::int END,
         CASE WHEN NOT enabled THEN 'archive_mode=off'
              ELSE 'başarısız: ' || failed_count || ', son hata: ' || coalesce(last_failed_time::text, '-') END,
         NULL, 1, 'gt'
  FROM arc
  UNION ALL
  SELECT 53, 'Arşiv', 'Son başarılı arşivden bu yana (sn)',
         CASE WHEN enabled AND NOT pg_is_in_recovery()
              THEN extract(epoch FROM now() - last_archived_time)::numeric(12,0) END,
         CASE WHEN enabled THEN coalesce(date_trunc('second', now() - last_archived_time)::text, 'hiç arşivlenmemiş')
              ELSE '-' END,
         3600, 21600, 'gt'
  FROM arc
  UNION ALL
  SELECT 54, 'Arşiv', 'Arşivlenmeyi bekleyen WAL (.ready)',
         NULLIF(:'ready_files', '')::numeric,
         coalesce(NULLIF(:'ready_files', ''), 'yetki yok'),
         10, 100, 'gt'
  UNION ALL
  -- ---------------- Veritabanı istatistikleri ----------------
  SELECT 60, 'Performans', 'Cache hit oranı (%)',
         round(100.0 * hit / NULLIF(hit + rd, 0), 2),
         coalesce(round(100.0 * hit / NULLIF(hit + rd, 0), 2)::text, '-'),
         :hit_warn, :hit_crit, 'lt'
  FROM dbs
  UNION ALL
  SELECT 61, 'Performans', 'Rollback oranı (%)',
         round(100.0 * rb / NULLIF(cm + rb, 0), 2),
         coalesce(round(100.0 * rb / NULLIF(cm + rb, 0), 2)::text, '-'),
         5, 20, 'gt'
  FROM dbs
  UNION ALL
  SELECT 62, 'Performans', 'Deadlock sayısı (reset''ten beri)', dl, dl::text, 1, NULL, 'gt'
  FROM dbs
  UNION ALL
  SELECT 63, 'Performans', 'Temp dosya hacmi (reset''ten beri)', tb, pg_size_pretty(tb), NULL, NULL, 'info'
  FROM dbs
  UNION ALL
  SELECT 64, 'Bütünlük', 'Checksum hatası', cf,
         CASE WHEN current_setting('data_checksums') = 'off' THEN 'data_checksums kapalı'
              ELSE coalesce(cf, 0)::text END,
         NULL, 1, 'gt'
  FROM dbs
  UNION ALL
  SELECT 65, 'Standby', 'Recovery conflict (iptal edilen sorgu)',
         sum(confl_tablespace + confl_lock + confl_snapshot + confl_bufferpin + confl_deadlock),
         sum(confl_tablespace + confl_lock + confl_snapshot + confl_bufferpin + confl_deadlock)::text,
         1, NULL, 'gt'
  FROM pg_stat_database_conflicts
)
SELECT kategori                                   AS "Kategori",
       kontrol                                    AS "Kontrol",
       gosterim                                   AS "Değer",
       coalesce(uyari::text, '-')                 AS "Uyarı",
       coalesce(kritik::text, '-')                AS "Kritik",
       CASE
         WHEN yon = 'info'                         THEN 'INFO'
         WHEN n IS NULL                            THEN 'N/A'
         WHEN yon = 'gt' AND kritik IS NOT NULL AND n >= kritik THEN 'CRIT'
         WHEN yon = 'gt' AND uyari  IS NOT NULL AND n >= uyari  THEN 'WARN'
         WHEN yon = 'lt' AND kritik IS NOT NULL AND n <  kritik THEN 'CRIT'
         WHEN yon = 'lt' AND uyari  IS NOT NULL AND n <  uyari  THEN 'WARN'
         ELSE 'OK'
       END                                        AS "Durum"
FROM checks
ORDER BY sira;
