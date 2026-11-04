# BUG-2026-001: Docker Compose PostgreSQL startup failure — POSTGRES_PASSWORD not set

- **Status:** Verified
- **Severity / priority:** Medium / P2
- **Phase / feature:** Phase 0 infrastructure
- **Environment and version/commit:** Docker Desktop 29.8.2, Docker Compose 5.5.1, postgres:16-alpine
- **First observed:** 2026-10-29 13:32 UTC
- **Fixed / verified:** 2026-10-30 00:54 IST

## Expected behavior
`docker compose up -d` starts both PostgreSQL and Redis containers healthy and reachable.

## Actual behavior
PostgreSQL container exited with code 1 immediately after starting. Redis started healthy.

## Reproduction steps
1. `cd C:\Users\yuvra\Desktop\BASERA_`
2. `docker compose up -d`
3. `docker compose ps --all` — PostgreSQL shows `Exited (1)`

## Evidence
- Error output from `docker compose logs postgres`:
  ```
  Error: Database is uninitialized and superuser password is not specified.
  You must specify POSTGRES_PASSWORD to a non-empty value for the superuser.
  ```
- `docker compose config` output showed `POSTGRES_PASSWORD: ""` — the variable was referenced but never set.

## Root-cause analysis
- Confirmed facts: `docker-compose.yml` references `${POSTGRES_PASSWORD}` in the `environment:` block, but no `.env` file existed at the project root to supply the value. Docker Compose defaulted it to an empty string, which the official `postgres` image rejects on first start.
- Root cause status: Confirmed

## Fix
1. Created `.env` at project root with `POSTGRES_PASSWORD=basera-local-dev` and `REDIS_URL=redis://localhost:6379`.
2. Created `.gitignore` with `.env` (and other local artifacts) so the secret file is never committed.

## Files changed
- `.env` (new, local-only)
- `.gitignore` (new)
- `docker-compose.yml` (Redis image swap — see BUG-2026-002)

## Regression coverage
- Re-ran `docker compose up -d` after fix; both containers show `Up N seconds (healthy)`.
- Verified with `docker exec basera-postgres psql -U app_user -d basera -c "SELECT version();"` → PostgreSQL 16.15.
- Verified with `docker exec basera-redis redis-cli ping` → PONG.

## Verification
- Commands run:
  - `docker compose config` — valid
  - `docker compose up -d` — both services started
  - `docker compose ps` — both healthy
  - `docker exec basera-postgres psql -U app_user -d basera -c "SELECT version();"` — PostgreSQL 16.15
  - `docker exec basera-redis redis-cli ping` — PONG
- Unit tests: N/A
- Integration/E2E tests: N/A
- Live service/database verification: PostgreSQL and Redis containers, local only

## Regression and security review
- `.env` contains only local development secrets; `.gitignore` excludes it from source control.
- No production credentials used.
- No application code, migrations, or schemas created.

## Prevention / lessons learned
- Add a `.env` file alongside `env.example` for local development, and ensure `.gitignore` excludes it.
- Verify `docker compose config` output for empty environment-variable defaults before `docker compose up`.

## Related bugs / ADRs / commits
- BUG-2026-002 — Redis image pull access denied
- ADR 0001 — Monorepo vs single app