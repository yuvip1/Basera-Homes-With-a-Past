-- Basera Phase 1 — Migration 0007: Additional constraints
-- Adds rating CHECK and check_out > check_in constraint.
-- Executed as basera_migrator (member of basera_owner).

-- Rating constraint (1-5)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'reviews_rating_check'
  ) THEN
    ALTER TABLE reviews ADD CONSTRAINT reviews_rating_check
      CHECK (rating >= 1 AND rating <= 5);
  END IF;
END $$;

-- Check-out after check-in
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'bookings_check_out_after_check_in'
  ) THEN
    ALTER TABLE bookings ADD CONSTRAINT bookings_check_out_after_check_in
      CHECK (check_out > check_in);
  END IF;
END $$;

-- Updated at is already in grants for reviews
-- No action needed - verified in 0002_grants.sql