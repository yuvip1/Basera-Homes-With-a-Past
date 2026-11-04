-- Basera Phase 1 — Migration 0002: Grants
-- Grants runtime privileges to basera_app.
-- Executed as basera_migrator (member of basera_owner).

-- users table
GRANT SELECT, INSERT, DELETE ON users TO basera_app;
GRANT UPDATE (email, role, auth_provider, auth_subject, updated_at) ON users TO basera_app;

-- properties table
GRANT SELECT, INSERT, DELETE ON properties TO basera_app;
GRANT UPDATE (name, description, city, state, country, property_type, is_published, updated_at) ON properties TO basera_app;

-- bookings table
GRANT SELECT, INSERT, DELETE ON bookings TO basera_app;
GRANT UPDATE (status, guests, updated_at) ON bookings TO basera_app;

-- reviews table
-- CRITICAL: No table-level UPDATE. Only column-level UPDATE on content columns.
GRANT SELECT, INSERT, DELETE ON reviews TO basera_app;
GRANT UPDATE (title, body, rating, updated_at) ON reviews TO basera_app;

-- review_tags table
GRANT SELECT, INSERT, DELETE ON review_tags TO basera_app;

-- amenities table
GRANT SELECT, INSERT, DELETE ON amenities TO basera_app;
GRANT UPDATE (name) ON amenities TO basera_app;

-- property_photos table
GRANT SELECT, INSERT, DELETE ON property_photos TO basera_app;
GRANT UPDATE (caption) ON property_photos TO basera_app;

-- user_sessions table
GRANT SELECT, INSERT, DELETE ON user_sessions TO basera_app;
GRANT UPDATE (token_hash, expires_at) ON user_sessions TO basera_app;

-- Sequences: not used — tables use gen_random_uuid() for primary keys