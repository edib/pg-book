## FUNCTIONS

```
-- bir sorgu sanal bir tablo olarak dönebilir.
CREATE OR REPLACE FUNCTION return_timestamp()
    RETURNS TABLE(mytime TIMESTAMP with timezone) AS
$BODY$
    SELECT now();
$BODY$ LANGUAGE SQL;

-- bir sorgu bir veri tipi olarak dönebilir.

CREATE FUNCTION one() RETURNS integer as '
    SELECT 1;
' language sql;

-- parametreler parametre adlarıyla birlikte oluşturulabilir.
CREATE FUNCTION my_power(x integer, y integer) RETURNS FLOAT AS $$
    SELECT x ^ y;
$$ LANGUAGE SQL;

-- ya da sadece typelar yeterli olmaktadır.
CREATE FUNCTION my_power(integer, integer) RETURNS FLOAT AS $$
    SELECT $1 ^ $2;
$$ LANGUAGE SQL;

-- function update işlemi için de kullanılabilir.
CREATE FUNCTION tf1 (accountno integer, debit numeric) RETURNS numeric AS $$
    UPDATE bank
        SET balance = balance - debit
        WHERE accountno = tf1.accountno;
    SELECT 1.0;
$$ LANGUAGE SQL;

-- returns yerine in out aynı yerde tanımlanabilir. Okuma açısından kolaylık sağlar.
CREATE FUNCTION add_em (IN x int, IN y int, OUT sum int)
    AS 'SELECT x + y'
LANGUAGE SQL;

-- returns yerine in out aynı yerde tanımlanabilir. Okuma açısından kolaylık sağlar. Ayrıca sadece veri tipini de kullanabiliriz.
CREATE FUNCTION add_em (int, int, OUT int)
    AS 'SELECT $1 + $2'
LANGUAGE SQL;

-- double parametre selectlenebiliyor
CREATE FUNCTION sum_n_product (x int, y int, OUT sum int, OUT product int)
    AS 'SELECT x + y, x * y'
LANGUAGE SQL;


-- CUSTOM DATA TYPE İLE FUNCTİON YAZABİLİRİZ.
CREATE TYPE sum_prod AS (sum int, product int);

CREATE FUNCTION sum_n_product (int, int, out sum_prod)
AS 'SELECT $1 + $2, $1 * $2'
LANGUAGE SQL;
```

## PROCEDURES

PostgreSQL'de, fonksiyonlar ve prosedürler belirli görevleri yerine getirmek için yazılabilir, ancak bazı farklılıklar vardır.

### PostgreSQL'deki Stored Procedures ve Functions

#### Functions (Fonksiyonlar)

PostgreSQL'de **functions** (fonksiyonlar), belirli bir değeri veya sonuç setini döndüren PL/pgSQL veya başka bir dilde yazılmış kod parçalarıdır. Fonksiyonlar genellikle bir sorgu içerisinde kullanılabilir ve belirli bir sonucu döndürmek üzere tasarlanmıştır.

- **Temel Özellikler**:
  - **Değer Döndürme**: Fonksiyonlar her zaman bir değer döndürür (basit bir değer veya bir sonuç kümesi).
  - **DML İşlemleri**: Fonksiyonlar içlerinde SQL sorguları çalıştırabilir, ancak genellikle veri manipülasyon (DML) işlemleri yapmazlar.
  - **Kullanım**: Fonksiyonlar SELECT, WHERE, FROM gibi SQL deyimleri içinde kullanılabilir.

- **Örnek Fonksiyon**:

```sql
CREATE FUNCTION add_numbers(a INTEGER, b INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN a + b;
END;
$$ LANGUAGE plpgsql;
```


Bu fonksiyon iki tamsayıyı toplar ve sonucu döndürür.

#### Procedures (Prosedürler)

PostgreSQL 11 ve sonraki sürümlerinde **procedures** (prosedürler) tanıtılmıştır. Prosedürler, fonksiyonlardan farklı olarak doğrudan SQL deyimlerini (DML - Data Manipulation Language işlemleri gibi) ve kontrol yapıları içerebilir ve ayrıca dış dünyaya sonuç döndürmek zorunda değildirler.

