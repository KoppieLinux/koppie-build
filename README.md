# Koppie Linux - Build Profile

Repositori resmi untuk membuat ISO **Koppie Linux** berbasis Arch Linux dengan desktop KDE Plasma minimalis dan Calamares Installer offline multi-boot.

---

## 🛠️ Persiapan & Persyaratan (Prerequisites)

Build wajib dijalankan di sistem operasi **Arch Linux** (atau turunannya):

```bash
sudo pacman -Syu --needed archiso mkinitcpio-archiso base-devel git
```

Pastikan user kamu memiliki akses `sudo` tanpa hambatan dan ruang disk kosong minimal **15 GB**.

---

## 🚀 Panduan Setup & Build (Untuk Pengembang / Contributor)

Setiap pengembang atau pengguna yang ingin melakukan build ISO di mesin masing-masing, jalankan langkah-langkah berikut:

### 1. Clone Repositori
Clone repositori ini langsung ke direktori `~/Projects/koppie-arch`:

```bash
mkdir -p ~/Projects
git clone https://github.com/KoppieLinux/koppie-build.git ~/Projects/koppie-arch
cd ~/Projects/koppie-arch
```

### 2. Setup Submodule / Repositori Paket Lokal [koppie]
Koppie Linux menyertakan aplikasi kustom (`koppie-software-centre`, `koppie-update-manager`, `koppie-driver-manager`, `calamares`, `yay`, dll.). 

Pastikan paket lokal sudah disiapkan di folder `koppie-repo/x86_64`:
```bash
# Clone atau update repositori paket kustom
git clone https://github.com/KoppieLinux/koppie-repo.git koppie-repo

# Masuk ke folder repo lokal dan buat indeks pacman db
cd koppie-repo/x86_64
repo-add koppie.db.tar.gz *.pkg.tar.zst
ln -sf koppie.db.tar.gz koppie.db
ln -sf koppie.files.tar.gz koppie.files
cd ~/Projects/koppie-arch
```

### 3. Sesuaikan Path di `pacman.conf`
Buka file `pacman.conf` dan pastikan direktori lokalnya mengarah ke folder repo di user masing-masing:
```ini
[koppie]
SigLevel = Optional TrustAll
Server = file:///home/$USER/Projects/koppie-arch/koppie-repo/x86_64
```
*(Ganti `$USER` dengan username sistem masing-masing).*

### 4. Mulai Build ISO
Jalankan skrip build anti-tidur yang sudah disediakan:
```bash
./build.sh
```

> **Catatan:** Skrip `build.sh` secara otomatis:
> - Mengaktifkan `systemd-inhibit` agar laptop/PC tidak tertidur/sleep saat build.
> - Membersihkan `db.lck` sisa bila ada.
> - Menghasilkan file ISO di dalam folder `out/`.
> - Menjalankan verifikasi integritas ISO secara otomatis setelah build selesai.

---

## 💾 Membakar ISO ke Flashdisk (USB)

Setelah build selesai dan file ISO berada di `out/koppie-*.iso`, bakar menggunakan perintah `dd` (ganti `/dev/sdX` sesuai perangkat USB kamu, cek dengan `lsblk`):

```bash
sudo dd if=out/koppie-*.iso of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct
sync
```
ISO ini mendukung **Hybrid Boot**: bisa langsung di-boot di mode **UEFI** (GRUB) maupun **Legacy BIOS** (Syslinux).
