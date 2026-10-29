Type: task
Blocked by: 02, 03

## Question

Run the `sign.sh` wrapper (ticket 03) against the dummy test `.exe` (ticket 02) using one of the real KMS signing keys in account 741780802448 (e.g. `alias/codesign2026`, region `sa-east-1`) and its matching `.p7b` bundle, then verify the resulting signature on Linux (e.g. via `jsign`'s own verification or `osslsigncode verify`, per the map's Destination — Windows `signtool` verification is out of scope).

Resolve by: confirming the signed file lands in `signed/`, the original dummy `.exe` is untouched, the signature verifies successfully (valid chain, RFC3161 timestamp present and pointing at the configured TSA), and recording the exact commands used plus verification output in the resolution.
