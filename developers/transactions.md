# transactions

```sql
-- Create the 'subeler' table
CREATE TABLE subeler (
    isim VARCHAR(50) PRIMARY KEY,   -- Branch name
    bakiye NUMERIC(15, 2)          -- Branch balance
);

-- Create the 'hesaplar' table
CREATE TABLE hesaplar (
    isim VARCHAR(50) PRIMARY KEY,   -- Account holder's name
    bakiye NUMERIC(15, 2),          -- Account balance
    sube_adi VARCHAR(50) REFERENCES subeler(isim)  -- Branch name (foreign key)
);

-- Insert sample data into 'subeler' table
INSERT INTO subeler (isim, bakiye) VALUES
('Branch1', 10000.00),
('Branch2', 15000.00);

-- Insert sample data into 'hesaplar' table
INSERT INTO hesaplar (isim, bakiye, sube_adi) VALUES
('A', 500.00, 'Branch1'),
('B', 300.00, 'Branch2');


```

```sql
-- Perform the update statements
UPDATE hesaplar SET bakiye = bakiye - 100.00
    WHERE isim = 'A';
UPDATE subeler SET bakiye = bakiye - 100.00
    WHERE isim = (SELECT sube_adi FROM hesaplar WHERE isim = 'A');
UPDATE hesaplar SET bakiye = bakiye + 100.00
    WHERE isim = 'B';
UPDATE subeler SET bakiye = bakiye + 100.00
    WHERE isim = (SELECT sube_adi FROM hesaplar WHERE isim = 'B');

```