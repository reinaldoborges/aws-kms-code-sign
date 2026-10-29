Type: task
Status: resolved
Blocked by: none

## Question

Implement a script (e.g. `assemble-p7b.sh`) in this repo that assembles a PKCS#7 (`.p7b`) certificate bundle — suitable as input to the `sign.sh` wrapper's `--certfile`/`-c` parameter (ticket 03) — from a list of individual X.509 certificate files (the leaf code-signing certificate plus its intermediate CA certificates), each stored as a separate local file (PEM or DER).

Facts already gathered:
- `openssl` 3.0.2 is already installed on this machine.
- The standard way to build a PKCS#7 "certs-only" bundle from a set of X.509 certs is `openssl crl2pkcs7 -nocrl -certfile leaf.pem -certfile intermediate1.pem -certfile intermediate2.pem ... -out bundle.p7b` (repeat `-certfile` per cert, in leaf-to-root order), or equivalently concatenate the certs into one PEM file first and pass it once via `-certfile`.
- jsign (and `osslsigncode`) accept the resulting `.p7b` in either PEM or DER form, so the script should decide and document which encoding it outputs (PEM is more debuggable/diffable; DER is more universally recognized as ".p7b").

Resolve by: deciding the script's CLI interface (e.g. a list of cert file paths as positional args, or a directory of certs, plus an output path and an optional `--der`/`--pem` flag), implementing it, and verifying its output is a valid PKCS#7 bundle (e.g. via `openssl pkcs7 -print_certs -in bundle.p7b` listing all input certs in order). Record the final CLI interface and the exact `openssl` invocation(s) used in the resolution.

## Answer

Implemented `assemble-p7b.sh`:

```sh
./assemble-p7b.sh --output bundle.p7b [--der] leaf.pem intermediate.pem ...
```

It accepts PEM or DER X.509 files in leaf-to-root order, normalizes them with
`openssl x509`, and assembles a certs-only bundle with
`openssl crl2pkcs7 -nocrl -certfile ... -out ...`. The default output is PEM;
`--der` selects DER. The assembler test verifies the resulting certificate
order with `openssl pkcs7 -print_certs`.
