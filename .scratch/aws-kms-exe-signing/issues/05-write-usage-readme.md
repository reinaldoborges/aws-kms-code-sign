Type: task
Status: resolved
Blocked by: 03

## Question

Write usage documentation (e.g. in this repo's `README.md`) for the `sign.sh` wrapper: prerequisites (jsign installed, AWS credentials configured with `kms:Sign`/`kms:DescribeKey`/`kms:GetPublicKey` on the target key), the exact CLI invocation with all parameters explained (key alias/ARN, `.p7b` path, input file, optional TSA URL override), and where signed output lands.

Resolve by: writing the docs using the script's finalized interface from ticket 03, and noting the effort's scope boundaries (manual execution only, `.exe` only, Linux-side verification only) per the map's Out of scope section.

## Answer

Added `README.md` covering prerequisites, AWS permissions, certificate bundle
assembly, the finalized signing command, output placement, TSA override, and
the manual/Linux-side/.exe-only scope boundaries.
