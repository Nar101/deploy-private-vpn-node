#!/usr/bin/env bash
set -euo pipefail

echo '== system =='
if command -v lsb_release >/dev/null 2>&1; then
  lsb_release -ds
else
  sed -n 's/^PRETTY_NAME=//p' /etc/os-release
fi
printf 'cpu_cores: '
nproc
free -h
df -h /

echo '== services =='
for service in ssh x-ui fail2ban unattended-upgrades ufw; do
  printf '%s: ' "$service"
  systemctl is-active "$service" 2>/dev/null || true
done

echo '== service enablement =='
for service in ssh x-ui fail2ban ufw; do
  printf '%s: ' "$service"
  systemctl is-enabled "$service" 2>/dev/null || true
done

echo '== listening ports =='
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  ss -lntup
else
  ss -lntu
fi

echo '== ufw =='
if command -v ufw >/dev/null 2>&1; then
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    ufw status verbose
  else
    echo 'Run with sudo to read UFW status.'
  fi
else
  echo 'ufw not installed'
fi

echo '== congestion control =='
sysctl net.ipv4.tcp_congestion_control 2>/dev/null || true
sysctl net.core.default_qdisc 2>/dev/null || true

echo '== ssh effective policy =='
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  sshd -T 2>/dev/null | awk '/^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|pubkeyauthentication|maxauthtries) /'
else
  echo 'Run with sudo to read effective sshd policy.'
fi

echo '== ssh auth summary, last 7 days =='
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  ssh_log=$(journalctl -u ssh --since '7 days ago' --no-pager 2>/dev/null || true)
  printf 'accepted_publickey: '
  grep -c 'Accepted publickey' <<<"$ssh_log" || true
  printf 'accepted_non_publickey: '
  grep 'Accepted ' <<<"$ssh_log" | grep -vc 'Accepted publickey' || true
  printf 'invalid_user: '
  grep -c 'Invalid user' <<<"$ssh_log" || true
  printf 'unique_success_sources: '
  awk '/Accepted / {for (i=1;i<=NF;i++) if ($i=="from") source[$(i+1)]=1} END {print length(source)}' <<<"$ssh_log"
else
  echo 'Run with sudo to read the SSH journal.'
fi

echo '== fail2ban =='
if command -v fail2ban-client >/dev/null 2>&1; then
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    fail2ban-client status 2>/dev/null || true
    fail2ban-client status sshd 2>/dev/null | sed -E 's/(Banned IP list:).*/\1 [redacted]/' || true
  else
    echo 'Run with sudo to read Fail2ban status.'
  fi
else
  echo 'fail2ban not installed'
fi

echo '== security updates =='
apt-config dump 2>/dev/null | grep -E 'Unattended-Upgrade::(Allowed-Origins|Origins-Pattern)' || true
printf 'upgradable_packages: '
apt list --upgradable 2>/dev/null | sed -n '2,$p' | wc -l | tr -d ' '
printf 'security_candidates: '
apt list --upgradable 2>/dev/null | sed -n '2,$p' | grep -c -- '-security' || true
printf 'risky_upgrade_candidates: '
apt-get -s dist-upgrade 2>/dev/null | grep '^Inst ' | grep -Eic 'linux-(image|headers|modules)|systemd|openssh|network|netplan|ufw|iptables|nftables' || true
if [[ -f /var/run/reboot-required ]]; then
  echo 'reboot_required: yes'
else
  echo 'reboot_required: no'
fi
