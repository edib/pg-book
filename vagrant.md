# vagrant ve libvirt kullanımı 


```
egrep -c '(vmx|svm)' /proc/cpuinfo
    # 0'dan büyük bir sonucun dönmesi gerekiyor. 

kvm-ok
    INFO: /dev/kvm exists
    KVM acceleration can be used

# kurulum
sudo apt install qemu qemu-kvm libvirt-bin  bridge-utils  virt-manager
```

### vagrant box indirme

```
# libvirt için olanı seçip download edin.
vagrant box add centos/7 

# libvirt için olan fazla imaj olmadığından başka işletim sistemleri kullanmak isterseniz virtualbox için olan imaj indirip onu libvirt e dönüştürüyoruz.
vagrant mutate ubuntu/bionic64 libvirt

```

* Sonrasında  indirdiğimiz imajı kullanabilir ve Vagrantfile'ı aşağıdaki üretip 2. adaptör eklemeden management networkünden bağlanabiliriz. 

``` 
Vagrant.configure("2") do |config|

config.vm.provider "libvirt" do |v|
    v.memory = 1024
    v.cpus = 1

    # yeni bir bridge network oluşturup bu network kullanılabilir.
    #v.management_network_name = "my_network"
    #v.management_network_address = "10.11.12.0/24"
end

	config.vm.box = "centos/7"
	config.vm.hostname = "mypg1"
	config.vm.provision "shell", inline: <<-SHELL
	sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
	systemctl disable firewalld
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
  reboot
 SHELL
end
```

vagrant makineyi ayağa kaldırıp ip adresini size gösterecektir. 
```
vagrant up 
```

