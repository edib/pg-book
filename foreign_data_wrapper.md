Postgresql'de Foreign Data Wrapper (fdw) başka veritabanı ya da veri kaynağını postgresql içerisine bağlayarak ondan standart sql komutlarıyla veri alınmasını varolan sisteminize entegre edilmesini sağlar.

3 adet vt oluşturuyoruz ve masterdb asıl vt, fdw1 ve fdw2 ise yabancı vt olarak çalışacaklar.
create database masterdb;
```
create database fdw1;
create database fdw2;
```
Yabancı vtlere tek tek bağlanıp basit tablo oluşturuyoruz.
```
\c fdw1
create table tb1 (id int, name text);
\c fdw2
create table tb2 (id int, name text);
```

Ana vtye bağlanarak  üzerinde postgres_fdw eklentisini etkinleştiriyoruz ve diğer 2 vtyi bağlantı parametreleriyle asıl vtye bağlıyoruz.
```
\c masterdb
--  https://www.postgresql.org/docs/current/static/sql-createextension.html 
create extension postgres_fdw;

CREATE SERVER fdw1
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '5432', dbname 'fdw1');

CREATE SERVER fdw2
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '5432', dbname 'fdw2');
```

```
--- değiştirmek istersek (hangi parametreyi değiştirmek istersek sadece onu yazıyoruz. örneğin port)
ALTER SERVER fdw1 OPTIONS (set port '5432');
-- cursor her veri çekişinde en fazla kaç row çekmelidir. Default 100
ALTER SERVER my_fdw OPTIONS (fetch_size '10000');
-- eğer fdw nin read only olmasını istiyorsak
ALTER SERVER my_fdw OPTIONS (updatable 'false');
```
fdw1 ve fdw2 deki yetkileri olan kullanıcıları buradaki bir kullanıcıya bağlantılıyoruz. Burada kolaylık olması için parola kullanılmamıştır.
```
CREATE USER MAPPING FOR postgres
        SERVER fdw1
        OPTIONS (user 'postgres', password '');

CREATE USER MAPPING FOR postgres
        SERVER fdw2
        OPTIONS (user 'postgres', password '');
```
Asıl vt üzerinde 2 adet schema oluşturuyoruz ve yabancı dbleri bunlara adresliyoruz ve tabloları kontrol ediyoruz ve 2 vtyide içeren sorgumuzu yazıyoruz.
```
create schema fdws1;
IMPORT FOREIGN SCHEMA public
    FROM SERVER fdw1 INTO fdws1;

create schema fdws2;

IMPORT FOREIGN SCHEMA public
    FROM SERVER fdw2 INTO fdws2;
```

-- Eğer sadece belirli tabloları import etmek istersek limit to ile o tabloları sınırlıyoruz.
```
IMPORT FOREIGN SCHEMA public
	LIMIT TO (table1, table2)
    FROM SERVER fdw2 INTO fdws2;

\d fdws1.tb1
\d fdws2.tb2

select id,name from fdws1.tb1 union  select id, name from fdws2.tb2;
```
Eğer superuser yetkisi olmayan bir kullanıcı için fdw tanımı yaparsak;
* server tanımı
```
CREATE SERVER fdw_server
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host '<ip_adresi', port '<port>', dbname '<dbadi>');
```
* kullanıcı eşlemesi: erişendeki bir pg kullanıcısıyla, erişilendeki kullanıcının eşlenmesi gerekmektedir. 

```
CREATE USER MAPPING FOR <local_user>
        SERVER fdw_server
        OPTIONS (user 'remote_user>', password '<password>');
```
* başka kullanıcıları da maplemek gerekirse her bir kullanıcı için eklemek gerekiyor.
```
CREATE USER MAPPING FOR <local_user>
        SERVER fdw_server
        OPTIONS (user 'remote_user>', password '<password>');
```
* local schema tanımı: bundan sonrasında eğer tüm şema bağlanacaksa erişende yeni bir şema oluşturulmalıdır.

```
create schema <local_schema>;
```
*loca schema ve fdw servera bağlanacak user için yetki veriyoruz.
```
grant all on schema <local_schema> to <local_user>;
GRANT all ON FOREIGN SERVER fdw_server TO <local_user>;

```
* <local_user> kullanıcısına geciyoruz
```
\c - <local_user> # ya da
set role= <local_user>;
```
* local userdan schemayı import ediyoruz.
```
IMPORT FOREIGN SCHEMA <remote_schema>
    FROM SERVER fdw_server INTO <local_schema>;
```
remote sunucuda ddl işlemleri olursa aynısının local taraftada tekrar edilmesi gerekmektedir. Aksi durumda çalışmaz.

```
# eğer fdw de bir tablo oluşturusak
CREATE foreign TABLE tb2 (a int, b text);
# aynısını fdw sunucusunda tekrar ediyoruz
CREATE foreign TABLE tb2 (a int, b text) server fdw_server;
```

Kaynaklar:
* [Postgresql Wiki Foreign_data_wrappers ](https://wiki.postgresql.org/wiki/Foreign_data_wrappers)
* [pgnx fdw ](http://pgxn.org/tag/fdw/)
* [Postgresql fdwhandler](https://www.postgresql.org/docs/current/static/fdwhandler.html)
