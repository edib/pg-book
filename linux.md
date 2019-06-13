# GNU/Linux Temelleri

## Kurulum
* Imaj dosyası (iso)
* USB bellek / CD / DVD
* Sanal makine (hazır imajlar)
* Otomatik / manuel
* [Debian Kurulumu](]htps://www.youtube.com/watch?v=AXkhZkTGXW4)

## Disk Yapısı
* Fiziksel diskler
  - sda, hda, /dev/nvme0
- Bölümler (Partition)
    - sda1,sda2, /dev/nvme0n1
- Virtual disk (lvm2)
  - Diskleri birleştirme
  - Yeniden boyutlandırmaya
  - Snapshot

* Herşey Dosyadır.

# Dizin yapısı [[+]](https://www.wikiwand.com/en/Filesystem_Hierarchy_Standard)
```
/ : Primary hierarchy root and root directory of the entire file system hierarchy.
/bin :Essential command binaries that need to be available in single user mode; for all users, e.g., cat, ls, cp.
/boot :Boot loader files, e.g., kernels, initrd.
/dev : Device files, e.g., /dev/null, /dev/disk0, /dev/sda1, /dev/tty, /dev/random.
/etc : Host-specific system-wide configuration files
/etc/opt : Configuration files for add-on packages that are stored in /opt.
/etc/sgml : Configuration files, such as catalogs, for software that processes SGML.
/etc/X11 : Configuration files for the X Window System, version 11.
/etc/xml : Configuration files, such as catalogs, for software that processes XML.
/home :Users' home directories, containing saved files, personal settings, etc.
/lib : Libraries essential for the binaries in /bin and /sbin.
/lib<qual> : Alternative format essential libraries. Such directories are optional, but if they exist, they have some requirements.
/media : Mount points for removable media such as CD-ROMs (appeared in FHS-2.3 in 2004).
/mnt : Temporarily mounted filesystems.
/opt : Optional application software packages.[6]
/proc : Virtual filesystem providing process and kernel information as files.
/root : Home directory for the root user.
/run : Run-time variable data: Information about the running system since last boot.
/sbin : Essential system binaries, e.g., fsck, init, route.
/srv :
/sys : Contains information about devices, drivers, and some kernel features.
/tmp : Temporary files
/usr : Secondary hierarchy for read-only user data
/usr/bin : Non-essential command binaries
/usr/include : Standard include files.
/usr/lib : Libraries for the binaries in /usr/bin and /usr/sbin.
/usr/lib<qual> : Alternative format libraries, e.g. /usr/lib32 for 32-bit libraries on a 64-bit machine (optional).
/usr/local
Tertiary hierarchy for local data, specific to this host. Typically has further subdirectories, e.g., bin, lib, share.[9]
/usr/sbin
Non-essential system binaries, e.g., daemons for various network-services.
/usr/share
Architecture-independent (shared) data.
/usr/src
Source code, e.g., the kernel source code with its header files.
/usr/X11R6
X Window System, Version 11, Release 6 (up to FHS-2.3, optional).
/var : Variable files
  /var/cache : Application cache data.
  /var/lib : State information. Persistent data
  /var/lock : Lock files
  /var/log : Log files
  /var/mail: Mailbox files
  /var/opt : Variable data
  /var/run : Run-time variable data.
  /var/spool: Spool for tasks waiting to be processed
  /var/tmp : Temporary files

```

