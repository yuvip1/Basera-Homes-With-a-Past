# ADR 003: JWT-to-Postgres Trust Bridge Decision

## Context
Basera requires a secure bridge between the authentication layer (Auth.js v5 on frontend, Passport JWT on NestJS backend) and PostgreSQL Row-Level Security (RLS) policies. The RLS policies rely on session variables `basera.user_id` and `basera.user_role` set via `SET LOCAL` within a transaction.

Two architectural options exist for bridging Auth.js authentication to the PostgreSQL trust boundary:

## Options

### Option A: Auth.js JWT Override (Issue Signed JWTs)
- Override Auth.js `encode`/`decode` callbacks to issue signed JWTs (HS256/RS256) directly from NextAuth
- Backend verifies these JWTs with the same secret/key
- Backend sets `basera.user_id` and `basera.user_role` from verified JWT claims

**Pros:**
- Single JWT format throughout
- Auth.js handles token generation/refresh
- Simpler token flow

**Cons:**
- NextAuth v5 encrypts session tokens (JWE) by default; overriding requires deep customization
- JWE decryption keys must be shared with backend
- Custom encode/decode can break Auth.js internal assumptions
- Signing secret must be shared between frontend and backend

### Option B: Token Exchange (Short-Lived API Token)
- Auth.js issues standard encrypted session token (JWE) as designed
- Backend exposes `/api/auth/exchange` endpoint
- Frontend exchanges session cookie for short-lived signed API token (JWS)
- Backend verifies exchange token, issues signed API JWT (short TTL, e.g., 5 min)
- API JWT used for subsequent authenticated requests

**Pros:**
- Uses Auth.js as designed (no override hacks)
- Short-lived API tokens limit exposure
- Backend controls token format, claims, TTL, rotation
- Clear separation: Auth.js for session, backend for API auth
- Backend controls key rotation, revocation, audience/issuer validation

**Cons:**
- Extra network round-trip for token exchange
- Additional endpoint to secure and monitor
- Token exchange adds latency to first authenticated request

## Decision
**Choose Option B: Token Exchange (Short-Lived API Token)**

### Rationale
1. **Security**: Auth.js v5 encrypts session tokens by design. Fighting JWE encryption is fragile and version-dependent.
2. **Separation of concerns**: Auth.js manages user sessions; backend manages API authorization.
3. **Operational flexibility**: Backend controls API token TTL, rotation, revocation, audience/issuer validation independently.
3. **Security posture**: Short-lived API tokens (5 min TTL) limit blast radius of token theft.
4. **Operational clarity**: Clear separation between session management (Auth.js) and API authorization (backend).
5. **Future-proof**: Works with Auth.js updates; no override maintenance burden.

## Token Specification

### Exchange Endpoint
- `POST /api/auth/exchange`
- Input: HttpOnly session cookie (set by NextAuth)
- Output: `{ access_token: string, expires_in: number, token_type: "Bearer" }`
- Rate limited, CSRF protected

### API Access Token (JWS)
- Algorithm: RS256 (asymmetric) or HS256 (symmetric, if key rotation managed)
- Claims: `sub` (user UUID), `role` (GUEST/HOST/BOTH/ADMIN), `iat`, `exp` (5 min), `iss` (backend), `aud` (basera-api)
- Signed with backend private key (RS256) or shared secret (HS256 with rotation)
- Stored only in memory on frontend (never localStorage/cookies)

### Token Exchange Flow
1. User signs in via Auth.js (Google OAuth / magic link) → HttpOnly session cookie set
2. Frontend calls `POST /api/auth/exchange` with credentials (cookie sent automatically)
4. Backend validates session cookie via NextAuth `getServerSession`, extracts user UUID + role
5. Backend issues short-lived signed API token (5 min TTL)
6. Frontend stores API token in memory (React context/state), includes in `Authorization: Bearer <token>` header
6. API token used for all subsequent authenticated requests
7. On 401/expired, frontend re-exchanges automatically

### Key Management
- **Signing**: RS256 with RSA key pair (recommended) or HS256 with rotation
- **Private key**: Stored in backend env (`JWT_PRIVATE_KEY`), never in frontend
- **Public key**: Exposed via `GET /.well-known/jwks.json` for frontend validation (optional)
- **Rotation**: Monthly key rotation; old keys retained for validation until all tokens expire

### Token Revocation
- Short TTL (5 min) makes explicit revocation rarely needed
- For immediate revocation: maintain denylist in Redis (token `jti` + expiry)
- On role change/disable: add user to revocation list; next exchange fails

## Consequences

### Positive
- Clean separation: Auth.js owns sessions, backend owns API auth
- Short-lived tokens limit blast radius
- Backend controls all API auth semantics
- No Auth.js internal override risk
- Clear token lifecycle: session → exchange → API token → RLS

### Negative
- Extra hop on first authenticated request per session
- Additional endpoint to secure (rate limit, CSRF, monitoring)
- Token exchange latency on first authenticated request per session
- Frontend must handle 401 → re-exchange flow

## Implementation Notes
1. Create `/api/auth/exchange` endpoint in `backend/` (NestJS controller)
2. Frontend: `AuthProvider` calls exchange on session init, stores token in React context
3. Axios/fetch interceptor: attach Bearer token, handle 401 → re-exchange
4. Backend middleware: verify API JWT → `SET LOCAL basera.user_id/role`
6. ADR 003 recorded; implementation proceeds with token exchange pattern