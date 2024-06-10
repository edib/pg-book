# Veritabanı Kümesi ,Veritabanları ve Tablolar

## Veritabanı Kümesinin Mantıksal Yapısı


Bir **veritabanı kümesi**, bir PostgreSQL sunucusu tarafından yönetilen bir veritabanları topluluğudur. Bir `base` dizini vardır. 

[vt yapısı](https://www.interdb.jp/pg/pgsql01/01.html)


```sql
CREATE DATABASE degerlidb;

CREATE DATABASE

-- veritabanların dizini
SELECT datname, oid FROM pg_database WHERE datname = 'degerlidb';
 datname |  oid  
---------+-------
 degerlidb    | 113748
(1 row)


\c degerlidb

-- tabloların gerçek dizinleri  
CREATE TABLE degerlitablo(i int);
CREATE TABLE

SELECT pg_relation_filepath('degerlitablo');
 pg_relation_filepath 
----------------------
 base/113748/113749
(1 row)

```


## Veritabanı Kümesinin Fiziksel Yapısı

### Veritabanı Kümesinin Düzeni

Bir **veritabanı kümesi**'nin bir `base` dizini vardır. 

[fiziksel yapı](https://www.interdb.jp/pg/pgsql01/02.html)

|dosyalar|açıklamalar|
|--- |--- |
|PG_VERSION|PostgreSQL'in ana sürüm numarasını içeren bir dosya|
|pg_hba.conf|PosgreSQL'in istemci kimlik doğrulamasını kontrol etmek için bir dosya|
|pg_ident.conf|PostgreSQL'in kullanıcı adı eşlemesini kontrol eden bir dosya|
|postgresql.conf|Yapılandırma parametrelerini ayarlamak için bir dosya|
|postgresql.auto.conf|ALTER SYSTEM'de ayarlanan yapılandırma parametrelerini depolamak için kullanılan bir dosya, özelleştirilmiş postgresql.conf|
|postmaster.opts|Sunucunun en son başlatıldığı komut satırı seçeneklerini kaydeden bir dosya|

[Dizinler](http://www.interdb.jp/pg/pgsql01.html)

### Veritabanları ve Tabloların Düzeni

```psql

degerlidb=# SELECT relname, oid, relfilenode FROM pg_class WHERE relname = 'degerlitablo';
  relname  |  oid  | relfilenode
-----------+-------+-------------
  degerlitablo | 113749 |      113749
(1 row)

```

* TRUNCATE, REINDEX, CLUSTER komutları tablolaların oidlerini ve filenode değiştirir.
* filenode'lar 1GB büyük olamaz. olursa arka tarafta numaralandırır. (relfilnode, relfilnode.1 şeklinde)


Her tablonun yanında '_fsm' ve '_vm' son ekine sahip iki ilişkili vardır.

`Visibility Map`: Her page içinde ölü kayıt olup olmadığını belirler. Vakum işleme, ölü kayıtları olmayan bir sayfayı atlayabilir. [Görsel](https://www.interdb.jp/pg/img/fig-6-02.png)

`free space map` : Tablolardaki boş alanlar hakkında bilgi depolar. insert ve update sorguları kullanır.

```sh
cd $PGDATA
ls -la base/16384/18751*
-rw------- 1 postgres postgres  8192 Apr 21 10:21 base/16384/18751
-rw------- 1 postgres postgres 24576 Apr 21 10:18 base/16384/18751_fsm
-rw------- 1 postgres postgres  8192 Apr 21 10:18 base/16384/18751_vm
```

### Tablespaces (Tablo alanları)

Temel dizinin dışındaki ek bir veri alanıdır.

[tablespace yapısı](http://www.interdb.jp/pg/img/fig-1-03.png)

`pg_tablespc` dizini altında symlinki durur. Onun içinde nesne oid ve asıl dizin neredeyse oraya bağlanmış. Tablespace'ler cluster olmadan bir işe yaramazlar. 

Symlink adı 
```sh
PG _ 'Major version' _ 'Catalogue version number'
```

```sh
ls -l /home/postgres/tblspc/
total 4
drwx------ 2 postgres postgres 4096 Apr 21 10:08 PG_14_202107181
```

## Bir Heap (yığın) Tablo Dosyasının İç Düzeni

Veri dosyası (tablo, index, vm, fsm vb.), sabit uzunlukta sayfalara (veya bloklara) bölünmüştür, varsayılan değer 8192 bayttır (8 KB). Her dosyadaki bu sayfalar 0'dan sıralı olarak numaralandırılır ve bu numaralara blok numaraları denir. Dosya doldurulmuşsa, PostgreSQL dosya boyutunu artırmak için dosyanın sonuna yeni bir boş sayfa ekler.

[pagefile yapısı](http://www.interdb.jp/pg/img/fig-1-04.png)

`heap tuple`: asıl veri
`line pointer`: offset number: heap tuplea referans veren pointer
`header data`: sayfayla ilgili ek bilgiler

DB boyutu 8k artacaktır devamlı. 

`CTID`: ("block number", "line pointer")

`TOAST (The Oversize-Attribute Storage Technique)`: boyutu yaklaşık 2 KB'den (8 KB'nin yaklaşık 1/4'ü) büyük olan `heap tuple` bu yöntem kullanılarak depolanır ve yönetilir.

## Kayıt Yazma ve Okuma Yöntemleri

### Heap Tuple yazma
[yöntem](http://www.interdb.jp/pg/img/fig-1-05.png)

* line pointer header data dan sonra ve tuple sondan başa doğru. 

### Heap Tuple okuma

* **Sequential scan**
* **Index scan**
* **TID-Scan**

```psql

sampledb=# SELECT ctid, data FROM sampletbl WHERE ctid = '(0,1)';
 ctid  |   data    
-------+-----------
 (0,1) | AAAAAAAAA
(1 row)

```



[yöntem](http://www.interdb.jp/pg/img/fig-1-06.png)


bileşenleri