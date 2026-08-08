#!/usr/bin/env bash
set -e

echo "Building Vaivart TUI executable..."
mkdir -p build/bin

dart compile exe bin/vaivart_tui.dart -o build/bin/vaivart-tui

echo "Successfully compiled standalone Vaivart TUI binary to build/bin/vaivart-tui"
echo ""
echo "To install to ~/.local/bin, run:"
echo "  mkdir -p ~/.local/bin && cp build/bin/vaivart-tui ~/.local/bin/vaivart-tui"
