# Mevcut PostgreSQL Ortamlarını Patroni'ye Taşıma Yol Haritası

Varsayım: ortamlar VM veya bare-metal üzerinde çalışıyor ve klasik streaming replication ya da tek node kurulumlar kullanıyor. Kubernetes tarafı zaten CNPG ile ayrı yönetildiği için kapsam dışında. Patroni'nin en büyük avantajı mevcut data directory'yi **yeniden kurmadan devralabilmesi**. Bu sayede geçiş çoğu cluster'da dakikalar mertebesinde bir kesintiyle yapılabilir.

## Faz 0: Envanter ve değerlendirme (1–2 hafta)

Her cluster için şu bilgiler çıkarılmalı:

- PG major versiyonu ve OS
- Topoloji (primary/replica sayısı, sync/async)
- Replication slot'ları, özellikle logical slot'lar ve CDC tüketicileri (Debezium vb.)
- `archive_command` ve backup aracı
- `wal_log_hints` veya data checksums durumu (pg_rewind için gerekli)
- Uygulamaların nasıl bağlandığı (sabit IP, DNS, VIP, pgbouncer)
- Mevcut `pg_hba.conf` ve `postgresql.conf` özelleştirmeleri

Bu aşamada cluster'ları kritiklik sırasına göre gruplayın ve dalgaları buna göre planlayın. Major upgrade bekleyen ortamlar varsa bunu Patroni geçişiyle aynı adımda yapmamaya karar vermek genellikle daha güvenlidir. Alternatif olarak bu ortamları aşağıdaki "yeni cluster" yöntemiyle taşıyabilirsiniz.

## Faz 1: Hedef mimari kararları

**DCS:** 3 (veya 5) node'lu ayrı bir etcd cluster'ı kurun. Cluster başına ayrı etcd yerine, `namespace`/`scope` ile ayrılmış ortak bir etcd tercih edilebilir. etcd'yi PostgreSQL node'larıyla aynı disk üzerinde çalıştırmayın, çünkü fsync gecikmesi leader kaybına yol açar. TLS ve kimlik doğrulama baştan açık olsun.

**Trafik yönlendirme:** Üç seçenek var.

- **HAProxy:** Patroni REST API'deki `/primary` ve `/replica` health check'leriyle çalışır. Keepalived ile HA yapılır.
- **vip-manager:** DCS'deki leader key'ini izleyerek VIP'i taşır, daha basit bir çözümdür.
- **İstemci tarafı çoklu host:** libpq'da `target_session_attrs=read-write`, JDBC'de `targetServerType=primary` ile birden fazla host verilir.

Java ve Node uygulamalarında istemci tarafı çoklu host ile HAProxy'yi birlikte kullanmak, uygulama değişikliğini minimumda tutar.

**Replikasyon modu:** RPO=0 gereken ortamlarda `synchronous_mode: true` kullanın. Tek replika kalırsa yazmaların durmasını kabul edemiyorsanız `synchronous_mode_strict` kapalı kalmalı.

**Fencing:** Split-brain'e karşı son savunma hattı olarak `watchdog` (softdog) açılmalı.

**Backup:** pgBackRest önerilir. `archive_command` ve `restore_command` Patroni DCS konfigürasyonuna taşınmalı. Böylece failover sonrası yeni primary'den arşivleme kesintisiz devam eder.

**Logical slot'lar:** CDC varsa PG17+ native failover slot'ları (`sync_replication_slots`) veya Patroni'nin `permanent slots` özelliğiyle slot'ların failover sonrası korunmasını sağlayın. Bu, geçişin en riskli kısmıdır ve ayrıca test edilmelidir.

## Faz 2: Altyapı hazırlığı

Yapılacaklar:

- etcd cluster'ını kurun.
- Patroni paketini node'lara kurun. PGDG reposunda RPM ve DEB paketleri mevcut.
- Firewall'da şu portları açın: 8008 (REST API), 2379/2380 (etcd), 5432.
- Replikasyon ve `pg_rewind` için ayrı kullanıcılar oluşturun.
- Config yönetimi için Ansible rollerini hazırlayın.

Monitoring için Patroni'nin `/metrics` endpoint'i, postgres_exporter ve etcd metrikleri Prometheus'a eklenmeli. Alarmlar şu durumlar için kurulmalı:

- Leader değişimi
- Replication lag
- DCS erişim kaybı
- Patroni'nin "paused" modda kalması

## Faz 3: Lab / PoC ve test matrisi

Production'ın kopyası bir ortamda tüm prosedürü uçtan uca prova edin. Test edilecek senaryolar:

