# izleme

## sistemi izleme
```
top
df -h
iftop
```

## postgres istatistikler
### pg_stat_*

### pg_activity
### pgcenter

### zabbix hızlı kurulumu
```
apt install
```
docker run --name zabbix-server-pgsql -t \
      -e DB_SERVER_HOST="172.17.0.1" \
      -e POSTGRES_USER="postgres" \
      -e POSTGRES_PASSWORD="123" \
      -e POSTGRES_DB="zabbix" \
      -p 10051:10051 \
      -d zabbix/zabbix-server-pgsql:latest
