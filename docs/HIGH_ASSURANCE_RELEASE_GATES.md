# High-assurance security release profile

**No software is hack-proof.** "Military-grade" is not a measurable software certification. This LMS targets NIST SP 800-207 zero-trust design and risk-based OWASP ASVS 5.0.0 verification.

## Must-pass release gates (fail closed)
- Dedicated production Firebase/GCP project; restrict IAM by task and service account, disable downloadable service-account keys wherever feasible, and require hardware security keys / phishing-resistant MFA for privileged human accounts through your identity provider.
- Firebase App Check with production attestations, monitoring, and enforcement for protected callable resources. Confirm legitimate clients work before turning on enforcement. App Check does not prove user identity.
- On privileged requests, check current Firebase Admin SDK account state, custom claims, token revocation and recent authentication where appropriate.
- Classify and minimize collected learner personal information. Encrypt in transit, apply provider-managed encryption at rest, and use CMEK only when operationally justified with tested key rotation/recovery.
- Place hosted code execution behind independently security-reviewed microVM/gVisor isolation with default-deny egress; do not enable lab runs until tested.
- Private GitHub branches protected by required CI, reviews, dependency/secret checks, least privilege CI permissions and signed provenance where supported.
- Require server-generated signed credentials, tested revocation, strict retention and privacy controls.
- Deploy SAST, SCA, DAST, mobile analysis and emulator permission tests; run external penetration tests before public availability.
- Establish tamper-resistant audit retention, severity-based alerting, IR exercises, backups and tested restoration, RTO/RPO targets.
- Monitor abuse budgets for AI, auth, video, storage and labs. Institute rate limits at infrastructure edge.

## Evidence and explicit gaps
The source includes selective server-authoritative auth, read/write rules, CI scans, and revocation checks. It does **not** enforce Firebase App Check, provide confirmed privileged-user MFA, provision sandbox/cloud IAM, configure an external WAF, establish incident-response operations or prove ASVS compliance.

Security documentation: https://www.nist.gov/publications/zero-trust-architecture
ASVS: https://asvs.owasp.org/
