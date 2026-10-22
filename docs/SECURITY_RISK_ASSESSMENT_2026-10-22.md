# Risk-based security assessment — 2026-10-22
Scope: public source code of AC-Mtaani-LMS; Firebase configuration, cloud IAM, deployed infrastructure, operational records, and mobile devices were **not** independently assessed. This is not an OWASP ASVS certification.

## Methodology
Assets: student accounts and learning records, minors' data where applicable, certificate validity, instructor course content, staff identities, lab runner, model provider credentials, meeting tokens, audit history.
Qualitative ratings combine likelihood and impact (Critical / High / Moderate / Low), not quantified exploit probabilities. Reference framework: OWASP ASVS 5.0.0 security verification domains and NIST SP 800-207 resource-focused policy decisions. Precise ASVS requirement IDs must be checked against the canonical versioned checklist before claiming compliance.

| ID | Threat scenario | Rating | Evidence/current control | Required mitigation | Gate |
|---|---|---|---|---|---|
| R-01 | Stale instructor token used to finalize credentials after role removal | Critical | Completion callable relied on request JWT role; corrected in commit be0ebb6 by requireCurrentRole | Emulator test of demoted and revoked accounts across every staff callable | Block release |
| R-02 | Browser accesses another learner's protected data via insufficient rules | Critical | Firestore mostly deny-client-write; course lessons publicly readable when published | Cross-role automated rule tests and review sensitive lesson metadata, quiz answers, PII | Block release |
| R-03 | Student code escapes runner to obtain credentials / host access | Critical | Queue exists; worker deliberately not executing user code | Independently isolated gVisor/microVM runner, no egress, narrow service account, resource limits, pentest | Block lab execution |
| R-04 | Compromised admin account changes staff roles or disables accounts | Critical | Fresh role checks, recent login and audit events partially present | Enforced staff MFA/phishing-resistant authentication, break-glass procedure, approval for high-impact role grants | Block release |
| R-05 | Fraudulent or replayed certificates | High | Server-side completion flags, signed PDF record and revocation check | Atomic issuance, immutable evidence, rotation versioning, QR verification, lifecycle tests | Block certificates |
| R-06 | AI tutor exfiltrates sensitive context, incurs cost, follows adversarial instructions | High | Limited to approved lessons and budget per user/day | App Check, tighter input scanning, retrieval provenance, abuse throttles, prompt-injection evaluations | Block public AI |
| R-07 | Credential or secret leaked via git/CI | High | GitHub basic secret scan and npm audit workflow | Historical secret scan, automatic alerts, restrict GitHub Actions permissions and rotate secrets | Block release |
| R-08 | Live classroom link/token hijack | High | Limited time token and enrollment check | LiveKit server configured, room moderation, MFA for hosts, consent for recording, revoke rooms after access changes | Block embedded classes |
| R-09 | Offline cache exposes restricted learner details on a shared device | High | Lessons in SharedPreferences; no sensitive grades intended | Encrypt restricted data, per-user cache segregation, secure logout cleanup, device threat-model testing | Block sensitive offline data |
| R-10 | Admin analytics reveal learner identity or small cohorts | Moderate | Aggregate enrollment counts and event summaries | Suppress small cohorts, retention controls, consent and analytics access logging | Before analytics release |
| R-11 | Website susceptible to script injection through instructor content/H5P embeds | High | Flutter text widgets; external links use HTTPS | CSP, allowlisted content origins, sanitization for rich HTML, H5P iframe sandbox policy, DAST | Block rich embeds |
| R-12 | Availability loss from bot abuse | High | AI/lab daily quotas | Firebase App Check enforcement, edge rate limits, quotas, alerts, cost caps, load test | Block public launch |

## Zero-trust design decisions
- **Policy decision point:** authoritative Firebase Identity account state, current custom claims, certificate/role/resource ownership and session revocation. No automatic trust based on network location.
- **Policy enforcement:** callable API authorization on each sensitive request plus Firestore deny-by-default rules; service-account IAM must additionally limit backend capabilities.
- **Telemetry:** access denials, privilege changes, audit events, risky lab submissions and certificate issuance, with restricted retention.
- **Continuous evaluation:** scan dependencies and code every commit; review access quarterly and promptly on staff separation.

## Validation tasks and acceptance criteria
1. Anonymous/learner/instructor/admin/disabled/revoked account permission tests using Firebase Emulator Suite; no unauthorized read/write or role elevation.
2. Confirm no callable trusts a stale role claim after demotion or token revocation.
3. Test concurrent certificates, XP, lab quotas and bookings for duplicate issuance or bypass.
4. Run independent isolation tests of production lab worker, including no network egress and no access to metadata/secret stores.
5. Require pass of CI SAST/SCA/secret scanning, tested cloud backup recovery, incident notification drills, and third-party penetration test before marketing as high assurance.

## Assessment limitations
This document is a preliminary code-informed risk register, not a comprehensive code audit, external network scan, deployment assessment, ASVS verification certificate or proof of being hack-proof.

Authoritative references:
- OWASP ASVS: https://asvs.owasp.org/
- NIST SP 800-207: https://csrc.nist.gov/pubs/sp/800/207/final
