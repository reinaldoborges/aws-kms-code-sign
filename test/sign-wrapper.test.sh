#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cp "$repo_root/test/fixtures/dummy.exe" "$workdir/input.exe"
printf 'bundle' > "$workdir/cert.p7b"
cat > "$workdir/fake-jsign" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$FAKE_JSIGN_LOG"
test -f "${@: -1}"
EOF
chmod +x "$workdir/fake-jsign"

FAKE_JSIGN_LOG="$workdir/fake-jsign.log" JSIGN_BIN="$workdir/fake-jsign" "$repo_root/sign.sh" \
  --alias alias/test-key \
  --region sa-east-1 \
  --certfile "$workdir/cert.p7b" \
  --tsaurl http://tsa.example.test \
  "$workdir/input.exe"

test -f "$workdir/signed/input.exe"
cmp "$workdir/input.exe" "$repo_root/test/fixtures/dummy.exe"
grep -q -- "--storetype AWS" "$workdir/fake-jsign.log"
grep -q -- "--keystore sa-east-1" "$workdir/fake-jsign.log"
grep -q -- "--alias alias/test-key" "$workdir/fake-jsign.log"
grep -q -- "--tsaurl http://tsa.example.test" "$workdir/fake-jsign.log"
