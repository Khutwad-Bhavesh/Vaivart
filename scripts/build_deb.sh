#!/usr/bin/env bash
set -e

echo "🔨 Building Vaivart Linux release..."
flutter build linux --release

echo "📦 Creating Debian package structure..."
VERSION=$(grep 'version:' pubspec.yaml | cut -d ' ' -f2 | cut -d '+' -f1)
VERSION=${VERSION:-1.0.0}

PKG_DIR="build/debian_pkg"
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/lib/vaivart"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/pixmaps"
mkdir -p "$PKG_DIR/DEBIAN"

cp -r build/linux/x64/release/bundle/* "$PKG_DIR/usr/lib/vaivart/"
ln -s /usr/lib/vaivart/vaivart "$PKG_DIR/usr/bin/vaivart"
cp assets/icons/icon_128.png "$PKG_DIR/usr/share/pixmaps/vaivart.png"

cat <<EOF > "$PKG_DIR/usr/share/applications/vaivart.desktop"
[Desktop Entry]
Name=Vaivart
Comment=Free, offline file converter.
Exec=/usr/bin/vaivart
Icon=vaivart
Terminal=false
Type=Application
Categories=Utility;FileTools;
EOF

cat <<EOF > "$PKG_DIR/DEBIAN/control"
Package: vaivart
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Bhavesh Khutwad
Description: Free, offline, open-source file converter.
 Vaivart is a desktop file converter optimized for low-end hardware.
EOF

dpkg-deb --build "$PKG_DIR" "build/Vaivart_${VERSION}_amd64.deb"

echo "✅ Debian package created successfully at build/Vaivart_${VERSION}_amd64.deb"
