# VACUUM 

* MVCC'nin bir sonucudur. 
* Olmazsa olmazdır.
* Autovacuum olarak otomatik çalışır. Kapatılabilir. 
* Bir sayfaya delete veya update operasyonu geldiği zaman o page’de bulunan ilgili kayıt işaretlenir. [*](sorgu-isleme.md)
* Kullanılamaz olarak işaretlenen tuple’lara dead tuple denir. 
* Dead Tuple’ların disk üzerinden yer kaplar ama üzerinde yazılamaz.
* Bunu yapmak için pg, vacuum işlemini kullanılır. 
* Vacuum işlemi disk üzerinde herhangi bir boş alan yaratmaz. Sadece dead tuple’ların üzerine yazılabilir yapar. [*](https://www.interdb.jp/pg/img/fig-6-08.png)

```
create table tbl (data int);
-- tabloya bir sürü blok verisi girişi 
insert into tbl (data) SELECT * from generate_series(1,1000);
\dt+ tbl
DELETE FROM tbl WHERE data % 200 != 0;

\dt+ tbl

VACUUM tbl;

\dt+ tbl

VACUUM full tbl;

\dt+ tbl


```

## Vacuum full

* Tabloyu kilitler. Tablo erişilemez olur.
* Tabloyu başka yere yeniden yazar. [*](https://www.interdb.jp/pg/img/fig-6-09.png)
* Yer açar.
* Gerçek ortamlarda kullanmak sakıncalı. 
* pg_repack



```
(1) FOR her tablo 
(2) ShareUpdateExclusiveLock kilidi edin

        /* İlk blok */
(3) Tüm ölü kayıtları almak için tüm sayfaları tarayın ve gerekirse eski kayıtları dondurun
(4) Varsa, ilgili ölü kayıtlara işaret eden index kayıtlarını kaldırın

        /* İkinci blok */
(5) FOR tablonun her sayfası
(6) Ölü demetleri kaldırın ve sayfadaki canlı demetleri yeniden yerleştirin
(7) FSM ve VM'yi Güncelleyin
    END FOR

/* Üçüncü blok */
(8) indexleri temizle
(9) Mümkünse son sayfayı kısalt
(10 Hedef tablonun hem istatistiklerini hem de sistem kataloglarını güncelleyin
    ShareUpdateExclusiveLock kilidini serbest bırakın

END FOR

/* Rötuş */
(11) İstatistikleri ve sistem kataloglarını güncelleyin
(12) Mümkünse hem gereksiz dosyaları hem de clogtaki sayfaları kaldırın

```

[pg_repack](https://github.com/reorg/pg_repack)


## Autovacuum

* Sequential scan sıralı okuma işlemidir ve dead tuple’ları atlamaz. 
* Dead tuple’ların temizlenmesi daha az satır okunması anlamına gelir.
* Çok fazla güncellenen tablolarda vacuum işleminin düzenli olarak yapılması gerekir. [parametreler](https://tubitak-bilgem-yte.github.io/pg-yonetici/mydoc_automatic_vacuuming.html)
* Vacuum işlemi veri tabanı boyutunu azaltır ve performansı arttırır.
* Autovacuum özelliği ile bu işlemlerin manuel olarak yapılmasına gerek kalmamıştır. 
* Autovacuum işlemi sırasında hem vacuum hem de analiz işlemi yapılacağından veri tabanı performansını arttıtır.


[Eklenecek](https://www.percona.com/blog/2018/08/10/tuning-autovacuum-in-postgresql-and-autovacuum-internals/)

* `autovacuum_max_workers`: Kaç tane VT varsa bu kadar , vakum veya analiz gerektiren bir tablo için bir çalışan işlemi başlatır. autovacuum_max_workers'ın 3 olarak ayarlandığı dört veritabanı varsa, 4. veritabanının mevcut çalışan işlemlerinden biri boşalana kadar beklemesi gerekir.
* `autovacuum_naptime`: default 1 dakika. Bir sonraki autovacuum tetikleme = `autovacuum_naptime` / <vt sayısı>  sn'dir. 3 vt varsa 60 / 3 = 20 saniyedir.  
* [tüm autovacuum parametreleri](https://tubitak-bilgem-yte.github.io/pg-yonetici/docs/02-veritabani-yapilandirmasi/automatic_vacuuming/)

### Autovacuum ileri düzey ayarlar

* Tablolar oldukça büyüdüğünde, eski ve geçici veriler sistematik olarak kaldırılmazsa performans önemli ölçüde düşebilir.
* Varsayılan otomatik vakum analizi ve vakum ayarları küçük bir dağıtım için yeterlidir.
* Varsayılan olarak, 
  * Satırların %20'si artı 50 satır eklendiğinde, güncellendiğinde veya silindiğinde varsayılan olarak otomatik olarak temizlenir. 
  * Satırların %10'u artı 50 satır için bir eşik aşıldığında tablolar otomatik olarak analiz edilir. 
  * Bir tablo için Autovacuum vacuum eşiği = `autovacuum_vacuum_scale_factor` * kayıt sayısı + `autovacuum_vacuum_threshold`
  * Bir tablo için Autovacuum ANALYZE eşiği = `autovacuum_analyze_scale_factor` * kayıt sayısı + `autovacuum_analyze_threshold`
  * Örneğin, 
    * 10000 satırlık bir tablo, 2050 satır eklenene, güncellenene veya silinene kadar otomatik olarak vakumlanmaz. 
    * 1050 satır eklendiğinde, güncellendiğinde veya silindiğinde otomatik olarak analiz edilir.
* Tablolar büyüdükçe yüzde eşiklerinin tetiklenmesi daha uzun sürer. Vakum ve analiz gerçekleşmeden önce performans önemli ölçüde düşebilir.
* Bu yüzden Ölçek faktörü, 
  * hem vakum hem de analiz otomatik vakum ayarları için sıfıra ayarlanmalıdır. `autovacuum_vacuum_scale_factor`, `autovacuum_analyze_scale_factor`
  * Hem vakum hem de analiz eşiği ayarları için eşik 1000 olarak ayarlanmalıdır. `autovacuum_vacuum_threshold`, `autovacuum_analyze_threshold`

```
ALTER TABLE buyuk_tablo SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE buyuk_tablo SET (autovacuum_vacuum_threshold = 1000);
ALTER TABLE buyuk_tablo SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE buyuk_tablo SET (autovacuum_analyze_threshold = 1000);

```
* `pg_stat_user_tables`daki duruma bakarak karar verilebilir.

```
SELECT n_tup_ins as "inserts",n_tup_upd as "updates",n_tup_del as "deletes", n_live_tup as "live_tuples", n_dead_tup as "dead_tuples"
FROM pg_stat_user_tables
WHERE schemaname = '<hedef_şema>' and relname = '<hedef_tablo>'; 
```

* Autovacuum, bazı durumlarda diski etkileyebilir. Bu durumda ek ayarlar gerektirebilir. [1](https://www.percona.com/blog/2018/08/10/tuning-autovacuum-in-postgresql-and-autovacuum-internals/), [2](https://pganalyze.com/blog/visualizing-and-tuning-postgres-autovacuum), [3](https://www.2ndquadrant.com/en/blog/autovacuum-tuning-basics/), [4](https://www.2ndquadrant.com/en/blog/when-autovacuum-does-not-vacuum/)

* Autovacuum daha sık çalışması için 

```ini
# Autovacuum processini logla
log_autovacuum_min_duration = 0
# Daha fazla process çalışsın. 
autovacuum_max_workers = 6
autovacuum_naptime = 15s
# Daha sık çalışması için eşik değerlerini düşür.
autovacuum_vacuum_threshold = 25
autovacuum_vacuum_scale_factor = 0.1
autovacuum_analyze_threshold = 10
autovacuum_analyze_scale_factor = 0.05
# autovacuum daha az bölünsün.
autovacuum_vacuum_cost_delay = 10ms
autovacuum_vacuum_cost_limit = 1000

```

* Vacuum nasıl çalışır? Örnek:
  
```

create table tbl (data int);
-- tabloya bir sürü blok verisi girişi 
insert into tbl (data) SELECT * from generate_series(1,1000);

-- pagelere bak
SELECT lp as tuple, t_xmin, t_xmax, t_field3 as t_cid, t_ctid 
                FROM heap_page_items(get_raw_page('tbl',0));

\d+

delete from tbl where data % 2 = 0;
SELECT lp as tuple, t_xmin, t_xmax, t_field3 as t_cid, t_ctid 
                FROM heap_page_items(get_raw_page('tbl',0));

\d+

vacuum tbl;

SELECT lp as tuple, t_xmin, t_xmax, t_field3 as t_cid, t_ctid 
                FROM heap_page_items(get_raw_page('tbl',6));

\d+

vacuum full tbl;

\d+

SELECT lp as tuple, t_xmin, t_xmax, t_field3 as t_cid, t_ctid 
                FROM heap_page_items(get_raw_page('tbl',2));

```

#### Bloat Kontrol

```
SELECT current_database(),
       schemaname,
       tablename, /*reltuples::bigint, relpages::bigint, otta,*/ round((CASE
                                                                            WHEN otta = 0 THEN 0.0
                                                                            ELSE sml.relpages::FLOAT / otta
                                                                        END)::NUMERIC, 1) AS tbloat,
                                                                 CASE
                                                                     WHEN relpages < otta THEN 0
                                                                     ELSE bs * (sml.relpages - otta)::BIGINT
                                                                 END AS wastedbytes,
                                                                 iname, /*ituples::bigint, ipages::bigint, iotta,*/ round((CASE
                                                                                                                               WHEN iotta = 0
                                                                                                                                    OR ipages = 0 THEN 0.0
                                                                                                                               ELSE ipages::FLOAT / iotta
                                                                                                                           END)::NUMERIC, 1) AS ibloat,
                                                                                                                    CASE
                                                                                                                        WHEN ipages < iotta THEN 0
                                                                                                                        ELSE bs * (ipages - iotta)
                                                                                                                    END AS wastedibytes
FROM
  (SELECT schemaname,
          tablename,
          cc.reltuples,
          cc.relpages,
          bs,
          ceil((cc.reltuples * ((datahdr + ma - (CASE
                                                     WHEN datahdr % ma = 0 THEN ma
                                                     ELSE datahdr % ma
                                                 END)) + nullhdr2 + 4)) / (bs - 20::FLOAT)) AS otta,
          coalesce(c2.relname, '?') AS iname,
          coalesce(c2.reltuples, 0) AS ituples,
          coalesce(c2.relpages, 0) AS ipages,
          coalesce(ceil((c2.reltuples * (datahdr - 12)) / (bs - 20::FLOAT)), 0) AS iotta -- very rough approximation, assumes all cols
FROM
     (SELECT ma,
             bs,
             schemaname,
             tablename,
             (datawidth + (hdr + ma - (CASE
                                           WHEN hdr % ma = 0 THEN ma
                                           ELSE hdr % ma
                                       END)))::NUMERIC AS datahdr,
             (maxfracsum * (nullhdr + ma - (CASE
                                                WHEN nullhdr % ma = 0 THEN ma
                                                ELSE nullhdr % ma
                                            END))) AS nullhdr2
      FROM
        (SELECT schemaname,
                tablename,
                hdr,
                ma,
                bs,
                sum((1 - null_frac) * avg_width) AS datawidth,
                max(null_frac) AS maxfracsum,
                hdr +
           (SELECT 1 + count(*) / 8
            FROM pg_stats s2
            WHERE null_frac <> 0
              AND s2.schemaname = s.schemaname
              AND s2.tablename = s.tablename) AS nullhdr
         FROM pg_stats s,
 
           (SELECT
              (SELECT current_setting('block_size')::NUMERIC) AS bs,
                   CASE
                       WHEN substring(v, 12, 3) IN ('8.0',
                                                    '8.1',
                                                    '8.2') THEN 27
                       ELSE 23
                   END AS hdr,
                   CASE
                       WHEN v ~ 'mingw32' THEN 8
                       ELSE 4
                   END AS ma
            FROM
              (SELECT version() AS v) AS foo) AS constants
         GROUP BY 1,
                  2,
                  3,
                  4,
                  5) AS foo) AS rs
   JOIN pg_class cc ON cc.relname = rs.tablename
   JOIN pg_namespace nn ON cc.relnamespace = nn.oid
   AND nn.nspname = rs.schemaname
   AND nn.nspname <> 'information_schema'
   LEFT JOIN pg_index i ON indrelid = cc.oid
   LEFT JOIN pg_class c2 ON c2.oid = i.indexrelid) AS sml
ORDER BY wastedbytes DESC;
```
