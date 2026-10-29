#!/usr/bin/env python3
"""Resolve AWS credentials for jsign's AWS KMS storetype.

jsign's AWS keystore only reads credentials from the AWS_ACCESS_KEY_ID /
AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN environment variables, the ECS
container credentials endpoint, or EC2 IMDSv2 -- it does not read
~/.aws/credentials profiles, SSO, or assumed-role chains. This script
resolves credentials via the same standard chain the AWS CLI/SDK use
(botocore) and prints them in the "accessKey|secretKey[|sessionToken]"
format jsign expects for --storepass.
"""
import sys


def main() -> int:
    try:
        import botocore.session
    except ImportError:
        print(
            "error: botocore is required to resolve AWS credentials "
            "(install with: pip3 install botocore)",
            file=sys.stderr,
        )
        return 1

    session = botocore.session.get_session()
    credentials = session.get_credentials()
    if credentials is None:
        print(
            "error: no AWS credentials found via the standard credential chain",
            file=sys.stderr,
        )
        return 1

    frozen = credentials.get_frozen_credentials()
    parts = [frozen.access_key, frozen.secret_key]
    if frozen.token:
        parts.append(frozen.token)
    print("|".join(parts))
    return 0


if __name__ == "__main__":
    sys.exit(main())
