# containerized postgres version upgrade workshop

```
#create volume
docker volume create --name pg10

# lets see where the volume is
docker volume inspect pg10

# create an postgres instance in the volume
docker run -d -v pg10:/var/lib/postgresql/data --name pg10 postgres:10

# to test create something
docker exec -it pg10_upgrade bash
su - postgres
psql
> create database upgradetest;

# exit to the host
# on the host again

# stop pg10
docker stop pg10

# create pg11 volume
docker volume create --name pg11

# create a transition container with old and new volumes

docker run -d -v pg11:/var/lib/postgresql/data11 \
              -v pg10:/var/lib/postgresql/data10 \
              --name pg10_2_pg11_upgrade \
              postgres:11

# connect to the container
docker exec -it pg10_2_pg11_upgrade bash
su - postgres

# create a postgres 11 cluster in the data11 directory
/usr/lib/postgresql/11/bin/pg_ctl init -D /var/lib/postgresql/data11/

# there is an existing cluster in port 5432, not to conflict it, change the ports
echo "port=6432" >> /var/lib/postgresql/data10/postgresql.auto.conf
echo "port=7432" >> /var/lib/postgresql/data11/postgresql.auto.conf

# install postgresql 10 to the container (required for pg_upgrade)
apt update && apt install postgresql-10

# docker think that different volumes cannot be hardlinked, then we cannot use "-k" parameter.
# create a transition container with old and new volumes
/usr/lib/postgresql/11/bin/pg_upgrade \
   -b /usr/lib/postgresql/11/bin\ \
   -B /usr/lib/postgresql/11/bin\ \
   -d /var/lib/postgresql/data10\ \
   -D /var/lib/postgresql/data11\


# if upgrade is successfull then exit and remove the pg10_2_pg11_upgrade container
# create a new container with updagraded volume
docker run -d -v pg11:/var/lib/postgresql/data --name pg11 postgres:11

# you can remove the old volume unless needed.
docker volume rm pg10

   ```
