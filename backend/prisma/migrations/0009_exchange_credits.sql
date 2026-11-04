-- Basera Phase 2 — Migration 0009: Exchange Credits for Replay Protection
-- Creates the exchange_credits table for JWT replay protection
-- This table stores consumed exchange credential JTIs to prevent replay attacks

CREATE TABLE IF NOT EXISTS exchange_credits (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    jti         TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ NOT NULL
);

-- Index for efficient cleanup of expired records
CREATE INDEX IF NOT EXISTS idx_exchange_credits_expires_at ON exchange_credits(expires_at);

-- The unique constraint on jti is already enforced by the UNIQUE constraint above
-- The atomic INSERT with ON CONFLICT (jti) DO NOTHING will work correctly
