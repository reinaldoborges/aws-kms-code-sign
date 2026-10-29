#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# With no credentials available anywhere in the chain, the resolver must fail
# clearly rather than let jsign print a confusing downstream error.
output="$(env -i PATH="$PATH" HOME="$(mktemp -d)" \
  python3 "$repo_root/tools/resolve-aws-credentials.py" 2>&1)" && status=0 || status=$?
[[ "$status" -ne 0 ]]
grep -qi "no aws credentials" <<<"$output"

# With explicit env var credentials (part of the standard credential chain),
# the resolver must emit the exact accessKey|secretKey|sessionToken format
# jsign's AWS storetype expects for --storepass.
output="$(env -i PATH="$PATH" HOME="$(mktemp -d)" \
  AWS_ACCESS_KEY_ID=AKIAEXAMPLE \
  AWS_SECRET_ACCESS_KEY=secretexample \
  AWS_SESSION_TOKEN=tokenexample \
  python3 "$repo_root/tools/resolve-aws-credentials.py")"
[[ "$output" == "AKIAEXAMPLE|secretexample|tokenexample" ]]

# Without a session token, the resolver must omit the trailing segment rather
# than emit a dangling pipe.
output="$(env -i PATH="$PATH" HOME="$(mktemp -d)" \
  AWS_ACCESS_KEY_ID=AKIAEXAMPLE \
  AWS_SECRET_ACCESS_KEY=secretexample \
  python3 "$repo_root/tools/resolve-aws-credentials.py")"
[[ "$output" == "AKIAEXAMPLE|secretexample" ]]
