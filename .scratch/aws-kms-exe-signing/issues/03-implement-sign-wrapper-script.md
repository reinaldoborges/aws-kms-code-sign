Type: task
Status: resolved
Blocked by: 01

## Question

Implement a thin shell script wrapper (e.g. `sign.sh`) in this repo that signs a Windows `.exe` using jsign with an AWS KMS-backed key.

Per the map's Destination and Notes, the script must:
- Accept as parameters: the KMS key alias/ARN (jsign `--alias`), the path to the local `.p7b` cert+chain bundle (jsign `--certfile`, passed through unconverted), the input `.exe` path, and optionally a TSA URL override (defaulting to GlobalSign's `http://timestamp.globalsign.com/tsa/r45standard`).
- Derive the AWS region from the key alias/ARN or accept it as a parameter (jsign's `--keystore` option takes the AWS region for the `AWS` storetype) — decide the simplest parameter shape during implementation.
- Rely entirely on the standard AWS credential chain (env vars, profiles, SSO, IMDS) — no custom credential flags.
- Write the signed output to a `signed/` directory (created if missing) alongside/relative to the input, never overwriting the original input file.
- Surface jsign/AWS SDK errors (e.g. missing `kms:Sign` permission) as-is rather than masking them.

Resolve by: writing the script, documenting its usage in a `--help`/usage message, and confirming it runs end-to-end against a real KMS key up to the point of invoking jsign (full sign+verify happens in the next ticket). Record the final CLI interface (flags/arguments) in the resolution.

## Answer

Implemented `sign.sh` with this interface:

```sh
./sign.sh --alias ALIAS --region REGION --certfile BUNDLE \
  [--tsaurl URL] INPUT.exe
```

It copies the input to a sibling `signed/` directory, then invokes jsign with
`--storetype AWS`, the explicit region, the KMS alias/ARN, the unchanged
`.p7b` path, and the RFC3161 GlobalSign URL (overrideable with `--tsaurl`).
The original is never overwritten and jsign/AWS failures are not masked.

The local boundary test confirms the complete argument forwarding and output
path. A real KMS invocation was not run because no matching certificate bundle
is present on this machine; ticket 04 remains the end-to-end validation point.
