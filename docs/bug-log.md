# Bug Journal Index

| ID | Title | Phase | Severity | Status | Root Cause Confirmed? | Regression Test | Verification |
|---|---|---|---|---|---|---|---|
| BUG-2026-001 | Docker Compose PostgreSQL startup failure — POSTGRES_PASSWORD not set | Phase 0 | Medium | Verified | Yes | `docker compose up -d` + `docker compose ps` | Live containers |
| BUG-2026-002 | Docker Compose Redis image pull access denied | Phase 0 | Medium | Verified | Yes | `docker compose up -d` + `docker compose ps` | Live containers |
| BUG-2026-003 | RLS identity missing/empty string handling | Phase 1 | High | Verified | Yes | `psql -U basera_app -d basera -c "SELECT count(*) FROM reviews"` | Live containers |
| BUG-2026-004 | Table-level UPDATE grant bypasses column-level REVOKE | Phase 1 | High | Verified | Yes | `psql -U basera_app -d basera -c "UPDATE reviews SET reviewer_id = '...'"` | Live containers |

*Every meaningful defect requires a source-backed record. See roadmap §3C for the required format.*