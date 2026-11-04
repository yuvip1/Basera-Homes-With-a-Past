# Phase 1 Handoff — Database Design and Row-Level Security

## Implemented
- **Database schema**: 8 tables (users, properties, bookings, reviews, review_tags, amenities, property_photos, user_sessions) with UUID primary keys, foreign keys, indexes, and CHECK constraints.
- **Roles**: `app_user` (superuser, bootstrap only), `basera_owner` (NOLOGIN, table owner), `basera_migrator` (member of basera_owner, runs migrations), `basera_app` (runtime role, least privilege).
- **RLS policies** on all 8 tables with `FORCE ROW LEVEL SECURITY`. Direction-specific review privacy: host-to-guest reviews private to author; guest-to-property reviews public when published; authors can read own unpublished reviews.
- **Column-level privileges** on `reviews`: `basera_app` has SELECT, INSERT, DELETE, and UPDATE only on content columns (title, body, rating, updated_at). Immutable columns (reviewer_id, target_id, direction, booking_id, is_published) cannot be modified.
- **Constraints**: `reviews.rating` CHECK (1-5), `bookings.check_out > check_in`, all foreign keys with cascading deletes.
- **Identity**: `current_user_id()` helper handles missing/empty `basera.user_id` safely (fails closed).
- **Identity setting**: `SET LOCAL basera.user_id = '<verified-uuid>'` transaction-locally after JWT verification (Phase 2).

## Files Changed
- `env.example` — DATABASE_URL uses `basera_app`
- `apps/api/prisma/schema.prisma` — corrected UUID types, added CHECK constraints
- `apps/api/prisma/migrations/0000_bootstrap.sql` through `0007_constraints.sql`
- `apps/api/prisma/migrations/0004_test_fixtures.sql` — test data
- `apps/api/prisma/migrations/0005_security_tests.sql` — 11 security tests
- `apps/api/prisma/migrations/0006_fix_identity.sql` — safe identity helper + corrected RLS
- `apps/api/prisma/migrations/0007_constraints.sql` — rating and booking date constraints
- `apps/api/prisma/migrations/0008_constraint_tests.sql` — constraint tests
- `docs/adr/0002-rls-policy-structure.md` — ADR 002
- `docs/bug-log.md` — 4 bugs documented
- `docs/bugs/BUG-2026-001` through `BUG-2026-004` — individual bug records
- `apps/api/tsconfig.json`, `eslint.config.js`, `jest.config.js` — tool configs
- `apps/web/tsconfig.json`, `eslint.config.js` — tool configs
- `package.json`, `apps/api/package.json`, `apps/web/package.json` — scripts and dev deps
- `apps/api/tsconfig.json`, `eslint.config.js`, `jest.config.js` — API configs
- `apps/web/tsconfig.json`, `eslint.config.js` — Web configs

## Verification Commands
```bash
# Security tests (all 11 pass)
cat apps/api/prisma/migrations/0005_security_tests.sql | docker exec -i basera-postgres psql -U basera_app -d basera -v ON_ERROR_STOP=0

# Constraint tests (all 6 pass)
cat apps/api/prisma/migrations/0008_constraint_tests.sql | docker exec -i basera-postgres psql -U basera_app -d basera -v ON_ERROR_STOP=0

# Verify RLS policies
docker exec basera-postgres psql -U app_user -d basera -c "\dp reviews"

# Verify column-level grants
docker exec basera-postgres psql -U app_user -d basera -c "\dp reviews"

# Verify constraints
docker exec basera-postgres psql -U app_user -d basera -c "\d reviews"
docker exec basera-postgres psql -U app_user -d basera -c "\d bookings"

# Verify roles
docker exec basera-postgres psql -U app_user -d basera -c "\du"

# Verify current_user_id() function
docker exec basera-postgres psql -U basera_app -d basera -c "SELECT current_user_id();"
```

## Learning Notes
1. **RLS does not authenticate** — it only scopes access based on session variable. Application must verify JWT before `SET LOCAL basera.user_id`.
2. **Column-level privileges require removing table-level UPDATE** — `REVOKE` on columns is ineffective if table-level UPDATE exists.
3. **`current_setting('...', true)` returns empty string** — must wrap with `NULLIF(..., '')` before `::uuid` cast.
4. **`CREATE POLICY IF NOT EXISTS` not supported in PostgreSQL 16** — use DO blocks with catalog checks.
5. **`basera_owner` NOLOGIN cannot create objects directly** — migrations run as `basera_migrator` (member of `basera_owner`) and transfer ownership.

## Bug Journal Updates
- BUG-2026-003: RLS identity missing/empty string handling — fixed with `current_user_id()` helper
- BUG-2026-004: Table-level UPDATE bypasses column-level REVOKE — fixed by removing table-level UPDATE grant

## Remaining Limitations
- `basera_dba` role not created (deferred to Phase 10)
- Admin authorization via API, not RLS (Phase 2/10)
- Prisma schema has `@@check` but raw SQL constraints are authoritative
- No application code yet (Phase 2+)
- CI scripts exist but need `pnpm install` first
- `basera_app` password not set in `.env` (use `.env` locally)
- No application code yet (Phase 2+)

## Next Steps
Phase 2: Authentication and JWT-to-Postgres trust bridge (Auth.js v5 + Passport JWT)