- Planlı switchover (`patronictl switchover`)
- Primary'nin `kill -9` ile ve sunucu kapatılarak düşürülmesi
- Network partition (primary'nin DCS'den izole edilmesi)
- etcd quorum kaybı
- Eski primary'nin pg_rewind ile geri katılması
- Backup'tan replika oluşturma (`create_replica_methods: pgbackrest`)
- Uygulamaların failover sırasındaki reconnect davranışı (HikariCP timeout'ları, Node pool ayarları)

Her senaryoda RTO/RPO ölçülüp kayıt altına alınmalı.

## Faz 4: Mevcut cluster'ı devralma prosedürü

Patroni, `data_dir`'de zaten initialize edilmiş bir cluster bulursa ve DCS'de bu cluster için kayıt yoksa, `initdb` yapmadan mevcut veriyi sahiplenir. Önerilen sıra:

**1. Hazırlık.** Patroni config'ini yazın:

- `data_dir` ve `bin_dir` mevcut kurulumla birebir aynı olmalı.
- `max_connections`, `max_wal_senders`, `max_replication_slots`, `max_worker_processes`, `max_locks_per_transaction`, `max_prepared_transactions` değerleri mevcut değerlerle eşleşmeli. Bunlar replikalarda primary'den küçük olamaz, Patroni bunları DCS'den yönetir.
- `pg_hba` kuralları config'e taşınmalı.

Bilmeniz gereken bir davranış: Patroni `postgresql.conf` dosyasını kendisi yazar. Orijinal dosyayı `postgresql.base.conf` olarak yeniden adlandırır ve include eder.

**2. Primary geçişi** (kısa bakım penceresi):

```bash
systemctl stop postgresql-16        # mevcut unit
systemctl disable postgresql-16     # Patroni dışında başlamasın
systemctl start patroni
patronictl -c /etc/patroni/patroni.yml list
```

Node leader lock'u alır ve aynı sysid ile primary olarak açılır. Kesinti, servisin stop/start süresi kadardır.

**3. Replikalar.** Her replikada aynı işlemi yapın. Patroni `primary_conninfo` ve `primary_slot_name` değerlerini kendi yönetimine alır ve replikayı leader'a bağlar. Timeline uyuşmazlığı yoksa yeniden `basebackup` gerekmez.

**4. Temizlik.** Eski manuel physical slot'ları primary'de drop edin. Aksi halde tüketilmeyen slot'lar WAL birikmesine yol açar. Ardından `patronictl edit-config` ile dinamik parametreleri DCS'ye taşıyın ve kontrollü bir switchover ile tüm topolojiyi doğrulayın.

**Geri dönüş planı:** Patroni'yi durdurup eski systemd unit'ini başlatmak yeterli, çünkü data directory değişmedi. Yalnızca `postgresql.base.conf` düzenlemesini geri almanız gerekir.

### Alternatif: yeni sunucularda paralel cluster

Donanım veya OS yenileniyorsa ya da kesintiye hiç tolerans yoksa, Patroni'nin `standby_cluster` özelliğiyle yeni bir Patroni cluster'ı kurun. Bu cluster, mevcut primary'den physical replication ile beslenir. Cutover anında:

1. Uygulama yazmaları durdurulur.
2. Lag sıfırlanır.
3. `standby_cluster` bölümü config'den kaldırılarak yeni cluster promote edilir.
4. DNS veya VIP çevrilir.

Major upgrade gerekiyorsa aynı yaklaşım logical replication ile uygulanabilir.

## Faz 5: Production dalgaları

Sıralama şöyle olmalı: önce düşük kritiklikteki dev/test ortamları, sonra iç uygulamalar, en son kritik sigorta çekirdek sistemleri. Her dalgadan sonra en az bir hafta gözlem süresi bırakın ve bir planlı switchover tatbikatı yapın. CDC tüketicisi olan cluster'ları, slot failover testi başarıyla geçmeden taşımayın.

## Faz 6: Operasyonel olgunluk

Şu runbook'lar yazılmalı:

- Switchover
- Failover sonrası inceleme
- `patronictl pause` ile bakım modu
- Minor upgrade (rolling: önce replikalar, sonra switchover)
- Node ekleme/çıkarma
- etcd yedekleme ve kurtarma

Ek olarak:

- Düzenli aralıklarla (ör. çeyreklik) failover tatbikatı yapın.
- Konfigürasyon değişikliklerini `edit-config` yerine Ansible veya Git üzerinden yönetin. Bu, DCS ile dosyadaki config arasında drift oluşmasını engeller.
- DR için uzak lokasyonda bir `standby_cluster` kurmayı değerlendirin.

## Kritik riskler özeti

En çok sorun çıkaran noktalar:

1. Logical slot'ların failover'da kaybolması (CDC yeniden snapshot ister)
2. `wal_log_hints`/checksums kapalı olduğu için pg_rewind'in çalışmaması
3. etcd'nin yavaş diskte çalışması nedeniyle gereksiz leader değişimleri
4. Uygulamaların sabit IP'ye bağlı kalması
5. Eski systemd unit'inin yanlışlıkla başlatılıp Patroni'den bağımsız bir postgres açması (unit mutlaka `mask` edilmeli)

İsterseniz bir sonraki adımda örnek bir `patroni.yml` (DCS bölümü, pgBackRest entegrasyonu, watchdog ve permanent slot'larla) ya da HAProxy konfigürasyonu hazırlayabilirim.