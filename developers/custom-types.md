# custom types

```sql

CREATE TYPE FRUIT_QTY as (name text, qty int);
 
SELECT '("APPLE", 3)'::FRUIT_QTY;
 
 
CREATE FUNCTION fruit_qty_larger_than(left_fruit FRUIT_QTY,
                                      right_fruit FRUIT_QTY)
RETURNS BOOL
AS $$
BEGIN
    IF (left_fruit.name = 'APPLE' AND right_fruit.name = 'ORANGE')
    THEN
        RETURN left_fruit.qty > (1.5 * right_fruit.qty);
    END IF;
    IF (left_fruit.name = 'ORANGE' AND right_fruit.name = 'APPLE' )
    THEN
        RETURN (1.5 * left_fruit.qty) > right_fruit.qty;
    END IF;
    RETURN  left_fruit.qty > right_fruit.qty;
END;
$$
LANGUAGE plpgsql;
 
SELECT fruit_qty_larger_than('("APPLE", 3)'::FRUIT_QTY,'("ORANGE", 2)'::FRUIT_QTY);
 
SELECT fruit_qty_larger_than('("APPLE", 4)'::FRUIT_QTY,'("ORANGE", 2)'::FRUIT_QTY);
 
CREATE OPERATOR > (
    leftarg = FRUIT_QTY,
    rightarg = FRUIT_QTY,
    procedure = fruit_qty_larger_than,
    commutator = >
);
 
SELECT '("ORANGE", 2)'::FRUIT_QTY > '("APPLE", 2)'::FRUIT_QTY;
 
SELECT '("ORANGE", 2)'::FRUIT_QTY > '("APPLE", 3)'::FRUIT_QTY;

```