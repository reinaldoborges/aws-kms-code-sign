#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
fixture="$workdir/dummy.exe"

python3 "$repo_root/test/create-dummy-exe.py" "$fixture"
python3 - "$fixture" <<'PY'
from pathlib import Path
import struct
import sys

data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b"MZ"
assert data[struct.unpack_from("<I", data, 0x3C)[0]:][:4] == b"PE\0\0"
assert len(data) == 0x400
PY
