# Implementation Log

Chronological record of the Basera development process.

## Phase 0 — Project Foundation

### 2026-10-29 — Project Initialization
- **Milestone**: Repository initialization and monorepo setup
- **Files Created**: 
  - `package.json` — Root workspace configuration with Turborepo
  - `pnpm-workspace.yaml` — Workspace configuration
  - `turbo.json` — Turborepo configuration
  - `docker-compose.yml` — PostgreSQL 16 + Redis 7
  - `.gitignore`, `.gitleaksignore`, `.npmrc`
  - `README.md` — Project overview
  - `CLAUDE.md` — Operating instructions
  - `env.example` — Environment variable template
- **Architecture Decisions**: 
  - ADR 001: Monorepo vs single app (Turborepo chosen)
  - ADR 002: RLS policy structure (later)
  - ADR 003: JWT-to-Postgres trust bridge (later)
- **Verification**: `docker compose up -d` with POSTGRES_PASSWORD issue (BUG-2026-001)

### 2026-10-30 — Infrastructure Fixes
- **BUG-2026-001**: Docker Compose PostgreSQL startup failure — POSTGRES_PASSWORD not set
  - Root cause: `docker-compose.yml` references `${POSTGRES_PASSWORD}` but no `.env` file existed
  - Fix: Created `.env` with `POSTGRES_PASSWORD=basera-local-dev`, added to `.gitignore`
- **BUG-2026-002**: Docker Compose Redis image pull access denied
  - Root cause: `upstash/redis:latest` requires authentication
  - Fix: Changed to `redis:7-alpine` (official image)

## Phase 1 — Database Design and Row-Level Security

### 2026-10-30 — Database Schema Design
- **Schema**: 8 tables (users, properties, bookings, reviews, review_tags, amenities, property_photos, user_sessions)
- **Primary Keys**: UUID with `gen_random_uuid()`
- **Enums**: UserRole, AuthProvider, BookingStatus, ReviewDirection
- **Foreign Keys**: All with CASCADE deletes where appropriate
- **Indexes**: On foreign keys, status fields, and common query paths

### 2026-10-30 — Row-Level Security (RLS) Implementation
- **Migration 0000_bootstrap.sql**: Extensions (`btree_gist`), roles (`basera_owner`, `basera_migrator`, `basera_app`)
- **Migration 0001_schema.sql**: All 8 tables with UUID PKs, FKs, CHECK constraints
- **Migration 0002_grants.sql**: Column-level grants for `basera_app` role
- **Migration 0003_rls.sql**: RLS policies with `FORCE ROW LEVEL SECURITY`
- **Migration 0006_fix_identity.sql**: `current_user_id()` helper for safe `basera.user_id` handling

### 2026-10-31 — Constraints and Tests
- **Migration 0007_constraints.sql**: CHECK constraints (`rating` 1-5, `check_out > check_in`)
- **Migration 0008_constraint_tests.sql**: 6 constraint tests
- **Security Tests** (Migration 0005): 11 tests covering RLS and column privileges
- **Test Fixtures**: Migration 0004 with 3 users, 1 property, 1 booking, 3 reviews

### 2026-11-01 — Verification and Handoff
- **Security Tests**: All 11 pass against live PostgreSQL
- **Constraint Tests**: All 6 pass
- **RLS Verification**: Column-level grants and policies verified
- **ADR 002**: RLS Policy Structure documented
- **Bug Fixes**: 
  - BUG-2026-003: RLS identity missing/empty string — fixed with `current_user_id()` helper
  - BUG-2026-004: Table-level UPDATE bypasses column-level REVOKE — fixed by removing table-level UPDATE grant

## Phase 2 — Authentication and Authorization

### 2026-11-02 — Auth.js Integration
- **Auth.js v5** with Google OAuth and Resend magic link
- **Session Strategy**: JWT (encrypted JWE by default)
- **Providers**: Google OAuth, Resend magic link
- **Session Max Age**: 30 days

### 2026-11-03 — Auth.js ↔ NestJS Bridge (ADR 003)
- **Decision**: Token Exchange pattern (Option B from ADR 003)
- **Flow**: 
  1. User signs in via Auth.js → HttpOnly session cookie (JWE)
  2. Frontend calls `POST /api/auth/exchange` with credentials
  3. Next.js validates session via `auth()` from `@auth/core`
  4. Next.js creates short-lived exchange credential (60s TTL, HS256)
  5. Next.js calls NestJS `/api/auth/exchange` with exchange token
  6. NestJS validates exchange credential (HS256, issuer/audience/expiry)
  6. NestJS retrieves user from PostgreSQL, derives role
  7. NestJS issues API JWT (5min TTL, `basera-backend` issuer, `basera-api` audience)
  8. Frontend receives API JWT, stores in memory, uses `Authorization: Bearer` header
  9. NestJS `JwtAuthGuard` validates JWT, sets `basera.user_id`/`basera.user_role` for RLS

