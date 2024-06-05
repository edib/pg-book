## Nesneler
### CLUSTER
### DATABASE
### TABLESPACE
### SCHEMA
### TABLE
* [create table örnekleri](https://tubitak-bilgem-yte.github.io/pg-gelistirici/docs/02-sorgu-yapisi-davranislari/sorgu_tipleri/
)

### SEQUENCE
* https://www.postgresql.org/docs/current/sql-createsequence.html

### INDEX
Tablolara giriş noktasıdır.
Tablodaki bir veriye işaret eder.
İndexler tablolardan farklı yerde depolanır.




#### Btree
#### Btree
* Cover INDEX
* Multicolumn INDEX
  Kolonların sırası önemlidir.


### VIEW
### FUNCTION
### STORED PROCEDURE



### TRIGGER
Trigger,  `INSERT`, `UPDATE`, `DELETE` ya da `TRUNCATE` SQL işlemlerinden biri gerçekleştiğinde otomatik olarak tetiklenen bir fonksiyondur. Trigger oluşturabilmek için
* Bir trigger fonksiyonu yaratacaksınız.
* Bu trigger fonksiyonunu yukarıdaki bir olaya bağlanacaksınız.
#### Trigger Türleri
* Ne zaman tetikleneceği yönünden
  - BEFORE Trigger
  - INSTEAD OF Trigger
  -
* Nerede tetikleneceği yönünden

Bir trigger `satır` seviyesi ya da `SQL deyimi` seviyesinden tetiklenebilir. İkisi arasındaki farkı şöyle anlatabiliriz:
* Bir `UPDATE` deyiminin 20 satırı etkilediğini varsayalım. Eğer bu satır seviyesi bir trigger ise 20 kere tetiklenecektir. Eğer SQL deyimi seviyesi bir trigger ise 1 kere tetiklenecektir. Çünkü deyim 1 kere kullanılmıştır.
Bir trigger, bir olaydan önce ya da sonra olacak diye tanımlanabilir.
```
-- Örnek tablo
CREATE TABLE Personel (
  personel_adi text,
  maas integer
  );
```

Trigger fonksiyonunu oluşturuyoruz.
```
CREATE or replace FUNCTION personel_control() RETURNS trigger AS $BODY$
  BEGIN
    -- Personel adı ve maaş alanı boş mu?
    IF NEW.personel_adi IS NULL THEN
      RAISE EXCEPTION 'Personel adı alanı boş olamaz!';
    END IF;
    IF NEW.maas IS NULL THEN
      RAISE EXCEPTION '% in maaş alanı boş olamaz!',NEW.personel_adi;
    END IF;

    -- Personel maaşı negatif sayı olamaz.
    IF NEW.maas < 0 THEN
      RAISE EXCEPTION '% eksi maaş alamaz!', NEW.personel_adi;
    END IF;

    RETURN NEW;
  END
$BODY$ language plpgsql;

```
Triggerımızı oluşturuyoruz.
```
-- INSERT veya UPDATE deyiminden ÖNCE, her satır için bu prosedürü çalıştır diye okunur.
CREATE TRIGGER personel_control BEFORE INSERT OR UPDATE ON Personel
  FOR EACH ROW EXECUTE PROCEDURE personel_control();
```
Test etmek için
```
insert into personel (personel_adi, maas)
values ('Mehmet',-1000);
ERROR: Mehmet eksi maaş alamaz!


insert into personel (personel_adi)
values ('Mehmet');
ERROR: Mehmet in maaş alanı boş alamaz!

insert into personel (maas)
values (1000);
ERROR: Personel adı alanı boş olamaz!

```
### RULES
### ROLES / USERS
