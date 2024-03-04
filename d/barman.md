# barman 
* RPO: zero data loss, sync backup
* Örnekler: https://docs.pgbarman.org/release/3.2.0/

## backup sunucusuna kurulum
## kullanıcılar
```
create user barman password '<birparola>';

create user streaming_barman password '<birparola>' replication;

GRANT EXECUTE ON FUNCTION pg_backup_start(text, boolean) to barman;
GRANT EXECUTE ON FUNCTION pg_backup_stop(boolean) to barman;
GRANT EXECUTE ON FUNCTION pg_switch_wal() to barman;
GRANT EXECUTE ON FUNCTION pg_create_restore_point(text) to barman;

GRANT pg_read_all_settings TO barman;
GRANT pg_read_all_stats TO barman;
```

## pg_hba ayarları
* barman normal user gibi

```
host    all             barman             <barman_host>/32            scram-sha-256

```
* streaming_barman replication için ulaşacak
```
host    replication     streaming_barman             <barman_host>/32            scram-sha-256

```

## config
* template i orj conf yapalım. 
  
```
cp /etc/barman.d/streaming-server.conf-template /etc/barman.d/streaming-server.conf

```

* /etc/barman.d/streaming-server.conf düzenleyelim.
* primary sunucumuzun adı node1 olsun.


```
[node1]
; Human readable description
description =  "Example of PostgreSQL Database (Streaming-Only)"

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PostgreSQL connection string (mandatory)
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
conninfo = user=barman password=<barpass> host=<primaryip> dbname=postgres


; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PostgreSQL streaming connection string
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; To be used by pg_basebackup for backup and pg_receivewal for WAL streaming
; NOTE: streaming_barman is a regular user with REPLICATION privilege
streaming_conninfo = user=<replicauser> password=<replicapassword> host=<primaryip>

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Backup settings (via pg_basebackup)
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
backup_method = postgres
;streaming_backup_name = barman_streaming_backup

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WAL streaming settings (via pg_receivewal)
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
streaming_archiver = on
slot_name = barman
create_slot = auto
;streaming_archiver_name = barman_receive_wal
;streaming_archiver_batch_size = 50

; PATH setting for this server
path_prefix = "/usr/lib/postgresql/14/bin"

```
# ek 
```
# local backup alırken bunu yapmam gerekti
barman switch-xlog --force --archive  node1
```


## cron 
* cron olarak wal archive'ı ayarlayalım.
  
```
barman cron

Starting WAL archiving for server node1
Starting streaming archiver for server node1

```

## check  
* herşey ok mi kontrol edelim.
```
barman check node1

Server node1:
	PostgreSQL: OK
	superuser or standard user with backup privileges: OK
	PostgreSQL streaming: OK
	wal_level: OK
	replication slot: OK
	directories: OK
	retention policy settings: OK
	backup maximum age: OK (no last_backup_maximum_age provided)
	backup minimum size: OK (34.0 MiB)
	wal maximum age: OK (no last_wal_maximum_age provided)
	wal size: OK (0 B)
	compression settings: OK
	failed backups: OK (there are 0 failed backups)
	minimum redundancy requirements: OK (have 1 backups, expected at least 0)
	pg_basebackup: OK
	pg_basebackup compatible: OK
	pg_basebackup supports tablespaces mapping: OK
	systemid coherence: OK
	pg_receivexlog: OK
	pg_receivexlog compatible: OK
	receive-wal running: OK
	archiver errors: OK


```
## backup

```
barman backup node1

Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20220205T192101
Backup start at LSN: 0/14000060 (000000010000000000000014, 00000060)
Starting backup copy via pg_basebackup for 20220205T192101
WARNING: pg_basebackup does not copy the PostgreSQL configuration files that reside outside PGDATA. Please manually backup the following files:
	/etc/postgresql/14/main/postgresql.conf
	/etc/postgresql/14/main/pg_hba.conf
	/etc/postgresql/14/main/pg_ident.conf

Copy done (time: 4 seconds)
Finalising the backup.
This is the first backup for server node1
WAL segments preceding the current backup have been found:
	000000010000000000000013 from server node1 has been removed
	000000010000000000000014 from server node1 has been removed
Backup size: 34.0 MiB
Backup end at LSN: 0/16000000 (000000010000000000000015, 00000000)
Backup completed (start time: 2022-02-05 19:21:01.036029, elapsed time: 4 seconds)
Processing xlog segments from streaming for node1
	000000010000000000000015


```

## diğer komutları

* `barman diagnose` : json report üretir. 
* `barman list-servers`: aktif sunucuların listesi


* primaryden tüm streaming replicationları gösterir. 

```
barman replication-status node1

Status of streaming clients for server 'node1':
  Current LSN on master: 0/160000C8
  Number of streaming clients: 2

  1. Async standby
     Application name: 14/main
     Sync stage      : 5/5 Hot standby (max)
     Communication   : TCP/IP
     IP Address      : 10.0.0.248 / Port: 47412 / Host: -
     User name       : replicauser
     Current state   : streaming (async)
     Replication slot: node3
     WAL sender PID  : 1532
     Started at      : 2022-02-05 16:42:57.667887+00:00
     Sent LSN   : 0/160000C8 (diff: 0 B)
     Write LSN  : 0/160000C8 (diff: 0 B)
     Flush LSN  : 0/160000C8 (diff: 0 B)
     Replay LSN : 0/160000C8 (diff: 0 B)

  2. Async WAL streamer
     Application name: barman_receive_wal
     Sync stage      : 3/3 Remote write
     Communication   : TCP/IP
     IP Address      : 10.0.0.224 / Port: 39484 / Host: -
     User name       : replicauser
     Current state   : streaming (async)
     Replication slot: barman
     WAL sender PID  : 6561
     Started at      : 2022-02-05 19:13:17.921818+00:00
     Sent LSN   : 0/160000C8 (diff: 0 B)
     Write LSN  : 0/160000C8 (diff: 0 B)
     Flush LSN  : 0/16000000 (diff: -200 B)

```

* backupları listeleyelim

```
barman list-backups node1

node1 20220205T192101 - Sat Feb  5 19:21:05 2022 - Size: 50.0 MiB - WAL Size: 0 B

```

* backup dosyalarını listeler

```
barman list-files node1 20220205T192101
```

## restore

* pg çalışırken yapmayın. 


```
barman recover <server_name> <backup_id> /path/to/recover/dir

```