- **Temel Özellikler**:
  - **İşlemleri Yürütme**: Prosedürler, fonksiyonlardan farklı olarak veri manipülasyon işlemlerini (INSERT, UPDATE, DELETE) doğrudan yürütmek için kullanılır.
  - **CALL İfadesi**: Prosedürler, `CALL` ifadesi kullanılarak yürütülür.
  - **Transaksiyon Kontrolü**: Prosedürler, PL/pgSQL içindeki transaksiyonları (transactions) kontrol etmek için `COMMIT` ve `ROLLBACK` ifadelerini kullanabilirler.
  - **Değer Döndürmezler**: Prosedürler bir değer döndürmek zorunda değildir.

- **Örnek Prosedür**:

```sql
CREATE PROCEDURE insert_user(name TEXT, age INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO users (name, age) VALUES (name, age);
END;
$$;
```

Bu prosedür `users` tablosuna yeni bir kullanıcı ekler.

### Fonksiyonlar ve Prosedürler Arasındaki Farklar

| Özellik              | Fonksiyon (Function)                           | Prosedür (Procedure)                             |
|----------------------|-----------------------------------------------|------------------------------------------------|
| **Değer Döndürme**   | Evet (bir değer veya sonuç seti döndürür)      | Hayır (değer döndürmek zorunda değildir)        |
| **DML İşlemleri**    | Genellikle sınırlı, veri okuma amaçlı kullanılır | DML işlemlerini doğrudan gerçekleştirebilir   |
| **Kullanım**         | SQL sorguları içinde kullanılabilir            | `CALL` ifadesiyle doğrudan yürütülür            |
| **Transaksiyon Kontrolü** | Yok (genellikle)                              | Evet (transaksiyonları kontrol edebilir)       |

### Fonksiyon ve Prosedürlerin Listelenmesi

PostgreSQL'de tanımlanmış tüm fonksiyonları ve prosedürleri görmek için `pg_catalog` ve `information_schema` görünümlerini kullanabilirsiniz.

- **Fonksiyonları Listeleme**:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_type = 'FUNCTION'
  AND specific_schema = 'SİZİN ŞEMA';
```

Bu sorgu, veritabanınızda tanımlı olan kullanıcı tanımlı fonksiyonları listeler.

- **Prosedürleri Listeleme**:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_type = 'PROCEDURE'
  AND specific_schema = 'SİZİN ŞEMA';
```

Bu sorgu, veritabanınızda tanımlı olan kullanıcı tanımlı prosedürleri listeler.

### PostgreSQL'de Fonksiyon ve Prosedürlerin Kullanımı

- **Fonksiyon Kullanımı**: Fonksiyonlar, SELECT ifadeleri içinde veya WHERE koşulunda kullanılabilir.
  ```sql
  SELECT add_numbers(5, 10);
  ```

- **Prosedür Kullanımı**: Prosedürler, `CALL` ifadesi ile yürütülür.
  ```sql
  CALL insert_user('John Doe', 30);
  ```

## Anonim Fonksiyonlar

Elbette! PostgreSQL'de `DO` komutları, tek seferlik anonim PL/pgSQL blokları çalıştırmak için kullanılır. Bu komutlar, ad-hoc işlemler veya kısa süreli kod parçaları için uygundur ve bir fonksiyon tanımlamak zorunda kalmadan işlem yapmanızı sağlar. Aşağıda, `DO` komutlarının, `DECLARE` bölümlerinin ve PL/pgSQL'deki kullanım şekillerinin detaylı açıklaması verilmiştir.

### `DO` Komutu

`DO` komutu, PostgreSQL'de bir PL/pgSQL bloğunu çalıştırmanıza olanak tanır. Bu, bir prosedürü veya fonksiyonu tanımlamak zorunda kalmadan PL/pgSQL dilinde kod çalıştırmanızı sağlar.

#### Temel Kullanım

```sql
DO $$
BEGIN
    -- PL/pgSQL kodu burada çalışır
END $$;
```

- **`$$`**: Bu, `DO` bloğunun sınırlarını belirler. Alternatif olarak farklı bir sınır belirteci de kullanılabilir (örneğin, `$BODY$`).
- **`BEGIN ... END`**: Bu blok, PL/pgSQL komutlarını içerir ve işlem burada gerçekleşir.