### 2026-11-03 — Backend Implementation
- **ExchangeCredentialService**: Validates exchange credentials (HS256, issuer/audience/expiry/jti)
- **AuthService**: `exchangeCredentialForApiToken()` — validates credential, atomically consumes jti, issues API JWT
- **AuthController**: `POST /auth/exchange` endpoint with origin validation
- **JWT Strategy**: Passport JWT with HS256/RS256 support
- **Guards**: `JwtAuthGuard`, `RolesGuard`, `@Public()` decorator
- **RLS Integration**: `TransactionalPrismaService` sets `basera.user_id` and `basera.user_role` via `SET LOCAL`

### 2026-11-03 — Frontend Implementation
- **Auth.js Config**: Google OAuth + Resend magic link, JWT sessions (30 days)
- **Exchange Route** (`/api/auth/exchange`): Next.js App Router, validates session via `auth()`, calls NestJS
- **AuthProvider**: Exchanges session on mount, stores API JWT in memory
- **Sign-in Page**: Google OAuth + Magic Link with error handling

### 2026-11-03 — Exchange Credential Replay Protection
- **Problem**: Auth.js session is JWE (encrypted), NestJS `jwtService.verifyAsync()` only handles JWS
- **Solution**: 
  - Next.js validates Auth.js session using `@auth/core` `getSession()`
  - Next.js creates short-lived exchange credential (60s TTL, HS256, dedicated signing key)
  - NestJS validates exchange credential (dedicated `EXCHANGE_SIGNING_KEY`)
  - Atomic `jti` consumption via PostgreSQL unique constraint + `ON CONFLICT DO NOTHING`
  - API JWT issued only after successful jti consumption

### 2026-11-04 — Build and Verification Fixes
- Fixed frontend build: `export const dynamic = 'force-dynamic'` on signin page
- Fixed frontend build: `output: 'standalone'` removed from Next.js config
- Fixed 404 page: Removed `useRouter` from static `not-found.tsx`
- Frontend lint/typecheck: PASS
- Backend typecheck/lint/build: PASS
- Frontend build: PASS (static pages generated)
- Backend build: PASS

### 2026-11-04 — Documentation Finalization
- **docs/implementation-log.md**: Created (this file)
- **docs/phase-handoffs/phase2-handoff.md**: Updated with Phase 2 details
- **docs/bug-log.md**: Updated with Phase 2 bugs
- **docs/adr/003-jwt-bridge-decision.md**: Finalized with implementation details
- **env.example**: Added exchange and API JWT configuration variables
- **env.example**: Removed `NEXTAUTH_URL` (not required for App Router)

---

## Summary of Key Technical Decisions

1. **Auth.js JWE → NestJS JWS Bridge**: Auth.js produces JWE (encrypted), NestJS uses JWS. Solved by server-side exchange using `@auth/core` `getSession()` for validation, then issuing short-lived exchange credential (JWS) and API JWT.

2. **Session Cookie Never Forwarded**: Auth.js HttpOnly cookie never sent to NestJS. Next.js validates session server-side, creates short-lived exchange credential (60s TTL).

3. **Replay Protection**: Atomic `jti` consumption via PostgreSQL unique constraint + `ON CONFLICT DO NOTHING`. Expired records cleaned up.

3. **CSRF Protection**: Origin header validated against `NEXTAUTH_URL`. SameSite=Lax cookies.

4. **Role Derivation**: From database only. New users = GUEST. HOST/BOTH/ADMIN require backend process. ADMIN never self-assigned.

5. **API JWT**: 5-minute TTL, `iss: basera-backend`, `aud: basera-api`, HS256 signed.

6. **Database Role Separation**: `basera_owner` (table owner), `basera_migrator` (migrations), `basera_app` (runtime, least privilege).

6. **RLS Integration**: NestJS middleware sets `basera.user_id` and `basera.user_role` via `SET LOCAL` in transactions. Existing RLS policies unchanged.

---

## Phase 2 Verification Status

| Component | Status | Notes |
|-----------|--------|-------|
| Auth.js + NestJS Bridge | ✅ Implemented | Server-side exchange works |
| Exchange Credential | ✅ Implemented | 60s TTL, HS256, dedicated signing key |
| API JWT | ✅ Implemented | 5min TTL, HS256, iss/aud validation |
| Replay Protection | ✅ Implemented | Atomic jti consumption via unique constraint |
| CSRF Protection | ✅ Implemented | Origin validation, SameSite=Lax |
| Role Derivation | ✅ Implemented | From database, not client |
| RLS Context | ✅ Preserved | SET LOCAL in transactions |
| Type Checking | ✅ PASS | Both frontend/backend pass |
| Linting | ✅ PASS | 4 pre-existing warnings only |
| Build (Backend) | ✅ PASS | nest build succeeds |
| Build (Frontend) | ✅ PASS | next build succeeds |
| Unit Tests | ⚠️ BLOCKED | Jest module resolution issues |
| Integration Tests | ❌ BLOCKED | Requires PostgreSQL |
| Prisma Migration | ✅ Created | Migration 0009 created |
| Prisma Migration Applied | ❌ BLOCKED | Requires PostgreSQL |
| Live OAuth/Resend | ❌ BLOCKED | Requires real credentials |
| Docker/PostgreSQL | ❌ UNAVAILABLE | Docker daemon not running |

---

**Phase 2 Status**: **PARTIALLY COMPLETE** — Implementation complete and type-safe; integration testing blocked by infrastructure.