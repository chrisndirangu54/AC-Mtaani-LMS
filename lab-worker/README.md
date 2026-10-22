# Isolated lab worker — deployment reference

This folder supplies **worker orchestration and a container image example**, not a deployed secure multi-tenant execution service.

The worker service must be deployed in a dedicated cloud project with workload identity, **no public ingress**, private queue access, read-only filesystem, unprivileged UID, disabled egress, limits (CPU, RAM, PIDs, time, output), disposable per-job instances and no mounted credentials. Do not mount Docker socket. Do not use privileged containers. For untrusted learner submissions prefer an isolation boundary stronger than ordinary shared-container execution (e.g., gVisor/Kata or microVMs) and validate it with penetration testing.

The included image deliberately contains **no handler that executes user source**. Connect it only after deploying and reviewing the sandbox executor and policy enforcement. Do not deploy this container as a production code runner.

## Required lifecycle
1. Claim queued Firestore job atomically using a unique worker lease.
2. Verify curriculum, language, size, daily quota, ownership and expiry.
3. Launch a disposable isolated sandbox with pinned image digest and no external network.
4. Limit time and captured stdout/stderr; redact secrets.
5. Mark completed/failed and clear learner source after retention expiry.
6. Record auditable worker image, exit code, latency and policy version.
