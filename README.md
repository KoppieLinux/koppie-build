# Koppie Linux - Build Profile

The official build repository for generating the **Koppie Linux** ISO based on Arch Linux, featuring a minimal KDE Plasma desktop and an offline, multi-boot capable Calamares Installer.

---

## 🛠️ Prerequisites

Building the ISO requires an **Arch Linux** (or Arch-based) host system:

```bash
sudo pacman -Syu --needed archiso mkinitcpio-archiso base-devel git
```

Ensure your user has working `sudo` permissions and at least **15 GB** of free disk space.

---

## 🚀 Setup & Build Instructions

Follow these steps to set up and build the ISO in your local environment:

### 1. Clone the Repository
Clone this repository directly into your `~/Projects/koppie-arch` folder:

```bash
mkdir -p ~/Projects
git clone https://github.com/KoppieLinux/koppie-build.git ~/Projects/koppie-arch
cd ~/Projects/koppie-arch
```

### 2. Setup the Local [koppie] Package Repository
Koppie Linux relies on custom packages (`koppie-software-centre`, `koppie-update-manager`, `koppie-driver-manager`, `calamares`, `yay`, etc.).

Set up the local repository packages in `koppie-repo/x86_64`:
```bash
# Clone the custom package repository (or pull latest changes if already present)
if [ ! -d "koppie-repo" ]; then
    git clone https://github.com/KoppieLinux/koppie-repo.git koppie-repo
else
    git -C koppie-repo pull
fi

# Generate pacman repository database
cd koppie-repo/x86_64
repo-add -n -R koppie.db.tar.gz *.pkg.tar.zst
ln -sf koppie.db.tar.gz koppie.db
ln -sf koppie.files.tar.gz koppie.files
cd ~/Projects/koppie-arch
```

### 3. Verify Local Path in `pacman.conf`
Ensure the local repository path in `pacman.conf` matches your user path:
```ini
[koppie]
SigLevel = Optional TrustAll
Server = file:///home/$USER/Projects/koppie-arch/koppie-repo/x86_64
```
*(Replace `$USER` with your system username).*

### 4. Build the ISO
Execute the provided build script:
```bash
./build.sh
```

> **Note:** The `build.sh` script automatically:
> - Prompts for `sudo` password if needed.
> - Activates `systemd-inhibit` to prevent the system from sleeping or suspending during compilation.
> - Cleans any leftover pacman `db.lck` locks and previous `work/` directory.
> - Compiles and outputs the bootable ISO file into the `out/` directory.
> - Automatically runs `verify-iso.sh` to validate checksums and file integrity upon completion.

---

## 💾 Flashing the ISO to USB

Once the build is complete and the ISO is created under `out/koppie-*.iso`, flash it using `dd` (replace `/dev/sdX` with your USB drive identifier, which can be found via `lsblk`):

```bash
sudo dd if=out/koppie-*.iso of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct
sync
```

This ISO supports **Hybrid Boot**: it boots seamlessly on both **UEFI** (via GRUB) and **Legacy BIOS** (via Syslinux).
