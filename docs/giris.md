# PostgreSQL'e Giriş


## İlişkisel Veritabanı

## Transactions (Atomik İşlemler)

İVTYSler, veritabanı işlemlerinde (transactions) ACID özelliklerine sahiptir.

* Atomicity (Bölünmezlik): İşlemde bir çok sql cümlesi vardır ve işletilmesi ya hep ya hiç olarak çalışır. İşleme tek birim gibi davranılır.
* Consistency (Tutarlılık): Bir tutarlı durumdan diğer tutarlı duruma geçer.
* Isolation (İzolasyon): Veritabanları, bir vt işlemi devam ederken, işlediği verilerin ne durumlarda başka kullanıcılara görülebilir olduğunu belirlemek için kullanılır. Kontrol edilebilir.
* Durability(Sağlamlık): İşlem tamamlanmış mesajı (commit) kullanıcıya döndükten sonra, her durumda (disk sorunları hariç), o mesaj saklanır.

## SQL Cümle Çeşitleri (Statements)
* DDL (Data Definition Language)
  CREATE, ALTER, DROP, TRUNCATE, COMMENT, RENAME
* DML (Data Management Language)
  SELECT, INSERT, UPDATE, DELETE
* DCL (Data Control Language)
  GRANT REVELE, ALTER DEFAULT PRILEGES
* TCL (Transaction Control Language)
  COMMIT, SAVEPOINT, ROLLBACK

## PostgreSQL

* İlişkisel Veritabanı Yönetimi Sistemi (DBMS)
  * İlişkisel ve Nesne İlişkisel Özellikler
* Çoklu kullanıcı ve, yüksek eş zamanlı tasarım
  * İstemci-Sunucu Mimarisi
* SQL Standardlarına (SQL:2014) uyumlu
* Açık Kaynak Yazılım
  * Ücretsiz kullanım ve dağıtım
  * Geliştirmelere açık
* SQL / NoSQL
  * Önemli, ileri düzey algoritmalar
* Esnek ve Özelleştirmeye uygun
  * Geliştirici Dostu
  * Kullanıcı Dostu
* Oracle'a bir çok yönden benzer
* Açık Kaynak Lisans
  * PostgreSQL Lisansı (BSD, MIT Benzeri)
* Lisans Yönetimi PGDG'ye ait
  * Her zaman beleş, kopyalamaya müsait

# PostgreSQL Tarihi 

- [Wikipedia](https://en.wikipedia.org/wiki/PostgreSQL)

# PostgreSQL Mimarisi
  * C
  * Bütün işletim Sistemlerinde çalışır.
  * Hızlı kurulum
  * Fantastik veri tipleri
    * Ranges, Arrays, inet, cidr, mac, JSON, XML, UTF-8, özel veri tipleri
  * Geniş Dokümantasyon
  * Güçlü topluluk
  * Bir çok istemci destekler (.net,...., Python)
  * Birçok Sunucu tarafı prosedüler dili destekler
    * PL/pgSQL, PL/Python, PL/Java, PL/Perl, PL/V8, PL/R, PL/PHP, PL/Ruby
  * Regex
  * Sıkıştırma
  * Transactional DDL
  * Loglama, Debug
  * [Resmi](https://www.postgresql.org/docs/current/intro-whatis.html)

# Güvenlik
  * Doğuştan güvenli
  * İşletim sistemi güvenlik özelliklerini kullanabilir.
  * Şifreleme
  * Selinux
  * Kurumsal kullanıcı yönetim katmanlarına entegre
  * Bug fixlere hızlı müdahale
  * Satır, Sütun temelli yetkilendirme

# Kullanım Alanları
  * OLTP (Online Transaction Processing)
  * Web Uygulamaları
  * Veri Ambarı
  * İnceleme & Değerlendirme
  * Gerçek zamanlı veri analizi
  * NoSQL
  * Gömülü

# Hata Bildirme 
  * Sorunu tanımlama
    * Nerede kartışaltın?
  * Ne raporlanacak
    * Yeterli detay olmak zorunda
  * [Nereye raporlanacak](https://www.postgresql.org/docs/current/bug-reporting.html#id-1.3.8.7)
