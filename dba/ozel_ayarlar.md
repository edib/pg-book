## initdb özel ayarlar

Pakette otomatik küme oluşturulmasını kapatın. [1](https://askubuntu.com/a/663673/23126)

## pg_createcluster


### Redhat Dağıtımlarında
* eğer farklı dizin seçilirse paket yöneticisisinin systemd dosyasından cluster data dosyasının değiştirilmesi gerekir.

`/usr/lib/systemd/system/postgresql-14.service`

* ikinci cluster'ı 1. den üretmek için

```
cp /usr/lib/systemd/system/postgresql-14.service /usr/lib/systemd/system/postgresql-14-5433.service

```

* Yerini hatırlamazsak  

```
vi `rpm -ql postgresql14-server | grep systemd`
```
Bu dosyanın içerisinde aşağıdaki satırı değiştiriyoruz.

```
# önceki
Environment=PGDATA=/var/lib/pgsql/14/data/

# sonraki
Environment=PGDATA=/var/lib/pgsql/14/veri/
```

* servisi başlangıçta çalışır şekilde aktif ediyor.

```
systemctl enable postgresql-14

systemctl edit postgresql-14

# bunu değiştiriyoruz.
Environment=PGDATA=/var/lib/pgsql/14/veri/

systemctl daemon-reload

systemctl cat postgresql-14
# en sonda

systemctl edit postgresql-14
# /etc/systemd/system/postgresql-14.service.d/override.conf
Environment=PGDATA=/var/lib/pgsql/14/veri/

systemctl daemon-reload

# servisi başlatıyoruz.
systemctl start postgresql-14

```

### cluster init ayarlarını değiştir.

* data-checksum'ı etkinleştirmek için
* Türkçe utf8 olarak oluşturmak için
* cluster path değiştirmek için

```
su - postgres
/usr/pgsql-14/bin/initdb --data-checksums --encoding='UTF-8' --lc-collate='tr_TR.UTF-8' --lc-ctype='tr_TR.UTF-8' --pgdata='/var/lib/pgsql/14/veri/'

# 2. cluster ise port değiştiriyoruz.
# posgresql.auto.conf içerisinde

```
[Servisi başlatmak](https://www.postgresql.org/docs/14/server-start.html)

[Diğer seçenekler için](https://www.postgresql.org/docs/14/app-initdb.html)


* encoding: karakterlerin bytelara dönüşüm algoritması (latin1'de farklı, utf-8'de farklı )
* ctype: Stringler karşılaştırması kurallarını koyar. Karakter sınıflandırması, büyük, küçük değişimi, diğer karakter özelliklerini belirler.[*](https://www.ibm.com/support/knowledgecenter/ssw_aix_71/com.ibm.aix.files/LC_CTYPE.htm)
* collation: karakter ve stringleri bir araya getirirken (collate) sıralama kurallarını belirler.
[*](https://dba.stackexchange.com/a/211588/97226)

```
# collation karşılaştırması (collate bölümündeki 3 farklı collate tipini tek tek seçerek farklı görebiliriz.)
SELECT name FROM unnest(ARRAY[
     string_to_array('ş Ş ü Ü ö Ö İ ğ Ğ ı ç Ç',' ')
]) name ORDER BY name COLLATE "C|en_US|tr_TR";
```
* PostgreSQL 12'ye kadar cluster oluşturulduğu zaman tekrar encoding değiştirmek mümkün değildir. Tek yöntem mantıksal yedeğini alıp başka bir Cluster oluşturup ona aktarmaktır.

#  postgres yöntemi
* Cluster oluşturma elle de yapılabilir.

```
# seçenek 1
sudo -u postgres /usr/pgsql-14/bin/initdb -D $dizin -k

# seçenek 2
sudo -u postgres /usr/pgsql-14/bin/pg_ctl init -D $dizin -o "-k"

## servisi başlat.
sudo -u postgers /usr/pgsql-14/bin/pg_ctl -D $dizin start
```
