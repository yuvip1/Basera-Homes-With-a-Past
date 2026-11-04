-- Basera Phase 1 — Security tests
-- Run as basera_app (runtime role).
-- Expected results are documented inline.
-- Uses NULLIF to handle empty basera.user_id safely.

\echo '========================================'
\echo 'PHASE 1 SECURITY TESTS (as basera_app)'
\echo '========================================'

-- T1: Guest A reads host-to-guest reviews about A (expect 0 rows)
\echo ''
\echo '--- T1: Guest A reads host-to-guest reviews about A (expect 0 rows) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
SELECT count(*) AS host_to_guest_about_A FROM reviews
  WHERE direction = 'host_to_guest'
    AND target_id = '11111111-1111-1111-1111-111111111111';
COMMIT;

-- T2: Guest A reads published guest-to-property reviews (expect 1 row)
\echo ''
\echo '--- T2: Guest A reads published guest-to-property reviews (expect 1 row) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
SELECT count(*) AS published_guest_to_property FROM reviews
  WHERE direction = 'guest_to_property' AND is_published = true;
COMMIT;

-- T3: Host B reads own host-to-guest reviews (expect 1 row)
\echo ''
\echo '--- T3: Host B reads own host-to-guest reviews (expect 1 row) ---'
BEGIN;
SET LOCAL basera.user_id = '22222222-2222-2222-2222-222222222222';
SELECT count(*) AS own_host_to_guest FROM reviews
  WHERE direction = 'host_to_guest'
    AND reviewer_id = '22222222-2222-2222-2222-222222222222';
COMMIT;

-- T4: Guest A reads own unpublished review (expect 1 row)
\echo ''
\echo '--- T4: Guest A reads own unpublished review (expect 1 row) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
SELECT count(*) AS own_unpublished FROM reviews
  WHERE reviewer_id = '11111111-1111-1111-1111-111111111111'
    AND is_published = false;
COMMIT;

-- T5: Guest C reads B's unpublished review (expect 0 rows)
\echo ''
\echo '--- T5: Guest C reads B's unpublished review (expect 0 rows) ---'
BEGIN;
SET LOCAL basera.user_id = '33333333-3333-3333-3333-333333333333';
SELECT count(*) AS others_unpublished FROM reviews
  WHERE reviewer_id = '22222222-2222-2222-2222-222222222222'
    AND is_published = false;
COMMIT;

-- T6: Guest A cannot UPDATE reviewer_id (expect permission denied)
\echo ''
\echo '--- T6: Guest A cannot UPDATE reviewer_id (expect denied) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
UPDATE reviews SET reviewer_id = '33333333-3333-3333-3333-333333333333'
  WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
COMMIT;

-- T7: Guest A cannot UPDATE direction (expect permission denied)
\echo ''
\echo '--- T7: Guest A cannot UPDATE direction (expect denied) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
UPDATE reviews SET direction = 'host_to_guest'
  WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
COMMIT;

-- T8: Guest A cannot UPDATE is_published (expect permission denied)
\echo ''
\echo '--- T8: Guest A cannot UPDATE is_published (expect denied) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
UPDATE reviews SET is_published = true
  WHERE id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
COMMIT;

-- T9: Guest A cannot INSERT with is_published=true (expect RLS violation)
\echo ''
\echo '--- T9: Guest A cannot INSERT with is_published=true (expect denied) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO reviews (reviewer_id, target_id, direction, is_published)
  VALUES ('11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222', 'guest_to_property', true);
COMMIT;

-- T10: Missing basera.user_id → 0 rows (expect no error)
\echo ''
\echo '--- T10: Missing basera.user_id → 0 rows (expect no error) ---'
BEGIN;
SELECT count(*) AS missing_identity FROM reviews;
COMMIT;

-- T11: basera_app cannot SET ROLE basera_owner (expect denied)
\echo ''
\echo '--- T11: basera_app cannot SET ROLE basera_owner (expect denied) ---'
BEGIN;
SET ROLE basera_owner;
COMMIT;

\echo ''
\echo '========================================'
\echo 'ALL TESTS COMPLETE'
\echo '========================================'