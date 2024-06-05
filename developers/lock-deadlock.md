# kilitler

## deadlocks

Bir deadlock (ölü kilit) durumu, iki veya daha fazla işlem birbirinin kaynaklarını beklerken sonsuza kadar beklemesi durumu olarak tanımlanabilir. PostgreSQL'de bir deadlock durumunu simüle etmek için iki işlem arasında kilitlenmeye neden olabilecek örnek bir senaryo yazalım.

### Örnek Senaryo: Deadlock Durumu Oluşturma

Aşağıdaki örnek, iki farklı işlem (Transaction 1 ve Transaction 2) arasında bir deadlock durumu oluşturacaktır.

#### Adım 1: Örnek Tablo Oluşturma

Öncelikle, örnek bir tablo oluşturalım.

```sql
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    balance NUMERIC(15, 2)
);

-- Örnek veriler ekleyelim
INSERT INTO accounts (balance) VALUES (1000.00), (2000.00);
```

#### Adım 2: Transaction 1 Başlatma

Transaction 1'i başlatın ve ilk satırı kilitleyin.

```sql
BEGIN;

-- Transaction 1: id = 1 olan satırı kilitle
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
```

#### Adım 3: Transaction 2 Başlatma

Transaction 2'yi başlatın ve ikinci satırı kilitleyin.

```sql
BEGIN;

-- Transaction 2: id = 2 olan satırı kilitle
SELECT * FROM accounts WHERE id = 2 FOR UPDATE;
```

#### Adım 4: Deadlock Oluşturma

Şimdi, Transaction 1 ve Transaction 2'nin birbirlerinin kilitlediği satırları güncellemeye çalışmasıyla deadlock oluşacaktır.

##### Transaction 1'de şu komutu çalıştırın:

```sql
-- Transaction 1: id = 2 olan satırı güncellemeye çalış
UPDATE accounts SET balance = balance - 100 WHERE id = 2;
```

##### Transaction 2'de şu komutu çalıştırın:

```sql
-- Transaction 2: id = 1 olan satırı güncellemeye çalış
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
```

Bu noktada, Transaction 1 ve Transaction 2 birbirinin kilitlediği satırları beklemekte ve bu nedenle deadlock durumu oluşmaktadır.

### Deadlock Algılama ve Çözme

PostgreSQL, deadlock durumlarını otomatik olarak algılar ve bir deadlock durumunu çözmek için işlemlerden birini iptal eder. Bu durumda, PostgreSQL'den bir deadlock hatası alırsınız ve işlemlerden biri geri alınır.

#### Deadlock Hatasını Gözlemleme

Aşağıdaki hata mesajını görebilirsiniz:

```plaintext
ERROR: deadlock detected
DETAIL: Process 1234 waits for ShareLock on transaction 5678; blocked by process 8765.
Process 8765 waits for ShareLock on transaction 1234; blocked by process 1234.
HINT: See server log for query details.
```

Bu hata mesajı, PostgreSQL'in deadlock durumunu algıladığını ve işlemlerden birini iptal ettiğini gösterir.

### Deadlock Durumundan Kaçınma

Deadlock durumlarından kaçınmak için işlemler arasında tutarlı bir kilitleme sırası takip edebilir ve gerektiğinde işlemleri yeniden deneyecek şekilde uygulamalarınızı tasarlayabilirsiniz.

Örneğin:
- Tüm işlemlerde aynı sırayla satırları güncellemeyi deneyin.
- İşlemleri daha küçük parçalara bölerek daha kısa sürede tamamlanmalarını sağlayın.
- Zaman aşımı değerlerini ayarlayarak uzun süren kilitleri algılayıp işlem yapın.

Bu şekilde, PostgreSQL'de deadlock durumunu simüle edebilir ve bu tür durumlardan nasıl kaçınabileceğinizi öğrenebilirsiniz.