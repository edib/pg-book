# Kurulum

Eğer kişisel bilgisayarımızda bir sanal makina oluşturarak postgres kurulumu yapmak istiyorsak en kısa yol vagrant iledir. [Vagrant kurulumu](vagrant.md) 

## Postgres Kurulumu
pg sürüm 14 için ve ubuntu 20.04 için
https://www.postgresql.org/download/linux/ubuntu/ adresine gidin

Eğer cluster'ı başlatırken özel ayarlar yapmak istiyorsanız buraya başvurun.
[Özel initdb ayarları](docs/ozel_ayarlar.md)
Yoksa aşağıdaki gibi devam edin.

Debian sistemlerde pg kümesi otomatik varsayılan dizinlerde oluşturulur. 

'psql' komut satırından çalışan ve sunucu kurulumuyla birlikte gelen gelişmiş bir istemcidir. psql'in parametrelerini görmek için

```
psql --help
 ```
[psql tanıtımı](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_postgresql_istemcileri_psql.html)
[psql periodic table](https://www.reddit.com/r/PostgreSQL/comments/bzup2k/a_periodic_table_of_psql_commands_higher/)



### Cluster
Postgres çalışan servisi ve onun veri dizini birlikte `cluster` denmektedir.
Postgres servisinin paket yerleri, dağıtıma göre değişir. Bir makine üzerine tercih edilmemekle birlikte birden çok cluster kurulabilir.
* Tek servis ve port
* Tek veri dizini
* Tek ayar dosyası/dosya grubu
* Dağıtık cluster değildir.
* Veritabanı sunucusu'da denir.

### Debian Dağıtımları

```
Binaries: /usr/lib/postgresql/${version}/bin
Data: /var/lib/postgresql/${version}/${kume_adi}
```

**`Cluster` yönetimi**
* pg_ctl utility
* init.d scripts / systemd services
* pg_createcluster/pg_ctlcluster/pg_conftool vb.
 

### Redhat Dağıtımları

```

Binaries: /usr/pgsql-${version}/bin
Data: /var/lib/pgsql/${version}/data

```

### **`Cluster` yönetimi**
* pg_ctl utility
* init.d scripts / systemd services


### Ayarlar nerede yapılır?

Postgresql ayar dosyaları: En Önemli 2 ayar dosyası var.
*  [postgresql.conf](postgresql.conf.md) [*](https://postgresqlco.nf/en/doc/param/)
varsayılan yeri ```/var/lib/postgresql/${version}/${cluster_adı}```. Cluster'ın çalışması gereken tüm ayarları içerir. İçinde bir çok parametre vardır. postgresql.conf a alternatif olarak postgresql.auto.conf dosyası da özel ayarların yazılması için kullanılabilir.
* [pg_hba.conf](pg_hba.conf.md) İstemci erişimi denetimi bu dosyayla sağlanır.

* ------ diğer ayarlar
* replication: eskiden recovery.conf vardı. 12'de kalktı. postgresql.conf içine yedirildi. 
* initdbde bazı parametreler var. 
* her bir objede set edilen/edilebilen. (fillfactor)
* geliştirici parametreleri
* compile-time parametreleri
* [Ayarlara Genel Bakış](d/ozel_ayarlar.md)


## postgresql servisinin yönetimi
```
# postgres yöntemi
pg_ctl -D /var/lib/postgresql/${version}/${küme_adı}/ ${action}

# systemd yöntemi
systemctl ${action} postgresql.service

```



### Kaynaklar
* [Detay](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_postgresql_kurulum_ayarlanmasi.html)
* [GSSAPI Kurulumu](https://blog.crunchydata.com/blog/windows-active-directory-postgresql-gssapi-kerberos-authentication)
* [SSL Yapılandırması](https://www.cybertec-postgresql.com/en/setting-up-ssl-authentication-for-postgresql/)
