#!/usr/bin/env python3
"""Resolve the AWS region for jsign's AWS KMS storetype.

jsign's AWS keystore takes the region directly as its --keystore value; it
has no fallback resolution of its own. This script resolves the region via
the same standard chain the AWS CLI/SDK use (env vars, then shared profile
config), so sign.sh can omit --region when it's already configured in the
environment or AWS credential chain.

AWS_REGION is checked explicitly before deferring to botocore, since older
botocore releases only recognize AWS_DEFAULT_REGION in their config chain.
"""
import os
import sys


def main() -> int:
    region = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION")

    if not region:
        try:
            import botocore.session
        except ImportError:
            print(
                "error: botocore is required to resolve the AWS region "
                "(install with: pip3 install botocore)",
                file=sys.stderr,
            )
            return 1
        region = botocore.session.get_session().get_config_variable("region")

    if not region:
        print(
            "error: no AWS region found via the standard credential chain "
            "(set AWS_REGION, AWS_DEFAULT_REGION, or a profile region, or "
            "pass --region explicitly)",
            file=sys.stderr,
        )
        return 1

    print(region)
    return 0


if __name__ == "__main__":
    sys.exit(main())
