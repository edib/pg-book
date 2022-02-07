## Erişim ve Yetkilendirme 
 
* PostgreSQL kurulduğunda güvenlik ayarları olarak sadece localhost'u dinlemektedir.
* PostgreSQL'in dinlediği IP listesi **postgresql.conf** dosyası içinde bulunur. Bu alan ön tanımlı olarak localhost olarak belirlenmiştir.
* Bu dosyanın değiştirilmesi işleminden sonra Postgresql servislerinin kapatılıp açılması gerekir.
  
  ```
  systemctl restart postgresql

  ```

* Postgresql'de erişim hakları **pg_hba.conf** dosyasında tanımlanır.

* **pg_hba.conf** dosyasında yapılan değişikliklerin PostgreSQL servisinin etkinleşmesi için "pg_reload_conf();" komutu kullanılır. Bu sayede işletim sistemine gitmeden (systemctl) işlem yapılabilir.

##  Host-based Authenticatiton
* İstemci erişimi denetimi bu dosyayla sağlanır.
* Varsayılanda sadece localhost erişimine izin verir. İlk kurulumda, dışarıdan erişime izin vermez.
* Her bir satırı 1 kayıttır.
* replication erişimi ayrı tanımlanır.
* [Doküman](https://www.postgresql.org/docs/11/auth-pg-hba-conf.html)
* güvenlik duvarı gibi  kısıtla/izin ver ifadesiyle eşleşen ilk kayıta göre işlem yapar.
psql satırından yerini öğrenmek için, 

```
show hba_file;
```

### İçeriği

```
# TYPE  DATABASE     USER      ADDRESS       METHOD     [OPTIONS]
local      database  user  auth-method  [auth-options]
host       database  user  CIDR-address  auth-method  [auth-options]
hostssl    database  user  CIDR-address  auth-method  [auth-options]
hostnossl  database  user  CIDR-address  auth-method  [auth-options]
host       database  user  IP-address  IP-mask  auth-method  [auth-options]
hostssl    database  user  IP-address  IP-mask  auth-method  [auth-options]
hostnossl  database  user  IP-address  IP-mask  auth-method  [auth-options]
```

* USER:  
  * all: tüm kullanıcılar
  * user:
  * +group: bir rol
  * @file: bir dizindeki dosyadaki kayıtlara göre


### auth-method
* **trust** : Kullanıcıların veritabanına parolasız bağlanmasını sağlar.
* **rejet** : Erişimi reddeder.
* **md5**   : md5 formatında şifrelenmiş parola ile giriş gerektirir.
* **scram-sha-256: (v10 la birlikte geldi)[[+]](http://hacksoclock.blogspot.com/2018/10/how-to-set-up-scram-sha-256.html)** : sha-256 şifreleme
* **crypt** : Bağlantı için crypt formatında şifrelenmiş parola girmesi gerekir.
* **password** : Düz metin parola ile girişe izin verir.
* **pam** : İşletim sistemi tarafından sağlanan Pluggable Authentication Modules (PAM) servisini kullanarak bağlanmak için.
* **ldap** : bir LDAP sunucudan kullanıcı bilgilerini kullanmak için
* **radius** : bir RADIUS sunucudan kullanıcı bilgilerini kullanmak için
* **cert** : SSL istemci sertifikalarını kullanarak bağlanmak için.
* **ident** : işletim sistemi kullanıcısı, tcp port üzerinden bağlantı için
* **peer**: işletim sistemi kullanıcısı, socket bağlantısı için


### TYPE
* peer, ident: bir sistem kullanıcısını bir db kullanıcısına eşlemek mümkün.
  
```
pg_ident.conf
# MAPNAME       SYSTEM-USERNAME PG-USERNAME
birmap            fatma            appuser

pg_hba.conf
local   all     all                     peer map=birmap

```

### auth-options
name=value

### Güvenli Bağlantı

* SSL/TLS
* Ayar dosyalarında belirtilir.
* Güvenli olmayan bağlantı da eş zamanlı kullanılabilir.

[Detaylı kurulum](https://www.cybertec-postgresql.com/en/setting-up-ssl-authentication-for-postgresql/)


* VT bağlanma kısıtlama

```
create database othervalueabledb;

UPDATE pg_database SET datallowconn='false'
                  WHERE datname='othervalueabledb';
UPDATE 1

\c othervalueabledb
FATAL:  database "othervalueabledb" is not currently accepting connections
Previous connection kept

```

## Kullanıcı Yönetimi

```
# tüm kullanıcıları listeler

\du 

create user biruser;

create role birrole;

\h create user 

drop role/user biruser/birrole;

# roleler ve userlar kaldırılmadan önce sahip olduklarının devredilmesi veya kaldırılması gerekir. 

REASSIGN OWNED BY biruser TO ikinciuser;
DROP OWNED BY biruser;

bir rolü diğerine de verme

\h grant 

GRANT biruser TO ikinciuser;
REVOKE biruser FROM ikinciuser;

# yetkileri görmek
\dp 

```
* userlar role gibi davranabilir.

Örnek:

```
postgres=# CREATE ROLE baskauser NOLOGIN;
CREATE ROLE

postgres=# ALTER ROLE baskauser CREATEDB;
ALTER ROLE

postgres=# CREATE ROLE ucuncuuser LOGIN PASSWORD 'abcd12';
CREATE ROLE

postgres=# CREATE ROLE ikincirole LOGIN;
CREATE ROLE

postgres=# GRANT baskauser TO ikincirole;
GRANT ROLE

```
* grant edilmiş rollerin yetkilerini kullanmak için role geçmen gerek.

```
# baskauser'ın createdb yetkisi var.

psql -U ikincirole

create database hede124;
ERROR:  permission denied to create database

set role to baskauser;
create database hede124;

CREATE DATABASE

# eski role dönmek için

postgres=> RESET ROLE;
RESET

```

* Önemli viewler: 
  * `pg_user`  
  * `pg_roles`
  * `pg_shadow`

### column based security

```
create table t1 ( a int, b int);
insert into t1 
values (1,1),(2,2);

# rates tablosunda description alanı için 
grant select (a) on t1 to dbuser;

```
### row level security

* Satır düzeyinde güvenlik (Row level security-RLS), belirli veri satırlarının bir veya daha fazla rol için nasıl görüntüleneceğini ve çalıştığını kontrol etmek için ilkeler tanımlamak.
* Bir tabloya uygulayabileceğiniz ek bir filtredir. Bir kullanıcı bir tablo üzerinde işlem yapmaya çalıştığında, sorgu kriterlerinden veya diğer filtrelemelerden önce bu filtre uygulanır ve veriler güvenlik politikanıza göre daraltılır veya reddedilir.
* SELECT, INSERT, UPDATE ve DELETE gibi belirli komutlar için satır düzeyinde güvenlik politikaları oluşturabilir, TÜM komutlar için belirtebilirsiniz.
* superuser dışında herkesi etkiler. 

```
etkinleştirmek için
ALTER TABLE birtablo ENABLE ROW LEVEL SECURITY;

```

[Diğer security yöntemleri](https://www.enterprisedb.com/postgres-tutorials/how-implement-column-and-row-level-security-postgresql)

[Diğer işlemler](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_kullanici_yonetimi.html)