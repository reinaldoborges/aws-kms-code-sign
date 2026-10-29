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

## Comments

A real-world run surfaced an error jsign's AWS keystore raises when
credentials come from a shared `~/.aws/credentials` profile rather than env
vars or an EC2/ECS instance role:

```
jsign: storepass option must specify the AWS credentials: <accessKey>|<secretKey>[|<sessionToken>], when not running from ECS or an EC2 instance
```

jsign's `AWS` storetype only reads `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/
`AWS_SESSION_TOKEN` env vars, the ECS container credentials endpoint, or EC2
IMDSv2 — it does not read `~/.aws/credentials` profiles, SSO, or assumed-role
chains. This is narrower than the originally recorded "standard AWS SDK/CLI
credential chain, no custom credential handling" decision.

Fix: added `tools/resolve-aws-credentials.py`, which resolves credentials via
`botocore`'s standard credential chain (the same one the AWS CLI/SDK use —
env vars, profiles, SSO, assumed roles, instance roles) and prints them in
jsign's `accessKey|secretKey[|sessionToken]` format. `sign.sh` now calls this
resolver and passes the result to jsign via `--storepass env:JSIGN_AWS_STOREPASS`,
so credentials never appear in argv/process listings. This preserves the
user-facing goal (no manual credential wrangling) while working around
jsign's narrower built-in credential support. Covered by
`test/resolve-aws-credentials.test.sh` and an updated
`test/sign-wrapper.test.sh`.

`--region` was then made optional on the same reasoning: jsign's `AWS`
keystore takes the region as a plain `--keystore` value with no resolution
of its own, so requiring it as a mandatory flag duplicated information
already available via `AWS_REGION`/`AWS_DEFAULT_REGION` or a profile's
configured region. Added `tools/resolve-aws-region.py` (checks `AWS_REGION`
and `AWS_DEFAULT_REGION` explicitly, then falls back to botocore's config
chain for profile-configured regions) and `sign.sh` now calls it only when
`--region` is omitted. Covered by `test/resolve-aws-region.test.sh` and a
new case in `test/sign-wrapper.test.sh`.
