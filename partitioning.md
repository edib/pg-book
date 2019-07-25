## pg11 partition

```
CREATE TABLE measurement (
    logdate         date not null,
    peaktemp        int,
    unitsales       int
) PARTITION BY RANGE (logdate);

CREATE TABLE measurement_y2016 PARTITION OF measurement
FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE measurement_y2017 PARTITION OF measurement
FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE measurement_y2018 PARTITION OF measurement
FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE measurement_y2019 PARTITION OF measurement
FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');

INSERT INTO measurement (logdate, peaktemp, unitsales)
    VALUES ('2016-07-10', 66, 100); -- goes into measurement_y2016 table

insert into measurement (logdate,peaktemp, unitsales) SELECT logdate,1,1 FROM generate_series('2016-01-01'::date, '2018-12-31'::date, '1 min') as logdate;

-- alter table measurement5 rename to measurement;

explain analyse select * from measurement where logdate between '2017-11-01' and '2018-12-01';

select count(*)
	from measurement
	where logdate between '2019-01-01' and '2020-01-01';


update measurement set peaktemp=(random()*100)::int, unitsales=(random()*100)::int;

```
