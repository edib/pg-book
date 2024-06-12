# fts

Metni simgelere (token) dönüştürme (Parsing documents into tokens): (sayılar, kelimeler, karmaşık kelimeler , email adresleri olabilir.) Böyle her biri farklı işlenebilir. Bunu postgresql parser yapar. Custom parser da uygulanabilir.
Simgeleri (token) sözcük birimlerine (lexeme) dönüştürme (Converting tokens into lexemes): Bunlar aslında stringdir. Simgelere benzer fakat aynı kelimenin eklerinden ayrıştırılmış ve küçük harfe dönüştürülmüş halidir . Bu aynı kelimenin farklı ekli olanlarını bulmasını sağlar. 
Arama için optimize edilmiş, işlenmiş metinlerin saklanması (Storing preprocessed documents optimized for searching): Her metin sıralanmış normalize edilmiş sözcük birimlerinin (lexeme) dizisi olarak gösterilir. Bu dizi içerisinde ayrıca yakınlık derecelendirmesi (proximity ranking) koymakta istenebilir. 

Fulltext aramada sözlükler vardır. Sözlükler simgelerin normalleştirilmesi konusunda ciddi bir fayda sağlamaktadır. 

Veri Tipleri:

tsvector: İşlenmiş dokümanı saklar.

tsquery: işlenmiş sorguları göstermek için kullanır.

Operatörler:

@@ : en çok kullanılıdır. 


tsquery oeratörleri:

& (ve), | (ya da), !(değil), <-> (takip eder)

bu operatörlerin sağlıklı sonuçlar döndürebilmesi için tanımın tsquery olması gerekmektedir.


# cat ve rat olacak
to_tsquery('cat & rat') 
# cat ya da rat olacak
to_tsquery('cat | rat')
# cat olacak rat olmayacak 

to_tsquery('cat & ! rat')
# cat'i rat takip edecek.
to_tsquery('cat <-> rat')


< - > operatörünün daha genel kullanım alanları vardır. <1> operatörü default operatörler aynı işi yapar. <2> operatörü ise takip eden sözcükbirimi (lexeme) bir sonrasında değil 2 sonrasında takip edecek anlamına gelmektedir. 

SELECT phraseto_tsquery('the cats ate the rats');
phraseto_tsquery
-------------------------------
'cat' <-> 'ate' <2> 'rat'



fonksiyonlar: 

type casting yerine kullanılması tavsiye edilmektedir. 

to_tsvector()

to_tsquery()

plainto_tsquery()

phraseto_tsquery()



Indexler: İndexler kullanılarak FTS oldukça hızlandırılabilmektedir. 

Dokuman: FTS'deki arama birimidir. Örn: Dergi makalesi, yada eposta mesajıdır. 

Örnek: 

SELECT title || ' ' || author || ' ' || abstract || ' ' || body AS document
FROM messages
WHERE mid = 12;

SELECT m.title || ' ' || m.author || ' ' || m.abstract || ' ' || d.body AS document
FROM messages m, docs d
WHERE mid = did AND mid = 12;


Temel text araması:

@@  operatörü tsquery(query) yi tsvector(döküman) içerisinde aramasını gerçekleştirir. 

SELECT 'a fat cat sat on a mat and ate a fat rat'::tsvector @@ 'cat & rat'::tsquery;
?column?
----------
t

Veri tabanındaki alan üzerinden yaparsak

create table x (t text);
insert into x values ('a fat cat sat on a mat and ate a fat rat');

tsquery ile arama yapıyoruz.

select * from x where t::tsvector @@ 'cat & rat'::tsquery; 
                   t
------------------------------------------
 a fat cat sat on a mat and ate a fat rat
(1 row)


select * from x where t::tsvector @@ 'cat & ratt'::tsquery;
 t
---
(0 rows)

Bazan type casting yanlış sonuçlar çıkarabilmektedir. tsvector'ün adreslediği texti parser zaten normalize edilmiş kabul etmektedir. Bu yüzden "cats" normalize edilmez. 

SELECT 'fat cats ate fat rats'::tsvector @@ to_tsquery('cat & rat');
SELECT to_tsvector('fat cats ate fat rats') @@ to_tsquery('fat & rat');


@@ operatörü aşağıdaki operasyon seçeneklerini destekler.

tsvector @@ tsquery

SELECT to_tsvector('fat cats ate fat rats') @@ to_tsquery('fat & rat');


tsquery @@ tsvector

SELECT to_tsquery('fat & rat') @@ to_tsvector('fat cats ate fat rats');


text @@ tsquery ya da to_tsvector(x) @@ y

SELECT 'fat cats ate fat rats' @@ 'cat & rat'; 


text @@ text ya da to_tsvector(x) @@ plainto_tsquery(y)

SELECT 'fat cats ate fat rats' @@ 'fat rat'; 



