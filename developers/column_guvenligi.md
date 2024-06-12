# sütun güvenliği

```sql
CREATE TABLE passwd (
  user_name             text UNIQUE NOT NULL,
  pwhash                text,
  uid                   int  PRIMARY KEY,
  gid                   int  NOT NULL,
  real_name             text NOT NULL,
  home_phone            text,
  extra_info            text,
  home_dir              text NOT NULL,
  shell                 text NOT NULL
);


CREATE ROLE basri;  -- sınırlı erişim verilecek kullanıcı  
CREATE ROLE husnu;  -- sınırlı erişim verilecek kullanıcı  

-- Populate the table
INSERT INTO passwd VALUES
  ('admin','xxx',0,0,'Admin','111-222-3333',null,'/root','/bin/dash');
INSERT INTO passwd VALUES
  ('bob','xxx',1,1,'Bob','123-456-7890',null,'/home/bob','/bin/zsh');
INSERT INTO passwd VALUES
  ('alice','xxx',2,1,'Alice','098-765-4321',null,'/home/alice','/bin/zsh');

-- Be sure to enable row-level security on the table
ALTER TABLE passwd ENABLE ROW LEVEL SECURITY;

--  okuma yetkisi veriyoruz. 
CREATE POLICY all_view ON passwd FOR SELECT USING (true);


-- basrinin pwhash alanı dışındakileri görebilmesini sağlıyoruz.
GRANT SELECT
  (user_name, uid, gid, real_name, home_phone, extra_info, home_dir, shell)
  ON passwd TO basri;
  
GRANT SELECT
  (user_name, uid)
  ON passwd TO husnu;

 set role to basri;
 
 -- olmaz
select * from passwd ;

-- olur
select user_name, uid, gid, real_name, home_phone, extra_info from passwd ;



set role to husnu;
 
-- olur
select user_name, uid from passwd ;

-- olmaz
select user_name, uid, gid, real_name, home_phone, extra_info from passwd ;

```

### Kaynaklar
https://www.postgresql.org/docs/current/sql-createpolicy.html
https://www.postgresql.org/docs/current/ddl-rowsecurity.html
