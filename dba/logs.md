# Loglar

### Log Analizi : PgBadger

PgBadger öngereksinimler ve kurulum:

```sql
# yum install perl-ExtUtils-MakeMaker make httpd
$ git clone https://github.com/dalibo/pgbadger.git
$ cd pgbadger
$ perl Makefile.PL
$ make && sudo make install
```

`postgresql.conf`’a aşağıdaki gibi log ayarlarını ekleyelim ve PostgreSQL’i yeniden başlatalım:

```sql
# vim /var/lib/pgsql/9.6/data/postgresql.conf
log_min_duration_statement = 0
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0

systemctl restart postgresql
```

Derlenmiş binary’yi global bir yere taşıyıp Apache’yi başlatalım ve raporu günün loglarından yarattırıp web dizinine koyalım::

```sql
# cp /home/oyas/pgbadger/pgbadger /usr/bin/

# systemctl start httpd

# pgbadger -f stderr -s 10 -q -o /var/www/html/pgbadger/report_`date +\%Y-\%m-\%d`.html /var/lib/pgsql/9.6/data/pg_log/postgresql-Mon.log
```

### Log Analizi : pg_query_analyser

Öngereksinimler ve kurulum:

```bash
yum install make gcc-c++ qt-devel
git clone https://github.com/WoLpH/pg_query_analyser.git
cd pg_query_analyser/
qmake-qt4
make && sudo make install
```

*postgresql.conf*’a pgbadger’daki gibi log ayarlarını ekleyelim, sadece prefix farklı:

```bash
# vim /var/lib/pgsql/9.6/data/postgresql.conf
log_line_prefix = '%t [%p]: [%l-1] host=%h,user=%u,db=%d,tx=%x,vtx=%v '

# systemctl restart postgresql-9.6
```

Yine PgBagder’da olduğu gibi Apache dizinine log analizi raporunu çıkartıyoruz:

```bash
./pg_query_analyser -i /var/lib/pgsql/9.6/data/pg_log/postgresql-Mon.log -o /var/www/html/report.html
```