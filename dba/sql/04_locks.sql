-- =====================================================================
-- 04_locks.sql
-- Kilitler ve bloklanan oturumlar
--   * kim kimi bloklıyor (pg_blocking_pids)
--   * kök bloklayıcılar (zincirin başındaki oturumlar)
--   * verilmemiş (granted = false) kilitler
--   * kilit modu dağılımı, advisory lock'lar
-- Not: pg_blocking_pids() çok yoğun sistemlerde pahalıdır; sorunu
--      incelerken çalıştırın, saniyelik izlemede kullanmayın.
-- Çalıştırma: psql -X -d <db> -f 04_locks.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'

\echo '--- 4.1 Bloklanan ve bloklayan oturumlar ---'
SELECT blocked.pid                                   AS blocked_pid,
       blocked.usename                               AS blocked_user,
       blocked.application_name                      AS blocked_app,
       blocking.pid                                  AS blocking_pid,
       blocking.usename                              AS blocking_user,
       blocking.state                                AS blocking_state,
       date_trunc('second', now() - blocked.query_start)  AS blocked_duration,
       date_trunc('second', now() - blocking.xact_start)  AS blocker_xact_age,
       left(regexp_replace(blocked.query,  '\s+', ' ', 'g'), 100) AS blocked_query,
       left(regexp_replace(blocking.query, '\s+', ' ', 'g'), 100) AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
  ON blocking.pid = ANY (pg_blocking_pids(blocked.pid))
WHERE cardinality(pg_blocking_pids(blocked.pid)) > 0
ORDER BY blocked_duration DESC;

\echo '--- 4.2 Kök bloklayıcılar (kendisi bloklanmayan ama başkalarını bloklayan) ---'
-- Genelde müdahale edilmesi gereken oturum budur. Sık görülen tablo:
-- "idle in transaction" durumda bekleyen bir uygulama oturumu.
WITH b AS (
  SELECT pid, unnest(pg_blocking_pids(pid)) AS blocker
  FROM pg_stat_activity
  WHERE cardinality(pg_blocking_pids(pid)) > 0
)
SELECT a.pid,
       a.usename,
       a.application_name,
       a.client_addr,
       a.state,
       date_trunc('second', now() - a.xact_start)   AS xact_age,
       date_trunc('second', now() - a.state_change) AS in_state_for,
       count(DISTINCT b.pid)                        AS directly_blocked,
       left(regexp_replace(a.query, '\s+', ' ', 'g'), 120) AS query
FROM b
JOIN pg_stat_activity a ON a.pid = b.blocker
WHERE cardinality(pg_blocking_pids(a.pid)) = 0
GROUP BY a.pid, a.usename, a.application_name, a.client_addr, a.state,
         a.xact_start, a.state_change, a.query
ORDER BY directly_blocked DESC;

\echo '--- 4.3 Verilmemiş (bekleyen) kilitler ---'
SELECT l.pid,
       l.locktype,
       l.mode,
       l.granted,
       coalesce(c.relname, l.relation::text) AS relation,
       l.transactionid,
       l.virtualxid,
       date_trunc('second', now() - a.query_start) AS waiting,
       left(regexp_replace(a.query, '\s+', ' ', 'g'), 100) AS query
FROM pg_locks l
LEFT JOIN pg_class c        ON c.oid = l.relation
LEFT JOIN pg_stat_activity a ON a.pid = l.pid
WHERE NOT l.granted
ORDER BY a.query_start;

\echo '--- 4.4 Kilit modu dağılımı ---'
SELECT locktype, mode, granted, count(*)
FROM pg_locks
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

\echo '--- 4.5 AccessExclusiveLock tutan oturumlar (DDL, VACUUM FULL, LOCK TABLE) ---'
SELECT l.pid, c.relname, a.usename, a.state,
       date_trunc('second', now() - a.xact_start) AS xact_age,
       left(regexp_replace(a.query, '\s+', ' ', 'g'), 100) AS query
FROM pg_locks l
JOIN pg_class c ON c.oid = l.relation
JOIN pg_stat_activity a ON a.pid = l.pid
WHERE l.mode = 'AccessExclusiveLock' AND l.granted
  AND c.relnamespace <> 'pg_catalog'::regnamespace;

\echo '--- 4.6 Advisory lock kullanımı ---'
SELECT l.pid, a.usename, a.application_name, count(*) AS advisory_locks
FROM pg_locks l JOIN pg_stat_activity a ON a.pid = l.pid
WHERE l.locktype = 'advisory'
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

\echo '--- 4.7 Prepared (2PC) transaction''lar ---'
-- Unutulmuş prepared transaction'lar kilit tutar ve vacuum'u engeller.
-- Temizlik: COMMIT PREPARED '<gid>';  veya  ROLLBACK PREPARED '<gid>';
SELECT gid, prepared, date_trunc('second', now() - prepared) AS age, owner, database,
       transaction, age(transaction) AS xid_age
FROM pg_prepared_xacts
ORDER BY prepared;
