-- Basera Phase 1 — Migration 0003: Row-Level Security Policies
-- Executed as basera_migrator (member of basera_owner).
-- All policies use current_setting('basera.user_id', true) which is missing-safe.

-- Enable RLS on all application tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;

ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties FORCE ROW LEVEL SECURITY;

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings FORCE ROW LEVEL SECURITY;

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews FORCE ROW LEVEL SECURITY;

ALTER TABLE review_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_tags FORCE ROW LEVEL SECURITY;

ALTER TABLE amenities ENABLE ROW LEVEL SECURITY;
ALTER TABLE amenities FORCE ROW LEVEL SECURITY;

ALTER TABLE property_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_photos FORCE ROW LEVEL SECURITY;

ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions FORCE ROW LEVEL SECURITY;

-- users: can read/write own row only
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'users_self') THEN
    CREATE POLICY users_self ON users
      FOR ALL TO basera_app
      USING (id = current_setting('basera.user_id', true)::uuid)
      WITH CHECK (id = current_setting('basera.user_id', true)::uuid);
  END IF;
END $$;

-- properties: owner can manage, public can read published
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'properties_owner') THEN
    CREATE POLICY properties_owner ON properties
      FOR ALL TO basera_app
      USING (owner_id = current_setting('basera.user_id', true)::uuid)
      WITH CHECK (owner_id = current_setting('basera.user_id', true)::uuid);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'properties_public_read') THEN
    CREATE POLICY properties_public_read ON properties
      FOR SELECT TO basera_app
      USING (is_published = true);
  END IF;
END $$;

-- bookings: guest or host can access
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'bookings_guest') THEN
    CREATE POLICY bookings_guest ON bookings
      FOR ALL TO basera_app
      USING (guest_id = current_setting('basera.user_id', true)::uuid)
      WITH CHECK (guest_id = current_setting('basera.user_id', true)::uuid);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'bookings_host') THEN
    CREATE POLICY bookings_host ON bookings
      FOR SELECT TO basera_app
      USING (
        property_id IN (
          SELECT id FROM properties
          WHERE owner_id = current_setting('basera.user_id', true)::uuid
        )
      );
  END IF;
END $$;

-- reviews: direction-specific privacy
-- Published guest-to-property reviews are public.
-- Authors can read their own reviews (published or not).
-- Host-to-guest reviews are never publicly readable.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'reviews_select') THEN
    CREATE POLICY reviews_select ON reviews
      FOR SELECT TO basera_app
      USING (
        (direction = 'guest_to_property' AND is_published = true)
        OR (reviewer_id = current_setting('basera.user_id', true)::uuid)
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'reviews_insert') THEN
    CREATE POLICY reviews_insert ON reviews
      FOR INSERT TO basera_app
      WITH CHECK (
        reviewer_id = current_setting('basera.user_id', true)::uuid
        AND is_published = false
        AND direction IN ('guest_to_property', 'host_to_guest')
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'reviews_update') THEN
    CREATE POLICY reviews_update ON reviews
      FOR UPDATE TO basera_app
      USING (
        reviewer_id = current_setting('basera.user_id', true)::uuid
        AND is_published = false
      )
      WITH CHECK (
        reviewer_id = current_setting('basera.user_id', true)::uuid
        AND is_published = false
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'reviews_delete') THEN
    CREATE POLICY reviews_delete ON reviews
      FOR DELETE TO basera_app
      USING (
        reviewer_id = current_setting('basera.user_id', true)::uuid
        AND is_published = false
      );
  END IF;
END $$;

-- review_tags: author can manage tags on their own reviews
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'review_tags_author') THEN
    CREATE POLICY review_tags_author ON review_tags
      FOR ALL TO basera_app
      USING (
        review_id IN (
          SELECT id FROM reviews
          WHERE reviewer_id = current_setting('basera.user_id', true)::uuid
        )
      )
      WITH CHECK (
        review_id IN (
          SELECT id FROM reviews
          WHERE reviewer_id = current_setting('basera.user_id', true)::uuid
        )
      );
  END IF;
END $$;

-- amenities: owner can manage
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'amenities_owner') THEN
    CREATE POLICY amenities_owner ON amenities
      FOR ALL TO basera_app
      USING (
        property_id IN (
          SELECT id FROM properties
          WHERE owner_id = current_setting('basera.user_id', true)::uuid
        )
      )
      WITH CHECK (
        property_id IN (
          SELECT id FROM properties
          WHERE owner_id = current_setting('basera.user_id', true)::uuid
        )
      );
  END IF;
END $$;

-- property_photos: owner can manage
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'property_photos_owner') THEN
    CREATE POLICY property_photos_owner ON property_photos
      FOR ALL TO basera_app
      USING (
        property_id IN (
          SELECT id FROM properties
          WHERE owner_id = current_setting('basera.user_id', true)::uuid
        )
      )
      WITH CHECK (
        property_id IN (
          SELECT id FROM properties
          WHERE owner_id = current_setting('basera.user_id', true)::uuid
        )
      );
  END IF;
END $$;

-- user_sessions: own sessions only
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polname = 'user_sessions_self') THEN
    CREATE POLICY user_sessions_self ON user_sessions
      FOR ALL TO basera_app
      USING (
        user_id = current_setting('basera.user_id', true)::uuid
      )
      WITH CHECK (
        user_id = current_setting('basera.user_id', true)::uuid
      );
  END IF;
END $$;