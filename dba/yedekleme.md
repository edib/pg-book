# Yedekleme

## mantıksal Yedekleme

```
pg_dumpall -r > roller.sql
create database  yeniyeri;
pg_dump -d eskidb -f eskidb.sql
cat eskidb.sql | psql -d yeniyeri
```

* pg_dump ve akrabaları
  * custom (-Fc)
  * directory (-Fd)
  * tar (-Ft)

```
# text dump alır
pg_dump {vt_adi} > dump.dosyasi.dmp

## yada
pg_dump {vt_adi} -f dump.dosyasi.dmp

# binary formatta alır, sıkıştırır sadece `pg_restore` komutuyla restore edilebilir.

pg_dump {vt_adi} -Fc dump.dosyasi.dmp

# sadece yapı
pg_dump {vt_adi} -Fc -s yapi.dump.dosyasi.dmp

# sadece veri
pg_dump {vt_adi} -Fc -a veri.dump.dosyasi.dmp

# clusterdaki herşeyi alır
pg_dumpall {vt_adi} -f all.dump.dosyasi.dmp


# replikalardan yedek almak için (db seviyesinde tutarsızlık olabilir.)

pg_dump -Fd -f <BACKUP_DIR> -j 20 <DB_ADI> -t <TABLO1>  -t <TABLO2> --no-synchronized-snapshots

pg_dump -Fd -f <BACKUP_DIR> -j 20 <DB_ADI> \
 -n <SCHEMA1>       \
 -n <SCHEMA2>  \
 -n <SCHEMA3> 


# bir dbyi restore
pg_restore --help
pg_restore -Fd <BACKUP_DIR> -d degerlidb -v
$ pg_restore -j 5 -c -d degerlidb dosya.db


-- Dizin dumptan sadece bir tablo alarak başka bir yere yüklemek istersek
-- pg_restore komutunu aşağıdaki şekilde çalıştırıyoruz ve dosya nolarının hangi tablonun verisi olduğu bilgisini görüyoruz. 
pg_restore -Fd <dizin_adi> -l | grep <tablo_adi> 
207; 1259 339841 TABLE <schema_adi> <tablo_adi> 

-- db ye gidip tablonun definition'ı çalıştırıp tabloyu create ediyoruz. 
create table ....;

-- sonrasında yukarıda bulduğumuz sıkıştılmış dosyası copy komutuna kaynak olarak veriyoruz. 

COPY <tablo_adi> from PROGRAM 'zcat /<path>/<dosya_no>.dat.gz' 

# doğrudan dizin yedeği, db servisinin kapalı olması gerek.
tar cvfz /tmp/yedek.tar.gz /var/lib/pgsql/11/data/

```



* restore
```
psql {vt_adi} < text.sql

pg_restore -d {vt_adi} dump.dosyasi.dump

```




  * Bir sonraki:
  [Örnek Veri](ornek_veri.md)


[Farklı kullanımları](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_postgresql_yedekleme.html#pg_restore)
