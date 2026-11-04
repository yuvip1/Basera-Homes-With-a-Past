-- Basera Phase 1 — Migration 0001: Schema
-- Creates all application tables. Executed as basera_migrator.
-- After creation, each table is transferred to basera_owner.

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT NOT NULL UNIQUE,
  role          TEXT NOT NULL DEFAULT 'GUEST'
                CHECK (role IN ('GUEST', 'HOST', 'BOTH', 'ADMIN')),
  auth_provider TEXT NOT NULL
                CHECK (auth_provider IN ('GOOGLE', 'MAGIC_LINK')),
  auth_subject  TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS properties (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT,
  city          TEXT,
  state         TEXT,
  country       TEXT,
  property_type TEXT,
  is_published  BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bookings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guest_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'REQUESTED'
                CHECK (status IN ('REQUESTED', 'DECLINED', 'AWAITING_PAYMENT',
                                  'CONFIRMED', 'COMPLETED', 'CANCELLED')),
  check_in      TIMESTAMPTZ NOT NULL,
  check_out     TIMESTAMPTZ NOT NULL,
  guests        INT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS reviews (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  direction     TEXT NOT NULL
                CHECK (direction IN ('guest_to_property', 'host_to_guest')),
  booking_id    UUID REFERENCES bookings(id) ON DELETE SET NULL,
  title         TEXT,
  body          TEXT,
  rating        INT,
  is_published  BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS review_tags (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  tag       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS amenities (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS property_photos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  url         TEXT NOT NULL,
  caption     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_sessions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_properties_owner ON properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_properties_published ON properties(is_published);
CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX IF NOT EXISTS idx_bookings_guest ON bookings(guest_id);
CREATE INDEX IF NOT EXISTS idx_bookings_property ON bookings(property_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON bookings(check_in, check_out);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_target ON reviews(target_id);
CREATE INDEX IF NOT EXISTS idx_reviews_direction ON reviews(direction);
CREATE INDEX IF NOT EXISTS idx_reviews_published ON reviews(is_published);
CREATE INDEX IF NOT EXISTS idx_reviews_booking ON reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_review_tags_review ON review_tags(review_id);
CREATE INDEX IF NOT EXISTS idx_amenities_property ON amenities(property_id);
CREATE INDEX IF NOT EXISTS idx_property_photos_property ON property_photos(property_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);

-- Transfer ownership to basera_owner
ALTER TABLE users OWNER TO basera_owner;
ALTER TABLE properties OWNER TO basera_owner;
ALTER TABLE bookings OWNER TO basera_owner;
ALTER TABLE reviews OWNER TO basera_owner;
ALTER TABLE review_tags OWNER TO basera_owner;
ALTER TABLE amenities OWNER TO basera_owner;
ALTER TABLE property_photos OWNER TO basera_owner;
ALTER TABLE user_sessions OWNER TO basera_owner;