# POSTGRESQL VERİTABANI NESNELERİ  

## PostgreSQL Nesneleri

* Servis (Service)
* Veritabanı (database)
* Table (Tablo) : Veri saklamak için kullanılan nesnelerdir.
* Schema (Şema) : Veritabanı içerisinde bulunan nesneleri mantıksal olarak gruplamaya yarar. Bilgisayarımızdaki klasör mantığına benzer.
* Tablespace    : Veritabanındaki nesnelerin saklandığı fiziksel alandır.
* View : Karmaşık sorguları basitleştirmek için kullanılmaktadır.
* Function : Veritabanı içinde işlem yapmamızı sağlayan nesnelerdir.
* operators: Sembol fonksiyonlar, özelleştirilebilir.
* Casts: bir veri tipini diğerine döndürür.
* Sequence (Artan Sayı): Sequence nesneleri PostgreSQL'de otomatik olarak artan sayıları takip etmek için kullanılan veritabanı nesnesidir.
* Extensions: Extra özellikler
* Constraints (Koşullar) : Veritabanı katmanında istenirse verilerin belirli şartlara uygunluğu kontrol edilebilir. Bu kontroller için Constraint'ler kullanılır.
* İndeks (Dizi) : İndeksler tablolarda bulunan verilere daha hızlı ulaşmamızı sağlayan veritabanı nesneleridir.

# POSTGRESQL'DE TABLO

* Bir tablo oluşturulurken,içinde bulunğu Schema'dan bulunan Tablo, Sequence, Index, View, ve diğer tablo isimlerinden farklı olmalıdır.
* İsimlendirme yaparken büyük harf ve Türkçe karakter kullanmamaya dikkat edilmelidir.
* Tablolar en fazla fiziksel yer kaplayan nesnelerdir.

## Tablo Oluşturma

**CREATE TABLE** ifadesi ile tablo oluşturulur.

En basit kullanım şekli:
```
CREATE TABLE tablo_adi(
    kolon_adi1 veri_tipi,
    kolon_adi2 veri_tipi );
```

```
CREATE TABLE tb_il (id Integer, il_adi Varchar(50));
```
Oluşturduğumuz bu tabloya hiçbir kontrol eklemedik.

```
postgres=# DROP TABLE tb_il ;
DROP TABLE
```
```
postgres=# CREATE TABLE public.tb_il (
id serial NOT NULL UNIQUE,
id_adi varchar(50) NOT NULL UNIQUE );
CREATE TABLE
```
## Column Constraints

* **NOT NULL** : Sütunun değeri boş "NULL" olamaz.
* **NULL**  : Sütun değeri boş "NULL" olabilir. Varsayılan değeridir. Değer verilmezse bu değer işletilir.
* **CHECK** : Insert ve Update işlemlerinde girilen verinin CHECK içinde belirtilen şarta uygunluğunu kontrol eder.
* **DEFAULT** Sütuna dışardan veri girilmez ise, yani NULL bırakılır ise girilecek veri buraya yazılır.
* **UNIQUE** : Sütunun değeri tüm tabloda, sütun için benzersiz olmalıdır. NULL dışındaki veriler için QUIQUE işletilir
* **PRIMARYKEY** : Sütun için "NOT NULL" ve "UNIQUE" kısıtlamalarını beraber işletir.
* **REFERANSLAR** : Sütunun içerdiği verinin başka bir tabloda varlığı kontrol edilir.

Öncelikle referans tablo olabilmesi için bölümler tablosunu oluşturuyoruz. Tablomuzu *public* scheması içinde oluşturalım.

```
postgres=# CREATE TABLE public.tb_bolumler(
id SERIAL NOT NULL,
bolum_adi Varchar(50) NOT NULL UNIQUE,
PRIMARY KEY(id));
CREATE TABLE
```
*Öğrenciler tablosu oluşturulurken bölümler tablosu referans alınmıştır. Girilen bölüm bilgisibölümler tablosunda yok ise veritabanı kabul etmeyecektir.*

