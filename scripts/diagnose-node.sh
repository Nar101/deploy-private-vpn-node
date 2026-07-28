#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: diagnose-node.sh \
  --server-received none|tcp|clienthello \
  --reality unknown|failed|passed \
  --vless unknown|failed|passed \
  --exit unknown|wrong|expected \
  --effective-config yes|no \
  --contaminated yes|no \
  --restored yes|no
EOF
  exit 2
}

server_received=''
reality=''
vless=''
exit_state=''
effective_config=''
contaminated=''
restored=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-received) server_received="${2:-}"; shift 2 ;;
    --reality) reality="${2:-}"; shift 2 ;;
    --vless) vless="${2:-}"; shift 2 ;;
    --exit) exit_state="${2:-}"; shift 2 ;;
    --effective-config) effective_config="${2:-}"; shift 2 ;;
    --contaminated) contaminated="${2:-}"; shift 2 ;;
    --restored) restored="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ "$server_received" =~ ^(none|tcp|clienthello)$ ]] || usage
[[ "$reality" =~ ^(unknown|failed|passed)$ ]] || usage
[[ "$vless" =~ ^(unknown|failed|passed)$ ]] || usage
[[ "$exit_state" =~ ^(unknown|wrong|expected)$ ]] || usage
[[ "$effective_config" =~ ^(yes|no)$ ]] || usage
[[ "$contaminated" =~ ^(yes|no)$ ]] || usage
[[ "$restored" =~ ^(yes|no)$ ]] || usage

if [[ "$contaminated" == 'yes' ]]; then
  echo 'INVALID test_evidence=contaminated'
  echo 'NEXT restore formal port, service, route, node object, and rule state; then repeat one synchronized test'
  exit 1
fi

if [[ "$restored" == 'no' ]]; then
  echo 'STOP formal_state=not_restored'
  echo 'NEXT restore and verify the production service before any new hypothesis'
  exit 1
fi

if [[ "$server_received" == 'none' ]]; then
  if [[ "$reality" != 'unknown' || "$vless" != 'unknown' ]]; then
    echo 'INVALID contradiction=protocol_result_without_server_connection'
    exit 1
  fi
  echo 'BRANCH pre_server_path'
  echo 'NEXT verify instance/IP, cloud firewall, TUN exclusion route, saved node object, and tunnel runtime snapshot'
  exit 0
fi

if [[ "$effective_config" == 'no' ]]; then
  echo 'BRANCH effective_config_unknown'
  echo 'NEXT read the Xray configuration actually loaded by the running process before changing parameters'
  exit 0
fi

if [[ "$reality" == 'failed' ]]; then
  echo 'BRANCH reality_authentication'
  echo 'NEXT compare credential hashes, SNI, short ID, time, ClientVer boundaries, and fallback evidence'
  exit 0
fi

if [[ "$reality" == 'unknown' ]]; then
  echo 'BRANCH reality_observability'
  echo 'NEXT run one synchronized, watchdog-protected Reality debug window'
  exit 0
fi

if [[ "$vless" == 'failed' ]]; then
  echo 'BRANCH vless_xtls'
  echo 'NEXT compare UUID hash, Vision flow, TCP, and client serialization; do not change Reality target'
  exit 0
fi

if [[ "$vless" == 'unknown' ]]; then
  echo 'BRANCH vless_observability'
  echo 'NEXT collect the native client and server log for the same connection'
  exit 0
fi

case "$exit_state" in
  wrong)
    echo 'BRANCH routing_policy'
    echo 'NEXT inspect rule order, selected configuration, proxy-group delegation, and runtime route log'
    ;;
  unknown)
    echo 'BRANCH business_acceptance'
    echo 'NEXT verify expected exit IP and target HTTP statuses through the native client'
    ;;
  expected)
    echo 'PASS node_path=protocol_and_exit_verified'
    ;;
esac
