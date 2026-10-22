# Zero-trust verification plan

Baseline: NIST SP 800-207 and OWASP ASVS 5.0.0. This is an engineering control matrix, **not** a certification or claim of full ASVS compliance.

| Protected resource | Authentication | Fresh authorization | Additional boundary | Verification |
|---|---|---|---|---|
| Administrator users and certificates | Firebase ID token | Current user, role, revocation, recent sign-in | Server-only writes and audit trail | Firebase emulator tests and manual abuse tests |
| Live classroom tokens | Firebase ID token | Current Firebase role and revocation state | Enrolled learner, time window, limited grants | Token issuance and permission tests |
| Learner progress | Firebase Auth | Authenticated subject UID | Idempotent server-owned writes | Cross-user tampering tests |
| Certificates | Firebase Auth | Staff approval and verified learning evidence | Server HMAC/revocation | Tampering, replay, revoked credential tests |
| Lab jobs | Firebase Auth | Learner identity, published lab | Per-day quotas; no server execution of learner code | Quota race and isolation tests |
| AI tutor | Firebase Auth | Published, approved materials | Daily budget cap; secret server-side | Prompt injection and budget tests |

## Required cloud configuration
1. Enable Firebase App Check for web and mobile and gradually enforce on callable functions after client rollout. Configure appropriate attestation providers.
2. Require MFA for staff at the Identity Provider level and enforce reauthentication for sensitive administration. Recent login is **not** a substitute for MFA.
3. Apply branch protection, required CI statuses, CODEOWNERS reviews, environment approval and minimal GitHub Actions permissions.
4. Separate staging and production. Run workloads under individual least-privilege identities and prefer workload federation to long-lived credentials.
5. Enable structured security logs, alerts for privilege changes and account revocations, certificate revocations, unusual lab submission rates, and key rotation.
6. Test tenant isolation, disabled accounts, revoked tokens, forged custom claims and privilege escalation against Firebase emulators.
7. Commission an independent assessment including OWASP ASVS 5.0.0 Level 2-oriented requirements and risk-appropriate additional requirements; track evidence by requirement.
8. Add a controlled security-incident response, backup restoration exercise, data retention policy and Kenyan learner-data privacy review.

No current code-only change can guarantee resistance to every attack, secure a misconfigured cloud account, or validate an undeployed sandbox.
