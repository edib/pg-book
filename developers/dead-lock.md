# DEADLOCK

PostgreSQL'de **deadlock** (kilitlenme) durumu, iki veya daha fazla işlemin birbirlerini beklemesi sonucu ortaya çıkar ve hiçbir işlem ilerleyemez. Bu, veritabanı kaynaklarının (örneğin, satırlar veya tablolar) kilitlenmesi sırasında gerçekleşir.

### Deadlock Durumu Oluşturma

Aşağıda, PostgreSQL'de deadlock durumunu simüle eden bir örnek verilmiştir. Bu örnekte, iki farklı işlem aynı anda birbiriyle çakışan kilitler almak isteyecek ve böylece deadlock durumu oluşacaktır.

#### Adımlar

1. **Tablo Oluşturma ve Veri Ekleme**
2. **İlk İşlemi Başlatma ve Kilit Alma**
3. **İkinci İşlemi Başlatma ve Kilit Alma**
4. **Deadlock Durumunun Oluşması**

### 1. Tablo Oluşturma ve Veri Ekleme

Öncelikle, `accounts` adlı bir tablo oluşturup birkaç satır ekleyelim:

```sql
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    balance NUMERIC(10, 2) NOT NULL
);

INSERT INTO accounts (balance) VALUES (1000.00), (1500.00), (2000.00);
```

### 2. İlk İşlemi Başlatma ve Kilit Alma

Birinci terminalde veya oturumda, bir işlemi başlatın ve `accounts` tablosundaki bir satırı kilitleyin:

```sql
BEGIN;

-- 1. Satırı kilitleme
UPDATE accounts SET balance = balance - 100.00 WHERE account_id = 1;

-- Bu işlemi ikinci işlemin başlatılmasını beklerken burada bırakın.
-- Henüz COMMIT veya ROLLBACK yapmayın.
```

### 3. İkinci İşlemi Başlatma ve Kilit Alma

İkinci terminalde veya oturumda, başka bir işlemi başlatın ve farklı bir satırı kilitleyin:

```sql
BEGIN;

-- 2. Satırı kilitleme
UPDATE accounts SET balance = balance - 200.00 WHERE account_id = 2;
```

Şimdi, bu işlemde bir deadlock oluşturacağız.

### 4. Deadlock Durumunun Oluşması

**Birinci oturum**:
Bu oturumda, ikinci satırı güncellemeye çalışın:

```sql
-- 2. Satırı kilitleme girişimi
UPDATE accounts SET balance = balance - 200.00 WHERE account_id = 2;
```

**İkinci oturum**:
Bu oturumda, birinci satırı güncellemeye çalışın:

```sql
-- 1. Satırı kilitleme girişimi
UPDATE accounts SET balance = balance - 100.00 WHERE account_id = 1;
```

### Deadlock Durumu

- İlk oturumda, `account_id = 1` satırında kilit alındı ve daha sonra `account_id = 2` üzerinde kilit almak için bekleniyor.
- İkinci oturumda, `account_id = 2` satırında kilit alındı ve daha sonra `account_id = 1` üzerinde kilit almak için bekleniyor.

Bu durumda, PostgreSQL bir deadlock tespit eder ve işlemlerden birini sonlandırır (rollback yapar) ve hata mesajı ile geri döner:

```plaintext
ERROR:  deadlock detected
DETAIL:  Process 12345 waits for ShareLock on transaction 67890; blocked by process 54321.
Process 54321 waits for ShareLock on transaction 12345; blocked by process 12345.
HINT:  See server log for query details.
CONTEXT:  while locking tuple (1,2) in relation "accounts"
```

### Deadlock'u Önlemek İçin İpuçları

- **Tutarlı Kilitleme Sırası**: Tüm işlemlerin veritabanı kaynaklarını aynı sırada kilitlemesini sağlayarak deadlock'u önleyebilirsiniz.
- **Kilitleri Minimize Etme**: Gereksiz kilitlemelerden kaçının ve mümkünse daha küçük kilitleme alanları (örneğin, satır bazında kilitleme yerine tablo bazında kilitleme) kullanın.
- **Zaman Aşımı Ayarı**: Kilitlemelerin çok uzun sürmesini önlemek için zaman aşımı ayarlarını yapılandırabilirsiniz. Bu, potansiyel deadlock durumlarını daha erken tespit etmeye yardımcı olur.

```sql
SET lock_timeout TO '10s';
```

### Özet

Deadlock'lar, iki veya daha fazla işlemin birbirini beklemesi ve bu nedenle hiçbir işlemin ilerleyememesi durumudur. PostgreSQL'de bu tür durumları tespit etmek ve yönetmek için sistemler vardır. Bu örnek, deadlock'ların nasıl oluşabileceğini ve bu tür durumları nasıl yönetebileceğinizi anlamanızı sağlar.