```
postgres=# CREATE TABLE public.tb_ogrenci(
id SERIAL NOT NULL,
ogrenci_no BIGINT NOT NULL UNIQUE CHECK (ogrenci_no> 0),
adi VARCHAR(50) NOT NULL,
soyadi VARCHAR(50) NOT NULL,
tc_kimlik_no BIGINT NOT NULL UNIQUE CHECK (tc_kimlik_no> 10000000000),
bolum_id INTEGER NULL,
PRIMARY KEY(id),
CONSTRAINT tb_ogrenci_fk FOREIGN KEY (bolum_id)
REFERENCES public.tb_bolumler(id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE) ;
CREATE TABLE
```
## Table Constraints ( Tablo Kısıtlamaları )

* Tablo kısıtlamaları, bir sütuna değil de tüm tabloya uygulanması dışında sütun kısıtlamalarına benzer.

## Parametreler

* TEMPORARY veya TEMP: Parametrelerinden biri kullanılırsa geçici tablo oluşturulur. Geçici tablo ve varsa indeksleri oturum sonunda silinir.
* IF NOT EXISTS : Belirtilen Schema içinde aynı isme sahip bir başka tablo varsa hata dönmez uyarı verir. Devamında yapılan işlemleri kesmez.
* COLLATE : Kolonda kullanılan veri tipi uygunsa, kolan için bir Collection belirler.
* INHERITS : Başka bir tablodan kalıtım olucaksa burada belirtilir.
* LIKE : Tablo oluştururken başka bir tablodan veri kopyalamak için kullanılır.
* TABLESPACE : Oluşturulan tablonun hangi Tablespace'de olucağını belirtilir.

**IF NOT EXISTS** kullanımı:

```
postgres=# CREATE TABLE IF NOT EXISTS public.tb_ogrenci(
id SERIAL NOT NULL,
ogrenci_no BIGINT NOT NULL UNIQUE CHECK (ogrenci_no> 0),
adi VARCHAR(50) NOT NULL,
soyadi VARCHAR(50) NOT NULL,
tc_kimlik_no BIGINT NOT NULL UNIQUE CHECK (tc_kimlik_no > 10000000000),
bolum_id INTEGER NULL,
PRIMARY KEY(id));
CREATE TABLE
```
**LIKE** ile öğrenci tablosunu kopyalayalım.
```
postgres=# CREATE TABLE public.tb_ogrenci_kopya ( LIKE public.tb_ogrenci INCLUDING ALL );
CREATE TABLE
```
*Kopyaladığımız tablonun içini doldurmak için :*

```
postgres=# INSERT INTO public.tb_ogrenci_kopya SELECT * FROM public.tb_ogrenci;
```

# TEMEL TABLO İŞLEMLERİ

## CREATE TABLE AS
CREATE TABLE AS ifadesi, SQL sonuç çıktısında belirtilen isimde bir tabloya çevirir. Kolon isimlerini ve veri tiplerini SQL'den gelen kolon isimleri ve tiplerine göre belirler.

Örneğimizde bölümü bilgisayar olan öğrencileri bir tabloda toplayalım :

```
postgres=# CREATE TABLE public.tb_ogrenci_bilgisayar AS
SELECT og.id,
og.ogrenci_no,
og.adi,
og.soyadi,
og.tc_kimlik_no,
og.bolum_id
FROM public.tb_ogrenci og
LEFT JOIN public.tb_bolumler b on b.id = og.bolum_id
WHERE b.bolum_adi = 'Bilgisayar' ;
```

* Oluşturduğumuz tablonun içine bakarsak sadece bilgisayar bölümü öğrencilerinin olduğunu görürüz:

```
SELECT * FROM public.tb_ogrenci_bilgisayar;
```
* Daha kısa yazmak istersek;

```
postgres=# CREATE TABLE public.tb_ogrenci_bilgisayar AS
SELECT og.*
FROM public.tb_ogrenci og
LEFT JOIN public.tb_bolumler b on b.id = og.bolum_id
WHERE b.bolum_adi = 'Bilgisayar';
```
şeklinde de yazabiliriz.

## Tabloda Değişiklik Yapma

* Var olan bir tablo yapısında değişiklik yapmak için **ALTER TABLE** ifadesi kullanılır.

**Kullanımı:**

* Bir tabloya yeni bir kolon eklemek için **ALTER TABLE ADD COLUMN**  ifadesi kullanılır:
  ```
  postgres=# ALTER TABLE public.tb_ogrenci ADD COLUMN kayit_tarihi DATE;
  ```
