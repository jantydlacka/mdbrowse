#!/usr/bin/env bash
# uninstall.sh — reverse install.sh. Leaves the repo itself untouched.
set -uo pipefail

BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP="$APPS/mdbrowse.desktop"
STATE="${XDG_DATA_HOME:-$HOME/.local/share}/mdbrowse"

if [[ -L "$BIN/mdbrowse" ]]; then rm -f "$BIN/mdbrowse"; echo "removed: $BIN/mdbrowse"; fi
if [[ -f "$DESKTOP" ]]; then rm -f "$DESKTOP"; echo "removed: $DESKTOP"; fi

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" 2>/dev/null || true

# Give the .md association back to whoever had it before install.sh took it. This is
# the whole point of the file install.sh wrote: `xdg-mime default` overwrites in place
# and keeps no record, so without it the association could only be deleted, never
# restored — and uninstalling would leave the user worse off than never installing.
if [[ -f "$STATE/previous-handler" ]] && command -v xdg-mime >/dev/null 2>&1; then
  failed=0
  while IFS='=' read -r mt prev; do
    [[ -n "$mt" && -n "$prev" ]] || continue
    if xdg-mime default "$prev" "$mt" 2>/dev/null; then
      echo "restored: $mt -> $prev"
    else
      failed=1
      echo "warning: could not restore $mt -> $prev" >&2
    fi
  done < "$STATE/previous-handler"
  # The record is only thrown away once it has actually been applied. Deleting it after
  # a failed restore would leave the user with no association AND no memory of what the
  # old one was — precisely the state this file exists to make impossible.
  if [[ $failed -eq 0 ]]; then
    rm -f "$STATE/previous-handler"
  else
    echo "kept $STATE/previous-handler — rerun this script to retry" >&2
  fi
fi
rmdir "$STATE" 2>/dev/null || true    # empty unless there was something to save

# Now sweep up whatever we assigned that nobody claimed back. A user may have had a
# default for text/markdown but not for text/x-markdown, so restoring is never the
# whole job — and `xdg-mime default` can only ASSIGN a handler, never clear one. Any
# leftover mdbrowse.desktop points at the .desktop deleted above, and those files would
# then open with nothing at all. The sed only strips our own entries, so this is safe
# to run even after a restore.
MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
if [[ -f "$MIMEAPPS" ]] && grep -q 'mdbrowse\.desktop' "$MIMEAPPS"; then
  cp -f "$MIMEAPPS" "$MIMEAPPS.mdbrowse-backup"
  # Remove our entry from every association list, then drop lines left with no value.
  sed -i -E '/^[^=]+=/ { s/mdbrowse\.desktop;?//g; /^[^=]+=[[:space:]]*$/d }' "$MIMEAPPS"
  echo "removed: leftover mdbrowse association in $MIMEAPPS (backup: $MIMEAPPS.mdbrowse-backup)"
fi

# Name the cache dirs that actually exist rather than guessing at one: with a confined
# browser the pages land in ~/mdbrowse-cache, not in the XDG cache, and pointing the
# user at an empty ~/.cache/mdbrowse would leave the real directory in their home for
# good. The rendered pages are deliberately not deleted — they are cheap to regenerate,
# but they are also the user's to keep.
declare -A seen=()
caches=()
add_cache() {
  [[ -n "$1" && -d "$1" && -z "${seen[$1]:-}" ]] || return 0   # MDBROWSE_CACHE may name the default
  seen["$1"]=1; caches+=("$1")
}
add_cache "${MDBROWSE_CACHE:-}"
add_cache "$HOME/mdbrowse-cache"
add_cache "${XDG_CACHE_HOME:-$HOME/.cache}/mdbrowse"

if [[ ${#caches[@]} -gt 0 ]]; then
  echo "done. Rendered pages were left in place; remove them with:"
  printf '  rm -rf %q\n' "${caches[@]}"
else
  echo "done."
fi
