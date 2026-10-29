#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -subj "/CN=Intermediate Test CA" \
  -keyout "$workdir/intermediate.key" \
  -out "$workdir/intermediate.pem" >/dev/null 2>&1
openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -subj "/CN=Leaf Test Certificate" \
  -keyout "$workdir/leaf.key" \
  -out "$workdir/leaf.pem" >/dev/null 2>&1

"$repo_root/assemble-p7b.sh" \
  --output "$workdir/bundle.p7b" \
  "$workdir/leaf.pem" "$workdir/intermediate.pem"

test -s "$workdir/bundle.p7b"
openssl pkcs7 -print_certs -inform PEM -in "$workdir/bundle.p7b" |
  grep -q '^subject=CN = Leaf Test Certificate'
openssl pkcs7 -print_certs -inform PEM -in "$workdir/bundle.p7b" |
  grep -q '^subject=CN = Intermediate Test CA'
