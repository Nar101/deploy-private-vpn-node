#!/usr/bin/env python3
import json
import re
import sys


def usage():
    print("Usage: redact-debug-log.py <effective-config.json|->", file=sys.stderr)
    raise SystemExit(2)


if len(sys.argv) != 2:
    usage()

config_path = sys.argv[1]
secrets = set()


def walk(value, key=""):
    if isinstance(value, dict):
        for child_key, child_value in value.items():
            walk(child_value, str(child_key))
    elif isinstance(value, list):
        for child in value:
            walk(child, key)
    elif isinstance(value, str) and any(
        marker in key.lower() for marker in ("id", "key", "password", "token")
    ):
        if len(value) >= 2:
            secrets.add(value)


if config_path != "-":
    with open(config_path, encoding="utf-8") as fh:
        walk(json.load(fh))

uuid_re = re.compile(
    r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}"
)
label_re = re.compile(
    r"(?i)((?:short.?id|private.?key|public.?key|password|uuid|token)[^:=\n]{0,24}[:=]\s*)(\S+)"
)

for line in sys.stdin:
    line = uuid_re.sub("[UUID_REDACTED]", line)
    line = label_re.sub(r"\1[REDACTED]", line)
    for secret in sorted(secrets, key=len, reverse=True):
        line = line.replace(secret, "[REDACTED]")
    sys.stdout.write(line)
