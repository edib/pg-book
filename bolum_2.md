# postgresql dizin yapısı
Varsayılan kurulumda:
- cluster ```/var/lib/pgsql/11/data`` altındadır. 
- çalıştırılabilir dosyalar ```/usr/pgsql-11/bin/``` altındadır.

## data altındaki yeni başlayanlar için önemli dosyalar ve dizinler
- postgresql.conf (Bütün cluster seviyesindeki ayar) 
- pg_hba.conf (cluster erişim ayarı)
- pg_ident.conf (cluster kullanıcı ve sistem kullanıcı eşleştirmesi)
- base: cluster nesnelerinin ve asıl veri bulunur.
- global: 
- log: text logları. erişim logları
- pg_tblspc: oluşturulan tablespacelerin kısa yolları bulunur.
- pg_wal: transacktion logların tutulduğu yer. Olabildiğince uzak durulmalıdır. Asla silinmemelidir. 

* psql postgresql instance'a ulaşmak için kullanılan bir komut satırı istemcisidir. 
## psql kısa yolları
```
--- psql client komutlarının listesi
\? 

--- \d bir schema altındaki tüm nesnelerin listesi
\d
--- tablolar
\dt
 --- gösterimler (views)
\dv
--fonksiyonlar
\df
-- kullanıcılar, roller
\du
-- vb.
```
