# AWS KMS Windows executable signing

This repository provides manual Linux-side tooling for signing Windows `.exe`
files with an RSA key in AWS KMS using [jsign](https://ebourg.github.io/jsign/).
It does not automate CI/CD and does not replace Windows `signtool` verification.

## Prerequisites

- Java 21 or newer.
- `bin/jsign` (the repository includes jsign 7.6 and its launcher).
- OpenSSL 3 or newer for assembling certificate bundles.
- AWS credentials available through the standard AWS SDK credential chain.
- The identity needs `kms:Sign`, `kms:DescribeKey`, and `kms:GetPublicKey` for
  the target KMS key.
- A PKCS#7 (`.p7b`) bundle containing the leaf code-signing certificate and
  intermediate CA certificates.

## Assemble a certificate bundle

Pass certificates in leaf-to-root order:

```sh
./assemble-p7b.sh --output code-signing.p7b leaf.pem intermediate-ca.pem
```

PEM and DER X.509 inputs are accepted. Add `--der` to write a DER-encoded
PKCS#7 bundle instead of the default PEM-encoded bundle.

## Sign an executable

```sh
./sign.sh \
  --alias alias/codesign2026 \
  --region sa-east-1 \
  --certfile code-signing.p7b \
  path/to/application.exe
```

The source file is never overwritten. The signed copy is written to
`path/to/signed/application.exe`. RFC3161 timestamping uses GlobalSign's
`http://timestamp.globalsign.com/tsa/r45standard` by default; override it with
`--tsaurl URL`.

The `--alias` value may be an AWS KMS alias or ARN. `--region` is always
explicit because jsign's AWS keystore uses it as the `--keystore` value.
Errors from jsign and the AWS SDK are returned unchanged.

## Test fixture

`test/create-dummy-exe.py` creates the minimal PE32+ fixture at
`test/fixtures/dummy.exe`; it is not a production executable.

Run the local tests with:

```sh
./test/run-tests.sh
```
