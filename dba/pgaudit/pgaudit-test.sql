-- pgaudit çok satırlı test sorgusu
-- Amaç: farklı statement sınıflarının (ddl, write, read, role) ve
-- çok satırlı / yorum içeren bir sorgunun csvlog'daki AUDIT: satırında
-- nasıl göründüğünü incelemek.

-- 1) DDL sınıfı
CREATE TABLE IF NOT EXISTS pgaudit_test_orders (
    id          serial PRIMARY KEY,
    customer    text NOT NULL,
    amount      numeric(10, 2) NOT NULL,
    created_at  timestamptz DEFAULT now()
);

-- 2) WRITE sınıfı - çok satırlı INSERT, birden fazla değer satırı
INSERT INTO pgaudit_test_orders (customer, amount)
VALUES
    ('Ayşe Yılmaz', 150.75),
    ('Mehmet Demir', 42.00),
    ('Zeynep Kaya', 999.99);

-- 3) READ sınıfı - JOIN, WHERE, ORDER BY içeren, satır sonu ve
--    içinde yorum barındıran bir sorgu
SELECT
    o.id,
    o.customer,
    o.amount,
    /* toplam tutara göre etiketleme */
    CASE
        WHEN o.amount > 500 THEN 'yüksek'
        WHEN o.amount > 100 THEN 'orta'
        ELSE 'düşük'
    END AS seviye
FROM pgaudit_test_orders AS o
WHERE o.amount > 0
    AND o.customer LIKE '%a%'
ORDER BY o.amount DESC
LIMIT 10;

-- 4) WRITE sınıfı - çok satırlı UPDATE
UPDATE pgaudit_test_orders
SET amount = amount * 1.10,
    created_at = now()
WHERE customer = 'Mehmet Demir';

-- 5) WRITE sınıfı - DELETE
DELETE FROM pgaudit_test_orders
WHERE amount < 50;

-- 6) ROLE sınıfı - test amaçlı, gerekirse yorum satırı yapabilirsiniz
-- GRANT SELECT, INSERT ON pgaudit_test_orders TO appuser;

-- 7) Temizlik (isterseniz ayrı çalıştırın, aynı log dosyasında ayrı bir
--    AUDIT satırı olarak görünür)
-- DROP TABLE pgaudit_test_orders;
