# POSTGRESQL VERİ TİPLERİ ( DATA TYPES )

PostgreSQL'de veri tiplerini;

* Sayısal Türler
* Para Türleri
* Metin Türleri
* Tarih Saat Türleri
* Binary Data Türleri
* Geometrik Türler
* Ağ Adres Türleri
* JSON Türleri
* XML Türü
* Diziler
olarak ana başlıkları altında inceleyebiliriz.

Yanlış veri tipi seçimi , veritabanımızın gereksiz büyümesine ve verimsizleşmesine neden olur. Veri tipi seçimi veritabanı performansını doğrudan etkiler.

# Sayısal Türler

## Tamsayı tipleri

* Integer   (4 bytes): Veritabanında kapladığı alan ve performansı dikkate alındığında en iyi dengeyi sağladığı için, çok fazla kullanılan bir veri türüdür.
* Smallint  (2 bytes): Küçük değerlerde tamsayı verilerini saklamak için kullanılır.
* BigInt    (8 bytes): Büyük değerlerde tamsayı veriileri saklamak için kullanılan veri türüdür. Integer alanının yetersiz kaldığı durumlarda tercih edilmelidir.

## Değişken hassasiyetli sayılar

* Bu türdeki veri tipleri kesinliğin gerekli olduğu ondalıklı sayılarda kullanılmalıdır. Matematiksel işlem sonuçlarını saklamada tercih edilmelidir. Performans olarak tam sayı tiplerine oranla yavaştır. Değişken hassasiyeti kullanıcı tarafından belirlenmektedir.

```
NUMERIC (precision, scale)
```

iki farklı değer verilerek oluşturulur.

## Kayan nokta türleri ( floating-point types )

* Real ve Double Precision veri türleri değişken hassas sayısal türlerdir. Bazı değerler bu veri tiplerinden tam olarak dönüştürülemez ve yaklaşık değer olarak depolanır.

## Seri Tipleri

* Bu türler Smallserial, Serial, ve Bigserial veri tipleridir. Bu veri tipinden bir kolon oluşturmak istediğimizde PostgreSQL bir adet Sequence oluşturarak sahipliğini, kolon oluşturmak istediğimiz tablo yapar ve kolonun varsayılan değeri olarak oluşturulan Sequence'i verir.

## Para Türleri

* Money veri tipi sabit hassasiyetli bir para değerini saklamak için kullanılır.

## Metin Veri Türleri

Her türden veri rahatlıkla depolandığı için saklanmak istenilen veri tipi bilinmiyor ise, metin veri tipinde bir alan oluşturularak bu alanda veri saklanır. Sayısal tiplere göre okuma oldukça yavaştır.

* character varying(n), varchar(n) -> Sınırlı değişken uzunluk
* character(n), char(n)            -> Sabit uzunluk
* Text                             -> Değişken sınırsız uzunluk

## Binary Veri Türü
Binary depolamak için imkan sağlar.

## Tarih / Saat Türleri

* Timestamp : Tarih ve saatin birlikte tutulduğu veri tipidir. Mikrosaniye hassasiyetinde veri tutmamıza imkan verir.
* Date      : Sadece tarih verisinin tutulduğu veri tipidir. Saatin önemsiz olduğu durumlarda tercih edilmelidir.
* Time      : Sadece saat verisinin tutulduğu veri tipidir.
* Interval  : Zaman aralığı saklamak için kullanılan veri tipidir.

## Boolean Türü

* 3 farklı değer alabilir. "true" , "false" ve "Null"

## Geometrik Türler

Bu veri türleri iki boyutlu uzaysal nesneleri temsil eder.

* point   (16 byte) :  Sayı düzlemi.
* line    (32 byte) :  Sonsuz hat.
* box     (32 byte) :  Dikdörtgen kutu.
* Circle  (24 byte) :  Daire.

## Ağ Adres Türleri

Ağ adreslerini depolamak için düz metin türleri yerine bu türleri kullanmak daha iyidir; çünkü bu türler hatalı veri girişine izin vermez, veri uyumsuzluğu hatası olarak geri döner.

* Cidr  (7 veya 19 byte) : IPV4 ve IPv6 ağları.
* Inet  (7 veya 19 byte) : IPV4 ve IPv6 barındırıcılar ve ağlar.
Varchar yerine ağ adres türlerini kullanmak;  IP/ağ doğrulamasının veritabanı tarafından otomatik yapılmasını sağlar.

# Veri Tipi Seçilirken Dikkat Edilmesi Gereken Unsurlar

## Metin veri tipi seçilirken;
* Karakter uzunluğu kaç olacak.
* Eksik uzunlukta ise eksik yerler boşlukla(null) doldurulacak mı ?
* İstediğim tip özel tiplerde var mı?

