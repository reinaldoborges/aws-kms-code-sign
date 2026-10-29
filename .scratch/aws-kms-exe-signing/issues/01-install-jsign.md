Type: task
Blocked by: none

## Question

Install `jsign` on this Linux machine so it's usable for Authenticode signing with an AWS KMS backend.

Facts already gathered:
- OpenJDK 21 is already installed (`/usr/bin/java`), so only the jsign distribution itself is needed, not a JVM.
- jsign publishes an all-in-one jar and DEB/RPM packages (see https://ebourg.github.io/jsign/ and https://github.com/ebourg/jsign releases).
- Ubuntu's `apt` does not carry a jsign package (only checked for `osslsigncode`); installation will need the upstream jar/deb release directly.

Resolve by: picking an install method (standalone jar vs. `.deb` package), installing it, and confirming `jsign --version` (or equivalent jar invocation) runs successfully. Record the chosen method, the installed version, and the exact invocation command (e.g. `jsign ...` vs `java -jar jsign-x.y.z.jar ...`) in the resolution.
