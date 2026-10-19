#!/usr/bin/env bash
# =====================================================================
# os_healthcheck.sh
# PostgreSQL sunucusunun İŞLETİM SİSTEMİ düzeyinde sağlık kontrolü.
# Veritabanı sunucusunda (root veya postgres kullanıcısıyla) çalıştırılır.
#
# Kontroller: servis / pg_isready, uptime & load, CPU, bellek & swap,
# kernel parametreleri (swappiness, overcommit, THP, huge pages),
# disk & inode doluluğu (PGDATA, pg_wal, tablespace'ler, log dizini),
# mount seçenekleri, dosya izinleri, açık dosya limiti, OOM killer,
# zaman senkronizasyonu, PostgreSQL log'unda FATAL/PANIC/ERROR özetleri.
#
# Kullanım:
#   sudo ./os_healthcheck.sh [-D PGDATA] [-p port] [-l log_dizini] [-n satır]
#     -D : veri dizini (verilmezse çalışan postmaster'dan bulunur)
#     -p : port (pg_isready için, varsayılan 5432)
#     -l : log dizini (verilmezse PGDATA/log, ardından /var/log/postgresql)
#     -n : log'da incelenecek son satır sayısı (varsayılan 20000)
#
# Çıkış kodu: 0 = OK, 1 = WARN, 2 = CRIT
# =====================================================================
set -uo pipefail

PGDATA_ARG="${PGDATA:-}"
PORT=5432
LOG_DIR=""
LOG_LINES=20000
DISK_WARN=80; DISK_CRIT=90
INODE_WARN=80; INODE_CRIT=90

while getopts "D:p:l:n:" opt; do
  case "$opt" in
    D) PGDATA_ARG="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    l) LOG_DIR="$OPTARG" ;;
    n) LOG_LINES="$OPTARG" ;;
    *) sed -n '2,22p' "$0"; exit 2 ;;
  esac
done

WARNS=0; CRITS=0
if [[ -t 1 ]]; then R=$'\e[31m'; Y=$'\e[33m'; G=$'\e[32m'; B=$'\e[1m'; N=$'\e[0m'; else R=; Y=; G=; B=; N=; fi
ok()   { printf '  %s[OK]  %s %s\n'   "$G" "$N" "$*"; }
warn() { printf '  %s[WARN]%s %s\n'   "$Y" "$N" "$*"; WARNS=$((WARNS+1)); }
crit() { printf '  %s[CRIT]%s %s\n'   "$R" "$N" "$*"; CRITS=$((CRITS+1)); }
info() { printf '  [INFO] %s\n' "$*"; }
hdr()  { printf '\n%s== %s ==%s\n' "$B" "$*" "$N"; }

# ---------------------------------------------------------------------
hdr "1. PostgreSQL süreci ve servis"
PM_PID=$(pgrep -o -f '(postgres|postmaster).*-D' 2>/dev/null || pgrep -o -x postgres 2>/dev/null || true)
if [[ -n "$PM_PID" ]]; then
  ok "postmaster çalışıyor (pid $PM_PID)"
  if [[ -z "$PGDATA_ARG" ]]; then
    PGDATA_ARG=$(tr '\0' ' ' < /proc/"$PM_PID"/cmdline | sed -n 's/.*-D \{0,1\}\([^ ]*\).*/\1/p')
    # Debian/Ubuntu: -D config dizinini gösterebilir; data_directory'yi config'ten al
    if [[ -n "$PGDATA_ARG" && ! -f "$PGDATA_ARG/PG_VERSION" && -f "$PGDATA_ARG/postgresql.conf" ]]; then
      DD=$(grep -E "^\s*data_directory" "$PGDATA_ARG/postgresql.conf" | sed -E "s/.*=\s*'?([^' #]*)'?.*/\1/")
      [[ -n "$DD" ]] && PGDATA_ARG="$DD"
    fi
  fi
  info "Süreç sayısı: $(pgrep -c -u "$(stat -c %U /proc/"$PM_PID")" postgres 2>/dev/null || echo '?')"
else
  crit "postmaster süreci bulunamadı"
fi

if command -v pg_isready >/dev/null; then
  if pg_isready -q -p "$PORT"; then ok "pg_isready: bağlantı kabul ediliyor (port $PORT)"
  else crit "pg_isready: yanıt yok ($(pg_isready -p "$PORT" 2>&1))"; fi
fi

if command -v systemctl >/dev/null; then
  for u in $(systemctl list-units --type=service --no-legend 2>/dev/null | awk '{print $1}' | grep -E 'postgres|patroni|pgbouncer|pgbackrest'); do
    st=$(systemctl is-active "$u" 2>/dev/null)
    [[ "$st" == "active" ]] && ok "systemd: $u aktif" || warn "systemd: $u durumu = $st"
  done
