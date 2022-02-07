# Yapısal İşlemler


### `tablespace` işlemleri
temp işlemlerini asıl dizinden ayırmak istersek, postgres linux kullanıcısında

```
tempdir="/var/lib/pgsql/11/temp"
mkdir -p $tempdir
chmod -R 700 postgres. $tempdir
```

Veritabanına psql ile giriş yapıyoruz.

```
--örnek dizin
create tablespace temp location '/var/lib/pgsql/11/temp';
```

`postgresql.conf` içerisine giriş yapıyoruz.

```
# bu satırı
temp_tablespaces = ''

# buna değiştiriyoruz.
temp_tablespaces = 'temp'


```

PostgreSQL'i reload ediyoruz.
```
# root yetkisindeyken
systemctl reload postgresql-11
# ya da
psql -c "select pg_reload_conf()"

```
`pg_tblspc` içerisine girip bakalım.

* Tablespaceler içerisine
temp, [database](https://www.postgresql.org/docs/11/sql-createdatabase.html), [tablo](https://www.postgresql.org/docs/11/sql-createtable.html) ya da [index](https://www.postgresql.org/docs/11/sql-createindex.html) konulabilir. Tablespaceler o cluster olmadan işe yaramazlar. [[+]](https://www.postgresql.org/docs/11/sql-createtablespace.html)
