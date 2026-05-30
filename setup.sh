#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# LINUP - Setup & Build (macOS / Windows / Android)
# ═══════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_MACOS="$SCRIPT_DIR"
DIR_WIN="$(dirname "$SCRIPT_DIR")/LinupWin"
DIR_ANDROID="$(dirname "$SCRIPT_DIR")/Linup"

# ── Colour helpers ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
err()  { echo -e "${RED}❌ $*${NC}"; }
hdr()  { echo -e "\n${BOLD}${BLUE}$*${NC}"; }

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  LINUP v18.1.0 — Multi-Platform Setup & Build${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Python ───────────────────────────────────────────────────────
hdr "[1/5] Python"
if ! command -v python3 &>/dev/null; then
    err "Python 3 not found.  Install: brew install python@3.11"
    exit 1
fi
PYTHON_VER=$(python3 --version | cut -d' ' -f2)
ok "Python $PYTHON_VER"

# ── 2. Virtual environment ──────────────────────────────────────────
hdr "[2/5] Virtual environment"
cd "$SCRIPT_DIR"
if [ -d "venv" ]; then
    warn "venv already exists — reusing"
else
    python3 -m venv venv
    ok "venv created"
fi
source venv/bin/activate

# ── 3. Dependencies ─────────────────────────────────────────────────
hdr "[3/5] Dependencies"
pip install --upgrade pip -q
pip install "flet>=0.25.0" "reportlab>=4.0.0" "Pillow>=10.0.0" -q
ok "flet       $(pip show flet       2>/dev/null | grep ^Version | cut -d' ' -f2)"
ok "reportlab  $(pip show reportlab  2>/dev/null | grep ^Version | cut -d' ' -f2)"
ok "Pillow     $(pip show Pillow     2>/dev/null | grep ^Version | cut -d' ' -f2)"

# ── 4. Flutter ──────────────────────────────────────────────────────
hdr "[4/5] Flutter"
FLUTTER_OK=false
if ! command -v flutter &>/dev/null; then
    warn "Flutter not found — needed for builds"
    echo "     Install: brew install --cask flutter"
    echo "     Or:      https://docs.flutter.dev/get-started/install"
else
    FLUTTER_VER=$(flutter --version 2>/dev/null | head -n1 | cut -d' ' -f2)
    ok "Flutter $FLUTTER_VER"
    FLUTTER_OK=true
fi

# ── Build helpers ────────────────────────────────────────────────────
build_macos() {
    if [ "$FLUTTER_OK" = false ]; then
        err "Flutter required for macOS build"; return 1
    fi
    echo -e "\n${BOLD}Building macOS...${NC}"
    flet build macos --output "$DIR_MACOS/build/macos"
    ok "macOS build → $DIR_MACOS/build/macos/Linup.app"
}

build_windows() {
    if [ "$FLUTTER_OK" = false ]; then
        err "Flutter required for Windows build"; return 1
    fi
    echo -e "\n${BOLD}Building Windows...${NC}"
    UNAME="$(uname -s)"
    if [ "$UNAME" = "Darwin" ]; then
        warn "Cross-compiling Windows on macOS is not supported by Flutter."
        warn "Run this script on a Windows machine (Git Bash / WSL) to build the .exe."
        warn "Output will go to: $DIR_WIN"
    else
        mkdir -p "$DIR_WIN"
        flet build windows --output "$DIR_WIN"
        ok "Windows build → $DIR_WIN/"
    fi
}

build_android() {
    if [ "$FLUTTER_OK" = false ]; then
        err "Flutter required for Android build"; return 1
    fi
    echo -e "\n${BOLD}Building Android APK...${NC}"
    if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
        warn "ANDROID_HOME / ANDROID_SDK_ROOT not set."
        warn "Install Android Studio and set the SDK path, then re-run."
        warn "  export ANDROID_HOME=\$HOME/Library/Android/sdk"
        warn "Output will go to: $DIR_ANDROID"
    else
        mkdir -p "$DIR_ANDROID"
        flet build apk --output "$DIR_ANDROID"
        ok "Android APK → $DIR_ANDROID/"
    fi
}

# ── 5. Platform build menu ──────────────────────────────────────────
hdr "[5/5] Build target"
echo ""
echo "  1)  Run dev server  (flet run)"
echo "  2)  Build macOS     → $DIR_MACOS/build/macos/"
echo "  3)  Build Windows   → $DIR_WIN/"
echo "  4)  Build Android   → $DIR_ANDROID/"
echo "  5)  Build ALL platforms"
echo "  0)  Skip build (env setup only)"
echo ""
read -rp "  Choice [0-5]: " CHOICE

case "$CHOICE" in
    1)
        echo ""
        ok "Starting dev server..."
        flet run main.py
        ;;
    2)
        build_macos
        ;;
    3)
        build_windows
        ;;
    4)
        build_android
        ;;
    5)
        build_macos || true
        build_windows || true
        build_android || true
        ;;
    *)
        echo ""
        ok "Environment ready — build skipped."
        ;;
esac

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "  Python      $PYTHON_VER"
echo -e "  flet        $(pip show flet      2>/dev/null | grep ^Version | cut -d' ' -f2)"
echo -e "  reportlab   $(pip show reportlab 2>/dev/null | grep ^Version | cut -d' ' -f2)"
echo -e "  Pillow      $(pip show Pillow    2>/dev/null | grep ^Version | cut -d' ' -f2)"
echo -e "  Project     $SCRIPT_DIR"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Quick commands:"
echo "    source venv/bin/activate"
echo "    flet run main.py                          # dev"
echo "    flet build macos                          # macOS .app"
echo "    flet build windows                        # Windows .exe  (run on Windows)"
echo "    flet build apk                            # Android .apk"
echo ""
