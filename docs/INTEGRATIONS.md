# Integration guide — free learning, paid infrastructure only to the operator

## Live classrooms
Use an institution-hosted LiveKit or Jitsi deployment with short-lived per-session participant tokens issued by a callable backend. Require enrollment or staff membership before granting a token. Do not expose meeting administrative credentials or allow users to nominate arbitrary room IDs. Obtain explicit recording consent and offer audio-only participation.

## WebXR and 3D
Curate HTTPS-based WebXR scenes that provide a 2D fallback. Host optimized glTF 2.0/GLB resources and alternatives (text, captions, reduced-motion modes). WebXR support varies by device and browser; test with actual hardware. Embedding a production Unity/Cesium/Three.js scene is separate work.

## LMS standards
Host H5P interactive content in a properly licensed instance. SCORM and xAPI require a tracking/learning record store service, a consistent learner identifier and content security policy. Do not collect extra learner telemetry without disclosure and consent.

## Offline learning
The current local queue delivers idempotent read events and can retry after disconnection. Course video, assessment attempts, conflict resolution and cross-device sync are not complete. Do not use unencrypted SharedPreferences for personally identifiable information.

## Admin analytics
Current server counts are aggregates. Add event schema, scheduled aggregation, retention periods, cohort filters and suppression of small groups to reduce re-identification risks.

## Certificates
PDF issuance requires both trusted completion and staff approval; current assessment flows do not set verifiedComplete. An external verification web page and complete revocation controls are not provided yet.

## Logos
Original institution-supplied binary logos are in the provided asset bundle, not yet in GitHub. The Flutter `assets/images` directory needs exact image files copied in. Brand permissions still apply.
