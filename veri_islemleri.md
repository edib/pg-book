## Örnek Veri İşlemleri
#### copy komutuyla `veritabanı` içerisine veri aktarımı.
Bunun Türkiyenin illeri ve ilçeleri veri setini kullanıyoruz. `postgres` kullanıcında komut satırından aşağıdaki dosyaları indiriyoruz.

```
wget https://raw.githubusercontent.com/edib/publicdata/master/ilce.csv
wget https://raw.githubusercontent.com/edib/publicdata/master/il.csv
```
db de 2 tane tablo oluşturuyor ve aşağıdaki şekilde dosyaları içeri aktarıyoruz.
yeni bir `veritabanı` oluşturuyoruz ve bağlanıyoruz.

```
psql -c "CREATE DATABASE ornek"
psql ornek
```
psql komut satırından
```
--il tablosu
create table il (id serial, il_adi varchar);

--ilce tablosu
create table ilce (id serial, il_id int, ilce_adi varchar);

--il tablosunu doldur
\copy il (id_il_adi) from il.csv WITH CSV HEADER

--ilce tablosunu doldur
\copy ilce (il_id, ilce_adi) from ilce.csv WITH CSV HEADER

--verilere bakalım
select il.il_adi, ilce.ilce_adi from il
inner join ilce on
il.id = ilce.il_id;

```
