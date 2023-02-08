# pgbouncer


pgbouncer bir sunucu gibi bir portu dinleyerek çalışacağından dinleme adresini (\* tüm ip adresleri demektir), kullanıcı adı ve parola bilgilerinin bulunacağı dosyanın adresi ve auth\_type'ı yazıyoruz. Deneme olduğundan plain seçilmiştir. Diğer seçenekler [https://pgbouncer.github.io/config.html](https://pgbouncer.github.io/config.html) adresinde verilmiştir. Ayrıca pgbouncer üzerinde istatistikler ve temel operasyonları gerçekleştirebilmek için bi tane admin user tanımlayıp onu aşağıdaki gibi tanımlıyoruz ayrıca /etc/pgbouncer/userlist.txt içerisine md5  parolasını da girmek gerekmektedir.

#kurulum
```ini

# debian/ubuntu
apt install pgbouncer

```

```console
/etc/pgbouncer/pgbouncer.ini

# aşağıdaki satırı databases altına ekliyoruz. 
---- 

[databases]
pgdb = host=<pghost> dbname=<pgdb> user=<pguser>

[pgbouncer]
pool_mode = session
listen_port = 5432
listen_addr = *

```
Dosya içerisini aşağıdaki gibi değiştiriyoruz. 

```console
/etc/pgbouncer/userlist.txt

--- 

-- select * from pg_shadow; dan alabiliriz.
"<pguser>" "SCRAM-SHA-256$<iterations>:<salt>$<storedkey>:<serverkey>"
```


#/etc/systemd/system/multi-user.target.wants/pgbouncer.service dosyası içerisine security limits tanımı yapıyoruz. Centosta pgbouncer /etc/security/limits.conf dosyası içerisindeki değerleri okumamamaktadır ve max open files 1024'ü geçmiyor. 

```console

# pid : pgbouncer pid
 
 cat /proc/<pid>/limits
 
Limit                     Soft Limit           Hard Limit           Units    
Max cpu time              unlimited            unlimited            seconds  
Max file size             unlimited            unlimited            bytes    
Max data size             unlimited            unlimited            bytes    
Max stack size            8388608              unlimited            bytes    
Max core file size        0                    unlimited            bytes    
Max resident set          unlimited            unlimited            bytes    
Max processes             31678                31678                processes
Max open files            1024                 524288               files

```
  
```console
systemctl edit pgbouncer
 
#bunu ekliyoruz.
LimitNOFILE=65536
 
systemctl edit pgbouncer --full
 
#öncesi
ExecStart=/usr/bin/pgbouncer -d -q ${BOUNCERCONF}
 
# sonrası
LimitNOFILE=65536
ExecStart=/usr/bin/pgbouncer -d -q ${BOUNCERCONF}

```

Sonrasında pgbouncer servisini yeniden başlatıyoruz.

```console
systemctl daeomon-reload
systemctl start pgbouncer
 
 
# tekrar kontrol ediyoruz.
cat /proc/<pid>/limits
```

Sadece 

Bağlantıyı test ediyoruz.

```console
psql -h localhost -p 5432 -U <pguser> -d <pgdb>

```

Pgbouncer komut satırı monitor

https://pgbouncer.github.io/usage.html

doğrudan pgbouncer servisine sanki db gibi bağlanıyoruz.


 ```console

 $ psql -p 5432 -U pgbouncer pgbouncer

pgbouncer=# show help;
NOTICE:  Console usage
DETAIL:
  SHOW [HELP|CONFIG|DATABASES|FDS|POOLS|CLIENTS|SERVERS|SOCKETS|LISTS|VERSION]
  SET key = arg
  RELOAD
  PAUSE
  SUSPEND
  RESUME
  SHUTDOWN
# eğer dosyada config değişikliği yapmışsanız
RELOAD;
 
# genel istatistikleri görmek önemli
show lists;
 
 ```

**Sorun Giderme**

Aşağıdaki gibi hatalar alırsak; 

jdbc tabanlı clientlardan bağlanırken (örn. dbeaver) aşağıdaki gibi bir hata alabiliriz ve vt'ye bağlanamayız.

  

Bu durumda `pgbouncer.ini dosyası içerisinde [pgbouncer]` section altına virgülle ayırarak ekliyoruz.

```ini
ignore_startup_parameters = extra_float_digits, search_path

```

Read only connectionı failover için. 

```console
# pgbouncer.ini den connection stringi değiştiriyoruz.
Sonra
psql -h localhost pgbouncer <pgbounceradmin>
pause <db_name>;
reload;
resume <db_name>;
```
  

[auth_query kullanımı](https://www.enterprisedb.com/postgres-tutorials/pgbouncer-authquery-and-authuser-pro-tips)
