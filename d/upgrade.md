# upgrade
* major sürüm: 10,11,12,13,14,... 
  * veri formatı değişebilir
  * belirli bir güncelleme prosedürü vardır
* minör sürüm: 
  * 14.1,..., 
  * veri yapısında değişiklik olmaz, 
  * yerinde işletim sistemi güncellemesiyle güncellenebilir.
* işletim sistemi ile yeni bir sürüm kursanız, yeni bir portta yeni bir dizinde çalışır. 
* bir major sürümden bir üstüne geçme

* postgres aracıyla
  * 13 var
  * 14 ü kurun
  * 

* pg yöntemi
```
/usr/lib/postgresql/14/bin/pg_upgrade \
   -b /usr/lib/postgresql/13/bin \
   -B /usr/lib/postgresql/14/bin \
   -d /var/lib/postgresql/13/main \
   -D /var/lib/postgresql/14/main \
   -o ' -c config_file=/etc/postgresql/13/main/postgresql.conf' \
   -O ' -c config_file=/etc/postgresql/14/main/postgresql.conf' \
   [-k|--clone] # birinden biri \
   -c # kontrol et

```
* debian yöntemi (üsttekine kapsayıcı)
* 
```
pg_upgradecluster 13 main -k --method=link --rename=canimpg

# -v version  olmazsa latesta gider.

```





