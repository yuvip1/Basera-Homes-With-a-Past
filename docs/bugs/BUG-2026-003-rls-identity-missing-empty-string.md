# BUG-2026-003: RLS identity missing/empty string handling

- **Status:** Verified
- **Severity / priority:** High / P1
- **Phase / feature:** Phase 1 — RLS policies
- **Environment and version/commit:** PostgreSQL 16.15, Basera Phase 1 implementation
- **First observed:** 2026-10-30
- **Fixed / verified:** 2026-10-30

## Expected behavior
Missing or empty `basera.user_id` should fail closed (return 0 rows) without raising a PostgreSQL error.

## Actual behavior
`current_setting('basera.user_id', true)` returns `""` (empty string) when unset. Casting `''::uuid` raises:
```
ERROR:  invalid input syntax for type uuid: ""
```

## Reproduction steps
1. Connect as `basera_app`
2. Don't set `basera.user_id`
3. Run `SELECT * FROM reviews`

## Evidence
- Error output: `ERROR:  invalid input syntax for type uuid: ""`
- `current_setting('basera.user_id', true)` returns `""` (empty string) not NULL

## Root-cause analysis
- Confirmed facts: `current_setting(name, true)` returns empty string for unset variables, not NULL
- The cast `''::uuid` fails in PostgreSQL
- Root cause status: Confirmed

## Fix
Created `current_user_id()` helper function that wraps `NULLIF(current_setting('basera.user_id', true), '')::uuid`:
```sql
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS UUID AS $$
  SELECT NULLIF(current_setting('basera.user_id', true), '')::uuid
$$ LANGUAGE sql STABLE SET search_path = 'public';
```

All RLS policies now use `current_user_id()` instead of raw `current_setting()`.

## Regression coverage
- Test T10: Missing identity → public guest-to-property reviews still visible (1 row), host-to-guest reviews hidden (0 rows) — correct behavior per privacy invariant

## Verification
- Commands run: `psql -U basera_app -d basera -c "SELECT count(*) FROM reviews"` → returns 1 row (published guest-to-property)
- Unit tests: N/A
- Integration tests: Security test suite passes

## Prevention / lessons learned
- Always use `NULLIF(current_setting('...', true), '')` for UUID session variables
- Missing identity should never raise an error; it should fail closed

## Related bugs / ADRs / commits
- BUG-2026-001: Docker Compose PostgreSQL startup failure
- BUG-2026-002: Docker Compose Redis image pull access denied