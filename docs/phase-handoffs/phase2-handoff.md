# Phase 2 Handoff — Authentication and JWT-to-Postgres Trust Bridge

## Implemented
- **Auth.js v5** authentication on frontend: Google OAuth + Resend magic link
- **Session Strategy**: JWT (encrypted JWE by default), 30-day max age
- **Auth.js ↔ NestJS Bridge** (ADR 003): Token Exchange pattern (Option B)
  1. User signs in via Auth.js → HttpOnly session cookie (JWE)
  2. Frontend calls `POST /api/auth/exchange` with credentials
  3. Next.js validates session via `auth()` from `@auth/core`
  4. Next.js creates short-lived exchange credential (60s TTL, HS256, dedicated signing key)
  6. Next.js calls NestJS `/api/auth/exchange` with exchange token
  6. NestJS validates exchange credential (HS256, issuer/audience/expiry/jti)
  7. NestJS retrieves user from PostgreSQL, derives role from database
  8. NestJS issues API JWT (5min TTL, `basera-backend` issuer, `basera-api` audience)
  8. Frontend receives API JWT, stores in memory, uses `Authorization: Bearer` header
  9. NestJS `JwtAuthGuard` validates JWT, sets `basera.user_id`/`basera.user_role` for RLS

## Files Changed
- `env.example` — Added exchange and API JWT configuration variables
- `backend/src/auth/auth.service.ts` — Exchange credential validation, jti consumption, API JWT generation
- `backend/src/auth/auth.controller.ts` — `/auth/exchange` endpoint with origin validation
- `backend/src/auth/exchange-credential.service.ts` — Exchange credential validation service
- `backend/src/auth/auth.module.ts` — Auth module registration with ExchangeCredentialService
- `backend/src/auth/auth.controller.ts` — Exchange token handler
- `backend/src/auth/auth.module.ts` — Auth module registration
- `backend/prisma/schema.prisma` — Added ExchangeCredit model with unique jti constraint
- `backend/prisma/migrations/0009_exchange_credits.sql` — Migration for ExchangeCredit table
- `backend/src/auth/auth.service.ts` — Exchange credential validation, jti consumption, API JWT generation
- `backend/src/auth/auth.controller.ts` — Exchange token handler
- `backend/src/auth/auth.module.ts` — Auth module registration
- `frontend/src/app/api/auth/exchange/route.ts` — Next.js App Router exchange endpoint
- `frontend/src/app/providers.tsx` — AuthProvider with token exchange
- `frontend/src/app/auth/signin/page.tsx` — Sign-in page with Google OAuth and magic link
- `frontend/src/lib/auth.ts` — Auth.js configuration with Google + Resend
- `env.example` — Added exchange and API JWT configuration variables
- `docs/phase-handoffs/phase2-handoff.md` — This document
- `docs/adr/003-jwt-bridge-decision.md` — Updated with implementation details

## Verification Commands
```bash
# Backend typecheck
pnpm --filter backend run typecheck

# Frontend typecheck
pnpm --filter frontend run typecheck

# Backend lint
pnpm --filter backend run lint

# Frontend lint
pnpm --filter frontend run lint

# Backend build
pnpm --filter backend run build

# Frontend build
pnpm --filter frontend run build

# Prisma validation (requires PostgreSQL)
pnpm --filter backend run generate
pnpm --filter backend run migrate

# Unit tests (blocked by Jest module resolution)
pnpm --filter backend run test
pnpm --filter frontend run test
```

## Learning Notes
1. **Auth.js JWE vs JWS**: Auth.js v5 encrypts session tokens (JWE) by default. NestJS `jwtService.verifyAsync()` only handles JWS. Solved by server-side exchange: Next.js validates session via `@auth/core` `getSession()`, then issues short-lived exchange credential (JWS) to NestJS.

2. **Session Cookie Never Forwarded**: Auth.js HttpOnly cookie never sent to NestJS. Next.js validates session server-side, creates short-lived exchange credential (60s TTL, dedicated signing key).

3. **Replay Protection**: Atomic `jti` consumption via PostgreSQL unique constraint + `ON CONFLICT DO NOTHING`. Expired records cleaned up.

3. **CSRF Protection**: Origin header validated against `NEXTAUTH_URL`. SameSite=Lax cookies.

4. **Role Derivation**: From database only. New users = GUEST. HOST requires backend process. BOTH requires explicit rule. ADMIN never self-assigned.

5. **API JWT**: 5min TTL, `iss: basera-backend`, `aud: basera-api`, HS256.

## Verification Status
| Component | Status | Notes |
|-----------|--------|-------|
| Auth.js sign-in | ✅ Implemented | Google + Magic Link |
| Session exchange | ✅ Implemented | Next.js ↔ NestJS bridge |
| Exchange credential | ✅ Implemented | 60s TTL, HS256, dedicated key |
| API JWT | ✅ Implemented | 5min TTL, iss/aud validation |
| Replay protection | ✅ Implemented | Atomic jti consumption |
| CSRF protection | ✅ Implemented | Origin validation, SameSite=Lax |
| Role derivation | ✅ Implemented | From database only |
| RLS context | ✅ Preserved | SET LOCAL in transactions |
| Type Checking | ✅ PASS | Both frontend/backend pass |
| Linting | ✅ PASS | 4 pre-existing warnings |
| Build (Backend) | ✅ PASS | nest build succeeds |
| Build (Frontend) | ✅ PASS | next build succeeds |
| Unit Tests | ⚠️ BLOCKED | Jest module resolution issues |
| Integration Tests | ⚠️ BLOCKED | Requires PostgreSQL |
| Prisma Migration | ⚠️ PENDING | Requires PostgreSQL |
| Live OAuth/Resend | ⚠️ BLOCKED | Requires real credentials |

## Remaining Limitations
- **Prisma Migration 0009**: Created but not applied (requires PostgreSQL)
- **Unit Tests**: Blocked by Jest module resolution issues (path aliases)
- **Integration Tests**: Blocked by PostgreSQL unavailability
- **Live OAuth/Resend**: Requires real API keys (not configured)
- **Rate Limiting**: Deferred (would add @nestjs/throttler)
- **CSRF Token**: Not implemented (relies on SameSite + Origin)
- **Token Revocation**: Not implemented (short TTL mitigates risk)

## Bug Journal Updates
- BUG-2026-005: Jest module resolution for `@nestjs/testing` and path aliases — blocked
- BUG-2026-006: Jest module resolution for `PrismaService` path alias — blocked
- BUG-2026-007: Next.js build fails on `/_not-found` page using `useRouter` — fixed with `dynamic = 'force-dynamic'`

## Next Steps
Phase 3: Core Backend API (NestJS) — Listings CRUD, booking requests, role guards, OpenAPI spec, date-overlap protection via Postgres exclusion constraint.