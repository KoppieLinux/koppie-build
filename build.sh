#!/bin/bash
# Koppie Linux - build ISO anti-tidur (1 script sh)
# Pakai: ./build.sh (jalanin dari ~/Projects/koppie-arch/)
# Selama mkarchiso jalan: sleep/idle/lid-switch di-BLOKIR.

set -e
set -o pipefail

echo "=== [1/4] cek sudo ==="
sudo -n true || { echo "ERROR: sudo minta password, grant dulu"; exit 1; }

echo "=== [2/4] bersihkan sisa build, work, dan lock pacman ==="
sudo rm -rf work/
sudo rm -f build-*.log *.log
if [ -f work/airootfs/var/lib/pacman/db.lck ]; then
    sudo rm -f work/airootfs/var/lib/pacman/db.lck
fi

echo "=== [3/4] build ISO (hybrid UEFI + BIOS) ==="
LOG="build-$(date +%Y%m%d-%H%M%S).log"
echo "log lengkap: $LOG"

rc=0
sudo systemd-inhibit \
    --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch \
    --who="Koppie ISO Build" \
    --why="mkarchiso jangan sampai ketiduran" \
    --mode=block \
    mkarchiso -v . 2>&1 | tee "$LOG" || rc=$?

if [ "$rc" -ne 0 ]; then
    echo "=== [X] BUILD GAGAL (mkarchiso exit=$rc) ==="
    echo "     cek log: $LOG"
    exit "$rc"
fi

echo "=== [4/4] SELESAI - inhibit lepas otomatis ==="
LATEST_ISO=$(ls -t out/*.iso 2>/dev/null | head -1 || true)
if [ -n "$LATEST_ISO" ] && [ -x ./verify-iso.sh ]; then
    echo "=== menjalankan verify-iso.sh otomatis ==="
    ./verify-iso.sh "$LATEST_ISO" || true
fi
ls -lh out/ 2>/dev/null | grep -E "iso|sha" || echo "(cek folder out/)"
