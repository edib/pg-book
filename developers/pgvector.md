# pgvector

`pgvector`, PostgreSQL'e vektör (embedding) veri tipini ve bu vektörler üzerinde benzerlik araması yapabilmeyi kazandıran bir eklentidir. Özellikle yapay zeka/LLM uygulamalarında (RAG, semantik arama, öneri sistemleri) metin, görsel veya ses gibi verilerin embedding'lerini saklamak ve en yakın komşu (nearest neighbor) sorguları çalıştırmak için kullanılır.

### Kurulum

Paket üzerinden kurulum (Debian/Ubuntu, PostgreSQL sürümüne göre paket adını değiştirin):

```bash
sudo apt install postgresql-16-pgvector
```

Kaynak koddan derleme:

```bash
git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install
```

Veritabanında eklentiyi etkinleştirme:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### Vektör Sütunu ile Tablo Oluşturma

`vector(n)` veri tipi, `n` boyutlu bir vektörü ifade eder. Boyut, kullandığınız embedding modeliyle uyumlu olmalıdır (örn. OpenAI `text-embedding-3-small` için 1536).

```sql
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding VECTOR(3)
);
```

### Veri Ekleme

```sql
INSERT INTO documents (content, embedding) VALUES
('elma kırmızıdır',  '[1, 2, 3]'),
('armut sarıdır',    '[1, 2, 4]'),
('otomobil hızlıdır', '[10, 20, 30]');
```

### Benzerlik Operatörleri

`pgvector` üç farklı mesafe operatörü sunar:

| Operatör | Anlamı |
|---|---|
| `<->` | Öklid (L2) mesafesi |
| `<#>` | Negatif iç çarpım (inner product) |
| `<=>` | Kosinüs mesafesi |

En yakın komşuları bulmak için `ORDER BY ... LIMIT` kalıbı kullanılır:

```sql
SELECT id, content, embedding <-> '[1, 2, 3]' AS distance
FROM documents
ORDER BY embedding <-> '[1, 2, 3]'
LIMIT 5;
```

Kosinüs benzerliğine göre en yakın kayıtlar:

```sql
SELECT id, content
FROM documents
ORDER BY embedding <=> '[1, 2, 3]'
LIMIT 5;
```

### İndeksleme

Tablo büyüdükçe her sorguda tüm satırları taramak (exact/brute-force arama) maliyetli hale gelir. `pgvector`, yaklaşık en yakın komşu (ANN) araması için iki indeks türü sunar.

#### IVFFlat

Vektör uzayını `lists` parametresi kadar kümeye (cluster) böler. İndeks oluşturmadan önce tabloda veri bulunmalıdır, çünkü kümeler mevcut veri üzerinden hesaplanır.

```sql
CREATE INDEX ON documents
USING ivfflat (embedding vector_l2_ops)
WITH (lists = 100);
```

Sorgu sırasında taranacak küme sayısı `ivfflat.probes` ile ayarlanır (varsayılan 1):

```sql
SET ivfflat.probes = 10;
```

#### HNSW

Daha yüksek sorgu doğruluğu ve performansı sunar, boş tabloda da oluşturulabilir; buna karşın indeks oluşturma süresi ve bellek kullanımı IVFFlat'a göre daha fazladır.

```sql
CREATE INDEX ON documents
USING hnsw (embedding vector_l2_ops)
WITH (m = 16, ef_construction = 64);
```

Sorgu sırasında aranacak aday sayısı `hnsw.ef_search` ile ayarlanır:

```sql
SET hnsw.ef_search = 40;
```

> Not: Mesafe fonksiyonuna uygun operator class seçilmelidir: `vector_l2_ops` (`<->`), `vector_ip_ops` (`<#>`), `vector_cosine_ops` (`<=>`).

### Örnek: Embedding ile Semantik Arama

```sql
-- Kullanıcı sorgusunun embedding'i uygulama tarafında (örn. OpenAI API) hesaplanıp parametre olarak gönderilir
SELECT content
FROM documents
ORDER BY embedding <=> '[0.12, 0.98, 0.45]'
LIMIT 3;
```

### Diğer Veri Tipleriyle Filtreleme

Vektör araması, normal SQL koşullarıyla birlikte kullanılabilir (hibrit arama):

```sql
SELECT content
FROM documents
WHERE content ILIKE '%meyve%'
ORDER BY embedding <-> '[1, 2, 3]'
LIMIT 5;
```

### Kullanım Alanları

- RAG (Retrieval-Augmented Generation) uygulamalarında bağlam belgelerini bulma
- Semantik/anlamsal arama motorları
- Öneri sistemleri (benzer ürün/içerik bulma)
- Görsel/ses benzerlik araması (image/audio embeddings)

https://github.com/pgvector/pgvector