fi

# ---------------------------------------------------------------------
hdr "2. Sistem yükü ve CPU"
CPUS=$(nproc)
read -r L1 L5 L15 _ < /proc/loadavg
info "Uptime: $(uptime -p 2>/dev/null || uptime)"
info "CPU çekirdek: $CPUS   Load (1/5/15): $L1 / $L5 / $L15"
if awk "BEGIN{exit !($L15 > $CPUS*2)}"; then crit "15 dk load ortalaması çekirdek sayısının 2 katından fazla"
elif awk "BEGIN{exit !($L15 > $CPUS)}"; then warn "15 dk load ortalaması çekirdek sayısını aşıyor"
else ok "Load ortalaması normal"; fi
if command -v vmstat >/dev/null; then
  read -r US SY ID WA ST < <(vmstat 1 2 | tail -1 | awk '{print $13,$14,$15,$16,$17}')
  info "CPU (anlık): user=$US% sys=$SY% idle=$ID% iowait=$WA% steal=${ST:-0}%"
  [[ ${WA:-0} -ge 20 ]] && warn "Yüksek iowait (%$WA) — disk darboğazı olabilir"
  [[ ${ST:-0} -ge 10 ]] && warn "Yüksek CPU steal (%$ST) — sanallaştırma katmanında kaynak sıkıntısı"
fi

# ---------------------------------------------------------------------
hdr "3. Bellek ve swap"
MEM_TOTAL=$(awk '/MemTotal/{print $2}' /proc/meminfo)
MEM_AVAIL=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
SWAP_TOTAL=$(awk '/SwapTotal/{print $2}' /proc/meminfo)
SWAP_FREE=$(awk '/SwapFree/{print $2}' /proc/meminfo)
AVAIL_PCT=$(( MEM_AVAIL * 100 / MEM_TOTAL ))
info "RAM: $((MEM_TOTAL/1024)) MB toplam, $((MEM_AVAIL/1024)) MB kullanılabilir (%$AVAIL_PCT)"
if   [[ $AVAIL_PCT -lt 5 ]];  then crit "Kullanılabilir bellek %5'in altında"
elif [[ $AVAIL_PCT -lt 10 ]]; then warn "Kullanılabilir bellek %10'un altında"
else ok "Bellek yeterli"; fi
if [[ $SWAP_TOTAL -gt 0 ]]; then
  SWAP_USED_PCT=$(( (SWAP_TOTAL - SWAP_FREE) * 100 / SWAP_TOTAL ))
  info "Swap: $((SWAP_TOTAL/1024)) MB, kullanım %$SWAP_USED_PCT"
  [[ $SWAP_USED_PCT -ge 20 ]] && warn "Swap kullanımı %$SWAP_USED_PCT — bellek baskısı" || ok "Swap kullanımı düşük"
else
  info "Swap tanımlı değil"
fi
if command -v vmstat >/dev/null; then
  read -r SI SO < <(vmstat 1 2 | tail -1 | awk '{print $7,$8}')
  [[ $((SI+SO)) -gt 0 ]] && warn "Aktif swap in/out var (si=$SI so=$SO)" || ok "Aktif swapping yok"
fi

# ---------------------------------------------------------------------
hdr "4. Kernel parametreleri"
SWAPPINESS=$(cat /proc/sys/vm/swappiness 2>/dev/null)
[[ ${SWAPPINESS:-60} -le 10 ]] && ok "vm.swappiness = $SWAPPINESS" || warn "vm.swappiness = $SWAPPINESS (öneri: 1–10)"
OVC=$(cat /proc/sys/vm/overcommit_memory 2>/dev/null)
[[ "$OVC" == "2" ]] && ok "vm.overcommit_memory = 2" \
  || info "vm.overcommit_memory = $OVC (öneri: 2 + uygun overcommit_ratio; OOM killer riskini azaltır)"
DR=$(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null); DBY=$(cat /proc/sys/vm/dirty_background_bytes 2>/dev/null)
info "vm.dirty_background_ratio = $DR, dirty_background_bytes = $DBY (büyük RAM'de bytes ile küçük tutulması önerilir)"
THP_FILE=/sys/kernel/mm/transparent_hugepage/enabled
if [[ -f $THP_FILE ]]; then
  THP=$(grep -o '\[[a-z]*\]' $THP_FILE | tr -d '[]')
  [[ "$THP" == "never" ]] && ok "Transparent Huge Pages = never" \
    || warn "Transparent Huge Pages = $THP (öneri: never; gecikme sıçramalarına yol açabilir)"
