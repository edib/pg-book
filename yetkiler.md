# Yetkiler
* superuser (postgres): sınırlanamaz.
* Yetkiler nesneler üzerinden çalışır.
* Her nesne yaratıldığında o nesneye bir sahip atanır. Sadece sahibin `DROP`, `ALTER`  ve `REVOKE` yetkisi vardır. Gizli (implicit) şekilde nesne sahiplerine aittir ve atanamaz ve geri alınamaz.
* Varsayılan olarak `public` şemasında tüm rollerin nesne yaratma yetkisi ve yarattığı nesnelerde tam yetkisi vardır. "`ROLE` oluşturulduğu anda geri alınması gerekir."
* `with grant option` ile yetki verilen `ROLE` bu yetkiyi diğer kullanıcılara da aktarabilir.

### Postgres Kullanılabilir Yetkiler
* SELECT (COPY TO),

* INSERT (COPY FROM),

* UPDATE, DELETE (ayrıca SELECT yetkisine de ihtiyaç duyar),

* TRUNCATE, REFERENCES, TRIGGER, CREATE, CONNECT, TEMPORARY, EXECUTE, ve USAGE'tır.

* Yetkiler GRANT ile verilir ve REVOKE ile alınır.

```
-- mehmet kullanıcısına defter tablosunda UPDATE yetkisi vermek için
GRANT UPDATE ON defter TO mehmet;
--ve geri almak için
REVOKE UPDATE ON defter TO mehmet;
```
* `ALL` yetkisi özel bir yetkidir ve o nesneyle ilgili ilişkili tüm yetkileri o `ROLE`e verir.
* `PUBLIC` özel bir `ROLE`'dür  ve sistemdeki tüm diğer `ROLE`lere bir yetkiyi tanımlamak için kullanılır.
* Ayrıca `GROUP` rolleri çok fazla veritabanı rolü olduğu durumlarda bunları daha kolay yönetmeye yarar.


### Postgresql role temelli yetki sistemi kullanır.

```
CREATE USER/ROLE ...;

```

* `USER` login yetkisi olan bir `ROLE`'dür.  `ROLE`'lerde hiyerarşi olabilir. Yani bir `ROLE` diğer `ROLE`'ün altında yer alabilir. Yetkiler `ROLE`'lere bağlanır.

```
CREATE ROLE role1;
CREATE ROLE role2;
GRANT role2 to role1;

```
* Açıklaması
  - role1 role2 nin üyesi oldu.
  - role1, role2'nin bütün yetkilerini de devraldı, kullanabilir.
  - role1 `SET ROLE` diyerek role2'ye dönüşebilir.

* Sistemde varsayılan olarak tanımlı yetkiler, `LOGIN`, `SUPERUSER`, `CREATEDB`, `CREATEROLE`, `REPLICATION`.

* psql yetkileri gözden geçirmek için

```
postgres=# \dp
                              Access privileges
 Schema | Name | Type  |     Access privileges     | Column access privileges
--------+------+-------+---------------------------+--------------------------
 public | x    | table | postgres=arwdDxt/postgres |
(1 row)

```
* Yukarıdaki harflerin okunuşu:
  - <roladı>=xxxx -- role tanımlanmış yetkiler
  - =xxxx -- public rolüne tanımlanmış yetkiler.

* r- SELECT ("read")
* w- UPDATE ("write")
* a- INSERT ("append")
* d- DELETE
* D- TRUNCATE
* x- REFERENCES
* t- TRIGGER
* arwdDxt - tüm yetkiler (tablolar için)
* X- EXECUTE
* U- USAGE
* C- CREATE
* c- CONNECT
* T- TEMPORARY

– tables, schema, tablespaces - hiç bir yetki yok.
– databases - CONNECT, CREATE TEMP TABLE
– functions - EXECUTE
– languages - USAGE

search path

Linux sistemlerdeki PATH değişkenine benzer. Nesnelerin şemaya Postgresql.conf içerisinden değiştirilmediyse varsayılan search_path "$user", public'tir. Search_path'teki ilk şema aktif şema kabul edilir. Eğer tam yol verilmezse yaratılmak istenen her nesne aktif şema'da yaratılır. Eğer aktif olanda yoksa sırayla diğerlerinde aranır.

# sessionda tanımlamak için
SET search_path TO myschema, public;
Gizli şemalar

pgtempNN ve pg_catalog sırayla 1. ve 2. sırada aranır, sonra diğer şemalar aranır.

-- aktif şemayı görmek için
select current_schema();
-- search_path'teki tüm şemaları verir.
select current_schemas(true);