* Var olan bir kolonu kaldırmak için **ALTER TABLE DROP COLUMN** ifadesi kullanılır:
  ```
    postgres=# ALTER TABLE public.tb_ogrenci DROP COLUMN kayit_tarihi ;
    ALTER TABLE
  ```
* Var olan bir kolonu yeniden adlandırmak için **ALTER TABLE RENAME COLUMN TO** ifadesi kullanılır.
    ```
    postgres=# ALTER TABLE public.tb_ogrenci RENAME COLUMN kayit_tarihi TO kayit_olma_tarihi;
    ALTER TABLE
    ```
* Kolonun varsayılan değerini değiştirmek için **ALTER TABLE ALTER COLUMN SET DEFAULT** ifadesi kullanılır.
  ```
  postgres=# ALTER TABLE public.tb_ogrenci ALTER COLUMN  kayit_olma_tarihi SET DEFAULT 'now()';
  ALTER TABLE
  ```
* Kolonun varsayılan değerini silmek için **DROP DEFAULT** ifadesi kullanılır:
  ```
  postgres=# ALTER TABLE public.tb_ogrenci ALTER COLUMN kayit_olma_tarihi DROP DEFAULT ;
  ```
* Tablonun herhangi bir kolonunda **NOT NULL** kısıtlaması eklemek veya kaldırmak için **ALTER TABLE ALTER COLUMN** ifadesi kullanılır.
  ```
  postgres=# ALTER TABLE public.tb_ogrenci ALTER COLUMN kayit_olma_tarihi SET NOT NULL ;
  ```
  ***İPUCU*** :  **NOT NULL** eklenmek istenen kolon boş veriler içeriyorsa, veritabanı size hata verecek **NOT NULL** şartını eklemeyecektir. Öncesinde bu alanlara değer
  girmeniz gerekir.
* Tabloya bir **CHECK** eklemek için **ALTER TABLE ADD CHECK** ifadesi kullanılır:
  ```
  postgres=# ALTER TABLE public.tb_ogrenci ADD CHECK (ogrenci_no > 100);
  ```
* Bir sınırlama eklemek **ALTER TABLE ADD CONSTRAINT** :
  ```
  postgres=# ALTER TABLE public.tb_ogrenci ADD CHECK (ogrenci_no > 100);
  ```
* Tabloda **FOREIGN KEY** bir koşul ekleyeceksek;
    ```
    postgres=# ALTER TABLE public.tb_ogrenci ADD CONSTRAINT distfk FOREIGN KEY (bolum_id) REFERENCES public.tb_bolumler(id);
    ```
* Tablomuza **UNIQUE** bir koşul ekleyeceksek;
    ```
    postgres=# ALTER TABLE public.tb_ogrenci ADD CONSTRAINT ogrenci_no_tekil UNIQUE (ogrenci_no) ;
    ```
* Var olan bir tablonun ismini değiştirmek isterseniz, **ALTER TABLE RENAME TO** ifadesi kullanılır:
  ```
  postgres=# ALTER TABLE public.tb_ogrenci RENAME TO tbnew_ogrenci;
  ```

## TABLO SİLME

Tablo silmek için **DROP TABLE** ifadesi kullanılır.

```
postgres=# DROP TABLE tb_ogrenci;
```
* Bu işlem sonunda tablo verisi dosya düzeyinde silinecektir. Tabloya bağlı olan tüm Index, Rule, Trigger ve Constraint'ler de silinecektir.
* Silinmek istenen tablonun kullanıldığı bir View ve **FOREIGN KEY** ile bağlı başka bir tablo var ise, silmek istediğinizde hata alırsınız.

**Parametreler** :

* **IF EXISTS** : Silinmek istenilen tablo ise hata dönmesini engeller; sadece uyarı verir.
* **CASCADE** : Silinmek istenilen tablo içinde başka bir nesneye bağlayan bir constraint var ise, bağlı olan nesne ile silinmesine imkan verir.
* **RESTRICT** : Varsayılan değerdir. Herhangi bir değer verilmezse kullanılır. Bir bağımlılık varsa hata döner.

### Tablo TRUNCATE

