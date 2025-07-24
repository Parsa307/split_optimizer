#!/bin/bash

# === Configurable filters ===
LANG="en"         # Target language
DPI="xxhdpi"      # Target screen density
ARCH="arm64_v8a"  # Target architecture

print_help() {
  echo "📦 Optimize APK bundle (.apks, .apkm, .zip, etc.)"
  echo
  echo "Usage: $0 your_app.<ext>"
  echo
  echo "Keeps only:"
  echo "  - base.apk"
  echo "  - split_config.${LANG}.apk"
  echo "  - split_config.${DPI}.apk"
  echo "  - split_config.${ARCH}.apk"
  echo
  echo "Output file: your_app_optimized.<ext>"
  echo
  echo "Note:"
  echo "  This script works on ZIP-format archives containing APK splits."
  echo "  It might work with other extensions if the file format is ZIP-based"
  echo "  and the APK split grouping is consistent."
  echo
  echo "Run with -h or --help to show this message."
  exit 0
}

# === Dependency Check ===
for dep in unzip zip; do
  if ! command -v "$dep" &>/dev/null; then
    echo "❌ Error: Required command '$dep' not found. Please install it."
    exit 1
  fi
done

# === Usage Check ===
if [[ $# -eq 0 || -z "$1" ]]; then
  echo "❌ Invalid usage: Missing input file."
  echo "Run with -h or --help for usage information."
  exit 1
fi

INPUT="$1"

# === Help flag ===
case "$INPUT" in
  -h|--help)
    print_help
    ;;
esac

# === File Existence Check ===
if [[ ! -f "$INPUT" ]]; then
  echo "❌ Error: File '$INPUT' not found."
  exit 1
fi

# === Extract File Info ===
EXT="${INPUT##*.}"
BASENAME="${INPUT%.*}"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "[*] Extracting $INPUT to $TMPDIR ..."
unzip -q "$INPUT" -d "$TMPDIR" || { echo "❌ Failed to unzip $INPUT"; exit 1; }

# === Filtering Files & Removing Directories ===
echo "[*] Filtering APK splits and cleaning up ..."

for entry in "$TMPDIR"/*; do
  name=$(basename "$entry")

  if [[ -d "$entry" ]]; then
    echo "  Removing directory: $name"
    rm -rf "$entry"
  elif [[ "$name" =~ ^(base\.apk|split_config\.${LANG}\.apk|split_config\.${DPI}\.apk|split_config\.${ARCH}\.apk)$ ]]; then
    echo "  Keeping $name"
  else
    echo "  Removing file: $name"
    rm -f "$entry"
  fi
done

# === Output File Creation ===
OUTPUT="${BASENAME}_optimized.${EXT}"
echo "[*] Creating optimized APK bundle: $OUTPUT"

(
  cd "$TMPDIR" || exit 1
  zip -q -r "$OLDPWD/$OUTPUT" . || { echo "❌ Failed to create $OUTPUT"; exit 1; }
)

echo "[✅] Done! Optimized APK bundle saved as $OUTPUT"
