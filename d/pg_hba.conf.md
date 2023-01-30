##  Host-based Authenticatiton
* İstemci erişimi denetimi bu dosyayla sağlanır.
* Varsayılanda sadece localhost erişimine izin verir.
* Her bir satırı 1 kayıttır.
* replication erişimi ayrı tanımlanır.
* Nerede bulmak için
* [Doküman](https://www.postgresql.org/docs/11/auth-pg-hba-conf.html)

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

* reject

* md5

* scram-sha-256: yeni geldi.

* password:
    unencrypted

* ident:
  operating system user, tcp connections.

* peer:
  only available for local connections.

* ldap:
  Authenticate using an LDAP server.

* radius:
  Authenticate using a RADIUS server.

* cert:
  Authenticate using SSL client certificates.

* pam:
  Authenticate using the Pluggable Authentication Modules (PAM) service provided by the operating system.

### [auth-options]
name=value