* **TRUNCATE** ifadesi tablodaki tüm verileri hızlı bir şekilde silmek için kullanılır.
* Veri satırı üzerinde **DELETE** komutuyla aynı işi yapar.
* Veri üzerinde tarama yapmadığı ve işlem sonunda disk alanını da temizlediği için **VACUUM** gerektirmez.

*Öğrenci tablosundaki tüm verileri silelim:*

```
postgres=# TRUNCATE TABLE tb_ogrenci;
TRUNCATE TABLE
```
## TEMP TABLO

* Bazen hesaplama yapmak veya süreç içinde daha rahat veriye ulaşmak için geçici olarak verileri saklamamız gereken durumlar olabilir. Bu durumlarda **TEMP TABLE** nesnesi kullanılabilir.
* Bu nesne oluşturulduğu oturum içinde var olur ve oturum sonlandığında kaldırılır.
* TEMP TABLE oluşturulurken Schema adı verilmez.
* Kullanımı **TABLO** nesnesiyle aynı özelliktedir.

# POSTGRESQL'DE TABLESPACE

* Tablespace'ler bize nesneleri farklı alanlarda saklama imkanı sunar.
* Bir Tablespace superusers olan kullanıcıların veritabanı nesnelerini (Tablolar, indexler vb.) içerecek dosyalar için dosya sisteminde yeni bir yer tanımlamaya imkan verir.
* **pg_default** ve **pg_global** PostgreSQL'deki varsayılan olarak bulunan Tablespacelerdir.

**Kullanımı**

* dbspace adında bir tablespace oluşturalım, dosya yolu ise "/data/dbs" olsun:
  ```
    postgres=# CREATE TABLESPACE dbspace LOCATION '/data/dbs';
  ```
* superuser kullanıcısı için indexspace adında bir Tablespace oluşturalım.
  ```
  postgres=# CREATE TABLESPACE indexspace OWNER superuser LOCATION '/data/indexes';
  ```
* **public** şemasında bulunan **tabloları** ve **Tablespace**'leri görmek için şu kumutu kullanabilirsiniz:
  ```
  SELECT tablename, tablespace FROM pg_tables WHERE schemaname = 'public' ;
  ```

**TABLESPACE KALDIRMAK**
* Bir Tablespaceyi kaldırmak için **DROP TABLESPACE** komutu kullanılır.
**TABLESPACE DÜZENLEMEK**
* Tablespace düzenlemek için **ALTER TABLESPACE** komutu kullanılır.

*Tablespace adının değiştirelim:*
```
postgres=# ALTER TABLESPACE dbspace RENAME TO genel_alan;
ALTER TABLESPACE
```
*genel_alan tablespace'nin sahibini değiştirelim.*

```
ALTER TABLESPACE genel_alan OWNER TO yazilim_grubu;
```
# CONSTRAINTS ( KISITLAMALAR )

* Veritabanında sakladığımız verilerin belirli şartları sağlaması gerekebilir. Örneğin, öğrenci notlarını veritabanında saklayacaksak girilen değerlerin sayısal olmasını bekleriz. Bu tür genel kısıtlamalarda veri tipi seçeneklerini kullanabiliriz. Ancak veri tipi üzerinden yapılan kısıtlamalar çok genel ve çoğu zaman eksik kalır. Örneğin, öğrenci notu 0 ile 100 arasında olacak dediğimiz zaman bunu sağlayacak bir veri tipimiz yoktur.PostgreSQL'de kolon içindeki saklanan verilerin kontrolü ve kısıtı için değişik **CONSTRAINTS** bulunmaktadır.

## CONSTRAINTS Çeşitleri :
* **CHECK** Constraint (Uyumluluk kontrolü)
* **Not-null** Constraint (Boşluk kontrolü)
* **UNIQUE** Constraint (Tekillilik kontrolü)
* **Primary Key**  (Birincil anahtar kontrolü)
* **Foreign Key** (Referans Anahtar kontrolü)
* **Exclusion** Constraint (Hariç tutma kontrolü)

## **CHECK** Constraint

* Belirli bir sütuna girilen değeri belirtilen şartlara uygunluğunu kontrol eder.