### `DECLARE` Bölümü

`DECLARE` bölümü, `DO` bloğu veya PL/pgSQL fonksiyonu içinde kullanılacak yerel değişkenleri tanımlamak için kullanılır. Değişkenler, sorgulardan gelen verileri depolamak veya ara hesaplamalar yapmak için kullanılır.

#### Kullanım Örneği

```sql
DO $$
DECLARE
    my_variable INTEGER := 10;
    another_variable TEXT := 'Hello, World!';
BEGIN
    RAISE NOTICE 'my_variable: %, another_variable: %', my_variable, another_variable;
END $$;
```

- **`DECLARE`**: Bu anahtar kelime, `DO` bloğu veya bir PL/pgSQL fonksiyonu içindeki yerel değişkenlerin tanımlandığı bölümü belirtir.
- **Değişken Tanımlamaları**: Değişkenlerin tipi ve başlangıç değeri (isteğe bağlı olarak) belirtilir.
- **`BEGIN ... END`**: Bu blok, PL/pgSQL komutlarını içerir. Burada, değişkenler kullanılarak işlem yapılabilir.

### `DO` Komutunun Kullanım Alanları

`DO` komutları, çeşitli senaryolarda kullanışlıdır:

1. **Ad-hoc İşlemler**:
   - Bir kerelik veri işleme, sorgu çalıştırma veya sistem yönetimi görevleri için kullanılır.
   - Örneğin, bir tabloyu geçici olarak güncellemek veya belirli koşullara göre veri işlemek için.

2. **Dinamik SQL**:
   - `DO` komutları, dinamik SQL oluşturmak ve yürütmek için kullanılır. Bu, `EXECUTE` komutları ile dinamik olarak SQL ifadeleri çalıştırmanıza olanak tanır.

3. **Döngüler ve Koşullu Mantık**:
   - Döngüler (`FOR`, `WHILE`) ve koşullu ifadeler (`IF`, `CASE`) kullanarak karmaşık mantık işlemleri gerçekleştirebilir.

4. **Veri Göçü ve Dönüşüm**:
   - Veri migrasyonu, dönüşümü veya başka bir yapıya veri taşıma işlemlerinde geçici olarak kullanılır.

### PL/pgSQL (Procedural Language/PostgreSQL)

PL/pgSQL, PostgreSQL'in prosedürel dilidir ve fonksiyonlar, tetikleyiciler ve `DO` komutları gibi yapıların yazılmasına olanak tanır. PL/pgSQL, kontrol yapıları (döngüler, koşullu ifadeler), hata ayıklama, ve değişkenler kullanarak daha karmaşık ve esnek SQL işlemleri gerçekleştirmenizi sağlar.

### Örnek: Tüm Tablolar İçin Yetkileri Aktarma

Aşağıdaki örnek, bir şemadaki tüm tabloların yetkilerini bir kullanıcıdan diğerine aktarmak için PL/pgSQL ile yazılmış bir `DO` bloğunu gösterir:

```sql
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_schema = 'your_schema'
    ) LOOP
        EXECUTE 'GRANT ALL PRIVILEGES ON TABLE ' || quote_ident(r.table_schema) || '.' || quote_ident(r.table_name) || ' TO new_user';
    END LOOP;
END $$;
```

## Kod Örnekleri - Java

Java Spring uygulamasında PostgreSQL'de tanımlı bir stored procedure'ü çağırmak için genellikle **JDBC** (Java Database Connectivity) veya **Spring Data JPA** ile birlikte **`@Procedure`** anotasyonu kullanılır. Aşağıda, her iki yöntemi de detaylı olarak ele alacağız.

### 1. JDBC Kullanarak Stored Procedure Çağırma

JDBC kullanarak bir PostgreSQL prosedürünü çağırmak için aşağıdaki adımları izleyebilirsiniz:

#### Adım 1: Bağlantı Ayarları

Öncelikle, PostgreSQL veritabanına bağlanmak için bir `DataSource` veya `DriverManager` kullanarak bağlantı ayarlarını yapmalısınız.

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.CallableStatement;
import java.sql.SQLException;

public class JdbcExample {

