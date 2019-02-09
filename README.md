# pg-dba-egitim

## Virtualbox ve Vagrant kurulumu
İndirin ve kurun

## Vagrant Kurulumu

Vagrant kullanımı
Vagrant masaüstü ortamları için kod ile otomatik sanal makine oluşturma uygulamasıdır. Varsayılan olarak virtualbox kullanır. Windows ve linux hostlar üzerinde çalışır.
# centos7 imajını eğer makinede yoksa vagrant reposundan indirir varsa imajı alıp yeni maline oluşturur.  
```
vagrant init centos/7
```
Yukarıdaki komut bulunulan dizinde Vagrantfile adında bir config dosyası oluşturur. Çoğu satırı comment li aşağıdaki satırları aktif bir dosya oluşturur.

```
Vagrant.configure("2") do |config|
	config.vm.box = "centos/7"
end
```
Bu dosyadan sanal makine aktif etmek için diyerek makineyi virtualbox altında poweron ederiz.

```
vagrant up 
```
poweron süreci bittikten sonra ssh ile kendi yönlendirmesiyle bağlanabiliriz.

```
vagrant ssh
```
Vagrant varsayılan olarak hostla sadedece "vagrant ssh" ile etkileşime geçen ve internete çıkabilen bir sanal makine çalıştırır. Eğer hostun ve diğer vagrant smlerin (sanal makine) doğrudan konuşabileceği bir makine oluşturmak istiyorsak, "vagrant up" demeden önce config dosyasında aşağıdaki değişiklikleri yapmak gerekir. Bu sayede virtualbox tarafından oluşturulmuş host-only yani sadece host üzerinde çalışan ağdan 2. bir adaptör tanımlamış ve onu da sm'ye bağlamış oluruz. Vagrantfile içerisindeki her bir ağ tanımı yeni bir adaptördür.

* Code Block 1 Vagrantfile

```
config.vm.network "private_network", type: "dhcp"
```

Eğer makine üzerinde başka bir ağ varsa adaptörü oraya yönlendirebiliyoruz.

```
config.vm.network "public_network",bridge: "vmnet2", type: "dhcp"
```

Ayrıca hostonly ağ tanımlamışssak ve o ağa ssh ile doğrudan erişmek istersek, vagrantın varsayılan "parola ile login olunmaz ayarını da değiştirmek gerekmektedir.

```
 config.vm.provision "shell", inline: <<-SHELL
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
  systemctl restart sshd
SHELL
```

```vagrant ssh``` ile makinenin içine girdikten sonra aşağıdaki ip komutuyla makinenin 2. adaptörünün ip adresini alıyoruz.

```
ip a
```

Masaüstü komut satırını açıyoruz ve bu ip adresine ssh erişimi yapıyoruz.
```
ssh vagrant@<sanal_makine_ip>
```

## Postgres Kurulumu
pg sürüm 11 için ve centos 7 için
```
sudo su
# depo centos depolarına eklenir. Bundan sonra postgres kurulumlarını bu depodan yapacağız demektir.
yum install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm

# postgresql veritabanı servisini kuruyoruz.
yum install postgresql11-server

# cluster ı oluşturuyor,
/usr/pgsql-11/bin/postgresql-11-setup initdb

# servisi başlangıçta çalışır şekilde aktif ediyor. 
systemctl enable postgresql-11

# servisi başlatıyoruz. 
systemctl start postgresql-11

# postgresqle giriş yapabiliriz.

su - postgres
psql
```