```sql 
CREATE TABLE public.tb_ogrenci_notlar(
ogrenci_id integer,
ders_id Integer,
vize1 INTEGER DEFAULT 0 CHECK (vize1 > 0),
vize2 INTEGER CHECK (vize2> 0) DEFAULT 0,
final INTEGER CHECK (final = (vize1 + vize2)/2::INTEGER));

```

* Örneğimizde görüldüğü üzere kısıtlama ifademiz veri tipinden sonra gelmelidir. Veri tipinden sonra gelen diğer bir ifade de **DEFAULT** değerdir.
* Kısıtlamamızda **CHECK** ifadesinden sonra parantez içinde istenilen şartlar yazılmalıdır.

*Aynı kolonda birden fazla kontrol yapılmak istenirse*

```sql

CREATE TABLE public.tb_ogrenci_notlar(
ogreci_id integer,
ders_id integer,
vize1 integer default 0  check (vize1> 0 and vize1 <=100),
vize2 integer default 0 check (vize2 > 0 and vize2 <=100),
final integer CONSTRAINT vize_final_not_uyumsuzlugu CHECK (final = (vize1 + vize2)/2::INTEGER and final > 0));

```

* Sonradan tabloya **CHECK** Constraint eklemek istersek **ALTER TABLE** ifadesi kullanılır:

```sql

ALTER TABLE public.tb_ogrenci_notlar ADD CHECK (final> 0 and final<=100 );

```

* Var olan bir **CHECK** Constraint'i silmek için **ALTER TABLE** ifadesi şu şekilde kullanılır.
  
```sql

ALTER TABLE public.tb_ogrenci_notlar DROP CONSTRAINT vize_final_not_uyumsuzlugu;

  ```
  
## **NOT NULL** Constraint

* **IS NULL**: Bu ifade değerin **NULL** olduğunu kontrol eder.(vize1 is NULL) ifadesinde vize1 değeri **NULL** ise olumlu; değilse olumsuz dönecektir.
* **IS NOT NULL**: Değerin NULL olmadığını kontrol etmek için kullanılır.
* PostgreSQL'de bir kolonun **NULL** dan farklı bir değer girilmesi gerektiğinde **NOT NULL** Constraint'i kullanılır.

```sql
CREATE TABLE public.tb_ogrenci_notlar(
ogreci_id integer NOT NULL,
ders_id integer NOT NULL,
vize1 integer default 0  check (vize1> 0 and vize1 <=100),
vize2 integer default 0 check (vize2 > 0 and vize2 <=100),
final integer CONSTRAINT vize_final_not_uyumsuzlugu CHECK (final = (vize1 + vize2)/2::INTEGER and final > 0));
```

* Var olan bir tablonun kolonuna **NOT NULL** kontrolü eklemek için **ALTER TABLE** ifadesi kullanılır.

## **UNIQUE** Constraint

* Benzersiz kısıtlaması, bir tabloda bir kolonun veya kolon grubunun tablodaki satırlar içinde takrarını önleyen bir kontroldür.
* Öğrenci No ve TC Kimlik No alanlarını tekrara izin vermeyecek şekilde oluşturalım.

```sql
CREATE TABLE IF NOT EXISTS public.tb_ogrenci2(
id SERIAL NOT NULL,
ogrenci_no BIGINT UNIQUE,
adi VARCHAR(50) NOT NULL,
soyadi VARCHAR(50) NOT NULL,
tc_kimlik_no BIGINT UNIQUE,
bolum_id INTEGER NULL);
```

* Var olan bir tablonun kolonuna **UNIQUE** kısıtı eklemek isterseniz **CREATE UNIQUE INDEX** komutu kullanılır:

```sql
CREATE UNIQUE INDEX ogrenci_no_unique_index ON public.tb_ogrenci(ogrenci_no);
```

## Primary Key Constraint

* Primary key istenilen sütunların benzersiz ve boş olmamasını sağlayan bir index oluşturur.
* NOT NULL ve UNIQUE kısıtlamalarının birleşmiş hali denilebilir.

```sql
postgres=# CREATE TABLE IF NOT EXISTS tb_ogrenci (
ID INTEGER PRIMARY KEY,
ad VARCHAR(50),
soyad Varchar(50),
Tc_kimlik_no BIGINT );
```

