# Security baseline — American Corner Mtaani LMS

This document describes implemented protections and remaining release blockers. Passing source checks **does not establish compliance, penetration-test coverage, or production-grade security**.

## Implemented in source
- All Firestore writes and sensitive resources deny direct client access unless specifically allowed; Firebase Cloud Functions enforce user identity and custom-claim roles.
- Only administrators may assign or revoke roles. Sensitive actions emit audit events.
- Server-owned XP, enrollments, certificate issuance and lab job status cannot be directly rewritten by learners.
- Certificate verification now recomputes the HMAC and uses a constant-time proof comparison; revoked records fail validation.
- Live classroom tokens are time-window restricted, enrollment checked, and room-admin privileges limited to administrators.
- Client analytics can no longer forge course completion, quiz submission or verified lesson completion counts.
- Lab submissions are capped by learner/day and restricted to queued, non-executable jobs until an isolated worker is deployed.
- CI includes backend high-severity dependency auditing and best-effort credential pattern scanning.

## Critical requirements before public launch
1. **Firebase App Check:** enable Play Integrity (Android), App Attest/DeviceCheck (iOS), reCAPTCHA Enterprise (web); configure debug providers only in development. After testing all clients, enforce App Check on appropriate callable endpoints. App Check is not yet enabled and cannot replace authentication.
2. **MFA and administrator provisioning:** require MFA (prefer phishing-resistant passkeys/security keys where supported by identity stack) for admins and instructors. Provision bootstrap admin out of band and review custom claims periodically.
3. **Session revocation:** explicitly revoke refresh tokens when disabling or demoting accounts, terminate active classroom sessions and enforce token expiration.
4. **Least-privilege IAM:** separate staging/production projects, narrow service identities, deny long-lived keys, use managed secrets and rotate them. Isolated worker must never have broad Firebase Admin permissions.
5. **Untrusted code sandbox:** require microVM/gVisor/Kata isolation, outbound network deny, immutable image digests, seccomp, caps drop, CPU/RAM/disk/time limits, no host or metadata access, output sanitization and red-team testing. Current lab worker is intentionally non-executable.
6. **Data protection:** Kenya Data Protection Act compliance review, safeguarding for younger learners, retention schedules, encryption/key lifecycle, user export/deletion, breach response and international-transfer assessment.
7. **Abuse resistance:** App Check, IP/risk rate limiting at edge, throttled sign-in, quotas for AI and file uploads, AV/malware scanning for content, signed URLs and MIME validation.
8. **Course and AI safety:** approval workflow and prompt-injection evaluations. Never use user-supplied lesson text as privileged instructions; do not expose assessment answer keys.
9. **Observability:** security event monitoring, anomalous privilege alerts, suspicious lab activity, tamper-resistant audit retention, backups and restore drills.
10. **Release evidence:** Firebase emulator authorization tests, end-to-end mobile/web tests, SAST/DAST, dependency inventory/SBOM, attack simulation and independent penetration test.

## CI
- `Flutter and Functions checks` handles analyzer/tests and Node syntax.
- `Security gates` runs a dependency audit and credential-pattern scan. Pattern scanning is incomplete and should be supplemented by Gitleaks/TruffleHog configured with historical scanning and alerting.
- Review failures before merge; require branch protection and status checks in GitHub repository settings.

Never put provider secrets in Flutter, Firestore client-readable documents, or this repository.
