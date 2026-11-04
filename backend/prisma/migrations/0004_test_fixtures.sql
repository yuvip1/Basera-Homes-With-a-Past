-- Basera Phase 1 — Test fixtures for RLS security tests
-- Executed as app_user (superuser) to bypass RLS for fixture creation.
-- This file is idempotent: it deletes existing test rows first.

DELETE FROM reviews;
DELETE FROM bookings;
DELETE FROM properties;
DELETE FROM users;

-- Test users
INSERT INTO users (id, email, role, auth_provider, auth_subject) VALUES
  ('11111111-1111-1111-1111-111111111111', 'guest-a@example.com', 'GUEST', 'MAGIC_LINK', NULL),
  ('22222222-2222-2222-2222-222222222222', 'host-b@example.com', 'HOST', 'MAGIC_LINK', NULL),
  ('33333333-3333-3333-3333-333333333333', 'guest-c@example.com', 'GUEST', 'MAGIC_LINK', NULL);

-- Test property (owned by host B)
INSERT INTO properties (id, owner_id, name, is_published) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'Heritage Cottage', true);

-- Test booking (guest A at host B's property, COMPLETED)
INSERT INTO bookings (id, guest_id, property_id, status, check_in, check_out) VALUES
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'COMPLETED',
   '2026-01-01 14:00', '2026-01-03 11:00');

-- Review R1: B→A, host_to_guest, unpublished (privacy test)
INSERT INTO reviews (id, reviewer_id, target_id, direction, booking_id, title, body, is_published) VALUES
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222',
   '11111111-1111-1111-1111-111111111111', 'host_to_guest',
   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Careful guest', 'Left everything in perfect order.', false);

-- Review R2: A→Property, guest_to_property, published (public access test)
INSERT INTO reviews (id, reviewer_id, target_id, direction, booking_id, title, body, is_published) VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'guest_to_property',
   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Lovely stay', 'Beautiful heritage home.', true);

-- Review R3: A→Property, guest_to_property, unpublished (author access test)
INSERT INTO reviews (id, reviewer_id, target_id, direction, booking_id, title, body, is_published) VALUES
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'guest_to_property',
   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Draft review', 'Needs more time.', false);