* Örneğimizde ID alanını **PRIMARY KEY** olarak tanımladık.
* Birden fazla sütunun **PRIMARY KEY** olarak tanımlanması gerekirse:

```sql
CREATE TABLE IF NOT EXISTS tb_ogrenci (
ID INTEGER ,
ad VARCHAR(50),
soyad Varchar(50),
Tc_kimlik_no BIGINT,
PRIMARY KEY (ID, Tc_kimlik_no) );
```

* Sonradan Primary Key eklemek istersek, ilk önce eklenmek isnenen sütunda tekrar eden kayıt var mı, kontrol etmemiz gerekir. Var ise bu kayıtları silmeliyiz. Aksi takdirde ***duplicated*** hatası alınır.

**Primary Key** Kaldırmak:  

* Var olan birincil anahtar kasıtlaması kaldırmak için, **ALTER TABLE** ifadesi kullanılır:

```sql
ALTER TABLE tb_ogrenci DROP CONSTRAINT tb_ogrenci_pkey ;
```

## Foreign Key Constraint

* Bir sütun veya sütun grubundaki değerlerin başka bir tablonun bazı satırlarında görünen değerlerle eşleşmesi gerektiğini belirtir, ilgili iki tablo arasındaki referans bütünlüğünün korunmasını sağlar.

```sql
CREATE TABLE public.tb_ogrenci (
id SERIAL NOT NULL,
ad VARCHAR(50) NOT NULL,
soyad VARCHAR(50) NOT NULL,
tc_kimlikno BIGINT NOT NULL UNIQUE,
primary key(id) );
```

* ID sütununda Primary Key olduğunu kaçırmayalım.*

```sql
CREATE TABLE public.tb_ogrenci_notlar (
id SERIAL NOT NULL,
ogrenci_id INTEGER,
ders_adi VARCHAR(50),
notu NUMERIC(5,2),
primary key(id),
FOREIGN KEY (ogrenci_id) REFERENCES tb_ogrenci (id) ) ;
```

* **FOREIGN KEY (ogrenci_id) REFERENCES tb_ogrenci (id)** ifadesi ile tb_ogrenci_notlar tablosunun ogrenci_id sütununu referans göstererek tb_ogrenci tablosunun ID sütununa bağladık.


# SCHEMA KAVRAMI

* Veritabanı içindeki klasörlere benzer.
* Oluşturulan şema içinde Tablolar, View'lar, Index'ler Sequence'ler, Veri Tipleri, Operatörler ve fonksiyonlar bulunabilir.
* Şema içinde oluşturulan nesneler aynı isimde olamaz.
* PostgreSQL ilk kurulduğunda **public** şeması oluşturulmuş olarak gelir.

## ŞEMA OLUŞTURMAK
* Bir veritabanında şema oluşturmak için **CREATE SCHEMA** ifadesi kullanılır:
  ```
  CREATE SCHEMA schema_adi;
  ```
* Bir şemanın sahipliği onu oluşturan kullanıcıya aittir. Sahipliği farklı schema oluşturmak istersek :
  ```
  CREATE SCHEMA schema_adi AUTHORIZATION kullanci_adi;
  ```
## ŞEMA SİLMEK

* Var olan bir şemayı silmek için **DROP SCHEMA** komutu kullanılır.
  ```
  DROP SCHEMA sema_adi;
  ```
* Bu komut içi boş şemaları silecektir. İçinde oluşturulmuş nesne varsa hata fırlatacaktır. İçindeki tüm nesnelerle beraber bir şemayı silmek için:
  ```
  DROP SCHEMA sema_adi CASCADE;
  ```
## PUBLIC ŞEMASI
* Bir veritabı ilk oluşturulduğunda "Public" şeması ile oluşturulur.
* Ayarları değiştirilmemiş bir veri tabanında varsayılan şema Public şamasıdır.
* Herhangi bir isim verilmeden oluşturulan nesneler varsayılan şema altında oluşturulur.

## VARSAYILAN ŞEMA

* Bir veritabanında birden fazla şema var ise, şema adı vermeden yapılan işlemler varsayılan şema belirtilmiş gibi çalışır. Varsayılan şema değiştirilmediği sürece Public şemasıdır.
* Varsayılan şemayı **SEARCH_PATH** ifadesi ile görebiliriz :
  ```
  SHOW search_path;
  ```
