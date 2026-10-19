#!/usr/bin/env bash
# =====================================================================
# pg_healthcheck.sh
# PostgreSQL healthcheck SQL'lerini çalıştırır ve tek bir rapor üretir.
#
#   * Küme (cluster) düzeyindeki kontroller bakım veritabanında bir kez,
#   * Veritabanına özel kontroller bağlantıya açık HER veritabanında çalışır.
#   * Özet tablolardaki CRIT / WARN sayısına göre çıkış kodu döner:
#       0 = OK, 1 = WARN var, 2 = CRIT var, 3 = bağlantı / çalışma hatası
#     (cron, Nagios/Icinga/Zabbix gibi araçlarda doğrudan kullanılabilir)
#
# Kullanım:
#   ./pg_healthcheck.sh [-h host] [-p port] [-U user] [-d bakım_db]
#                       [-D "db1,db2"] [-o çıktı_dizini] [-m mod] [-q]
#
#   -m summary : yalnızca özet kontroller (hızlı, izleme için)   [varsayılan: full]
#   -m full    : tüm detay raporları
#   -D         : yalnızca bu veritabanları (virgülle); verilmezse tümü
#   -o         : rapor dizini (varsayılan: ./reports)
#   -q         : ekrana yazma, sadece dosyaya yaz ve çıkış kodunu döndür
#
# Ek psql değişkenleri (eşikler) PSQL_VARS ortam değişkeniyle verilebilir:
#   PSQL_VARS="-v conn_warn=60 -v xid_warn=300000000" ./pg_healthcheck.sh
#
# Kimlik doğrulama: ~/.pgpass, PGPASSWORD veya peer auth kullanılır.
# Önerilen kullanıcı: superuser ya da pg_monitor üyesi özel bir rol.
# =====================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="${SQL_DIR:-$SCRIPT_DIR/../sql}"

PGHOST_ARG="${PGHOST:-}"
PGPORT_ARG="${PGPORT:-5432}"
PGUSER_ARG="${PGUSER:-postgres}"
MAINT_DB="postgres"
DB_FILTER=""
OUT_DIR="./reports"
MODE="full"
QUIET=0

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 3; }

while getopts "h:p:U:d:D:o:m:q" opt; do
  case "$opt" in
    h) PGHOST_ARG="$OPTARG" ;;
    p) PGPORT_ARG="$OPTARG" ;;
    U) PGUSER_ARG="$OPTARG" ;;
    d) MAINT_DB="$OPTARG" ;;
    D) DB_FILTER="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    m) MODE="$OPTARG" ;;
    q) QUIET=1 ;;
    *) usage ;;
  esac
done

[[ "$MODE" == "summary" || "$MODE" == "full" ]] || { echo "Geçersiz mod: $MODE"; usage; }
[[ -d "$SQL_DIR" ]] || { echo "SQL dizini bulunamadı: $SQL_DIR"; exit 3; }
command -v psql >/dev/null || { echo "psql bulunamadı"; exit 3; }

CONN=(-X -p "$PGPORT_ARG" -U "$PGUSER_ARG")
[[ -n "$PGHOST_ARG" ]] && CONN+=(-h "$PGHOST_ARG")
# shellcheck disable=SC2206
EXTRA_VARS=(${PSQL_VARS:-})

TS="$(date +%Y%m%d_%H%M%S)"
HOST_LABEL="${PGHOST_ARG:-local}"
REPORT_DIR="$OUT_DIR/${HOST_LABEL}_${PGPORT_ARG}_${TS}"
mkdir -p "$REPORT_DIR" || exit 3
REPORT="$REPORT_DIR/report.txt"
SUMMARY="$REPORT_DIR/summary.txt"

log() { if [[ $QUIET -eq 0 ]]; then tee -a "$1"; else cat >> "$1"; fi; }

run_sql() {   # $1 = db, $2 = sql dosyası, $3 = hedef dosya
  local db="$1" file="$2" target="$3"
  {
    echo
    echo "##### $(basename "$file")  [db: $db]  $(date '+%F %T')"
    psql "${CONN[@]}" -d "$db" "${EXTRA_VARS[@]}" -f "$file" 2>&1
  } | log "$target"
}

