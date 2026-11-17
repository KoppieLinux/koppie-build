#!/bin/bash
# Koppie Linux - script yang otomatis dijalankan mkarchiso di akhir persiapan rootfs.
set -e

# 1. PAKSA SEMUA WALLPAPER KDE (Next / Bawaan Plasma 6) menjadi Wallpaper Koppie Dark!
#    KDE Plasma secara default memuat wallpaper /usr/share/wallpapers/Next/
KP="/usr/share/wallpapers/Koppie/contents/Images_dark/5120x2880.png"
if [ -f "$KP" ]; then
    # Timpa semua file gambar Next (bawaan Plasma)
    if [ -d /usr/share/wallpapers/Next ]; then
        find /usr/share/wallpapers/Next -name "*.png" -o -name "*.jpg" | while read -r img; do
            cp -f "$KP" "$img"
        done
    fi
    # Pastikan wallpaper default SDDM Breeze juga Koppie Dark
    if [ -f /usr/share/sddm/themes/breeze/theme.conf ]; then
        sed -i 's|^background=.*|background=/usr/share/wallpapers/Koppie/contents/Images_dark/5120x2880.png|' \
            /usr/share/sddm/themes/breeze/theme.conf
    fi
fi

# 2. Pasang Tema Plymouth Spinner dari host
PLY_SRC="/usr/share/koppie/overrides/plymouth-spinner"
if [ -d "$PLY_SRC" ]; then
    mkdir -p /usr/share/plymouth/themes/spinner
    cp -af "$PLY_SRC"/* /usr/share/plymouth/themes/spinner/
fi
if [ -f /usr/share/koppie/overrides/plymouthd.conf ]; then
    mkdir -p /etc/plymouth
    cp -af /usr/share/koppie/overrides/plymouthd.conf /etc/plymouth/plymouthd.conf
fi
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme spinner || true
fi

# 3. Pastikan db.lck bersih
rm -f /var/lib/pacman/db.lck
