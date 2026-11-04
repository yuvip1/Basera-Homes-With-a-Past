-- Basera Phase 1 — Migration 0000: Bootstrap
-- Creates the btree_gist extension and the database roles.
-- This migration is idempotent and safe to re-run.
-- Executed as: app_user (superuser, from Docker image POSTGRES_USER)

-- 1. Extension required for date-overlap exclusion constraints
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 2. Dedicated non-login owner role for application tables
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'basera_owner') THEN
    CREATE ROLE basera_owner NOLOGIN;
  END IF;
END $$;

-- 3. Migration runner role — no superuser, no bypass, no createdb
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'basera_migrator') THEN
    CREATE ROLE basera_migrator LOGIN;
  END IF;
END $$;

-- 4. Application runtime role — least privilege
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'basera_app') THEN
    CREATE ROLE basera_app LOGIN;
  END IF;
END $$;

-- 5. Grant schema privileges to migration and owner roles
GRANT USAGE, CREATE ON SCHEMA public TO basera_migrator;
GRANT USAGE, CREATE ON SCHEMA public TO basera_owner;
GRANT USAGE ON SCHEMA public TO basera_app;

-- 6. Allow basera_migrator to transfer ownership to basera_owner
GRANT basera_owner TO basera_migrator;