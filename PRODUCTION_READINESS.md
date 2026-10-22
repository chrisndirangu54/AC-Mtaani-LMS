# Production Architecture and Release Gates

This project is **a prototype with backend foundations, not a production-certified SOTA LMS**. Learner courses remain free. Infrastructure and LLM usage may incur organizational costs.

## Secure laboratories
- A Firebase callable queues jobs in `labJobs`; it does not execute arbitrary learner code.
- Deploy a **separate isolated execution service** running disposable, non-root containers/microVMs, pinned read-only images, dropped Linux capabilities, network egress denied by default, CPU/memory/pid limits, wall-clock timeout, output limits, and no cloud metadata or host mounts.
- Worker must authenticate with workload identity and apply job status transitions atomically. Add queue-based throttling, per-learner quotas, run cancellation, abuse detection and audit logging. Never execute submissions in Firebase Functions.
- Enforce approved language templates; design SQL labs against disposable seeded datasets, never shared production databases.

## Offline
- `offline_learning.dart` caches selected lesson text; `offline_sync_queue.dart` persists idempotent read events.
- Hook enqueue/flush to lesson interaction and connectivity/app resume; define per-field merge policy for assignments and quiz attempts before adding bidirectional sync. Media caching requires copyright/DRM, quota and storage-expiry controls.
- `shared_preferences` is not encrypted storage. Do **not** cache grades, sensitive learner profiles or restricted instructor data there.

## Live classrooms
- Sessions link to explicitly allowed external conferencing hosts. An actual embedded conferencing stack and recording controls are **not implemented**.
- Recommended: deploy Jitsi Meet or LiveKit with server-issued room tokens, expiry, authenticated attendance and consent-based recording. Avoid storing meeting secrets in learner-visible Firestore documents.

## VR/AR
- Approved external HTTPS links can open WebXR resources. No native scene renderer or prepared 3D simulations are present.
- Model pipeline: GLB/glTF assets, compression, mobile performance profiling, motion-sickness safeguards, screen-reader-friendly 2D alternatives and proper asset attribution.

## Certificates
- Callable returns a generated PDF after enrollment has both trusted completion flag and staff approval. No frontend counter grants eligibility.
- The trusted `verifiedComplete` flag is not yet created by a complete assessment evaluation pipeline. Until implemented and tested, issuance correctly remains unavailable.
- Configure `CERTIFICATE_SIGNING_KEY`, evaluate HMAC record verification and revocation lifecycle, and approve credential design and institutional identity claims before launch.

## Analytics and operations
- Course analytics counts enrollment records, not engagement or active learning. Add privacy-preserving event capture, aggregation, retention, consent and cohort filters.
- Admin role assignment uses Firebase custom claims and audits changes. First super-admin must be provisioned via a separately authorized bootstrap procedure.
- Add IAM review, structured audit query UI, recovery processes, moderation appeals, deletion workflows, and incident monitoring.

## Visual identity and animation
- Install all four institution-provided images under `assets/images/` as referenced in project manifest once authorized. They have not been uploaded as binary assets to GitHub by this integration.
- Packages for Lottie and SVG are declared; actual licensed animations and graphical screens are not yet built. Review asset-specific licenses before use.

## Verification gates
1. Ensure `flutter analyze`, `flutter test` and `node --check` pass in CI.
2. Use Firebase emulator suite to validate learner/instructor/admin and cross-tenant access restrictions.
3. Red-team lab queue quotas, race conditions, role escalation and course completion.
4. End-to-end test credential PDF from a staff-verified result and verify revocation.
5. Test offline replay/recovery after device restart, failed network and duplicate operations.
6. Accessibility assessment (WCAG 2.2 AA), feature phones and low-bandwidth connections.
7. Implement privacy notice, safeguarding policy, data retention and authorized U.S. Embassy/KNLS branding.

This document identifies the services still needed before the LMS can safely be called production-ready.
