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

cat > "$workdir/fake-credentials-resolver" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "FAKEACCESSKEY|FAKESECRETKEY|FAKESESSIONTOKEN"
EOF
chmod +x "$workdir/fake-credentials-resolver"

FAKE_JSIGN_LOG="$workdir/fake-jsign.log" \
JSIGN_BIN="$workdir/fake-jsign" \
AWS_CREDENTIALS_RESOLVER="$workdir/fake-credentials-resolver" \
  "$repo_root/sign.sh" \
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
grep -qE -- "--storepass env:[A-Za-z_][A-Za-z0-9_]*" "$workdir/fake-jsign.log"

storepass_var="$(grep -oE -- '--storepass env:[A-Za-z_][A-Za-z0-9_]*' "$workdir/fake-jsign.log" | cut -d: -f2)"
[[ "$(printenv "$storepass_var" 2>/dev/null || true)" == "" ]] || {
  echo "error: credential env var leaked to parent shell" >&2
  exit 1
}

# When --region is omitted, sign.sh must resolve it via the standard AWS
# credential chain instead of requiring it as a mandatory flag.
cat > "$workdir/fake-region-resolver" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "eu-west-1"
EOF
chmod +x "$workdir/fake-region-resolver"

FAKE_JSIGN_LOG="$workdir/fake-jsign-noregion.log" \
JSIGN_BIN="$workdir/fake-jsign" \
AWS_CREDENTIALS_RESOLVER="$workdir/fake-credentials-resolver" \
AWS_REGION_RESOLVER="$workdir/fake-region-resolver" \
  "$repo_root/sign.sh" \
  --alias alias/test-key \
  --certfile "$workdir/cert.p7b" \
  --tsaurl http://tsa.example.test \
  "$workdir/input.exe"

grep -q -- "--keystore eu-west-1" "$workdir/fake-jsign-noregion.log"
