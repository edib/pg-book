# VT İşlemleri

## VT Yönetimi

```
CREATE DATABASE degerlidb;
CREATE DATABASE
```


```
\h create database
Command:     CREATE DATABASE
Description: create a new database
Syntax:
CREATE DATABASE name
    [ [ WITH ] [ OWNER [=] user_name ]
           [ TEMPLATE [=] template ]
           [ ENCODING [=] encoding ]
           [ LOCALE [=] locale ]
           [ LC_COLLATE [=] lc_collate ]
           [ LC_CTYPE [=] lc_ctype ]
           [ TABLESPACE [=] tablespace_name ]
           [ ALLOW_CONNECTIONS [=] allowconn ]
           [ CONNECTION LIMIT [=] connlimit ]
           [ IS_TEMPLATE [=] istemplate ] ]

URL: https://www.postgresql.org/docs/14/sql-createdatabase.html

```
* PUBLIC şeması: varsayılan olarak bağlandığımızda eriştiğimiz yer. 
* tüm nesneler bunun içinde oluşur. 
* kullanıcıların bu şemaya erişimini kesmek gerek. (best practice)

```
REVOKE ALL ON SCHEMA public FROM benimkullanici;

ALTER ROLE birrole SET search_path TO birsema,baskasema;

```

* [Önemli Komutlar](https://tubitak-bilgem-yte.github.io/pg-yonetici/docs/05-veritabani-yonetimi/postgres_veritaban%C4%B1_islemleri/)

### tablespaces
* https://tubitak-bilgem-yte.github.io/pg-yonetici/docs/05-veritabani-yonetimi/tablespace/

### partitioning
* https://tubitak-bilgem-yte.github.io/pg-yonetici/docs/05-veritabani-yonetimi/partitioning/
* https://hevodata.com/learn/postgresql-partitions/

### fdw
#### [postgres_fdw](d/fdw.md)
* https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_fdw.html#postgres_fdw
* https://wiki.postgresql.org/wiki/Foreign_data_wrappers

#### mysql_fdw
* https://github.com/EnterpriseDB/mysql_fdw
* https://www.alibabacloud.com/help/en/doc-detail/143613.htm
