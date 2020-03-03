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

## [MVCC ve Transaction](http://www.interdb.jp/pg/pgsql05.html#_5.10.)
 * Okuyanlar yazanları, yazanlar okuyanları emgellemez. Veri akışının birbirini etkilememesi için olabildiğince verinin durumlarını izole etmek.
 * Postgres Yöntemi: `Snapshot Isolation` (SI): Oracle yöntemi: `rollback segment`: eski veri buraya atılıp yenisi eskisinin üstüne yazılır. (mssql ve mysqlde de böyle)
 * pg de daha basit. Yeni bir page block olarak, yeni bir sürüm olarak yazılır.
 * `visibility check` kurallarına bakarak uygun sürümü okur.
 * `Dirty Read`, `Non-Repeatable Reads` ve `Phantom Reads`.
  - `Dirty Read`: (read uncommitted), sonuçlanmamış diğer vt işlemi içindeki değişen veriyi okumak.[+](https://qr.ae/TWnqjY) [+](http://shiroyasha.io/transaction-isolation-levels-in-postgresql.html), [+](https://tapoueh.org/blog/2018/07/postgresql-concurrency-isolation-and-locking/), [+](https://www.cybertec-postgresql.com/en/transactions-in-postgresql-read-committed-vs-repeatable-read/)
  [Videolu](https://pgdash.io/blog/postgres-transactions.html)
  - `Non-Repeatable Reads`: Bir işlem daha önce okuduğu verileri yeniden okur ve verilerin başka bir işlem tarafından değiştirildiğini tespit eder (ilk okunmadan bu yana commit edilmiş).
  - `Phantom Reads`: Bir vt işlemi, bir sorgu çalıştırır bir sonuç görür ama sonradan değiştiğini görür.

`Transaction`: Veriyi bir kararlı halden diğer bir kararlı hale getirmek. (Banka hesabı)
`TransactionID`: 32bit'tir. (wraparound problem)
`Transaction Isolation Level`: eş zamanlı 2 sorgu, Transaction içerisinde ise, Transaction bitmeden diğeri bir öncekini göremez.


`Dead Tuples`: Diskteki kayıt sırası bozulur. Tablo ve index için de geçerli. Bunların birileri tarafından temizlenmesi gerekir.
[vacuum](https://andreigridnev.com/blog/2016-04-01-analyze-reindex-vacuum-in-postgresql/) : `Autovacuum` ve `vacuum`

`Visibility Map`: [Açıklama](http://www.interdb.jp/pg/pgsql06.html), 


`free space map` : Tablolardaki boş alanlar hakkında bilgi depolar. insert ve update sorguları kullanır.

* Her bir filenode yanında (her bir page (8k'lık blok) için)
  - `oid_vm`: Visibility map: dead tuple var mı?, vacuum bakmaz,
  - `oid_fsm`: Free space map:  ne kadar boş alan olduğu


* Bir sonraki:
[yetkiler](yetkiler.md)
