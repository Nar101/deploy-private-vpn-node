#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: preflight-reality.sh --config <effective-xray-config.json> [--xray-bin <path>] [--expected-port <port>]

Reads the effective Xray JSON and reports only non-sensitive structure and hashes.
It never prints UUIDs, Reality keys, short IDs, or complete share links.
EOF
  exit 2
}

config=''
xray_bin='xray'
expected_port='443'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) config="${2:-}"; shift 2 ;;
    --xray-bin) xray_bin="${2:-}"; shift 2 ;;
    --expected-port) expected_port="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$config" && -r "$config" ]] || usage
[[ "$expected_port" =~ ^[0-9]+$ ]] || usage

if command -v "$xray_bin" >/dev/null 2>&1; then
  xray_version="$($xray_bin version 2>/dev/null | sed -n '1p' || true)"
else
  xray_version='unavailable'
fi
printf 'INFO xray_version=%s\n' "${xray_version:-unknown}"

python3 - "$config" "$expected_port" <<'PY'
import hashlib
import json
import sys

path, expected_port = sys.argv[1], int(sys.argv[2])
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)

def digest(value):
    raw = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode()).hexdigest()[:12]

inbounds = data.get("inbounds", [])
reality = []
for inbound in inbounds:
    stream = inbound.get("streamSettings") or {}
    if str(stream.get("security", "")).lower() != "reality":
        continue
    settings = stream.get("realitySettings") or {}
    reality.append((inbound, settings))

if not reality:
    print("FAIL reality_inbound=missing")
    raise SystemExit(1)
if len(reality) > 1:
    print(f"WARN reality_inbound_count={len(reality)}")

failed = False
for index, (inbound, settings) in enumerate(reality):
    port = inbound.get("port")
    protocol = inbound.get("protocol")
    target = settings.get("target") or settings.get("dest")
    names = settings.get("serverNames") or []
    short_ids = settings.get("shortIds") or []
    clients = ((inbound.get("settings") or {}).get("clients") or [])
    private_key = settings.get("privateKey")
    min_client = settings.get("minClientVer")
    max_client = settings.get("maxClientVer")

    print(f"INFO inbound[{index}].protocol={protocol or 'missing'}")
    print(f"{'PASS' if port == expected_port else 'FAIL'} inbound[{index}].port={port}")
    print(f"{'PASS' if target else 'FAIL'} inbound[{index}].target_present={'yes' if target else 'no'}")
    print(f"{'PASS' if names else 'FAIL'} inbound[{index}].server_names={len(names)}")
    print(f"{'PASS' if private_key else 'FAIL'} inbound[{index}].private_key_present={'yes' if private_key else 'no'}")
    print(f"{'PASS' if short_ids else 'FAIL'} inbound[{index}].short_ids={len(short_ids)}")
    print(f"{'PASS' if clients else 'FAIL'} inbound[{index}].clients={len(clients)}")
    if private_key:
        print(f"INFO inbound[{index}].private_key_sha256={digest(private_key)}")
    if short_ids:
        print(f"INFO inbound[{index}].short_ids_sha256={digest(short_ids)}")
    if clients:
        client_ids = [client.get("id") for client in clients if client.get("id")]
        flows = sorted({client.get("flow", "") for client in clients})
        print(f"INFO inbound[{index}].client_ids_sha256={digest(client_ids)}")
        print(f"INFO inbound[{index}].flows={','.join(flows) if flows else 'missing'}")

    if min_client in (None, ""):
        print(f"WARN inbound[{index}].min_client_ver=unset; current Xray may apply its own default minimum")
    else:
        print(f"INFO inbound[{index}].min_client_ver={min_client}")
    print(f"INFO inbound[{index}].max_client_ver={max_client or 'unset'}")

    if port != expected_port or not target or not names or not private_key or not short_ids or not clients:
        failed = True

if failed:
    raise SystemExit(1)
print("PASS reality_preflight=complete")
PY
