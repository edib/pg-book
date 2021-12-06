## Virtualbox ve Vagrant kurulumu
İndirin ve kurun

## Vagrant Kurulumu

Vagrant kullanımı
Vagrant masaüstü ortamları için kod ile otomatik sanal makine oluşturma uygulamasıdır. Varsayılan olarak virtualbox kullanır. Windows ve linux hostlar üzerinde çalışır.
* Bir yerde sanal makinemizi tanıtıcı bir dizin oluşturup (Örn. postgres01) komut satırından dizine gidiyoruz ve  aşağıdaki komutu çalıştırıyoruz. Komut, eğer makinede yoksa centos7 imajını vagrant reposundan indirir.

```
vagrant init centos/7
```
Yukarıdaki komut bulunulan dizinde Vagrantfile adında bir config dosyası oluşturur. Dosyanın içini silip aşağıdaki satırları ekleyin ve hostname ve ip karşısındaki alanları değiştirin. Uygun ip blokları için [buraya](https://www.wikiwand.com/en/Private_network#/Private_IPv4_address_spaces) bakınız.

![Vagrant virtualbox ağ yapısı](https://user-images.githubusercontent.com/4180560/79636826-3e0d9d80-8183-11ea-8ced-eed33d53e184.png)


```
Vagrant.configure("2") do |config|
	config.vm.box = "generic/ubuntu2004"
	config.vm.network "private_network", ip: "10.11.12.13"
	config.vm.hostname = "pg13"
	config.vm.provision "shell", inline: <<-SHELL
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
  reboot
 SHELL
end
```
Bu dosyadan sanal makine aktif etmek için diyerek makineyi virtualbox altında poweron ederiz.

```
vagrant up
```
poweron süreci bittikten sonra ssh ile kendi yönlendirmesiyle bağlanabiliriz.Masaüstü komut satırını açıyoruz ve bu ip adresine ssh erişimi yapıyoruz.
```
ssh vagrant@<sanal_makine_ip>
# varsayılan parola: "vagrant"

```

## Postgres Kurulumu
pg sürüm 13 için ve ubuntu 20.04 için
https://www.postgresql.org/download/linux/ubuntu/ adresine gidin

```
# install repository package
yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# install server service
yum install -y postgresql11-server
```
Eğer cluster'ı başlatırken özel ayarlar yapmak istiyorsanız buraya başvurun.
[Özel initdb ayarları](ozel_ayarlar.md)
Yoksa aşağıdaki gibi devam edin.

```
# cluster ı oluşturuyor,
/usr/pgsql-12/bin/postgresql-12-setup initdb

# servisi başlangıçta çalışır şekilde aktif ediyor.
systemctl enable postgresql-12

# servisi başlatıyoruz.
systemctl start postgresql-12

# postgresqle giriş yapabiliriz.

su - postgres
psql
-- bağlandığımız sürümü görmek için
SHOW server_version;
select version;

```
'psql' komut satırından çalışan ve sunucu kurulumuyla birlikte gelen gelişmiş bir istemcidir. psql'in parametrelerini görmek için
```
psql --help
 ```

## Sunucu Yönetimi

### Cluster
Postgres çalışan servisi ve onun veri dizini birlikte `cluster` denmektedir.
Postgres servisinin paket yerleri, dağıtıma göre değişir. Bir makine üzerine tercih edilmemekle birlikte birden çok cluster kurulabilir.
* Tek servis ve port
* Tek veri dizini
* Tek ayar dosyası/dosya grubu
* Dağıtık cluster değildir.
* Veritabanı sunucusu'da denir.


* **RPM**

```
Binaries: /usr/pgsql-${version}/bin
Data: /var/lib/pgsql/${version}/data

```

**`Cluster` yönetimi**
* pg_ctl utility
* init.d scripts / systemd services



Postgresql ayar dosyaları: Önemli diyebileceğimiz 2 farklı ayar dosyası vardır.
## [postgresql.conf](postgresql.conf.md) [*](https://postgresqlco.nf/en/doc/param/)
varsayılan yeri ```/var/lib/pgsql/12/data```. Cluster'ın çalışması gereken tüm ayarları içerir. İçinde bir çok parametre vardır. postgresql.conf a alternatif olarak postgresql.auto.conf dosyası da özel ayarların yazılması için kullanılabilir.
## [pg_hba.conf](pg_hba.conf.md)
İstemci erişimi denetimi bu dosyayla sağlanır.

* Bir sonraki:
[psql istemci komutları](psql.md)
