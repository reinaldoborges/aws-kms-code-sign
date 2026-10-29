#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: assemble-p7b.sh --output FILE [--der] CERT [CERT ...]

Assemble a certs-only PKCS#7 bundle in leaf-to-root order.
CERT files may be PEM or DER encoded X.509 certificates.
EOF
}

output=""
der=0
certs=()

while (($#)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -o|--output)
      (($# >= 2)) || { echo "error: --output requires a path" >&2; exit 2; }
      output=$2
      shift 2
      ;;
    --der)
      der=1
      shift
      ;;
    --)
      shift
      certs+=("$@")
      break
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      certs+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$output" || ${#certs[@]} -eq 0 ]]; then
  echo "error: --output and at least one certificate are required" >&2
  usage >&2
  exit 2
fi

for cert in "${certs[@]}"; do
  [[ -f "$cert" ]] || { echo "error: certificate not found: $cert" >&2; exit 1; }
done

output_dir="$(dirname -- "$output")"
mkdir -p "$output_dir"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

normalized=()
for index in "${!certs[@]}"; do
  normalized_file="$workdir/cert-$index.pem"
  if openssl x509 -in "${certs[$index]}" -out "$normalized_file" 2>/dev/null; then
    :
  elif openssl x509 -inform DER -in "${certs[$index]}" -out "$normalized_file" 2>/dev/null; then
    :
  else
    echo "error: invalid X.509 certificate: ${certs[$index]}" >&2
    exit 1
  fi
  normalized+=("$normalized_file")
done

command=(openssl crl2pkcs7 -nocrl)
for cert in "${normalized[@]}"; do
  command+=(-certfile "$cert")
done
if ((der)); then
  command+=(-outform DER)
fi
command+=(-out "$output")
"${command[@]}"
