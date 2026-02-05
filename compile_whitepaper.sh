#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# ESQET v2.0 PDF BUILD SCRIPT
# Pandoc + Tectonic (Termux-safe)
# -------------------------------

# Resolve base directory safely
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_MD="$BASE_DIR/ESQET_Whitepaper_v2.0.md"
BUILD_DIR="$BASE_DIR/build"
OUT_PDF="$BUILD_DIR/ESQET_Whitepaper_v2.0.pdf"

echo "📄 ESQET Whitepaper Build"
echo "Base dir : $BASE_DIR"
echo "Source   : $SRC_MD"
echo "Output   : $OUT_PDF"
echo

# Sanity checks
if [[ ! -f "$SRC_MD" ]]; then
  echo "❌ ERROR: Source markdown not found:"
  echo "   $SRC_MD"
  exit 1
fi

# Create build directory if needed
mkdir -p "$BUILD_DIR"

# Compile
echo "⚙️  Running Pandoc + Tectonic..."
pandoc "$SRC_MD" \
  -o "$OUT_PDF" \
  --pdf-engine=tectonic \
  --standalone \
  -V geometry:margin=0.9in \
  -V papersize=a4 \
  -V fontsize=11pt

echo
echo "✅ BUILD SUCCESS"
echo "📦 PDF generated at:"
echo "   $OUT_PDF"
