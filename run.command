#!/bin/zsh
set -eu
cd "${0:A:h}"
if [[ -n "${GODOT_BIN:-}" && -x "$GODOT_BIN" ]]; then
  exec "$GODOT_BIN" --path "$PWD"
fi
for candidate in /Applications/Godot.app/Contents/MacOS/Godot /opt/homebrew/bin/godot /private/tmp/godot-4.4.1/Godot.app/Contents/MacOS/Godot; do
  if [[ -x "$candidate" ]]; then
    exec "$candidate" --path "$PWD"
  fi
done
printf '%s\n' 'Chưa tìm thấy Godot. Cài Godot 4.4.1 hoặc đặt GODOT_BIN tới executable Godot.'
read -r '?Nhấn Enter để đóng.'
