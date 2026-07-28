#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/effective.json" <<'JSON'
{
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {"clients": [{"id": "example-client-id", "flow": "xtls-rprx-vision"}]},
    "streamSettings": {
      "security": "reality",
      "realitySettings": {
        "target": "example.com:443",
        "serverNames": ["example.com"],
        "privateKey": "example-private-key",
        "shortIds": ["example-short-id"]
      }
    }
  }]
}
JSON

preflight_output="$(bash "$root/scripts/preflight-reality.sh" --config "$tmpdir/effective.json")"
grep -q 'PASS reality_preflight=complete' <<<"$preflight_output"
! grep -q 'example-client-id\|example-private-key\|example-short-id' <<<"$preflight_output"

printf '%s\n' \
  'uuid=123e4567-e89b-42d3-a456-426614174000' \
  'privateKey=example-private-key' \
  'shortId: example-short-id' \
  'safe metadata line' \
  | python3 "$root/scripts/redact-debug-log.py" "$tmpdir/effective.json" >"$tmpdir/redacted.log"
grep -q 'safe metadata line' "$tmpdir/redacted.log"
! grep -q '123e4567\|example-private-key\|example-short-id' "$tmpdir/redacted.log"

cp "$tmpdir/effective.json" "$tmpdir/bad-effective.json"
python3 - "$tmpdir/bad-effective.json" <<'PY'
import json
import sys
path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)
del data["inbounds"][0]["streamSettings"]["realitySettings"]["privateKey"]
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh)
PY
if bash "$root/scripts/preflight-reality.sh" --config "$tmpdir/bad-effective.json" >/dev/null 2>&1; then
  echo 'preflight accepted a Reality config without a private key' >&2
  exit 1
fi

diagnosis="$(bash "$root/scripts/diagnose-node.sh" \
  --server-received clienthello --reality failed --vless unknown --exit unknown \
  --effective-config yes --contaminated no --restored yes)"
grep -q 'BRANCH reality_authentication' <<<"$diagnosis"

if bash "$root/scripts/diagnose-node.sh" \
  --server-received none --reality passed --vless passed --exit expected \
  --effective-config yes --contaminated no --restored yes >/dev/null 2>&1; then
  echo 'diagnose-node accepted contradictory evidence' >&2
  exit 1
fi

printf '%s%s\n' 'vless' '://private-example' >"$tmpdir/node.txt"
printf '%s\n' '[Rule]' 'DOMAIN,example.com,NEW-NODE-TEST' >"$tmpdir/rules.conf"
bash "$root/scripts/build-transfer-package.sh" \
  --node-file "$tmpdir/node.txt" --rules-file "$tmpdir/rules.conf" \
  --output-dir "$tmpdir/package" >/dev/null
[[ "$(stat -f '%Lp' "$tmpdir/package/node.txt" 2>/dev/null || stat -c '%a' "$tmpdir/package/node.txt")" == '600' ]]
[[ -f "$tmpdir/package/SHA256SUMS" ]]

printf '%s%s\n' '-----BEGIN OPENSSH ' 'PRIVATE KEY-----' >"$tmpdir/private-node.txt"
if bash "$root/scripts/build-transfer-package.sh" \
  --node-file "$tmpdir/private-node.txt" --rules-file "$tmpdir/rules.conf" \
  --output-dir "$tmpdir/rejected-package" >/dev/null 2>&1; then
  echo 'transfer package accepted private-key material' >&2
  exit 1
fi

mkdir "$tmpdir/mock-bin"
cat >"$tmpdir/mock-bin/curl" <<'MOCK'
#!/usr/bin/env bash
args="$*"
if [[ "$args" == *'api.ipify.org'* ]]; then
  printf '%s' '127.0.0.1'
elif [[ "$args" == *'api.openai.com'* ]]; then
  printf '%s' '401 0.12'
elif [[ "$args" == *'api.anthropic.com'* ]]; then
  printf '%s' '401 0.13'
elif [[ "$args" == *'google.com/generate_204'* ]]; then
  printf '%s' '204 0.10'
elif [[ "$args" == *'download.example'* ]]; then
  printf '%s' '10000000 4.00 2500000'
else
  exit 22
fi
MOCK
chmod 700 "$tmpdir/mock-bin/curl"
PATH="$tmpdir/mock-bin:$PATH" bash "$root/scripts/verify-client.sh" \
  --proxy socks5h://127.0.0.1:9999 --expected-ip 127.0.0.1 \
  --download-url https://download.example/file --json-output "$tmpdir/result.json" >/dev/null
python3 - "$tmpdir/result.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
assert data["passed"] is True
assert data["services"]["google"]["status"] == 204
assert data["download"]["requires_runtime_route_evidence"] is True
PY

if PATH="$tmpdir/mock-bin:$PATH" bash "$root/scripts/verify-client.sh" \
  --proxy direct --expected-ip 0.0.0.0 >/dev/null 2>&1; then
  echo 'verify-client accepted an unexpected exit IP' >&2
  exit 1
fi

echo 'Skill script tests passed.'
