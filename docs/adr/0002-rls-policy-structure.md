# ADR 0002: RLS Policy Structure and Identity Management

## Context
Phase 1 requires implementing Row-Level Security (RLS) for the `reviews` table and other application tables to enforce the privacy invariant: guests cannot read host-to-guest reviews about themselves, while published guest-to-property reviews remain publicly readable.

## Decision
Use a custom PostgreSQL session variable `basera.user_id` set transaction-locally by the application after JWT verification. All RLS policies reference this variable through a safe helper function `current_user_id()` that handles missing/empty values safely.

RLS policies are the authoritative enforcement mechanism. The application layer (Phase 2) is responsible for authentication and setting the identity variable from verified JWT claims.

## Consequences
- **Security:** RLS enforces row scoping at the database level, providing defense-in-depth.
- **Limitation:** RLS does not authenticate identity; it only scopes access based on the session variable. The application layer must verify JWT before setting `basera.user_id`.
- **Performance:** Session variables are fast; no additional tables or joins needed.
- **Maintenance:** Policies are declarative and versioned in raw SQL migrations.

## Alternatives considered
1. Application-level filtering only — rejected; no defense-in-depth.
2. Separate database users per application user — rejected; doesn't scale and doesn't work with connection pooling.
3. VIEW-based filtering — rejected; less flexible than RLS policies.

## Status
Adopted. Implemented in Phase 1 migrations.