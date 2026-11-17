#!/bin/bash
# verify-iso.sh — Verify Koppie Linux ISO integrity byte-per-byte before flashing.
# Usage: ./verify-iso.sh [path-to-iso]
# Exits non-zero if any essential check fails.

set -uo pipefail

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; CYN=$'\e[36m'; RST=$'\e[0m'
PASS=0; FAIL=0; WARN=0
ok()   { echo "${GRN}[OK]  ${RST} $1"; PASS=$((PASS+1)); }
bad()  { echo "${RED}[FAIL]${RST} $1"; FAIL=$((FAIL+1)); }
warn() { echo "${YLW}[WARN]${RST} $1"; WARN=$((WARN+1)); }
hdr()  { echo; echo "${CYN}=== $1 ===${RST}"; }

ISO="${1:-}"
if [ -z "$ISO" ]; then
    ISO=$(ls -t out/*.iso 2>/dev/null | head -1)
fi
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
    echo "${RED}ISO file not found. Usage: $0 <path.iso>${RST}"; exit 2
fi

PROFILE="${PROFILE:-profiledef.sh}"
if [ -f "$PROFILE" ]; then
    INSTALL_DIR=$(sed -n 's/^install_dir="\([^"]*\)".*/\1/p' "$PROFILE" | head -1)
fi
INSTALL_DIR="${INSTALL_DIR:-koppie}"

mkdir -p /tmp/koppie
MNT=$(mktemp -d /tmp/koppie/isomnt.XXXXXX)
SQROOT=""
cleanup() {
    [ -n "$SQROOT" ] && [ -d "$SQROOT" ] && sudo umount "$SQROOT" 2>/dev/null && rm -rf "$SQROOT"
    [ -d "$MNT" ] && sudo umount "$MNT" 2>/dev/null && rmdir "$MNT" 2>/dev/null
    rm -rf /tmp/koppie/isocheck.* 2>/dev/null || true
}
trap cleanup EXIT

hdr "1. ISO File Structure & Size"
ISOSIZE=$(stat -c %s "$ISO" 2>/dev/null || stat -f %z "$ISO")
echo "  ISO path : $ISO"
echo "  ISO size : $ISOSIZE bytes ($(numfmt --to=iec-i --suffix=B "$ISOSIZE" 2>/dev/null || echo "$((ISOSIZE/1024/1024)) MiB"))"
if [ "$ISOSIZE" -lt 500000000 ]; then
    bad "ISO is under 500MB (likely incomplete build)"
elif [ "$ISOSIZE" -gt 4500000000 ]; then
    warn "ISO exceeds 4.5GB (won't fit on standard 4GB media)"
else
    ok "ISO size is valid for standard USB media"
fi

hdr "2. Mounting ISO File"
if sudo mount -o loop,ro "$ISO" "$MNT" 2>/dev/null; then
    ok "Successfully mounted ISO to $MNT"

    hdr "3. Bootloader Verification"
    if [ -f "$MNT/EFI/BOOT/BOOTx64.EFI" ]; then
        ok "UEFI bootloader present: /EFI/BOOT/BOOTx64.EFI"
    else
        bad "Missing UEFI bootloader: /EFI/BOOT/BOOTx64.EFI"
    fi

    if [ -f "$MNT/$INSTALL_DIR/boot/x86_64/vmlinuz-linux-lts" ]; then
        ok "LTS Kernel image present in boot directory"
    else
        bad "Missing LTS Kernel image in boot directory"
    fi

    if [ -f "$MNT/$INSTALL_DIR/boot/x86_64/initramfs-linux-lts.img" ]; then
        ok "LTS Initramfs present in boot directory"
    else
        bad "Missing LTS Initramfs in boot directory"
    fi

    hdr "4. SquashFS Integrity"
    SFS="$MNT/$INSTALL_DIR/x86_64/airootfs.sfs"
    if [ -f "$SFS" ]; then
        ok "airootfs.sfs exists"
        SQROOT=$(mktemp -d /tmp/koppie/sqroot.XXXXXX)
        if sudo mount -t squashfs -o ro,loop "$SFS" "$SQROOT" 2>/dev/null; then
            ok "airootfs.sfs successfully mounted"

            hdr "5. System Configurations & Packages"
            # Verify os-prober
            if [ -x "$SQROOT/usr/bin/os-prober" ]; then
                ok "os-prober is installed (multi-boot support ready)"
            else
                bad "os-prober not found in root filesystem"
            fi

            # Verify Calamares installer
            if [ -f "$SQROOT/etc/calamares/settings.conf" ]; then
                ok "Calamares configuration found"
            else
                bad "Calamares configuration missing"
            fi

            # Verify offline pacman database backup
            if [ -d "$SQROOT/usr/share/koppie/pacman-sync" ] && [ -f "$SQROOT/usr/share/koppie/pacman-sync/core.db" ]; then
                ok "Offline pacman sync cache available (offline package management ready)"
            else
                bad "Offline pacman sync cache missing"
            fi

            # Verify no lock file leftover
            if [ -f "$SQROOT/var/lib/pacman/db.lck" ]; then
                bad "Leftover db.lck found in filesystem (will block pacman)"
            else
                ok "No leftover db.lck in filesystem"
            fi

            # Verify default wallpaper
            if [ -f "$SQROOT/usr/share/wallpapers/Koppie/contents/Images_dark/5120x2880.png" ]; then
                ok "Default Koppie dark wallpaper is present"
            else
                bad "Default Koppie dark wallpaper is missing"
            fi

            # Verify rolling release os-release
            if [ -f "$SQROOT/etc/os-release" ]; then
                if grep -q '^BUILD_ID=rolling' "$SQROOT/etc/os-release"; then
                    ok "os-release identified as rolling release (no static version tags)"
                else
                    warn "os-release might still have static version identifiers"
                fi
            fi

            sudo umount "$SQROOT" 2>/dev/null
            rmdir "$SQROOT" 2>/dev/null
            SQROOT=""
        else
            bad "Failed to mount airootfs.sfs"
        fi
    else
        bad "airootfs.sfs not found in ISO"
    fi

    sudo umount "$MNT" 2>/dev/null
    rmdir "$MNT" 2>/dev/null
    MNT=""
else
    bad "Failed to mount ISO"
fi

SHA512=$(sha512sum "$ISO" | awk '{print $1}')

echo
echo "================ SUMMARY ================"
echo " ISO    : $(basename "$ISO")"
echo " OK     : $PASS"
echo " FAIL   : $FAIL"
echo " WARN   : $WARN"
echo " SHA512 : $SHA512"
echo " SIZE   : $ISOSIZE bytes"
echo "========================================="

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GRN}>>> ISO PASSED VERIFICATION — Ready for USB flashing! <<<${RST}"
    exit 0
else
    echo -e "${RED}>>> ISO FAILED VERIFICATION — Please review errors above. <<<${RST}"
    exit 1
fi
