#dwh özellikleri

### GROUPING SETS Örneği

`GROUPING SETS` kullanarak dil ve seviye bazında gruplama yapalım ve toplam öğrenci sayısını hesaplayalım. Bu, farklı kombinasyonlarla gruplama yaparak her kombinasyon için toplamları döndürmemizi sağlar.

```sql
SELECT dil, seviye, COUNT(*) AS ogrenci_sayisi
FROM kurs_kayit
GROUP BY GROUPING SETS (
    (dil),
    (seviye),
    (dil, seviye),
    ()
);
```

Bu sorgu aşağıdaki gruplama seviyelerinde öğrenci sayılarını döndürecektir:
1. Sadece `dil`
2. Sadece `seviye`
3. `dil` ve `seviye`
4. Hiçbir gruplama olmadan toplam öğrenci sayısı

### CUBE Örneği

`CUBE` kullanarak tüm olası gruplama kombinasyonları için öğrenci sayılarını hesaplayalım.

```sql
SELECT dil, seviye, COUNT(*) AS ogrenci_sayisi
FROM kurs_kayit
GROUP BY CUBE (dil, seviye);
```

Bu sorgu, aşağıdaki tüm kombinasyonları kapsayan toplamları döndürecektir:
1. `dil` ve `seviye`
2. Sadece `dil`
3. Sadece `seviye`
4. Hiçbir gruplama olmadan toplam öğrenci sayısı

### ROLLUP Örneği

`ROLLUP` kullanarak dil ve seviye bazında hiyerarşik toplamlar hesaplayalım.

```sql
SELECT dil, seviye, COUNT(*) AS ogrenci_sayisi
FROM kurs_kayit
GROUP BY ROLLUP (dil, seviye);
```

Bu sorgu aşağıdaki gruplama seviyelerinde öğrenci sayılarını döndürecektir:
1. `dil` ve `seviye`
2. Sadece `dil`
3. Hiçbir gruplama olmadan toplam öğrenci sayısı

### Örnek Sonuçlar

Verdiğiniz verilerle bu sorguların döndüreceği örnek sonuçları inceleyelim.

#### GROUPING SETS Sonuçları

```sql
 dil         | seviye | ogrenci_sayisi
-------------|--------|----------------
 İSPANYOLCA  |        | 9
 JAPONCA     |        | 6
             | Giriş  | 7
             | Orta   | 4
 İSPANYOLCA  | Giriş  | 6
 İSPANYOLCA  | Orta   | 3
 JAPONCA     | Giriş  | 4
 JAPONCA     | Orta   | 2
             |        | 15
```

#### CUBE Sonuçları

```sql
 dil         | seviye | ogrenci_sayisi
-------------|--------|----------------
 İSPANYOLCA  | Giriş  | 6
 İSPANYOLCA  | Orta   | 3
 JAPONCA     | Giriş  | 4
 JAPONCA     | Orta   | 2
 İSPANYOLCA  |        | 9
 JAPONCA     |        | 6
             | Giriş  | 10
             | Orta   | 5
             |        | 15
```

#### ROLLUP Sonuçları

```sql
 dil         | seviye | ogrenci_sayisi
-------------|--------|----------------
 İSPANYOLCA  | Giriş  | 6
 İSPANYOLCA  | Orta   | 3
 İSPANYOLCA  |        | 9
 JAPONCA     | Giriş  | 4
 JAPONCA     | Orta   | 2
 JAPONCA     |        | 6
             |        | 15
```

Bu örnekler, PostgreSQL'de `GROUPING SETS`, `CUBE` ve `ROLLUP` fonksiyonlarını kullanarak farklı gruplama ve toplama işlemlerini nasıl gerçekleştirebileceğinizi göstermektedir. Bu yöntemler, verilerinizi daha esnek ve güçlü bir şekilde analiz etmenizi sağlar.
