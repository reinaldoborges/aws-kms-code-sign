#!/usr/bin/env bash
set -euo pipefail

default_tsa="http://timestamp.globalsign.com/tsa/r45standard"

usage() {
  cat <<'EOF'
Usage: sign.sh --alias ALIAS [--region REGION] --certfile BUNDLE [--tsaurl URL] INPUT.exe

Copy INPUT.exe into a sibling signed/ directory and sign the copy with jsign
using AWS KMS and the supplied PKCS#7 certificate chain.

--region may be omitted if it's resolvable from the standard AWS credential
chain (AWS_REGION, AWS_DEFAULT_REGION, or a profile's configured region).
EOF
}

alias_name=""
region=""
certfile=""
tsaurl="$default_tsa"
input=""

while (($#)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --alias)
      (($# >= 2)) || { echo "error: --alias requires a value" >&2; exit 2; }
      alias_name=$2
      shift 2
      ;;
    --region)
      (($# >= 2)) || { echo "error: --region requires a value" >&2; exit 2; }
      region=$2
      shift 2
      ;;
    -c|--certfile)
      (($# >= 2)) || { echo "error: --certfile requires a path" >&2; exit 2; }
      certfile=$2
      shift 2
      ;;
    -t|--tsaurl)
      (($# >= 2)) || { echo "error: --tsaurl requires a URL" >&2; exit 2; }
      tsaurl=$2
      shift 2
      ;;
    --)
      shift
      (($# == 1)) || { echo "error: exactly one input file is required" >&2; exit 2; }
      input=$1
      shift
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      [[ -z "$input" ]] || { echo "error: exactly one input file is required" >&2; exit 2; }
      input=$1
      shift
      ;;
  esac
done

if [[ -z "$alias_name" || -z "$certfile" || -z "$input" ]]; then
  echo "error: --alias, --certfile, and INPUT.exe are required" >&2
  usage >&2
  exit 2
fi
[[ -f "$input" ]] || { echo "error: input file not found: $input" >&2; exit 1; }
[[ "$input" == *.exe ]] || { echo "error: input must be a .exe file: $input" >&2; exit 1; }
[[ -f "$certfile" ]] || { echo "error: certificate bundle not found: $certfile" >&2; exit 1; }

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
jsign_bin="${JSIGN_BIN:-$script_dir/bin/jsign}"
[[ -x "$jsign_bin" ]] || { echo "error: jsign is not executable: $jsign_bin" >&2; exit 1; }
credentials_resolver="${AWS_CREDENTIALS_RESOLVER:-$script_dir/tools/resolve-aws-credentials.py}"
[[ -x "$credentials_resolver" ]] || { echo "error: credentials resolver not found or not executable: $credentials_resolver" >&2; exit 1; }
region_resolver="${AWS_REGION_RESOLVER:-$script_dir/tools/resolve-aws-region.py}"
[[ -x "$region_resolver" ]] || { echo "error: region resolver not found or not executable: $region_resolver" >&2; exit 1; }

if [[ -z "$region" ]]; then
  # jsign's AWS keystore takes the region as a plain --keystore value with
  # no resolution of its own. Resolve it the same way the standard AWS
  # credential chain would, so --region can be omitted when already
  # configured via env vars or a profile.
  region="$("$region_resolver")" || exit 1
fi

# jsign's AWS keystore only reads credentials from AWS_* env vars, the ECS
# endpoint, or EC2 IMDSv2 -- not from ~/.aws/credentials profiles or SSO.
# Resolve via the standard AWS credential chain here and hand jsign the
# result through an env var (via --storepass env:NAME) so it never appears
# in argv or process listings.
JSIGN_AWS_STOREPASS="$("$credentials_resolver")" || exit 1
export JSIGN_AWS_STOREPASS

input_dir="$(cd -- "$(dirname -- "$input")" && pwd)"
input_name="$(basename -- "$input")"
output_dir="$input_dir/signed"
output="$output_dir/$input_name"
mkdir -p "$output_dir"
cp --preserve=mode,timestamps "$input" "$output"

"$jsign_bin" \
  --storetype AWS \
  --keystore "$region" \
  --storepass env:JSIGN_AWS_STOREPASS \
  --alias "$alias_name" \
  --certfile "$certfile" \
  --tsaurl "$tsaurl" \
  "$output"
