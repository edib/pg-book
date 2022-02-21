# patroni HA

* 3 node
* pg kur: https://www.postgresql.org/download/linux/ubuntu/

* patroni kur

```
apt install python3-pip
pip3 install pysyncobj

# 5432 yi kullanacaksak tüm nodlarda 
pg_dropcluster 14 main

su - postgres

mkdir 14 patroni

```

cluster config yazma script

```

#! /bin/sh

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "wrong number of parameter!"
   echo
   echo "Syntax: bash setup_patroni.sh <name> <nodeself> <othernode1> <othernode2>"
   echo
}

if [[ $# -lt 4 ]]; then
     Help
     exit 1
fi

export NAME=$1
export NODEIP=$2
export NODE2=$3
export NODE3=$4

# NAME must be uniqe

# Apply needed changes on Patroni configuration file.
# https://www.techsupportpk.com/2020/02/how-to-create-highly-available-postgresql-cluster-centos-rhel-8.html
tee -a /etc/patroni/config.yml <<EOF

scope: postgres
name: ${NAME}

restapi:
    listen: ${NODEIP}:8008
    connect_address: ${NODEIP}:8008

raft:
  # a dir owner of which is postgres
  data_dir: /var/lib/postgresql/14/patroni
  self_addr: ${NODEIP}:2222
  partner_addrs:
  - ${NODE2}:2222
  - ${NODE3}:2222

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5
  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: ${NODEIP}:5432
  connect_address: ${NODEIP}:5432
  data_dir: /var/lib/postgresql/14/main
  bin_dir: /usr/lib/postgresql/14/bin
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
EOF

```

* tüm nodlarda sırayla
  
```
systemctl start patroni
```
* duruma bak

```
patronictl -c /etc/patroni/config.yml list

+ Cluster: postgres (7061712529073149378) --+----+-----------+
| Member   | Host       | Role    | State   | TL | Lag in MB |
+----------+------------+---------+---------+----+-----------+
| patroni1 | 10.0.0.226 | Leader  | running |  2 |           |
| patroni2 | 10.0.0.249 | Replica | running |  2 |         0 |
| patroni3 | 10.0.0.230 | Replica | running |  1 |         0 |
+----------+------------+---------+---------+----+-----------+

```