* Çoklu şema kullanıldığı durumlarda daha rahat kullanım için bazen varsayılan şemayı değiştirmek gerekebilir:
  ```
  SET search_path TO sema_adi;;

  -- bir kullanıcıyı temelli değiştirmek
  ALTER ROLE username SET search_path = schema1,schema2,schema3,etc;
  ```
# POSTGRESQL'DE SEQUENCE'LER

* Sequence nesneleri PostgreSQL'de otomatik olarak artan sayıları takip etmek için kullanılan veritabanı nesnesidir.
* Sequence'ler smallserial, serial, bigserial tipinde olarak 3 çeşit oluşturulabilir.
* Bu nesne, genellikle bir tabloya eklenecek olan bir kayda bir ID ayarlamak için kullanılır.
* Sequence değeri her istekte bir artırılacaktır. Transaction hata alsa veya Rollback yapılsa dahi artış devam edecektir.

## SEQUENCE Oluşturulması

* **CREATE SEQUENCE** ifadesi ile oluşturulur.
* Oluşturulan isim ile yeni bir özel tek satırlık tablo oluşturulur. Komutu çalıştıran kullanıcı Squence'nin sahibi olur.
* Bir Sequence oluşturulduktan sonra, kullanmak için **nextval**, **currval** ve **setval** komutları kullanılır.

*Şimdi bir Sequence oluşturalım :*

Bir kolonu Sequence bağlarken 3 farklı durum olabilir.
* Yeni tablo oluştururken.
* Var olan tabloya kolon eklerken
* Var olan tablonun var olan kolonuna Sequence bağlayarak.

1. Yeni tablo oluştururken istediğimiz kolonun veri tipini **serial** vermemiz yeterli olacaktır:

```
    postgres=# CREATE TABLE public.tb_ogrenci (
    id SERIAL,
    ad VARCHAR(20),
    soyad VARCHAR(20) );
```
2. Var olan tabloya kolon eklerken yeni eklenen kolunun veri tipinin serial verilmesi:
```
postgres=# ALTER TABLE tb_ogrenci ADD COLUMN no SERIAL;
```
3. Var olan bir tablonun var olan bir kolonuna sequence eklemek istersek;
   * Yeni Sequence oluşturulur.
   * Tablonun kolonunun varsayılan değerine Sequence'in değeri verilir.

## SEQUENCE Manipülasyon İşlemleri

* PostgreSQL Sequence nesneleri genellikle bir tablo içinde **IDENTITY** oluşturmak için kullanılır.

* **nextval** : Sequence için sonraki ardaşık sıralı değeri döndürür. Bu otomatik yapılır.
* **currval** : Oturum içinde alınan en son değeri döner.
* **lastval** : Son üretilen değeri döner.
* **setval**  : Sequence nesnesinin sayaç değerini değiştirmek için kullanılır.

## SEQUENCE'DE Değişiklik Yapmak

* Bir Sequence'de değişiklik yapmak için **ALTER SEQUENCE** komutu kullanılır.

* **OWNED BY**
  ```
  ALTER SEQUENCE sequence_adi **OWNED BY** yeni_tablo_adi.kolon_adi;
  ```
* **OWNER TO**
  ```
  ALTER SEQUENCE sequence_adi **OWNED TO** kullanici_adi;
  ```
* **SET SCHEMA**
  ```
  ALTER SEQUENCE sequence_name **SET SCHEMA** yeni_şema_adi;
  ```

## SEQUENCE SİLİNMESİ

**DROP SEQUENCE** komutu ile silinir.

*Bir sequence sadece sahibi ya da superuser kullanıcı tarafından silinebilir*.
```
    DROP SEQUENCE [IF EXISTS] sequence_adi [, ... ] [CASCADE | RESTRICT]
```

# INDEKSLER

* İndeksler, veritabanı performansını arttırmak için kullanılan önemli nesnelerdendir.İndeks olan bir alanda arama yapıldığı zaman indeksler, aramanın çok daha hızlı sonuçlanmasını ve istenilen bilgiye ulaşılmasını sağlar.
* Gereksiz indeks kullanımı veritabanı performansını olumsuz etkiler. Ayrıca indeksler fiziksel yer kapladıkları için gereksiz indekslerin bir de depolama maliyeti olacaktır.
* Küçük tablolar, büyük parti **INSERT** ve **UPDATE** olan tablolar ve çok fazla NULL içeren kolonların olduğu durumlarda indeks oluşturmamak daha iyi olacaktır.