# ---- bağlantı testi ----
if ! psql "${CONN[@]}" -d "$MAINT_DB" -Atc "select 1" >/dev/null 2>&1; then
  echo "HATA: $HOST_LABEL:$PGPORT_ARG/$MAINT_DB bağlantısı kurulamadı (kullanıcı: $PGUSER_ARG)" | log "$REPORT"
  exit 3
fi

VERSION=$(psql "${CONN[@]}" -d "$MAINT_DB" -Atc "show server_version")
ROLE=$(psql "${CONN[@]}" -d "$MAINT_DB" -Atc "select case when pg_is_in_recovery() then 'standby' else 'primary' end")
IS_MON=$(psql "${CONN[@]}" -d "$MAINT_DB" -Atc \
  "select (select rolsuper from pg_roles where rolname=current_user) or pg_has_role(current_user,'pg_monitor','member')")

{
  echo "=============================================================="
  echo " PostgreSQL Healthcheck Raporu"
  echo " Tarih     : $(date '+%F %T %Z')"
  echo " Sunucu    : $HOST_LABEL:$PGPORT_ARG   (çalıştırılan makine: $(hostname))"
  echo " Sürüm     : $VERSION   Rol: $ROLE"
  echo " Kullanıcı : $PGUSER_ARG   Mod: $MODE"
  echo "=============================================================="
  [[ "$IS_MON" != "t" ]] && echo "UYARI: kullanıcı superuser veya pg_monitor değil; bazı kontroller eksik kalabilir."
} | log "$REPORT"

# ---- veritabanı listesi ----
if [[ -n "$DB_FILTER" ]]; then
  IFS=',' read -r -a DBS <<< "$DB_FILTER"
else
  mapfile -t DBS < <(psql "${CONN[@]}" -d "$MAINT_DB" -Atc \
    "select datname from pg_database where datallowconn and not datistemplate order by 1")
fi

# ---- 1) özetler ----
run_sql "$MAINT_DB" "$SQL_DIR/00_cluster_summary.sql" "$SUMMARY"
for db in "${DBS[@]}"; do
  run_sql "$db" "$SQL_DIR/01_database_summary.sql" "$SUMMARY"
done
cat "$SUMMARY" >> "$REPORT"

# ---- 2) detaylar ----
if [[ "$MODE" == "full" ]]; then
  CLUSTER_FILES=(02_instance_config 03_connections_activity 04_locks 05_replication
                 06_wal_checkpoint_archive 16_database_stats_errors 17_security_quick 14_top_queries)
  DB_FILES=(07_sizes 08_vacuum 09_wraparound 10_table_bloat 11_index_bloat
            12_index_health 13_cache_io_scans 15_sequences_datatypes)

  for f in "${CLUSTER_FILES[@]}"; do
    run_sql "$MAINT_DB" "$SQL_DIR/$f.sql" "$REPORT_DIR/$f.txt"
  done
  for db in "${DBS[@]}"; do
    for f in "${DB_FILES[@]}"; do
      run_sql "$db" "$SQL_DIR/$f.sql" "$REPORT_DIR/${f}__${db}.txt"
    done
  done
  # tüm detayları tek rapora ekle
  for f in "$REPORT_DIR"/[0-9]*.txt; do cat "$f" >> "$REPORT"; done
fi

# ---- 3) sonuç ve çıkış kodu ----
# Özet tablolarında son kolon "Durum"dur: "| CRIT" / "| WARN"
CRIT=$(grep -cE '\|[[:space:]]+CRIT[[:space:]]*$' "$SUMMARY")
WARN=$(grep -cE '\|[[:space:]]+WARN[[:space:]]*$' "$SUMMARY")
ERRS=$(grep -cE '^(psql:.*)?ERROR:|^psql: error' "$REPORT")

{
  echo
  echo "=============================================================="
  echo " SONUÇ:  CRIT=$CRIT  WARN=$WARN  SQL_HATASI=$ERRS"
  if [[ $CRIT -gt 0 || $WARN -gt 0 ]]; then
    echo " Bulgular:"
    grep -E '\|[[:space:]]+(CRIT|WARN)[[:space:]]*$' "$SUMMARY" | sed 's/^/   /'
  fi
  echo " Rapor dizini: $REPORT_DIR"
  echo "=============================================================="
} | log "$REPORT"

if   [[ $CRIT -gt 0 ]]; then exit 2
elif [[ $WARN -gt 0 ]]; then exit 1
elif [[ $ERRS -gt 0 ]]; then exit 3
else exit 0
fi
