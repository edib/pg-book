-- =====================================================================
-- 17_security_quick.sql
-- Healthcheck kapsamında HIZLI güvenlik kontrolü.
-- Ayrıntılı sıkılaştırma değerlendirmesi için ayrı sıkılaştırma (hardening)
-- dokümanını ve CIS PostgreSQL Benchmark'ı kullanın.
-- Yetki: bazı sorgular (pg_authid, pg_hba_file_rules) superuser gerektirir.
-- Çalıştırma: psql -X -d postgres -f 17_security_quick.sql
-- =====================================================================
\set QUIET on
\pset footer off
\pset null '-'
SELECT (SELECT rolsuper FROM pg_roles WHERE rolname = current_user) AS is_super \gset

\echo '--- 17.1 Ayrıcalıklı roller ---'
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolreplication, rolbypassrls,
       rolcanlogin, rolconnlimit, rolvaliduntil
FROM pg_roles
WHERE rolname !~ '^pg_'
  AND (rolsuper OR rolcreaterole OR rolreplication OR rolbypassrls)
ORDER BY rolsuper DESC, rolname;

\echo '--- 17.2 Bağlı oturumlarda SSL kullanımı ---'
SELECT coalesce(s.ssl::text, 'local/unix')  AS ssl,
       s.version,
       count(*)
FROM pg_stat_activity a
LEFT JOIN pg_stat_ssl s ON s.pid = a.pid
WHERE a.backend_type = 'client backend'
GROUP BY 1, 2
ORDER BY 3 DESC;

\echo '--- 17.3 Güvenlik ile ilgili temel ayarlar ---'
SELECT name, setting
FROM pg_settings
WHERE name IN ('listen_addresses', 'ssl', 'ssl_min_protocol_version', 'password_encryption',
               'log_connections', 'log_disconnections', 'shared_preload_libraries',
               'row_security', 'authentication_timeout')
ORDER BY name;

\if :is_super
\echo '--- 17.4 pg_hba.conf: riskli kurallar (trust / password / md5 / geniş ağ) ---'
SELECT line_number, type, database, user_name, address, netmask, auth_method
FROM pg_hba_file_rules
WHERE auth_method IN ('trust', 'password', 'md5')
   OR (address IN ('0.0.0.0', '::', 'all') AND auth_method <> 'reject')
ORDER BY line_number;

\echo '--- 17.5 MD5 hash''li parolalar (scram-sha-256''e geçirilmeli) ---'
SELECT rolname
FROM pg_authid
WHERE rolpassword LIKE 'md5%';

\echo '--- 17.6 Parolasız oturum açabilen roller ---'
SELECT rolname
FROM pg_authid
WHERE rolcanlogin AND rolpassword IS NULL AND rolname !~ '^pg_';
-- peer / cert / ldap kullanılıyorsa normal olabilir; trust ile birlikte ise kritik.
\else
\echo '17.4–17.6 superuser gerektirir, atlandı.'
\endif

\echo '--- 17.7 PUBLIC''e CREATE yetkisi verilmiş şemalar (bu veritabanı) ---'
SELECT nspname, nspacl
FROM pg_namespace
WHERE has_schema_privilege('public', oid, 'CREATE')
  AND nspname NOT LIKE 'pg_%' AND nspname <> 'information_schema';
