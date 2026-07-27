#!/usr/bin/env bash
set -euo pipefail

proxy='socks5h://127.0.0.1:1082'
expected_ip=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxy)
      proxy="$2"
      shift 2
      ;;
    --expected-ip)
      expected_ip="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

curl_common=(--proxy "$proxy" --connect-timeout 10 --max-time 20 -sS)

actual_ip="$(curl "${curl_common[@]}" https://api.ipify.org)"
printf 'exit_ip %s\n' "$actual_ip"

if [[ -n "$expected_ip" && "$actual_ip" != "$expected_ip" ]]; then
  echo "FAIL expected $expected_ip but got $actual_ip" >&2
  exit 1
fi

curl "${curl_common[@]}" -o /dev/null -w 'openai %{http_code} %{time_total}s\n' https://api.openai.com/v1/models
curl "${curl_common[@]}" -o /dev/null -w 'claude %{http_code} %{time_total}s\n' https://api.anthropic.com/v1/models
curl "${curl_common[@]}" -o /dev/null -w 'google %{http_code} %{time_total}s\n' https://www.google.com/generate_204

echo 'Expected unauthenticated statuses: OpenAI 401, Claude 401, Google 204.'
