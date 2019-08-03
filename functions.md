#functions

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
