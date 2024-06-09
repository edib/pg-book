# CONSTRAINTS (KISITLAR)

https://www.postgresql.org/docs/current/ddl-constraints.html

### Check Constraints

https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-CHECK-CONSTRAINTS


### NOT NULL

https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-NOT-NULL


### Unique Constraints 

https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-UNIQUE-CONSTRAINTS

### Dış Anahtar Kısıtlaması (Foreign Key Constraint)

```SQL

create table tb_bolumler(
  id SERIAL not null,
  name varchar not null );

ALTER TABLE tb_bolumler ADD CONSTRAINT tb_bolumler_pk PRIMARY KEY (id);


create table public.tb_ogrenci(
  id SERIAL not null,
  ogrenci_no BIGINT not null unique check (ogrenci_no> 0),
  adi VARCHAR(50) not null,
  soyadi VARCHAR(50) not null,
  tc_kimlik_no BIGINT not null unique check (tc_kimlik_no> 10000000000),
  bolum_id INTEGER null,
  primary key(id),
  constraint tb_ogrenci_fk foreign key (bolum_id) references tb_bolumler(id) on
delete
	no action on
	update
		no action not deferrable) ;

```


Bu SQL ifadesi, `tb_ogrenci` tablosundaki `bolum_id` sütununun `tb_bolumler` tablosundaki `id` sütununa referans verdiğini ve bu referansın sıkı veri bütünlüğü kurallarına bağlı olduğunu belirler. 

- **Kısıt Adı**: `tb_ogrenci_fk`
- **Dış Anahtar**: `tb_ogrenci.bolum_id`
- **Referans**: `public.tb_bolumler(id)`
- **Silme Eylemi**: `NO ACTION` - silme işlemi yapılmaz ve işlem reddedilir.
- **Güncelleme Eylemi**: `NO ACTION` - güncelleme işlemi yapılmaz ve işlem reddedilir.
- **Anında Kontrol**: `NOT DEFERRABLE` - kısıtlama anında kontrol edilir ve işlem sırasında herhangi bir kısıtlama ihlali hemen algılanır.

Bu yapılandırma, veri bütünlüğünü korumak için sıkı kurallar uygular ve referans edilen tablodaki değişikliklerin izin verilen işlemleri açıkça tanımlar.