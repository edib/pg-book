##  Host-based Authenticatiton
* İstemci erişimi denetimi bu dosyayla sağlanır.
* Varsayılanda sadece localhost erişimine izin verir. İlk kurulumda, dışarıdan erişime izin vermez.
* Her bir satırı 1 kayıttır.
* replication erişimi ayrı tanımlanır.
* [Doküman](https://www.postgresql.org/docs/11/auth-pg-hba-conf.html)
psql satırından,

```
show hba_file;
```

### İçeriği

```

local      database  user  auth-method  [auth-options]
host       database  user  CIDR-address  auth-method  [auth-options]
hostssl    database  user  CIDR-address  auth-method  [auth-options]
hostnossl  database  user  CIDR-address  auth-method  [auth-options]
host       database  user  IP-address  IP-mask  auth-method  [auth-options]
hostssl    database  user  IP-address  IP-mask  auth-method  [auth-options]
hostnossl  database  user  IP-address  IP-mask  auth-method  [auth-options]
```

### [auth-method]
* trust

  parolasız, güvenilen erişim

* reject

  bağlantıyı reddet

* md5

  md5 hash li parola koruması

* scram-sha-256: (v10 la birlikte geldi)[[+]](http://hacksoclock.blogspot.com/2018/10/how-to-set-up-scram-sha-256.html)

  sha-256 şifreleme

* password

  şifrelenmemiş parola

* ident

  işletim sistemi kullanıcısı, tcp port üzerinden bağlantı için

* peer

  local, socket bağlantısı için

* ldap

  bir LDAP sunucudan kullanıcı bilgilerini kullanmak için

* radius

  bir RADIUS sunucudan kullanıcı bilgilerini kullanmak için

* cert

  SSL istemci sertifikalarını kullanrak bağlanmak için.

* pam

  İşletim sistemi tarafından sağlanan Pluggable Authentication Modules (PAM) servisini kullanarak bağlanmak için.

### [auth-options]
name=value
