#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: verify-client.sh --proxy <socks5h://host:port|http://host:port|direct> [options]

Options:
  --expected-ip <ip>
  --download-url <url>
  --json-output <file>
  --connect-timeout <seconds>
  --max-time <seconds>
EOF
  exit 2
}

proxy=''
expected_ip=''
download_url=''
json_output=''
connect_timeout='10'
max_time='20'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxy) proxy="${2:-}"; shift 2 ;;
    --expected-ip) expected_ip="${2:-}"; shift 2 ;;
    --download-url) download_url="${2:-}"; shift 2 ;;
    --json-output) json_output="${2:-}"; shift 2 ;;
    --connect-timeout) connect_timeout="${2:-}"; shift 2 ;;
    --max-time) max_time="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$proxy" ]] || usage
[[ "$connect_timeout" =~ ^[0-9]+$ && "$max_time" =~ ^[0-9]+$ ]] || usage

curl_common=(--connect-timeout "$connect_timeout" --max-time "$max_time" -sS)
if [[ "$proxy" != 'direct' ]]; then
  curl_common+=(--proxy "$proxy")
fi

actual_ip="$(curl "${curl_common[@]}" https://api.ipify.org)"
openai_result="$(curl "${curl_common[@]}" -o /dev/null -w '%{http_code} %{time_total}' https://api.openai.com/v1/models)"
claude_result="$(curl "${curl_common[@]}" -o /dev/null -w '%{http_code} %{time_total}' https://api.anthropic.com/v1/models)"
google_result="$(curl "${curl_common[@]}" -o /dev/null -w '%{http_code} %{time_total}' https://www.google.com/generate_204)"

read -r openai_code openai_time <<<"$openai_result"
read -r claude_code claude_time <<<"$claude_result"
read -r google_code google_time <<<"$google_result"

failed=0
[[ -z "$expected_ip" || "$actual_ip" == "$expected_ip" ]] || failed=1
[[ "$openai_code" == '401' ]] || failed=1
[[ "$claude_code" == '401' || "$claude_code" == '403' ]] || failed=1
[[ "$google_code" == '204' ]] || failed=1

printf 'exit_ip %s\n' "$actual_ip"
printf 'openai %s %ss\n' "$openai_code" "$openai_time"
printf 'claude %s %ss\n' "$claude_code" "$claude_time"
printf 'google %s %ss\n' "$google_code" "$google_time"

download_bytes=''
download_time=''
download_mbps=''
if [[ -n "$download_url" ]]; then
  download_result="$(curl "${curl_common[@]}" -o /dev/null -w '%{size_download} %{time_total} %{speed_download}' "$download_url")"
  read -r download_bytes download_time download_speed <<<"$download_result"
  download_mbps="$(awk -v speed="$download_speed" 'BEGIN {printf "%.2f", speed * 8 / 1000000}')"
  printf 'download %s_bytes %ss %s_Mbps\n' "$download_bytes" "$download_time" "$download_mbps"
  echo 'NOTE download is valid only after the client runtime log proves this hostname used the new node.'
fi

if [[ -n "$json_output" ]]; then
  VERIFY_EXIT_IP="$actual_ip" VERIFY_EXPECTED_IP="$expected_ip" \
  VERIFY_OPENAI_CODE="$openai_code" VERIFY_OPENAI_TIME="$openai_time" \
  VERIFY_CLAUDE_CODE="$claude_code" VERIFY_CLAUDE_TIME="$claude_time" \
  VERIFY_GOOGLE_CODE="$google_code" VERIFY_GOOGLE_TIME="$google_time" \
  VERIFY_DOWNLOAD_BYTES="$download_bytes" VERIFY_DOWNLOAD_TIME="$download_time" \
  VERIFY_DOWNLOAD_MBPS="$download_mbps" VERIFY_FAILED="$failed" \
  python3 - "$json_output" <<'PY'
import json
import os
import sys

payload = {
    "exit_ip": os.environ["VERIFY_EXIT_IP"],
    "expected_ip": os.environ["VERIFY_EXPECTED_IP"] or None,
    "services": {
        "openai": {"status": int(os.environ["VERIFY_OPENAI_CODE"]), "seconds": float(os.environ["VERIFY_OPENAI_TIME"])},
        "claude": {"status": int(os.environ["VERIFY_CLAUDE_CODE"]), "seconds": float(os.environ["VERIFY_CLAUDE_TIME"])},
        "google": {"status": int(os.environ["VERIFY_GOOGLE_CODE"]), "seconds": float(os.environ["VERIFY_GOOGLE_TIME"])},
    },
    "download": None,
    "passed": os.environ["VERIFY_FAILED"] == "0",
}
if os.environ["VERIFY_DOWNLOAD_BYTES"]:
    payload["download"] = {
        "bytes": int(float(os.environ["VERIFY_DOWNLOAD_BYTES"])),
        "seconds": float(os.environ["VERIFY_DOWNLOAD_TIME"]),
        "mbps": float(os.environ["VERIFY_DOWNLOAD_MBPS"]),
        "requires_runtime_route_evidence": True,
    }
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
PY
  chmod 600 "$json_output"
fi

if [[ "$failed" -ne 0 ]]; then
  echo 'FAIL client_acceptance' >&2
  exit 1
fi
echo 'PASS client_acceptance'
