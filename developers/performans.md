## performans ve explain
```
explain (analyze, format yaml) {SORGU}
```
* (actual time=STARTUP TIME..TOTAL TIME rows=ROW COUNT loops=LOOP COUNT)

* `analyze` komutu: veritabanı ya da tablo hakkında istatistik toplayıp onu `pg_statistic` altında saklar.

```
\h analyze
\d+ pg_stats
select * from pg_statistic where starelid = 23825 and staattnum=2;
select * from pg_stats where tablename = 'persons' and attname = 'first_name';
```   
### [sequential scan](http://www.interdb.jp/pg/pgsql01.html#_1.4.2.)
Tablodaki her satırı okur.

### [index scan](http://www.interdb.jp/pg/pgsql01.html#_1.4.2.)
### [index bitmap scan](https://andreigridnev.com/blog/2016-04-01-analyze-reindex-vacuum-in-postgresql/)
(Tamamı index'te var mı hayırsa) İndexten bitmap alır. Alanların diskteki yerini öğrenir ve sequential olarak table'ı tarar.
* index satırları gezer ve oradan tid (transaction id)lerden bitmap oluşturur
* Table i/o atlayarak fiziksel olarak sıralıdır.
* Çoklu indexleri verimli bir şekilde bir araya getirebilir.
* Limit operasyonu verimli değildir.
### index only scans
Aranılan değer indexte varsa. Tabloya gitmeye gerek kalmaz.
### [HOT](http://www.interdb.jp/pg/pgsql07.html)
Eğer sadece tabloda değişiklik var indexte bir değişmek yoksa, sadece heap tablosu güncellenir.   

[Explain'i anlamak (https://www.dalibo.org/_media/understanding_explain.pdf)

```
postgres=# explain select * from foo;
                          QUERY PLAN                         
--------------------------------------------------------------
 Seq Scan on foo  (cost=0.00..18918.18 rows=1058418 width=36)
(1 row)
```

* `Seq Scan`: Diski blok blok okuyacak demektir.

* `Cost`: 8K boyutundaki disk page'ini okumanın maliyeti 1 olarak kabul edilir. "sequential_page_cost" parametresiyle belirlenir.

* cost to get the first row: 0.00
* cost to get all rows: 18584.82 in “page cost” unit

* `Rows`: number of rows
* `Width`: average width of a row in bytes

**Önemli** Maliyet açısında birebir doğru olmayacaktır.