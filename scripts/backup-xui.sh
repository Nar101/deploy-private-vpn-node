#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: sudo bash $0 <output-file>" >&2
  exit 2
fi

source_db="${XUI_DB:-/etc/x-ui/x-ui.db}"
output_file="$1"

if [[ ! -r "$source_db" ]]; then
  echo "Missing or unreadable $source_db; use sudo for the default 3X-UI database." >&2
  exit 1
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo 'Missing sqlite3 CLI; install it before creating a hot backup.' >&2
  exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

sqlite3 "$source_db" ".backup '$tmp_file'"
integrity="$(sqlite3 "$tmp_file" 'PRAGMA integrity_check;')"
if [[ "$integrity" != 'ok' ]]; then
  echo "Backup integrity check failed: $integrity" >&2
  exit 1
fi

install -m 600 "$tmp_file" "$output_file"
sha256sum "$output_file"
