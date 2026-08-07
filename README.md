<div align="center">

<img src="assets/icons/icon_128.png" width="96" height="96" alt="Vaivart Icon"/>

# Vaivart

**The WinRAR of file conversion.**
Free. Offline. Open source. Forever.

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey)](#)
[![License](https://img.shields.io/badge/License-BSL%201.1-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-v1.0.8-brightgreen)](#)
[![Build](https://img.shields.io/github/actions/workflow/status/Khutwad-Bhavesh/Vaivart/release.yml?label=build)](https://github.com/Khutwad-Bhavesh/Vaivart/actions)

No ads. No watermarks. No sign-in. No internet. No nonsense.

[Download](#download) · [Features](#features) · [Setup](#setup) · [Contributing](#contributing)

</div>

---

## What is Vaivart?

Vaivart is a desktop file converter that does exactly what it says — converts files. Nothing else. No cloud uploads, no account creation, no watermarks on your PDFs, no telemetry. Install once, use forever.

Inspired by WinRAR's philosophy: simple, reliable, always there when you need it.

---

## Download

| Platform | Link |
|----------|------|
| 🐧 Linux | [Vaivart-linux-x64.tar.gz](https://github.com/Khutwad-Bhavesh/Vaivart/releases/latest) |
| 🪟 Windows | [Vaivart-windows-x64.zip](https://github.com/Khutwad-Bhavesh/Vaivart/releases/latest) |
| 🍎 macOS | [Vaivart-macos.zip](https://github.com/Khutwad-Bhavesh/Vaivart/releases/latest) |

---

## Supported Formats

| Category | Conversions |
|----------|-------------|
| 🖼 Images | JPG ↔ PNG ↔ WEBP ↔ BMP ↔ HEIC, Images → PDF, SVG → PNG/JPG/PDF |
| 📊 Data | CSV ↔ XLSX |
| 📄 Documents | DOCX → PDF, TXT → PDF, EPUB → PDF, HTML → PDF, MD → PDF, PDF → DOCX |
| 🔧 PDF Tools | Merge PDFs, Split by range / every N pages / odd-even |
| 🎬 Video | MP4 ↔ AVI ↔ MKV ↔ WebM, Video → GIF |
| 🎵 Audio | MP3 ↔ WAV ↔ OGG |
| 📊 Presentations | PPTX → PDF |

---

## Features

- **Batch queue** — add multiple files, set per-file output format, convert all at once
- **Progress tracking** — live status dots and progress bar per conversion
- **Engine picker** — choose lightweight (~50MB) or powerful (~200MB) on first launch
- **Output folder** — choose exactly where your files go
- **History** — searchable log of every conversion with open-folder shortcut
- **Auto light/dark theme** — follows your system, no manual toggle needed
- **100% offline** — nothing ever leaves your machine, ever

---

## Engine Options

Pick your engine on first launch. Change anytime in Settings.

| Engine | Install size | Best for |
|--------|-------------|----------|
| ⚡ Lightweight | ~50MB | Casual use, images, documents |
| 🔧 Powerful | ~200MB | Video, audio, heavy conversions |
| 🎛️ Manual | Minimal | Power users with tools already installed |

---

## Setup

### Linux (Arch / Manjaro / EndeavourOS)

**Option A: Install via PKGBUILD (Recommended)**
```bash
git clone https://github.com/Khutwad-Bhavesh/Vaivart.git
cd Vaivart/packaging/arch
makepkg -si
```

**Option B: Run from source**
```bash
sudo pacman -S flutter ffmpeg libreoffice-fresh calibre libheif
git clone https://github.com/Khutwad-Bhavesh/Vaivart.git
cd Vaivart
flutter pub get
flutter run -d linux
```

### Linux (Ubuntu/Debian)

```bash
sudo apt install flutter ffmpeg libreoffice calibre libheif-examples

git clone https://github.com/Khutwad-Bhavesh/Vaivart.git
cd Vaivart

flutter pub get
flutter run -d linux
```

### Windows

```bash
git clone https://github.com/Khutwad-Bhavesh/Vaivart.git
cd Vaivart
flutter pub get
flutter run -d windows
```

### macOS

```bash
git clone https://github.com/Khutwad-Bhavesh/Vaivart.git
cd Vaivart
flutter pub get
flutter run -d macos
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/        # Colors, typography tokens
│   ├── converters/       # Image, PDF, data, video, audio, document logic
│   ├── engine/           # Engine config + capability checks
│   ├── models/           # ConversionJob
│   └── services/         # History, output folder
├── features/
│   ├── onboarding/       # Engine picker (first launch)
│   ├── converter/        # Main conversion screen
│   ├── pdf_tools/        # Merge + split
│   ├── history/          # Conversion log
│   ├── settings/         # Engine + output preferences
│   └── compression/      # 🏆
└── shared/
    └── widgets/          # Sidebar, reusable components
```

---

## Contributing

Pull requests welcome. No CLA, no bureaucracy.

To add a new format:
1. Create `lib/core/converters/yourformat_converter.dart`
2. Add formats to `availableFormats` in `conversion_job.dart`
3. Add routing in `converter_dispatcher.dart`

The UI picks it up automatically — no other changes needed.

---

## Built with

- [Flutter](https://flutter.dev) — UI framework
- [ffmpeg](https://ffmpeg.org) — video + audio conversion
- [LibreOffice](https://libreoffice.org) — document conversion
- [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf) — PDF tools
- [Calibre](https://calibre-ebook.com) — EPUB conversion

---

## License

Business Source License 1.1 (BSL-1.1) © 2026 Bhavesh Khutwad

---

<div align="center">
<sub>Built with Flutter · No enemies · Just convert · 🏆 Please purchase WinRAR after your 40-day trial</sub>
</div>
