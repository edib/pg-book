## WITH Sorgular (Common Table Expressions)

```sql

CREATE TABLE employees
(
  employeeid int NOT NULL PRIMARY KEY,
  firstname varchar(50) NOT NULL,
  lastname varchar(50) NOT NULL,
  managerid int NULL
);

INSERT INTO employees VALUES (1, 'Ken', 'Thompson', NULL);
INSERT INTO employees VALUES (2, 'Terri', 'Ryan', 1);
INSERT INTO employees VALUES (3, 'Robert', 'Durello', 1);
INSERT INTO employees VALUES (4, 'Rob', 'Bailey', 2);
INSERT INTO employees VALUES (5, 'Kent', 'Erickson', 2);
INSERT INTO employees VALUES (6, 'Bill', 'Goldberg', 3);
INSERT INTO employees VALUES (7, 'Ryan', 'Miller', 3);
INSERT INTO employees VALUES (8, 'Dane', 'Mark', 5);
INSERT INTO employees VALUES (9, 'Charles', 'Matthew', 6);
INSERT INTO employees VALUES (10, 'Michael', 'Jhonson', 6) ;

with recursive ctereports (empid, firstname, lastname, mgrid, emplevel)
  as
  (
    select employeeid, firstname, lastname, managerid, 1
    from employees
    where managerid is null
    union all
    select e.employeeid, e.firstname, e.lastname, e.managerid, 
      r.emplevel + 1
    from employees e
      inner join ctereports r
        on e.managerid = r.empid
  )
Select
  firstname || ' ' || lastname as fullname, 
  emplevel,
  (select firstname || ' '  ||  lastname from employees 
    where employeeid = ctereports.Mgrid) as manager
From ctereports 
Order by emplevel, mgrid;


```
Asus Zenbook 14 Oled UX3405MA
```sql
WITH RECURSIVE count_series(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM count_series WHERE n < 5
)
SELECT * FROM count_series;

```

recursive query örneği

```sql

CREATE TABLE directory (
  id           INT NOT NULL,
  parent_id    INT,
  label        text,

  CONSTRAINT pk_directory PRIMARY KEY (id),
  CONSTRAINT fk_directory FOREIGN KEY (parent_id) REFERENCES directory (id)
);

INSERT INTO directory VALUES ( 1, null, 'C:');
INSERT INTO directory VALUES ( 2,    1, 'eclipse');
INSERT INTO directory VALUES ( 3,    2, 'configuration');
INSERT INTO directory VALUES ( 4,    2, 'dropins');
INSERT INTO directory VALUES ( 5,    2, 'features');
INSERT INTO directory VALUES ( 7,    2, 'plugins');
INSERT INTO directory VALUES ( 8,    2, 'readme');
INSERT INTO directory VALUES ( 9,    8, 'readme_eclipse.html');
INSERT INTO directory VALUES (10,    2, 'src');
INSERT INTO directory VALUES (11,    2, 'eclipse.exe');

WITH RECURSIVE t (
  id,
  name,
  path
) AS (
  SELECT
    DIRECTORY.ID,
    DIRECTORY.LABEL,
    DIRECTORY.LABEL
  FROM
    DIRECTORY
  WHERE
    DIRECTORY.PARENT_ID IS NULL
  UNION ALL
  SELECT
    DIRECTORY.ID,
    DIRECTORY.LABEL,
    t.path
      || '\'
      || DIRECTORY.LABEL
  FROM
    t
  JOIN
    DIRECTORY
  ON t.id = DIRECTORY.PARENT_ID
)
SELECT *
FROM
  t;

```

* https://www.postgresql.org/docs/current/queries-with.html