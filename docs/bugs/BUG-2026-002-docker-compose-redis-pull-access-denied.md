# BUG-2026-002: Docker Compose Redis image pull access denied

- **Status:** Verified
- **Severity / priority:** Medium / P2
- **Phase / feature:** Phase 0 infrastructure
- **Environment and version/commit:** Docker Desktop 29.8.2, Docker Compose 5.5.1
- **First observed:** 2026-10-29 13:32 UTC
- **Fixed / verified:** 2026-10-30 00:54 IST

## Expected behavior
`docker compose up -d` pulls the Redis image and starts the Redis container healthy.

## Actual behavior
Redis container failed to start. Pull access denied for `upstash/redis:latest`.

## Reproduction steps
1. `cd C:\Users\yuvra\Desktop\BASERA_`
2. `docker compose up -d`
3. `docker compose ps --all` — Redis shows `Error response from daemon: pull access denied for upstash/redis`

## Evidence
- Error output:
  ```
  Image upstash/redis:latest Error pull access denied for upstash/redis, repository does not exist or may require 'docker login'
  ```
- `docker pull upstash/redis:latest` reproduced the same error.
- `docker pull redis:7-alpine` succeeded.

## Root-cause analysis
- Confirmed facts: The `upstash/redis:latest` image is hosted on Upstash's private registry and requires `docker login` credentials to pull. It is designed for Upstash's managed cloud service, not for local Docker development.
- Root cause status: Confirmed

## Fix
Changed `docker-compose.yml` Redis image from `upstash/redis:latest` to `redis:7-alpine` (official Redis image). This is the smallest correction — the official image is available on Docker Hub and works for local development.

## Files changed
- `docker-compose.yml` (Redis image swap)

## Regression coverage
- Re-ran `docker compose up -d` after fix; Redis container shows `Up N seconds (healthy)`.
- Verified with `docker exec basera-redis redis-cli ping` → PONG.

## Verification
- Commands run:
  - `docker compose config` — valid
  - `docker compose up -d` — both services started
  - `docker compose ps` — both healthy
  - `docker exec basera-redis redis-cli ping` — PONG
- Unit tests: N/A
- Integration/E2E tests: N/A
- Live service/database verification: Redis container, local only

## Regression and security review
- No credentials or secrets exposed.
- No application code, migrations, or schemas created.

## Prevention / lessons learned
- Prefer official images (`postgres:16-alpine`, `redis:7-alpine`) for local development over managed-service images that require registry authentication.
- Verify image availability with `docker pull` before `docker compose up`.

## Related bugs / ADRs / commits
- BUG-2026-001 — Docker Compose PostgreSQL startup failure
- ADR 0001 — Monorepo vs single app