## Sayı veri tipleri seçilirken ;
* Ondalık basamak ihtiyacım var mı?
* Ondalık basamak hassasiyeti kaç olmalıdır?
* Üst limit kaç olmalıdır.
* Negatif sayı girebilecek miyim?

## Tarih veri tipi seçilirken;
* Sadece tarih mi olacak?
* Sadece saat mi olacak?
* Saat ve tarih birleşik mi olacak?
* Saat hassasiyeti ne olacak?

# DOMAIN

DOMAIN'i hazır tip kalıpları olarak düşünebiliriz. Bu sayede oluşturulan benzer alanlar aynı özellikte olmuş olur.

* Bir domain oluşturduğumuz zaman, bir veri tipinin kısıtlı bir alt veri tipini oluşturmuş olursunuz.

# COMPOSITE TYPES

Birleştirilmiş tipler olarak ifade edilebiliriz.

Kullanımı:

```
CREATE TYPE typ_ogrenci AS (
    ogrenci_no BIGINT,
    ad  VARCHAR(50),
    soyad VARCHAR(50)
);
```
Oluşturduğumuz yeni veri tipini, bir veri satırı olarak düşünebilirsiniz.Bu özelliği sayesinde tablomuzda bir alan içerisinde bir satır veri saklamamızı sağlar.

* Oluşturduğumuz yeni veri tipimizin bir tablo içinde kullanımı:
```
CREATE TABLE tb_ogrenci_not (
    ogrenci public.typ_ogrenci,
    ders_adi VARCHAR(30),
    ders_notu SMALLINT
) ;
```
 **Veri giriş şekli** :
```
INSERT INTO tb_ogrenci_not (
  ogrenci,ders_adi,ders_notu)
VALUES ((1,'ada','lovelace'), 'postgresql', 100);

```
Burada görüldüğü gibi ogrenci alanındaki tüm bilgiler aynı alanda gelmiştir.
* Bu alandaki verileri ayrı görmek için aşağıdaki şekilde sorgumuzu yazabiliriz:
```
SELECT (ogrenci).* FROM tb_ogrenci_not ;
```

* Oluşturduğumuz Composite Types verisinin bir alanına göre sorgulama yapmak istersek :

```
SELECT (ogrenci).ad FROM tb_ogrenci_not WHERE (ogrenci).ad = 'Ada' ;
```
* Eğer veri tipinin tüm alt değerlerini değiştirmek istersek :

```
UPDATE tb_ogrenci_not SET ogrenci = (101,'marie','curie')
WHERE (ogrenci).ogrenci_no=2;
```


# UUID ( Universally Unique Identifier ) TÜRLER

UUID'ler belirli bir algoritma kullanarak benzersiz bir sayı üretmeyi sağlar. Bu sayı 128 bitlik ve 36 karakter uzunluğundadır.
Veri gösteriminde standart olarak 8-4-4-4-12 formatında ve hepsi küçük harf olarak gösterilir.

UUID örnekleri :
```
 5545f312-9818-11e9-ac0c-525400261060
 5456f6fe-9818-11e9-ac0c-525400261060
 52b0b3e4-9818-11e9-ac0c-525400261060
```

```
CREATE TABLE tb_ogrenci(id uuid, ad varchar(50), soyad varchar(50));
```
tb_ogrenci tablosunda ID alanının veri tipini UUID veri tipinde oluşturduk.

 **UUID Veri Üretmek**

PostgreSQL'de UUID veri üretmek için uuid-ossp modülünü yüklememiz gerekir.

```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
Modül yüklendikten sonra şu şekilde UUID üretebiliriz :

```
SELECT uuid_generate_v1();
```

ID alanımızın varsayılan değerine UUID üreten fonksiyonumuzu atayalım:
```
CREATE TABLE tb_ogrenci2(
    id uuid DEFAULT uuid_generate_v4(),
    ad varchar(50),
    soyad varchar(50)
);
```
UUID veri tipinde bir kolon oluşturmak için standart kolon ekleme yöntemleri kullanılır. Sadece veri tipi yerine UUID ifadesi kullanılır.


# JSON ( JavaScript Object Notation ) Veri Tipi

JSON veri türleri; JSON türünde veri saklamak için kullanılan bir veri tipidir. Metin tabanlı, dilden bağımsız ve kendine özgü bir formatı bulunur.
Diğer formatların aksine JSON, insan tarafından okunabilen bir metindir.

**JSON veri tipi kullanımı**

```
CREATE TABLE tb_ogrenci_dersler(
    ID serial NOT NULL PRIMARY KEY,
    ogrenci_id Integer,
    dersler jsonb);
```
Bu tabloda dersler alanı JSONB veri tipinde oluşturulmuştur.
