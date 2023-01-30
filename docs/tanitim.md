# Tanıtım

* **Kullanıcı tanımlı veri tipleri:** PostgreSQL, kullanıcı tanımlı veri tipleri oluşturmak için genişletilebilir. Bir giriş ve çıkış işlevine sahip olmalıdır.
* **Sofistike kilitleme mekanizması:** Kilitleme için üç mekanizma vardır, 
  *  row-level
  *  column-levevl
  *  advisory locks
*  **Table Inheritance:** PostgreSQL, başka bir tabloya dayalı alt tablolar oluşturmanızı sağlar.
* **Yabancı Anahtar Referans Bütünlüğü(FK):** Yabancı anahtar değerlerinin başka bir tablodaki gerçek birincil anahtar değerlerine karşılık geldiğini belirtir.
* **Nested Transactions: (save-points):** Bu, bir alt sorgunun sonucunun, üst sorgusu geri alındığında geri alınmadığı anlamına gelir. Ancak, üst transaction geri alınırsa, tüm save pointler de geri alınır.
