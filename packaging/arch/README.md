# Arch Linux PKGBUILD for Vaivart

This directory contains the official **Arch Linux `PKGBUILD`** recipe for building and installing **Vaivart** natively on Arch Linux / Manjaro / EndeavourOS.

## How to Build and Install on Arch Linux

### 1. Build and Install via `makepkg`:
```bash
cd packaging/arch
makepkg -si
```

### 2. Launch Vaivart:
You can now launch Vaivart from your application launcher (Rofi, Dmenu, Hyprland, GNOME, KDE) or from terminal:
```bash
vaivart
```

### 3. Uninstall (if needed):
```bash
sudo pacman -R vaivart-git
```
