#!/usr/bin/env bash
# install.sh — put mdbrowse on PATH and register it as the default .md handler.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/mdbrowse"
BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP="$APPS/mdbrowse.desktop"
STATE="${XDG_DATA_HOME:-$HOME/.local/share}/mdbrowse"

[[ -f "$SCRIPT" ]] || { echo "install: mdbrowse script not found at $SCRIPT" >&2; exit 1; }
chmod +x "$SCRIPT"

# --- 1) symlink onto PATH ----------------------------------------------------
mkdir -p "$BIN"
ln -sf "$SCRIPT" "$BIN/mdbrowse"
echo "linked: $BIN/mdbrowse -> $SCRIPT"
case ":$PATH:" in *":$BIN:"*) : ;; *)
  echo "note: $BIN is not on your PATH — add it (e.g. in ~/.profile):"
  echo "      export PATH=\"$BIN:\$PATH\"" ;;
esac

# The Snap/Flatpak cache workaround used to be baked into Exec= here. It lives in the
# mdbrowse script now, so it protects `mdbrowse notes.md` from a terminal just as much
# as a double-click — the handler needs no special treatment.
#
# Paths are quoted inside Exec= per the Desktop Entry spec, so a clone living under a
# directory with a space in it still produces a working handler.
EXEC="\"$SCRIPT\" %f"

# --- 2) install .desktop + register as default for markdown ------------------
mkdir -p "$APPS"
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=mdbrowse
Comment=View .md rendered like GitHub (read-only)
Exec=$EXEC
Icon=text-markdown
Terminal=false
NoDisplay=false
MimeType=text/markdown;text/x-markdown;
Categories=Utility;Viewer;
EOF
echo "installed: $DESKTOP"

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" 2>/dev/null || true
if command -v xdg-mime >/dev/null 2>&1; then
  # Remember whoever held the association first. `xdg-mime default` overwrites it in
  # place and keeps no record, so without this uninstall could not put it back and the
  # user would end up with no .md handler at all — worse off than before installing.
  #
  # Read it out of the user's own mimeapps.list rather than asking `xdg-mime query`:
  # the query also answers with a system-wide default, and "restoring" that would pin
  # into the user's config a choice they never made. If there is no user-level entry,
  # there is nothing to save — the system default simply resurfaces on uninstall.
  MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"

  # Keyed by MIME type and written back whole, so re-installing replaces a record rather
  # than appending a second one for the same type. Plain truncation would not do: a
  # re-install where only text/markdown has a foreign handler must not drop the
  # text/x-markdown record the first install saved.
  declare -A PREVIOUS=()
  if [[ -f "$STATE/previous-handler" ]]; then
    while IFS='=' read -r k v; do
      [[ -n "$k" && -n "$v" ]] && PREVIOUS["$k"]="$v"
    done < "$STATE/previous-handler"
  fi

  for mt in text/markdown text/x-markdown; do
    prev=""
    # The section header is matched loosely: a stray trailing space (hand-edited files
    # have them) would otherwise hide the entry, nothing would be saved, and uninstall
    # would silently be unable to restore — the exact failure this guards against.
    [[ -f "$MIMEAPPS" ]] && prev="$(awk -F= -v mt="$mt" '
      /^\[/ { in_def = ($0 ~ /^\[Default Applications\][[:space:]]*$/); next }
      in_def && $1 == mt { sub(/^[^=]*=/, ""); sub(/;.*$/, ""); print; exit }
    ' "$MIMEAPPS")"
    case "$prev" in ""|mdbrowse.desktop) continue;; esac   # nothing to save, or already ours
    PREVIOUS["$mt"]="$prev"
    echo "saved: previous handler for $mt was $prev"
  done

  if [[ ${#PREVIOUS[@]} -gt 0 ]]; then
    mkdir -p "$STATE"                    # created only when there is something to keep
    : > "$STATE/previous-handler"
    for mt in "${!PREVIOUS[@]}"; do
      printf '%s=%s\n' "$mt" "${PREVIOUS[$mt]}" >> "$STATE/previous-handler"
    done
  fi

  xdg-mime default mdbrowse.desktop text/markdown 2>/dev/null || true
  xdg-mime default mdbrowse.desktop text/x-markdown 2>/dev/null || true
  echo "registered: default handler for text/markdown"
fi

echo "done. Try:  mdbrowse README.md"
