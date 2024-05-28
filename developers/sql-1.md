## Örnek Veri İşlemleri

* pagila (dvdrental) veritabanını kullanacağız.

```
su - postgres
git clone https://github.com/edib/pagila.git
cd pagila
# dosyalarımızın içine bakıyoruz.
```
yeni bir `veritabanı` oluşturuyoruz ve bağlanıyoruz.
```
psql -c "create database pagila"
psql pagila  < pagila-schema.sql
psql pagila  < pagila-data.sql
```
 * Görsel bir SQL IDE'den `pagila` veritabanımıza bağlanabiliriz.

### Operatörler
```
-- where release_year is 2006 and rental_duration is 6 days
SELECT *
FROM film
WHERE release_year = 2006
	AND rental_duration = 6;

-- where release_year is 2006 or rental_duration is 6 days
SELECT *
FROM film
WHERE release_year = 2006
	OR rental_duration = 6;

-- where release_year is 2006 and rental_duration is not 6 days
SELECT *
FROM film
WHERE release_year = 2006
	AND NOT rental_duration = 6;

SELECT *
FROM film
WHERE release_year = 2006
	AND rental_duration <> 6;

-- where rental_duration is between 2 and 6 days
SELECT *
FROM film
WHERE  rental_duration >=2
	AND rental_duration <= 6;

SELECT *
FROM film
WHERE  rental_duration BETWEEN 2 AND 6;

-- where length is equal to 160 minutes or rental_duration is between 2 and 6 days
SELECT *
FROM film
WHERE length = 160
	OR (rental_duration >=2
		AND rental_duration <= 6);

```

### Gömülü Fonksiyonlar
* https://www.postgresql.org/docs/current/functions.html

```
-- film süresini dakikadan saate çevirirken
SELECT film_id, title, length,
		(length/60.0) length_in_hour,
		round((length/60.0),2) length_in_hour_round
FROM film;

-- film süresi 2 saatten fazla olan filmleri seçin
SELECT film_id, title, length,
		(length/60.0) length_in_hour,
		round((length/60.0),2) length_in_hour_round
FROM film
WHERE length > 120;

SELECT film_id, title, length,
		(length/60.0) length_in_hour,
		round((length/60.0),2) length_in_hour_round
FROM film
WHERE (length/60.0) > 2;

-- while converting rental_rate to nearest higher integer
SELECT film_id, title, rental_rate ,
		ceiling(rental_rate) rental_rate_new
FROM film;

```

### String Operasyonları
```
-- while combining first_name and last_name in single column
SELECT first_name, last_name, first_name || ' ' || last_name AS full_name
FROM Actor;

SELECT first_name, last_name, CONCAT(first_name, ' ', last_name) AS full_name
FROM Actor;

-- with extra column which will list the initials of the actor
SELECT first_name, last_name, LEFT(first_name,1) || LEFT(last_name,1) AS Initials
FROM Actor;

-- where the length of the name is of 4 characters
SELECT first_name, last_name
FROM Actor
WHERE LENGTH(first_name) = 4
	OR LENGTH(last_name) = 4;


SELECT first_name, last_name
FROM Actor
WHERE LENGTH(first_name) = 4
AND LENGTH(last_name) = 4;

-- while converting all the last name in the upper case
SELECT first_name, last_name, UPPER(last_name) UpperLastName
FROM Actor;

-- while replacing character a with character @ in column first_name
SELECT first_name, REPLACE(first_name,'a','@'), last_name
FROM Actor;
```

### Tarih işlemleri
```
-- while displaying rental duration in days and hours
SELECT (return_date - rental_date) AS rented_days
FROM rental;

-- where rental duration of movie is over 3 days
SELECT (return_date - rental_date) rented_days,
	EXTRACT(days FROM return_date - rental_date)
FROM rental
WHERE EXTRACT(days FROM return_date - rental_date) > 3;

-- where rental duration of movie is over 100 hours
SELECT (return_date - rental_date) rented_days,
	EXTRACT(epoch FROM (return_date - rental_date))/3600
FROM rental
WHERE EXTRACT(epoch FROM (return_date - rental_date))/3600 > 100;

-- while adding an extra column with fix return_date as 7 days from rental
SELECT rental_date,
	return_date AS original_return_date,
	rental_date + interval '7 day' AS new_return_date,
	return_date - (rental_date + interval '7 day') difference
FROM rental;
```

### Bütünleme İşlemleri
```
-- Display the number of total rental in history
SELECT COUNT(*)
FROM rental;

-- Display the first ever rental and the latest rental
SELECT min(rental_date) FirstRental,
	max(rental_date) LastRental
FROM rental;

-- Find out total rental payment collected from customers
SELECT sum(amount) RentalAmount
FROM payment;
```

### Window Fonksiyonlar
[[+]](http://www.postgresqltutorial.com/postgresql-window-function/)
[[+]](https://www.postgresql.org/docs/current/tutorial-window.html)