## İndeks Oluşturmak

Indeks **CREATE INDEX** komutu ile oluşturulur.

###Parametreleri :

**UNIQUE** : Var olan tablo için oluşturuluyorsa önce verilerin tekilliğini kontrol eder. Verinin benzersiz olmasını sağlar.
**CONCURRENTLY** : Fazla veri içeren tabloya index eklenmek istenildiğinde tablo index oluşumu sırasında kilitlenir ve işlem yapılamaz. Bunu önlemek için kullanılır.
**USING** (metod) : indeksin hangi methodu kullanacağı burada belirtilir.btree, hash, gist, spgist ve brin metotlarından biri seçilebilir.

**CREATE INDEX** söz dizisinin en basit hali :
```
CREATE INDEX index_adi ON tablo_adi (kolon_ adi)
```
*Bu şekilde oluşturulan indexin B-tree olur varsayılan olarak*

* Çoklu kolonlu index oluşturma :
  ```
  CREATE INDEX index_adi ON tablo_adi USING btree (kolon_adi1,kolon_adi2,kolon_adi3);
  ```
* Kısmi İndex (Partial Index) : Bir tablonun içindeki, belirli şartlara uyan verilerin indexlenmesi işlemidir. Bu yöntemde performans ve disk işlemlerinde size avantaj sağlayacaktır.
*Elinizde milyon satırlık müşteri bilgisi bulunan bir tablo düşünün. Bu tablo içinde sadece 1990 - 2001 yılları arasında doğan müşteriler için kampanya planlaması yaptığınızı varsayalım  

```
CREATE INDEX index_adi ON tb_müsteri (dogum_tarihi) WHERE dogum_tarihi between '1990-01-01' and '2001-12-31';
```

* Tekil INDEX (UNIQUE INDEX) : Bu tür indexler sadece performans için değil, aynı zamanda veri bütünlüğünü sağlamak içinde kullanılır. Verilen kolon veya kolonların içerdiği verilerin tablo içinde benzersiz olarak tutulmasını sağlar.
  ```
  CREATE UNIQUEINDEX index_adi ON tablo_adi (kolon_adi);
  ```
* Dahili Index ( Implicit Index ) : Birincil anahtar (primary key) ve benzersiz (unique) kısıtlamaları için indexler otomatik oluşturulur.
* Zamanlı Index (Concurrent Index): Index oluştururken, index oluşacak oluşacak tabloda bir lock. Bu durumda tablo üzerinde işlem yapılamaz. Bu durumlarda indexin tablo üzerinde bir lock oluşturmadan yapılabilmesi için **CONCURRENT** ifadesi kullanılır.
  ```
  CREATE INDEX CONCURRENTLY index_adi ON tablo_adi (kolon_adi,kolon_adi2)
  ```
* Index silmek için **DROP INDEX** ifadesi kullanılır.

# VIEW'LAR

* İçerisinde SQL sorgusu saklayan bir veritabanı nesnesidir. Varsayılan olarak nesne içerisinde veri saklamazlar.
* Çağrıldıkları anda içersinde bulunan SQL cümlesi yorumlanarak, SQL sonucu geri dönderilir.
* Birden fazla tablodaki karışık verileride birleştirerek verilere ulaşmamızı sağlar. Bu nedenle karmaşık verilere ulaşmakta oldukça faydalı nesnelerdir.
* View'ları oluştururken **CREATE VIEW** komutu kullanılır.

# FONKSİYONLAR

* Fonksiyonlar veritabanı seviyesinde işlem yapmamıza izin veren nesnelerdir. Yaptığımız proje içinde, basit ya da karmaşık işleri veritabanı seviyesinde yapmamızı sağlar.
* PostgreSQL'de bir fonksiyon oluşturmak için **CREATE FUNCTION** ifadesi kullanılır:
* Bir fonksiyonu silmek için **DROP FUNCTION** komutu kullanılır.
