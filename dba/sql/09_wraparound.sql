-- =====================================================================
-- 09_wraparound.sql
-- Transaction ID (XID) ve MultiXact wraparound riski
--   * veritabanı ve tablo bazında XID / MXID yaşı
--   * autovacuum_freeze_max_age ve 2^31 sınırına uzaklık
--   * vacuum'un "xmin horizon"unu geride tutan kaynaklar:
--     uzun transaction'lar, replikasyon slotları, prepared xact, standby feedback
--
-- XID yaşı yorum tablosu (2^31 ≈ 2,147 milyar üst sınır):
--     < 200M      : normal (varsayılan autovacuum_freeze_max_age = 200M)
--     200M – 500M : autovacuum zorunlu freeze yapıyor olmalı, izle
--     500M – 1B   : dikkat; freeze yetişmiyor, nedeni bulun
--     1B – 1.5B   : risk; manuel VACUUM (FREEZE) planlayın
--     > 1.6B      : vacuum_failsafe_age; acil durum
--     ~2.1B       : yeni XID verilmez, veritabanı yazmaya kapanır
-- Çalıştırma: psql -X -d <db> -f 09_wraparound.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\echo '--- 9.1 Veritabanı bazında XID ve MultiXact yaşı ---'
SELECT datname,
       age(datfrozenxid)                                            AS xid_age,
       round(100.0 * age(datfrozenxid) / 2147483648, 2)             AS pct_to_wraparound,
       round(100.0 * age(datfrozenxid)
             / current_setting('autovacuum_freeze_max_age')::numeric, 1) AS pct_of_freeze_max_age,
       mxid_age(datminmxid)                                         AS mxid_age,
       CASE
         WHEN age(datfrozenxid) < 500000000  THEN 'güvenli'
         WHEN age(datfrozenxid) < 1000000000 THEN 'izle'
         WHEN age(datfrozenxid) < 1500000000 THEN 'RİSK'
         ELSE 'ACİL'
       END                                                          AS durum
FROM pg_database
ORDER BY age(datfrozenxid) DESC;

\echo '--- 9.2 En yaşlı 30 tablo (bu veritabanı) ---'
SELECT n.nspname                                     AS schema_name,
       c.relname                                     AS table_name,
       c.relkind,
       age(c.relfrozenxid)                           AS xid_age,
       mxid_age(c.relminmxid)                        AS mxid_age,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS size,
       greatest(s.last_vacuum, s.last_autovacuum)    AS last_vacuum_any,
       (SELECT split_part(o, '=', 2) FROM unnest(c.reloptions) o
        WHERE o LIKE 'autovacuum_freeze_max_age=%')  AS table_freeze_max_age
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid
WHERE c.relkind IN ('r', 'm', 't')
ORDER BY age(c.relfrozenxid) DESC
LIMIT 30;

\echo '--- 9.3 Kalan XID kapasitesi ve tüketim hızı ---'
SELECT current_setting('autovacuum_freeze_max_age') AS autovacuum_freeze_max_age,
       current_setting('vacuum_failsafe_age')       AS vacuum_failsafe_age,
       max(age(datfrozenxid))                       AS max_xid_age,
       2147483648 - 3000000 - max(age(datfrozenxid)) AS xids_left_before_stop
FROM pg_database;
-- Günlük XID tüketimini ölçmek için:
--   SELECT txid_current();   -- şimdi ve 24 saat sonra çalıştırıp farkı alın
-- (Not: txid_current() kendisi bir XID tüketir; standby'da çalışmaz.)

\echo '--- 9.4 xmin horizon''u geride tutanlar (vacuum ölü satırları temizleyemez) ---'
SELECT 'backend'          AS source,
       pid::text          AS id,
       usename || ' / ' || coalesce(application_name, '') AS who,
       state,
       age(backend_xmin)  AS xmin_age,
       date_trunc('second', now() - xact_start) AS duration
FROM pg_stat_activity
WHERE backend_xmin IS NOT NULL
UNION ALL
SELECT 'replication slot', slot_name, slot_type || ' ' || coalesce(database, ''),
       CASE WHEN active THEN 'active' ELSE 'INACTIVE' END,
       greatest(age(xmin), age(catalog_xmin)), NULL
FROM pg_replication_slots
WHERE xmin IS NOT NULL OR catalog_xmin IS NOT NULL
UNION ALL
SELECT 'prepared xact', gid, owner || ' / ' || database, 'prepared',
       age(transaction), date_trunc('second', now() - prepared)
FROM pg_prepared_xacts
UNION ALL
SELECT 'standby feedback', application_name, client_addr::text, state,
       age(backend_xmin), NULL
FROM pg_stat_replication
WHERE backend_xmin IS NOT NULL
ORDER BY xmin_age DESC NULLS LAST
LIMIT 20;
-- En üstteki satır horizon'u belirler. xmin_age milyonlarla ifade ediliyorsa
-- o kaynak giderilmeden (oturum kapatma, slot silme, prepared xact commit/rollback,
-- standby sorgusunu bitirme) VACUUM ölü satırları ve eski XID'leri temizleyemez.

-- ---------------------------------------------------------------------
-- ACİL MÜDAHALE (elle, dikkatle):
--   1) 9.4'teki engelleyici kaynağı kaldırın.
--   2) En yaşlı tablolardan başlayarak:
--        VACUUM (FREEZE, VERBOSE, INDEX_CLEANUP AUTO) schema.tablo;
--      Çok büyük tablolarda PG14+ için acil durumda:
--        VACUUM (FREEZE, INDEX_CLEANUP OFF, VERBOSE) schema.tablo;
--   3) Veritabanı tamamen kapanmışsa (yeni XID verilmiyor), resmi dokümandaki
--      single-user mode prosedürünü izleyin.
-- ---------------------------------------------------------------------
