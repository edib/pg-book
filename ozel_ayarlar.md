## initdb özel ayarlar

* data-checksum'ı etkinleştirmek için
```
export PGSETUP_INITDB_OPTIONS="--data-checksums"
```

* Türkçe utf8 olarak oluşturmak için
```
export PGSETUP_INITDB_OPTIONS="-k --encoding='UTF-8' --lc-collate='tr_TR.UTF-8' --lc-ctype='tr_TR.UTF-8'"
```
[Diğer seçenekler için](https://www.postgresql.org/docs/11/app-initdb.html)


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
* Cluster oluşturulduğu zaman tekrar encoding değiştirmek mümkün değildir. Tek yöntem mantıksal yedeğini alıp başka bir Cluster oluşturup ona aktarmaktır.

## Dizini değiştirmek için
- örneğin /var/lib/pgsql/11/veri dizini
```
mkdir /var/lib/pgsql/11/veri
chown -R postgres. /var/lib/pgsql/11/veri
chmod -R 700 /var/lib/pgsql/11/veri
```
- systemd yöntemiyle cluster dizinini değiştiriyoruz.
```
systemctl edit postgresql-11.service
```
- açılan dosya içerisie aşağıdakini ekleyin.
```
[Service]
Environment=PGDATA=/var/lib/pgsql/11/veri
```
- yaptığınız ayarı etkinleştirin.
```
systemctl daemon-reload
```

#  postgres yöntemi
* Cluster oluşturma elle de yapılabilir.

```
dizin="/var/lib/pgsql/11/veri"
mkdir $dizin
chown -R postgres. $dizin
chmod -R 700 $dizin

# seçenek 1
sudo -u postgres /usr/pgsql-11/bin/initdb -D $dizin -k

# seçenek 2
sudo -u postgres /usr/pgsql-11/bin/pg_ctl init -D $dizin -o "-k"

## servisi başlat.
sudo -u postgers /usr/pgsql-11/bin/pg_ctl -D $dizin start
```
* eğer farklı dizin seçilirse paket yöneticisisinin systemd dosyasından cluster data dosyasının değiştirilmesi gerekir.
`/usr/lib/systemd/system/postgresql-11.service`

* Yerini hatırlamazsak  
```
vi `rpm -ql postgresql11-server | grep systemd`
```
Bu dosyanın içerisinde aşağıdaki satırı değiştiriyoruz.
```
# önceki
Environment=PGDATA=/var/lib/pgsql/11/data/

# sonraki
Environment=PGDATA=/var/lib/pgsql/11/veri/
```



```

# servisi başlangıçta çalışır şekilde aktif ediyor.
ll /etc/systemd/system/multi-user.target.wants/postgresql-11.service
systemctl enable postgresql-11
ll /etc/systemd/system/multi-user.target.wants/postgresql-11.service

# servisi başlatıyoruz.
systemctl start postgresql-11
