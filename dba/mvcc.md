
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