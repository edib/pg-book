## Virtualbox ve Vagrant kurulumu
İndirin ve kurun

## Vagrant Kurulumu

### Vagrant kullanımı
* Vagrant masaüstü ortamları için kod ile otomatik sanal makine oluşturma uygulamasıdır. Varsayılan olarak virtualbox kullanır. Windows ve linux hostlar üzerinde çalışır.
* Bir yerde sanal makinemizi tanıtıcı bir dizin oluşturup (Örn. postgres01) komut satırından dizine gidiyoruz ve  aşağıdaki komutu çalıştırıyoruz. Komut, eğer makinede yoksa Ubuntu 20.04 imajını vagrant reposundan indirir.

```
vagrant init generic/ubuntu2204
```

Yukarıdaki komut bulunulan dizinde Vagrantfile adında bir config dosyası oluşturur. Dosyanın içini silip aşağıdaki satırları ekleyin ve hostname ve ip karşısındaki alanları değiştirin. Uygun ip blokları için [buraya](https://www.wikiwand.com/en/Private_network#/Private_IPv4_address_spaces) bakınız.

![Vagrant virtualbox ağ yapısı](https://user-images.githubusercontent.com/4180560/79636826-3e0d9d80-8183-11ea-8ced-eed33d53e184.png)


```
Vagrant.configure("2") do |config|
	config.vm.box = "generic/ubuntu2204"
	config.vm.network "private_network", ip: "10.11.12.13"
	config.vm.hostname = "pg13"
	config.vm.provision "shell", inline: <<-SHELL
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
  reboot
 SHELL
end
```

Bu dosyadan sanal makine aktif etmek için makineyi virtualbox altında poweron ederiz.

```
vagrant up
```

poweron süreci bittikten sonra ssh ile kendi yönlendirmesiyle bağlanabiliriz. Masaüstü komut satırını açıyoruz ve bu ip adresine ssh erişimi yapıyoruz.
```
ssh vagrant@<sanal_makine_ip>
# varsayılan parola: "vagrant"

```