    public static void main(String[] args) {
        String url = "jdbc:postgresql://localhost:5432/yourdatabase";
        String user = "yourusername";
        String password = "yourpassword";

        Connection conn = null;
        CallableStatement stmt = null;

        try {
            // Veritabanına bağlan
            conn = DriverManager.getConnection(url, user, password);

            // Prosedürü çağır
            String sql = "{call your_procedure_name(?, ?)}";
            stmt = conn.prepareCall(sql);

            // Parametreleri ayarla
            stmt.setInt(1, 123);  // İlk parametre (örnek)
            stmt.setString(2, "Example");  // İkinci parametre (örnek)

            // Prosedürü çalıştır
            stmt.execute();

            System.out.println("Procedure executed successfully!");

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            try {
                if (stmt != null) stmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
```

#### Adım 2: PostgreSQL JDBC Sürücüsünü Ekleme

Maven veya Gradle kullanıyorsanız, PostgreSQL JDBC sürücüsünü projenize eklemeniz gerekir.

**Maven**:
```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.2.24</version>
</dependency>
```

**Gradle**:
```groovy
implementation 'org.postgresql:postgresql:42.2.24'
```

### 2. Spring Data JPA Kullanarak Stored Procedure Çağırma

Spring Data JPA kullanarak bir stored procedure çağırmak daha modern ve Spring ile entegre bir yöntemdir. Aşağıdaki adımları izleyerek bunu yapabilirsiniz:

#### Adım 1: Entity Tanımı

Öncelikle, bir JPA entity sınıfı tanımlamanız gerekir.

```java
import javax.persistence.Entity;
import javax.persistence.Id;

@Entity
public class ExampleEntity {

    @Id
    private Long id;

    private String name;

    // Getters and setters
}
```

#### Adım 2: Repository Tanımı

Daha sonra, JPA repository'si tanımlayarak prosedürü çağırmak için `@Procedure` anotasyonunu kullanın.

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;

public interface ExampleRepository extends JpaRepository<ExampleEntity, Long> {

    // Prosedürü çağırmak için @Procedure anotasyonunu kullanın
    @Procedure(procedureName = "your_procedure_name")
    void callYourProcedure(@Param("param1") Integer param1, @Param("param2") String param2);
}
```

#### Adım 3: Service veya Controller'dan Prosedürü Çağırma

Artık Spring'inizin service veya controller katmanında prosedürü çağırabilirsiniz.

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ExampleService {

    @Autowired
    private ExampleRepository exampleRepository;

    public void executeProcedure() {
        // Prosedürü çağır
        exampleRepository.callYourProcedure(123, "Example");

        System.out.println("Procedure executed successfully!");
    }
}
```

### 3. Prosedür Örneği

PostgreSQL tarafında bir örnek prosedür:

```sql
CREATE OR REPLACE PROCEDURE your_procedure_name(param1 INTEGER, param2 TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- İşlemler burada
    RAISE NOTICE 'Procedure executed with param1: %, param2: %', param1, param2;
END;
$$;
```

### Sonuç

- **JDBC Kullanarak**: Daha düşük seviyeli bir erişim sağlar, manuel olarak bağlantı ve SQL işlemleri yapmanız gerekir.
- **Spring Data JPA Kullanarak**: Daha modern ve Spring entegrasyonu içeren bir yöntemdir, kodu daha temiz ve yönetilebilir hale getirir.

Bu iki yöntemden hangisinin kullanılacağı, projenizin gereksinimlerine ve mevcut teknoloji yığınınıza bağlıdır. Eğer Spring Data JPA kullanıyorsanız, Spring'in sunduğu `@Procedure` anotasyonu ile entegre bir şekilde stored procedure çağırmak daha temiz ve etkili olabilir.

### Kod Örnekleri - Python

Python'da PostgreSQL stored procedure'lerini çağırmak için genellikle **`psycopg2`** veya **`SQLAlchemy`** gibi PostgreSQL için popüler kütüphaneler kullanılır. Bu kütüphaneler, Python'dan PostgreSQL'e bağlantı kurmanıza ve SQL komutları veya prosedür çağrıları yapmanıza olanak tanır.

Aşağıda hem `psycopg2` hem de `SQLAlchemy` kullanarak stored procedure çağırma yöntemlerini detaylı olarak inceleyeceğiz.

### 1. `psycopg2` Kullanarak Stored Procedure Çağırma

`psycopg2`, Python ile PostgreSQL arasında etkileşim kurmak için kullanılan güçlü bir kütüphanedir.

#### Adım 1: `psycopg2` Kütüphanesini Yükleme

Öncelikle, `psycopg2` kütüphanesini yükleyin:

```bash
pip install psycopg2-binary
```

#### Adım 2: PostgreSQL'e Bağlanma ve Prosedürü Çağırma

Aşağıdaki örnek, `psycopg2` kullanarak bir PostgreSQL stored procedure'ünü çağırmayı gösterir:

```python
import psycopg2

# Veritabanı bağlantı bilgileri
dbname = "yourdatabase"
user = "yourusername"
password = "yourpassword"
host = "localhost"
port = "5432"

# Bağlantıyı oluştur
conn = psycopg2.connect(
    dbname=dbname, 
    user=user, 
    password=password, 
    host=host, 
    port=port
)

# Cursor oluştur
cur = conn.cursor()

try:
    # Prosedürü çağır
    cur.callproc('your_procedure_name', (123, 'Example'))  # Parametreleri burada değiştirin

    # Eğer prosedür bir sonuç seti döndürüyorsa, sonuçları alın
    results = cur.fetchall()
    for row in results:
        print(row)

    print("Procedure executed successfully!")
except Exception as e:
    print(f"Error: {e}")
finally:
    # Kaynakları serbest bırak
    cur.close()
    conn.close()
```

### 2. `SQLAlchemy` Kullanarak Stored Procedure Çağırma

`SQLAlchemy`, Python için popüler bir ORM (Object-Relational Mapping) kütüphanesidir ve doğrudan SQL çalıştırmak için de kullanılabilir.

#### Adım 1: `SQLAlchemy` Kütüphanesini Yükleme

Öncelikle, `SQLAlchemy` ve `psycopg2` kütüphanelerini yükleyin:

```bash
pip install sqlalchemy psycopg2-binary
```

#### Adım 2: PostgreSQL'e Bağlanma ve Prosedürü Çağırma

Aşağıdaki örnek, `SQLAlchemy` kullanarak bir PostgreSQL stored procedure'ünü çağırmayı gösterir:

```python
from sqlalchemy import create_engine, text

# Veritabanı bağlantı dizesi
engine = create_engine('postgresql+psycopg2://yourusername:yourpassword@localhost:5432/yourdatabase')

# Bağlantıyı oluştur ve bağlan
with engine.connect() as connection:
    try:
        # Prosedürü çağır
        result = connection.execute(text("CALL your_procedure_name(:param1, :param2)"), param1=123, param2='Example')

        # Eğer prosedür bir sonuç seti döndürüyorsa, sonuçları alın
        for row in result:
            print(row)

        print("Procedure executed successfully!")
    except Exception as e:
        print(f"Error: {e}")
```

### PostgreSQL Prosedür Örneği

İşte PostgreSQL tarafında bir prosedür örneği:

```sql
CREATE OR REPLACE PROCEDURE your_procedure_name(param1 INTEGER, param2 TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- İşlemler burada
    RAISE NOTICE 'Procedure executed with param1: %, param2: %', param1, param2;
END;
$$;
```

### Sonuç

- **`psycopg2`**: Python'dan PostgreSQL'e bağlantı kurmanın ve stored procedure çağırmanın düşük seviyeli bir yöntemidir. Doğrudan veritabanı işlemleri yapmanıza olanak tanır ve SQL komutlarını veritabanına gönderir.
- **`SQLAlchemy`**: Python için güçlü bir ORM kütüphanesidir ve aynı zamanda doğrudan SQL çalıştırmak için de kullanılabilir. ORM ve SQL kodlamasını birleştirerek daha esnek ve temiz bir çözüm sunar.

Her iki yöntem de PostgreSQL prosedürlerini Python'dan çağırmak için etkili bir yol sunar. Hangi yöntemi seçeceğiniz, projenizin gereksinimlerine ve mevcut teknoloji yığınınıza bağlıdır. Eğer SQLAlchemy'yi ORM olarak kullanıyorsanız, stored procedure çağırmak için de onu kullanmak kodunuzun tutarlılığını artırabilir.