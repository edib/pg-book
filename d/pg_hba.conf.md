# POSTGRESQL'e Erişim
* PostgreSQL kurulduğunda güvenlik ayarları olarak sadece localhost'u dinlemektedir.
* PostgreSQL'iin dinlediği IP listesi **postgresql.conf** dosyası içinde bulunur. Bu alan ön tanımlı olarak localhost olarak belirlenmiştir.
* Bu dosyanın değiştirilmesi işleminden sonra Postgresql servislerinin kapatılıp açılması gerekir.
  ```
  systemctl restart postgresql

  ```

* Postgresql'de erişim hakları **pg_hba.conf** dosyasında tanımlanır.

* **pg_hba.conf** dosyasında yapılan değişikliklerin PostgreSQL servisinin etkinleşmesi için "pg_reload_conf();" komutu kullanılır. Bu sayede işletim sistemine gitmeden işlem yapılabilir.

##  Host-based Authenticatiton
* İstemci erişimi denetimi bu dosyayla sağlanır.
* Varsayılanda sadece localhost erişimine izin verir. İlk kurulumda, dışarıdan erişime izin vermez.
* Her bir satırı 1 kayıttır.
* replication erişimi ayrı tanımlanır.
* [Doküman](https://www.postgresql.org/docs/11/auth-pg-hba-conf.html)
psql satırından,

```
show hba_file;
```

### İçeriği

```

local      database  user  auth-method  [auth-options]
host       database  user  CIDR-address  auth-method  [auth-options]
hostssl    database  user  CIDR-address  auth-method  [auth-options]
hostnossl  database  user  CIDR-address  auth-method  [auth-options]
host       database  user  IP-address  IP-mask  auth-method  [auth-options]
hostssl    database  user  IP-address  IP-mask  auth-method  [auth-options]
hostnossl  database  user  IP-address  IP-mask  auth-method  [auth-options]
```

### [auth-method]
* **trust** : Kullanıcıların veritabanına parolasız bağlanmasını sağlar.
* **rejet** : Erişimi reddeder.
* **md5**   : md5 formatında şifrelenmiş parola ile giriş gerektirir.
* **scram-sha-256: (v10 la birlikte geldi)[[+]](http://hacksoclock.blogspot.com/2018/10/how-to-set-up-scram-sha-256.html)** : sha-256 şifreleme
* **crypt** : Bağlantı için crypt formatında şifrelenmiş parola girmesi gerekir.
* **password** : Düz metin parola ile girişe izin verir.
* **pam** : İşletim sistemi tarafından sağlanan Pluggable Authentication Modules (PAM) servisini kullanarak bağlanmak için.
* **ldap** : bir LDAP sunucudan kullanıcı bilgilerini kullanmak için
* **radius** : bir RADIUS sunucudan kullanıcı bilgilerini kullanmak için
* **cert** : SSL istemci sertifikalarını kullanrak bağlanmak için.
* **ident** : işletim sistemi kullanıcısı, tcp port üzerinden bağlantı için
* **peer**: local, socket bağlantısı için

### [auth-options]
name=value
