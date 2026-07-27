#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required=(
  SKILL.md
  README.md
  LICENSE
  NOTICE
  CITATION.cff
  agents/openai.yaml
  references/client-adapters.md
  references/clash-mihomo.md
  references/security-and-acceptance.md
  references/shadowrocket.md
  references/tencent-lighthouse.md
  references/windows.md
  scripts/audit-server.sh
  scripts/backup-xui.sh
  scripts/verify-client.sh
)

for path in "${required[@]}"; do
  if [[ ! -f "$root/$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
done

for script in "$root"/scripts/*.sh; do
  bash -n "$script"
done

if find "$root" -path "$root/.git" -prune -o -type f \
  \( -name '*.pem' -o -name '*.key' -o -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) \
  -print -quit | grep -q .; then
  echo 'Sensitive file type found in the release tree.' >&2
  exit 1
fi

secret_pattern='(vless|ss|trojan)://|BEGIN (OPENSSH |RSA |EC )?PRIVATE KEY|ssh-(rsa|ed25519) AAAA|[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|~/Downloads'
if grep -REnI --exclude-dir=.git --exclude='validate-public.sh' "$secret_pattern" "$root"; then
  echo 'High-risk literal found in the release tree.' >&2
  exit 1
fi

public_ips="$({ grep -REhoI --exclude-dir=.git --exclude='validate-public.sh' '([0-9]{1,3}\.){3}[0-9]{1,3}' "$root" || true; } | sort -u)"
while IFS= read -r ip; do
  [[ -z "$ip" ]] && continue
  case "$ip" in
    0.0.0.0|127.0.0.1) ;;
    *) echo "Unexpected IPv4 literal: $ip" >&2; exit 1 ;;
  esac
done <<<"$public_ips"

if command -v sqlite3 >/dev/null 2>&1; then
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  sqlite3 "$tmpdir/source.db" 'CREATE TABLE test(id INTEGER PRIMARY KEY, value TEXT); INSERT INTO test(value) VALUES("verified");'
  XUI_DB="$tmpdir/source.db" bash "$root/scripts/backup-xui.sh" "$tmpdir/backup.db" >/dev/null
  [[ "$(sqlite3 "$tmpdir/backup.db" 'PRAGMA integrity_check;')" == 'ok' ]]
  [[ "$(sqlite3 "$tmpdir/backup.db" 'SELECT value FROM test;')" == 'verified' ]]
else
  echo 'sqlite3 not installed; skipped hot-backup integration test.' >&2
fi

echo 'Public release validation passed.'
