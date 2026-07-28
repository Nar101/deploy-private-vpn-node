#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: sudo run-debug-window.sh [--seconds 45] [--service x-ui] [--port 443] [--log <path>] [--redact-config <json>] -- <debug command> [args...]

Runs a temporary debug process while a systemd timer independently guarantees restoration
of the production service even if the SSH session disconnects.
EOF
  exit 2
}

seconds='45'
service='x-ui'
port='443'
log_file=''
redact_config=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --seconds) seconds="${2:-}"; shift 2 ;;
    --service) service="${2:-}"; shift 2 ;;
    --port) port="${2:-}"; shift 2 ;;
    --log) log_file="${2:-}"; shift 2 ;;
    --redact-config) redact_config="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) usage ;;
  esac
done

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run as root.' >&2; exit 1; }
[[ "$seconds" =~ ^[0-9]+$ && "$seconds" -ge 10 && "$seconds" -le 300 ]] || usage
[[ "$service" =~ ^[A-Za-z0-9@_.-]+$ ]] || usage
[[ "$port" =~ ^[0-9]+$ ]] || usage
[[ $# -gt 0 ]] || usage
[[ -z "$redact_config" || -r "$redact_config" ]] || usage
command -v systemd-run >/dev/null 2>&1 || { echo 'systemd-run is required.' >&2; exit 1; }
systemctl is-active --quiet "$service" || { echo "Production service $service is not active." >&2; exit 1; }

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
state_dir="$(mktemp -d "/run/private-proxy-debug.${stamp}.XXXXXX")"
pid_file="$state_dir/debug.pid"
restore_script="$state_dir/restore.sh"
runner_script="$state_dir/run-debug.sh"
unit="private-proxy-restore-${stamp,,}"
log_file="${log_file:-/var/log/private-proxy-debug-${stamp}.log}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
filter_script="$script_dir/redact-debug-log.py"
[[ -r "$filter_script" ]] || { echo "Missing log redactor: $filter_script" >&2; exit 1; }

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  "pid_file='$pid_file'" \
  "service='$service'" \
  'if [[ -s "$pid_file" ]]; then' \
  '  pid="$(cat "$pid_file")"' \
  '  if kill -0 "$pid" 2>/dev/null; then kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true; sleep 1; fi' \
  '  if kill -0 "$pid" 2>/dev/null; then kill -KILL -- "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true; fi' \
  'fi' \
  'systemctl start "$service"' \
  'systemctl is-active --quiet "$service"' >"$restore_script"
chmod 700 "$restore_script"
install -m 600 /dev/null "$log_file"

cat >"$runner_script" <<'SH'
#!/usr/bin/env bash
set -o pipefail
redact_config="$1"
filter_script="$2"
log_file="$3"
shift 3
"$@" 2>&1 | python3 "$filter_script" "${redact_config:--}" >>"$log_file"
SH
chmod 700 "$runner_script"

systemd-run --quiet --unit "$unit" --on-active="${seconds}s" /bin/bash "$restore_script"

restore_now() {
  /bin/bash "$restore_script" || true
}
trap restore_now EXIT INT TERM

systemctl stop "$service"
setsid "$runner_script" "$redact_config" "$filter_script" "$log_file" "$@" &
debug_pid=$!
printf '%s\n' "$debug_pid" >"$pid_file"

sleep 1
if ! kill -0 "$debug_pid" 2>/dev/null; then
  echo 'Debug process exited before the capture window opened.' >&2
  exit 1
fi

printf 'READY debug_pid=%s seconds=%s log=%s\n' "$debug_pid" "$seconds" "$log_file"
wait "$debug_pid" || true
restore_now
trap - EXIT INT TERM
systemctl stop "${unit}.timer" >/dev/null 2>&1 || true

systemctl is-active --quiet "$service" || { echo 'FAIL production_service=inactive' >&2; exit 1; }
if ! ss -lntH "sport = :$port" | grep -q .; then
  echo "FAIL production_port=${port}_not_listening" >&2
  exit 1
fi
printf 'PASS production_restored service=%s port=%s log=%s\n' "$service" "$port" "$log_file"
