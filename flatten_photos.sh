#!/bin/bash
# flatten_photos.sh
# Moves all photos from subdirectories into the root/target folder.
# Handles filename conflicts by appending a counter suffix.
#
# Usage:
#   ./flatten_photos.sh <target_folder>
#
# Example:
#   ./flatten_photos.sh /Users/you/Photos

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
PHOTO_EXTENSIONS=("jpg" "jpeg" "png" "gif" "bmp" "tiff" "tif" "webp" "heic" "heif" "raw" "cr2" "cr3" "nef" "arw" "dng" "orf" "rw2" "pef")

# ── Argument check ────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target_folder>"
  exit 1
fi

ROOT="$1"

if [[ ! -d "$ROOT" ]]; then
  echo "Error: '$ROOT' is not a directory."
  exit 1
fi

# ── Build find expression for all photo extensions ────────────────────────────
FIND_ARGS=()
first=true
for ext in "${PHOTO_EXTENSIONS[@]}"; do
  if $first; then
    FIND_ARGS+=(-iname "*.${ext}")
    first=false
  else
    FIND_ARGS+=(-o -iname "*.${ext}")
  fi
done

# ── Move photos ───────────────────────────────────────────────────────────────
moved=0
skipped=0

while IFS= read -r -d '' file; do
  # Skip files already in the root (not in a subdirectory)
  dir="$(dirname "$file")"
  if [[ "$dir" == "$ROOT" ]]; then
    continue
  fi

  filename="$(basename "$file")"
  dest="$ROOT/$filename"

  # Resolve conflicts by appending _1, _2, … before the extension
  if [[ -e "$dest" ]]; then
    name="${filename%.*}"
    ext_part="${filename##*.}"
    counter=1
    while [[ -e "$ROOT/${name}_${counter}.${ext_part}" ]]; do
      ((counter++))
    done
    dest="$ROOT/${name}_${counter}.${ext_part}"
    echo "Conflict: '$filename' → '$(basename "$dest")'"
  fi

  mv "$file" "$dest"
  echo "Moved: $file → $dest"
  ((moved++))

done < <(find "$ROOT" -mindepth 2 \( "${FIND_ARGS[@]}" \) -print0)

echo ""
echo "Done. Moved: $moved file(s), skipped: $skipped conflict(s) (renamed instead)."
