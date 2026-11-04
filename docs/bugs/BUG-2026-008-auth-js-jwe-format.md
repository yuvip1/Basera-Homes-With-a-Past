# BUG-2026-008: Auth.js session token format is JWE, not JWS

- **Status:** Not a bug — expected behavior
- **Severity / priority:** Informational / P3
- **Phase / feature:** Phase 2 — Auth.js ↔ NestJS bridge
- **Environment and version/commit:** Auth.js v5 (5.0.0-beta.32), @auth/core 0.25.1, NestJS 10.4.0
- **First observed:** 2026-11-03
- **Fixed / verified:** 2026-11-03 — understood and resolved via server-side exchange

## Expected behavior
The Auth.js session token can be directly verified by NestJS `jwtService.verifyAsync()`.

## Actual behavior
Auth.js v5 with `session: { strategy: 'jwt' }` produces an **encrypted JWT (JWE)** using A256CBC-HS512 algorithm, not a signed JWT (JWS). NestJS `jwtService.verifyAsync()` only handles JWS (signed JWTs), not JWE (encrypted JWTs).

## Evidence
- `@auth/core/jwt.d.ts` documentation: "The JWT issued by Auth.js is _encrypted by default_, using the _A256CBC-HS512_ algorithm"
- NextAuth v5 with `session: { strategy: 'jwt' }` stores session in JWE format
- `jwtService.verifyAsync()` from `@nestjs/jwt` uses `jsonwebtoken` library which only handles JWS

## Root-cause analysis
- **Confirmed facts**: 
  - Auth.js v5 encrypts session tokens (JWE) by default when using JWT strategy
  - NestJS `jwtService.verifyAsync()` only validates signed JWTs (JWS), cannot decrypt JWE
  - The Auth.js session cookie (`nextauth.session-token`) contains a JWE, not a JWS

- **Root cause**: Architecture mismatch — Auth.js session token format is JWE (encrypted), but NestJS JWT verification expects JWS (signed).

## Resolution
Implemented **server-side exchange pattern** (ADR 003 Option B):
1. Frontend sends Auth.js session cookie to Next.js `/api/auth/exchange`
1. Next.js validates session using `@auth/core` `getSession()` (handles JWE decryption)
1. Next.js creates short-lived exchange credential (JWS, 60s TTL, dedicated signing key)
1. Next.js calls NestJS `/auth/exchange` with exchange credential
1. NestJS validates exchange credential (JWS, HS256, dedicated signing key)
1. NestJS issues API JWT (5min TTL, separate signing key)
1. Frontend uses API JWT for subsequent requests

## Files changed
- `frontend/src/app/api/auth/exchange/route.ts` — Next.js exchange endpoint
- `backend/src/auth/exchange-credential.service.ts` — Exchange credential validation
- `backend/src/auth/auth.service.ts` — Exchange credential validation and API JWT generation
- `backend/src/auth/auth.controller.ts` — `/auth/exchange` endpoint
- `frontend/src/lib/auth.ts` — Auth.js configuration
- `frontend/src/app/providers.tsx` — AuthProvider with token exchange

## Verification
- Commands run: `pnpm --filter backend run typecheck`, `pnpm --filter frontend run typecheck`
- Type checking: PASS
- Linting: PASS
- Build (Backend): PASS
- Build (Frontend): PASS
- Integration tests: Requires PostgreSQL

## Related bugs / ADRs / commits
- ADR 003: JWT-to-Postgres trust bridge decision
- ADR 002: RLS policy structure
- Phase 2 implementation