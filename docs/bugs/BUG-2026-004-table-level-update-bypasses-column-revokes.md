# BUG-2026-004: Table-level UPDATE grant bypasses column-level REVOKE

- **Status:** Verified
- **Severity / priority:** High / P1
- **Phase / feature:** Phase 1 — Column-level privileges
- **Environment and version/commit:** PostgreSQL 16.15, Basera Phase 1 implementation
- **First observed:** 2026-10-30
- **Fixed / verified:** 2026-10-30

## Expected behavior
Column-level REVOKE on `reviewer_id`, `target_id`, `direction`, `booking_id`, `is_published` should prevent `basera_app` from modifying these columns.

## Actual behavior
PostgreSQL grants are additive, not restrictive. A table-level `GRANT UPDATE` allows updating ALL columns, regardless of column-level REVOKE.

## Reproduction steps
1. `GRANT UPDATE ON reviews TO basera_app`
2. `REVOKE UPDATE (reviewer_id) ON reviews FROM basera_app`
3. Connect as `basera_app` and try `UPDATE reviews SET reviewer_id = '...'`
4. The UPDATE succeeds despite the column-level REVOKE

## Evidence
- PostgreSQL documentation: "Column privileges are additional to table privileges, not replacements"
- Column-level REVOKE only works if the role does NOT have table-level UPDATE

## Root-cause analysis
- Confirmed facts: Table-level GRANT is not overridden by column-level REVOKE
- Root cause status: Confirmed

## Fix
Removed table-level `GRANT UPDATE ON reviews TO basera_app`. Only grant column-level UPDATE on permitted content columns:
```sql
GRANT SELECT, INSERT, DELETE ON reviews TO basera_app;
GRANT UPDATE (title, body, rating, updated_at) ON reviews TO basera_app;
```

## Regression coverage
- Test T6-T8: Immutable field updates denied — permission denied
- Test T9: Premature publication denied — RLS violation

## Verification
- Commands run: `psql -U basera_app -d basera -c "UPDATE reviews SET reviewer_id = '...'"` → `ERROR: permission denied for table reviews`

## Prevention / lessons learned
- Never grant table-level UPDATE if you need column-level restrictions
- Grant only column-level UPDATE on permitted columns
- Column-level REVOKE does NOT restrict a role that already has table-level UPDATE

## Related bugs / ADRs / commits
- BUG-2026-003: RLS identity missing/empty string handling