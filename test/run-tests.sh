#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
"$repo_root/test/assemble-p7b.test.sh"
"$repo_root/test/pe-fixture.test.sh"
"$repo_root/test/resolve-aws-credentials.test.sh"
"$repo_root/test/resolve-aws-region.test.sh"
"$repo_root/test/sign-wrapper.test.sh"
