#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# With no region available anywhere in the chain, the resolver must fail
# clearly rather than let jsign fail with a confusing keystore error.
output="$(env -i PATH="$PATH" HOME="$(mktemp -d)" \
  python3 "$repo_root/tools/resolve-aws-region.py" 2>&1)" && status=0 || status=$?
[[ "$status" -ne 0 ]]
grep -qi "no aws region" <<<"$output"

# AWS_REGION is checked explicitly, since this installation's botocore
# predates AWS_REGION support in the standard config chain.
output="$(env -i PATH="$PATH" HOME="$(mktemp -d)" \
  AWS_REGION=us-west-2 \
  python3 "$repo_root/tools/resolve-aws-region.py")"
[[ "$output" == "us-west-2" ]]

# AWS_DEFAULT_REGION is the long-standing standard env var fallback.
output="$(env -i PATH="$PATH" HOME="$(mktemp -d)" \
  AWS_DEFAULT_REGION=eu-west-1 \
  python3 "$repo_root/tools/resolve-aws-region.py")"
[[ "$output" == "eu-west-1" ]]

# A region configured in a shared profile (~/.aws/config) must resolve too,
# matching the standard AWS SDK/CLI credential chain.
fake_home="$(mktemp -d)"
mkdir -p "$fake_home/.aws"
cat > "$fake_home/.aws/config" <<'EOF'
[default]
region = ap-southeast-2
EOF
output="$(env -i PATH="$PATH" HOME="$fake_home" \
  python3 "$repo_root/tools/resolve-aws-region.py")"
[[ "$output" == "ap-southeast-2" ]]
