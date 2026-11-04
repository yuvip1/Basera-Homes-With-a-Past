-- Basera Phase 1 — Constraint tests
-- Tests for rating CHECK and check_out > check_in constraints
-- Run as basera_app (runtime role).

\echo '========================================'
\echo 'CONSTRAINT TESTS'
\echo '========================================'

-- T1: Valid rating (1-5) should succeed
\echo ''
\echo '--- T1: Valid rating 5 should succeed ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO reviews (reviewer_id, target_id, direction, is_published, rating)
  VALUES ('11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222', 'guest_to_property', false, 5);
COMMIT;

-- T2: Rating 0 should fail
\echo ''
\echo '--- T2: Rating 0 should fail (CHECK violation) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO reviews (reviewer_id, target_id, direction, is_published, rating)
  VALUES ('11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222', 'guest_to_property', false, 0);
COMMIT;

-- T3: Rating 6 should fail
\echo ''
\echo '--- T3: Rating 6 should fail (CHECK violation) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO reviews (reviewer_id, target_id, direction, is_published, rating)
  VALUES ('11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222', 'guest_to_property', false, 6);
COMMIT;

-- T4: check_out > check_in valid should succeed
\echo ''
\echo '--- T4: check_out > check_in valid should succeed ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO bookings (guest_id, property_id, check_in, check_out, status)
  VALUES ('11111111-1111-1111-1111-111111111111',
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          '2026-01-01 14:00', '2026-01-03 11:00', 'REQUESTED');
COMMIT;

-- T5: check_out <= check_in should fail
\echo ''
\echo '--- T5: check_out <= check_in should fail (CHECK violation) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO bookings (guest_id, property_id, check_in, check_out, status)
  VALUES ('11111111-1111-1111-1111-111111111111',
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          '2026-01-03 11:00', '2026-01-01 14:00', 'REQUESTED');
COMMIT;

-- T6: check_out = check_in should fail
\echo ''
\echo '--- T6: check_out = check_in should fail (CHECK violation) ---'
BEGIN;
SET LOCAL basera.user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO bookings (guest_id, property_id, check_in, check_out, status)
  VALUES ('11111111-1111-1111-1111-111111111111',
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          '2026-01-01 14:00', '2026-01-01 14:00', 'REQUESTED');
COMMIT;

\echo ''
\echo '========================================'
\echo 'CONSTRAINT TESTS COMPLETE'
\echo '========================================'