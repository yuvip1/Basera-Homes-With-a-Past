-- Basera Phase 1 — Migration 0006: Fix identity handling
-- current_setting('basera.user_id', true) returns "" (empty string) when unset,
-- which causes ''::uuid to error. Wrap with NULLIF to fail closed safely.
-- Executed as basera_migrator (member of basera_owner).

-- Helper function for safe identity lookup
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS UUID AS $$
  SELECT NULLIF(current_setting('basera.user_id', true), '')::uuid
$$ LANGUAGE sql STABLE SET search_path = 'public';

-- Drop and recreate all policies using the safe helper
DROP POLICY IF EXISTS users_self ON users;
DROP POLICY IF EXISTS properties_owner ON properties;
DROP POLICY IF EXISTS properties_public_read ON properties;
DROP POLICY IF EXISTS bookings_guest ON bookings;
DROP POLICY IF EXISTS bookings_host ON bookings;
DROP POLICY IF EXISTS reviews_select ON reviews;
DROP POLICY IF EXISTS reviews_insert ON reviews;
DROP POLICY IF EXISTS reviews_update ON reviews;
DROP POLICY IF EXISTS reviews_delete ON reviews;
DROP POLICY IF EXISTS review_tags_author ON review_tags;
DROP POLICY IF EXISTS amenities_owner ON amenities;
DROP POLICY IF EXISTS property_photos_owner ON property_photos;
DROP POLICY IF EXISTS user_sessions_self ON user_sessions;

-- users: can read/write own row only
CREATE POLICY users_self ON users
  FOR ALL TO basera_app
  USING (id = current_user_id())
  WITH CHECK (id = current_user_id());

-- properties: owner can manage, public can read published
CREATE POLICY properties_owner ON properties
  FOR ALL TO basera_app
  USING (owner_id = current_user_id())
  WITH CHECK (owner_id = current_user_id());

CREATE POLICY properties_public_read ON properties
  FOR SELECT TO basera_app
  USING (is_published = true);

-- bookings: guest or host can access
CREATE POLICY bookings_guest ON bookings
  FOR ALL TO basera_app
  USING (guest_id = current_user_id())
  WITH CHECK (guest_id = current_user_id());

CREATE POLICY bookings_host ON bookings
  FOR SELECT TO basera_app
  USING (
    property_id IN (
      SELECT id FROM properties
      WHERE owner_id = current_user_id()
    )
  );

-- reviews: direction-specific privacy
-- Published guest-to-property reviews are public.
-- Authors can read their own reviews (published or not).
-- Host-to-guest reviews are never publicly readable.
CREATE POLICY reviews_select ON reviews
  FOR SELECT TO basera_app
  USING (
    (direction = 'guest_to_property' AND is_published = true)
    OR (reviewer_id = current_user_id())
  );

CREATE POLICY reviews_insert ON reviews
  FOR INSERT TO basera_app
  WITH CHECK (
    reviewer_id = current_user_id()
    AND is_published = false
    AND direction IN ('guest_to_property', 'host_to_guest')
  );

CREATE POLICY reviews_update ON reviews
  FOR UPDATE TO basera_app
  USING (
    reviewer_id = current_user_id()
    AND is_published = false
  )
  WITH CHECK (
    reviewer_id = current_user_id()
    AND is_published = false
  );

CREATE POLICY reviews_delete ON reviews
  FOR DELETE TO basera_app
  USING (
    reviewer_id = current_user_id()
    AND is_published = false
  );

-- review_tags: author can manage tags on their own reviews
CREATE POLICY review_tags_author ON review_tags
  FOR ALL TO basera_app
  USING (
    review_id IN (
      SELECT id FROM reviews
      WHERE reviewer_id = current_user_id()
    )
  )
  WITH CHECK (
    review_id IN (
      SELECT id FROM reviews
      WHERE reviewer_id = current_user_id()
    )
  );

-- amenities: owner can manage
CREATE POLICY amenities_owner ON amenities
  FOR ALL TO basera_app
  USING (
    property_id IN (
      SELECT id FROM properties
      WHERE owner_id = current_user_id()
    )
  )
  WITH CHECK (
    property_id IN (
      SELECT id FROM properties
      WHERE owner_id = current_user_id()
    )
  );

-- property_photos: owner can manage
CREATE POLICY property_photos_owner ON property_photos
  FOR ALL TO basera_app
  USING (
    property_id IN (
      SELECT id FROM properties
      WHERE owner_id = current_user_id()
    )
  )
  WITH CHECK (
    property_id IN (
      SELECT id FROM properties
      WHERE owner_id = current_user_id()
    )
  );

-- user_sessions: own sessions only
CREATE POLICY user_sessions_self ON user_sessions
  FOR ALL TO basera_app
  USING (user_id = current_user_id())
  WITH CHECK (user_id = current_user_id());