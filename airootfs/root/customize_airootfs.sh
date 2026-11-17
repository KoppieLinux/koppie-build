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

# 2. Pastikan db.lck bersih
rm -f /var/lib/pacman/db.lck
