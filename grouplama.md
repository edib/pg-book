# Gruplama Ve Grup Veri Üzerinde Çalışma
```
postgres=# CREATE TABLE ogrenci (
id int,
isim VARCHAR(50),
dogdugu_sehir VARCHAR(20),
dogum_tarihi date);
```
## GROUP BY:

* **Group By**, sorgulanan verilerin içerisinde tekrar edenleri gruplayarak tek bir satırda göstermek için kullanılır.
* Group by ifadese, FROM ve WHERE tümcelerinden sonra gelmelidir. Sorguda, WHERE ifadesinden sonraki kriterler işletilden sonra Group By fonksiyonu işlemektedir

* 1987 yılında doğan kişileri doğdukları şehre göre gruplayalım :

```
postgres=# SELECT * from ogrenci ;
 id |         isim          | dogdugu_sehir | dogum_tarihi
----+-----------------------+---------------+--------------
  1 | berkan yıldırım       | Kırsehir      | 1996-01-01
 13 | Ibrahim Edbp Kokdemir | Cankiri       | 1976-02-02
 28 | Dilara Tugce          | Ankara        | 1995-12-28
 57 | Selim Altınsoy        | Konya         | 1995-02-28
 77 | Murat Yıldız          | Ankara        | 1997-02-28
(5 rows)
```

```
postgres=# SELECT dogdugu_sehir FROM ogrenci
WHERE dogum_tarihi BETWEEN '1987-01-01' AND '1999-01-01'
GROUP BY dogdugu_sehir;
```
  Bu durumda **GROUP BY** ifadesi, sonuç kümesinde yenilenen satırları kaldırarak **DISTINCT** ifadesi gibi davranır.
```
 dogdugu_sehir
---------------
 Ankara
 Kırsehir
 Konya
(3 rows)
```
*Eğer sonuç listemizin sıralamasını değiştirmek istiyorsak **ORDER BY** komutunu kullanabiliriz.*

**ORDER BY**
* ORDER BY komutu, sıralama düzenini belirtmek için kullanılmaktadır.  

* Sıralama yönünü artan veya azalan olarak ayarlamak için ASC (Ascending-Artan) veya DESC (Descending-Azalan) ifadeleri kullanılmaktadır.
* Bazı durumlarda verileri belirli bir sıraya göre değilde rastgele çekme ihtiyacımız olur. Bu durumda rastgele bir değer çekmek için ;
  ```
  SELECT ogrenci_adi_soyadi FROM tb_ogreci ORDER BY random();
  ```
**HAVING**
* Belirli bir koşulu karşılayamayan grup satırlarını filtrelemek için genellikle **GROUP BY** tümcesiyle birlikte **HAVING** tümcesi kullanılmaktadır.
*  WHERE koşulu ile HAVING'i ayıran temel fark; WHERE koşulunda yer alan ifadeler GROUP BY ifadesinden önce işletilmekte ve tek tek satırlariçin koşulları ayarlanmaktayken; HAVING ise GROUP BY ifadesinden sonra oluşan ifadelerle grup satır koşullarını ayarlamaktadır.

*tb_ogrenci tablomuzda ders adıve vize notuna göre gruplamayı yaptıktan sonra vize notu 50'den büyük olan dersleri ve vize notlarını bulalım:*
```
SELECT ders_adi, vize_notu FROM tb_ogrenci GROUP BY ders_adi, vize_notu HAVING vize_notu > 50;
```

**LIMIT-OFFSET**
* Oluşturulan sorgu neticesinde gelen sonuçların sadece bir bölümünün seçilmesi istendiği durumlarda tercih edilir.
* Çekilen veriler sınırlı sayıda isteniyorsa LIMIT; eğer belli sayıda veriyi atladıktan sonra sorgunun çalışması isteniyorsa OFFSET ifadeleri kullanılır.
  ```
  SELECT id,ogreci_adi_soyadi FROM tb_ogrenci LIMIT 3;

   id |   ogreci_adi_soyadi   
  ----+-----------------------
   1 | berkan yıldırım
  13 | Ibrahim Edip Kokdemir
  28 | Dilara Tugce
  (3 rows)

  ```
* Eğer sorguda ORDER BY kriteri yoksa limit ile çekilen sorguların her birinde farklı sonuçlar gelebilir. Bu sebeple LIMIT koşulunu kullanırken ORDER BY ile kullanmak önemli ve anlamlıdır.