fi
HP_TOTAL=$(awk '/HugePages_Total/{print $2}' /proc/meminfo)
HP_FREE=$(awk '/HugePages_Free/{print $2}' /proc/meminfo)
info "HugePages: toplam=$HP_TOTAL boş=$HP_FREE (shared_buffers büyükse huge_pages=on önerilir)"

# ---------------------------------------------------------------------
hdr "5. Disk ve inode doluluğu"
check_path() {   # $1 etiket, $2 yol
  local label="$1" path="$2"
  [[ -e "$path" ]] || return
  local line used iused mnt
  line=$(df -P "$path" | tail -1); used=$(echo "$line" | awk '{print $5}' | tr -d '%'); mnt=$(echo "$line" | awk '{print $6}')
  iused=$(df -Pi "$path" | tail -1 | awk '{print $5}' | tr -d '%')
  local msg; msg="$label ($path) -> $mnt: disk %$used, inode %${iused:-?}, boş $(df -Ph "$path" | tail -1 | awk '{print $4}')"
  if   [[ $used -ge $DISK_CRIT ]]; then crit "$msg"
  elif [[ $used -ge $DISK_WARN ]]; then warn "$msg"
  else ok "$msg"; fi
  if [[ "${iused:-0}" =~ ^[0-9]+$ ]]; then
    [[ $iused -ge $INODE_CRIT ]] && crit "$label: inode kullanımı %$iused"
    [[ $iused -ge $INODE_WARN && $iused -lt $INODE_CRIT ]] && warn "$label: inode kullanımı %$iused"
  fi
}
if [[ -n "$PGDATA_ARG" && -d "$PGDATA_ARG" ]]; then
  check_path "PGDATA" "$PGDATA_ARG"
  WALDIR=$(readlink -f "$PGDATA_ARG/pg_wal")
  check_path "pg_wal" "$WALDIR"
  info "pg_wal boyutu: $(du -sh "$WALDIR" 2>/dev/null | awk '{print $1}'), dosya sayısı: $(find "$WALDIR" -maxdepth 1 -type f -name '0*' | wc -l)"
  READY=$(find "$WALDIR/archive_status" -name '*.ready' 2>/dev/null | wc -l)
  if   [[ $READY -ge 100 ]]; then crit "Arşivlenmeyi bekleyen WAL: $READY (.ready)"
  elif [[ $READY -ge 10 ]];  then warn "Arşivlenmeyi bekleyen WAL: $READY (.ready)"
  else ok "Arşivlenmeyi bekleyen WAL: $READY"; fi
  for ts in "$PGDATA_ARG"/pg_tblspc/*; do
    [[ -L "$ts" ]] && check_path "tablespace $(basename "$ts")" "$(readlink -f "$ts")"
  done
  info "PGDATA alt dizinleri:"
  du -sh "$PGDATA_ARG"/{base,pg_wal,pg_xact,pg_multixact,pg_replslot,pg_stat_tmp,log} 2>/dev/null | sed 's/^/           /'
else
  warn "PGDATA bulunamadı; -D ile verin"
fi
info "Tüm dosya sistemleri:"
df -hP -x tmpfs -x devtmpfs -x overlay -x squashfs 2>/dev/null | sed 's/^/           /'

# ---------------------------------------------------------------------
hdr "6. Mount seçenekleri ve dosya izinleri"
if [[ -n "$PGDATA_ARG" && -d "$PGDATA_ARG" ]]; then
  MNT=$(df -P "$PGDATA_ARG" | tail -1 | awk '{print $6}')
  OPTS=$(findmnt -no OPTIONS "$MNT" 2>/dev/null)
  FST=$(findmnt -no FSTYPE "$MNT" 2>/dev/null)
  info "PGDATA mount: $MNT ($FST) $OPTS"
  [[ "$OPTS" == *noatime* || "$OPTS" == *relatime* ]] && ok "atime güncellemesi kısıtlı (noatime/relatime)" \
    || warn "noatime/relatime yok — gereksiz metadata yazımı"
  [[ "$OPTS" == *nobarrier* ]] && crit "nobarrier aktif — elektrik kesintisinde veri bozulma riski"
  PERM=$(stat -c '%a' "$PGDATA_ARG"); OWNER=$(stat -c '%U' "$PGDATA_ARG")
  [[ "$PERM" == "700" || "$PERM" == "750" ]] && ok "PGDATA izinleri $PERM (sahip: $OWNER)" \
    || crit "PGDATA izinleri $PERM — 0700 veya 0750 olmalı"
fi

# ---------------------------------------------------------------------
hdr "7. Süreç limitleri"
if [[ -n "$PM_PID" && -r /proc/$PM_PID/limits ]]; then
  NOFILE=$(awk '/Max open files/{print $4}' /proc/"$PM_PID"/limits)
  [[ "$NOFILE" == "unlimited" || ${NOFILE:-0} -ge 65536 ]] && ok "postmaster açık dosya limiti: $NOFILE" \
    || warn "postmaster açık dosya limiti düşük: $NOFILE (öneri: >= 65536)"
  OOM=$(cat /proc/"$PM_PID"/oom_score_adj 2>/dev/null)
  info "postmaster oom_score_adj = $OOM (öneri: -1000; çocuk süreçler PG_OOM_ADJUST_VALUE=0)"
fi

# ---------------------------------------------------------------------
hdr "8. OOM killer ve kernel hataları (son 7 gün)"
if command -v journalctl >/dev/null; then
  OOMS=$(journalctl -k --since "-7d" 2>/dev/null | grep -ciE 'out of memory|oom-kill|killed process')
  IOERR=$(journalctl -k --since "-7d" 2>/dev/null | grep -ciE 'i/o error|blk_update_request|medium error|ext4-fs error|xfs.*error')
else
  OOMS=$(dmesg 2>/dev/null | grep -ciE 'out of memory|oom-kill|killed process')
  IOERR=$(dmesg 2>/dev/null | grep -ciE 'i/o error|blk_update_request|medium error|ext4-fs error|xfs.*error')
fi
[[ ${OOMS:-0} -gt 0 ]] && crit "OOM killer kaydı: $OOMS" || ok "OOM killer kaydı yok"
[[ ${IOERR:-0} -gt 0 ]] && crit "Kernel disk / dosya sistemi hatası: $IOERR" || ok "Kernel I/O hatası yok"

# ---------------------------------------------------------------------
hdr "9. Zaman senkronizasyonu"
if command -v timedatectl >/dev/null; then
  SYNC=$(timedatectl show -p NTPSynchronized --value 2>/dev/null)
  [[ "$SYNC" == "yes" ]] && ok "NTP senkronize" || warn "NTP senkronizasyonu yok/doğrulanamadı (replikasyon lag ve log korelasyonu etkilenir)"
elif command -v chronyc >/dev/null; then
  chronyc tracking 2>/dev/null | grep -E 'Leap status|System time' | sed 's/^/  [INFO] /'
fi

# ---------------------------------------------------------------------
hdr "10. PostgreSQL log analizi (son $LOG_LINES satır)"
if [[ -z "$LOG_DIR" ]]; then
  for d in "$PGDATA_ARG/log" "$PGDATA_ARG/pg_log" /var/log/postgresql /var/lib/pgsql/data/log; do
    [[ -d "$d" ]] && { LOG_DIR="$d"; break; }
  done
fi
LOGFILE=$(ls -t "$LOG_DIR"/*.log "$LOG_DIR"/*.csv 2>/dev/null | head -1)
if [[ -n "$LOGFILE" ]]; then
  info "Log dosyası: $LOGFILE"
  TAIL=$(tail -n "$LOG_LINES" "$LOGFILE")
  P=$(grep -c 'PANIC:'  <<< "$TAIL"); F=$(grep -c 'FATAL:' <<< "$TAIL"); E=$(grep -c 'ERROR:' <<< "$TAIL")
  [[ $P -gt 0 ]] && crit "PANIC: $P" || ok "PANIC yok"
  info "FATAL: $F   ERROR: $E"
  for pat in 'could not write|No space left on device' 'invalid page|checksum|corrupt' \
             'archive command failed' 'terminating connection due to conflict' \
             'deadlock detected' 'too many clients|remaining connection slots' \
             'checkpoints are occurring too frequently' 'must be vacuumed within|wraparound' \
             'out of memory|could not fork'; do
    c=$(grep -ciE "$pat" <<< "$TAIL")
    [[ $c -gt 0 ]] && warn "'$pat' : $c kez"
  done
  echo "  En sık 10 ERROR/FATAL mesajı:"
  grep -E 'ERROR:|FATAL:' <<< "$TAIL" | sed -E 's/.*(ERROR|FATAL): +//' \
    | sed -E 's/"[^"]*"/"…"/g; s/[0-9]+/N/g' | sort | uniq -c | sort -rn | head -10 | sed 's/^/           /'
else
  warn "PostgreSQL log dosyası bulunamadı (-l ile dizini verin)"
fi

# ---------------------------------------------------------------------
echo
echo "=============================================================="
echo " OS SONUÇ: CRIT=$CRITS  WARN=$WARNS"
echo "=============================================================="
if   [[ $CRITS -gt 0 ]]; then exit 2
elif [[ $WARNS -gt 0 ]]; then exit 1
else exit 0; fi