## Komut Satırı
```
fdisk
# 2TB sorunu
parted
lsblk
df -h
command –help
man|info command
ps, top, free
whatis / which / locate
ip a, df -h
ls, cd (cd, cd .., cd -), pwd, clear, ctrl+l
# History / Ctrl+r (tekrar), !
cp / mv / rm / mkdir / touch / chmod / chown / gzip / tar
bg / fg / jobs
# (sleep 1000 &)
cat / find / grep / awk
env / export
ps / top / kill / killall / pkill(appname)
&&
true && echo "ok"
false && echo "ok"
```
### kısa yollar
[1](https://media.cheatography.com/storage/thumb/davechild_linux-command-line.750.jpg?last=1463102294) [2](https://www.git-tower.com/blog/content/posts/32-command-line-cheat-sheet/command-line-cheat-sheet-large01.png)
[3](https://nguyenxuanbinhminh.com/wp-content/uploads/2018/07/Linux-command-cheat-sheet.png)
[Vim](https://www.cs.colostate.edu/helpdocs/vi.html)

## Kullanıcı Yönetimi
* /etc/passwd : Kullanıcılara ait temel bilgiler
* /etc/shadow : Kullanıcıların parolaları
* /etc/groups: groupların listesi
```
whoami/id
id {kullanici_adi}
sudo / su
```
### Kullanıcı ve grup işlemleri
* Bir kullanıcı bir çok gruba dahil olabilir.

```
adduser / deluser / usermod
# /etc/skel
groupadd / groupmod / groupdel
/etc/passwd , /etc/groups
# /etc/sudoers -> sudo olmanın sınırlarını belirleyebiliriz. / visudo
# username host =(user:group) command
sudo usermod -G sudo kullanici
passwd  / passwd kullanici / chage / passwd -l/u kullanici
echo $PATH
last
```

## Başlama ve Servisler
* Systemd:  en yaygın, başlangıç servislerini düzenler.
Her process'in bir `ID`'si var.

```
ps auxww
```
* *Systemd*: Linux başladığında ilk servis, process ID, PID = 1, servis yöneticisi
  - Bağımlılık kontrolleri yapar.
  - Tüm hw okunur, diskler, ağ aktif edilir.

```
systemctl status/enable/disable/start/stop/restart/reload/cat/ show/mask/...
systemctl --help
systemctl list-units --all –state=inactive
Systemctl enable <paket_adi>
```
* yum paketlerin servis linki dosyaları vardır. Başlangıçta çalışır.
* Paketler orjinal başlangıç dosyalarını buraya koyar: `/usr/lib/systemd/system/`

## Zamanlanmış İşlemler (cron)
```
crontab -e
crontab -l
# Format
* * * * *
| | | | |  
| | | | |
| | | | +---- Day of the Week   (range: 1-7, 1 standing for Monday)
| | | +------ Month of the Year (range: 1-12)
| | +-------- Day of the Month  (range: 1-31)
| +---------- Hour              (range: 0-23)
+------------ Minute            (range: 0-59)
```
## Ağ Yönetimi
```
# yeni nesil ip komutu
ip a/l/r

# elle ip adresi verebilirsiniz.
ip addr add/del 192.168.10.1/24 dev ens33
```
* Redhat Sistemlerde ağ ayarları `/etc/sysconfig/network-scripts/` altında `ifcfg-{ifname}` olarak tutulmaktadır.
* `nmtui` gui aracıyla ip adresi verilebilir.

### Diğer Araçlar
```
ping
telnet <ip> <port>
netstat -atpn / -ltpn
# dns kayıtlarının yeri
/etc/resolv.conf
/etc/hosts # sisteme özgü adres tanımları
/etc/sysctl.conf # işletim sistemi düzeyindeki parametreler
```

## Paket Yönetimi
* Paketler, İS'de kullanılan programlardır. Her dağıtımın internette aynalı çalışan depoları vardır.
* Custom depolar eklenebilir.

### Paket Yöneticisi
* RH: yum (dnf), rpm, .rpm
```
yum search / install / remove/ info / provides / update <paket_adi>
```
* Bağımlılıkları otomatik olarak bulup kurarlar.
```
rpm -i/-r/-ql -qa/..
rpm -ql {paket_adi}
```
* Paketin bağlangıçta çalışması gerekiyorsa

```
systemctl enable {paket_adi}
```
* yum ile her uygulamanın kaynak kodu da indirilebilir.
