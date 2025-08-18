-- 0115_create_requests_table.sql
-- Adds core requests table required by later migrations (promo codes, conversations, responses, indexes)
-- Idempotent: uses IF NOT EXISTS and drops/recreates trigger.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category_id UUID NULL, -- future FK (categories) when categories table exists
  subcategory_id UUID NULL, -- future FK (sub_categories)
  location_city_id UUID NULL, -- placeholder for cities table
  country_code VARCHAR(10),
  status VARCHAR(40) NOT NULL DEFAULT 'active',
  budget NUMERIC(14,2),
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Basic supporting indexes (others added in later specialized migration file)
CREATE INDEX IF NOT EXISTS idx_requests_user ON requests(user_id);
CREATE INDEX IF NOT EXISTS idx_requests_country ON requests(country_code);
CREATE INDEX IF NOT EXISTS idx_requests_status_basic ON requests(status);

-- updated_at trigger
CREATE OR REPLACE FUNCTION touch_requests_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_requests_updated_at ON requests;
CREATE TRIGGER trg_requests_updated_at BEFORE UPDATE ON requests FOR EACH ROW EXECUTE FUNCTION touch_requests_updated_at();
