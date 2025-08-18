-- 024_create_firebase_replica_tables.sql
-- Create exact replicas of Firebase collections as PostgreSQL tables
-- This allows direct data import without schema mapping confusion

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- admin_users (from your Firebase data) - drop view first to avoid conflict
DROP VIEW IF EXISTS admin_users;
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id VARCHAR(255) UNIQUE, -- original Firebase document ID
  email VARCHAR(255),
  name VARCHAR(255),
  role VARCHAR(50) DEFAULT 'admin',
  is_active BOOLEAN DEFAULT true,
  permissions JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  last_permission_update TIMESTAMPTZ
);

-- app_countries (from your Firebase data)
CREATE TABLE IF NOT EXISTS app_countries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id VARCHAR(255) UNIQUE,
  code VARCHAR(10) UNIQUE,
  name VARCHAR(255),
  flag VARCHAR(10),
  phone_code VARCHAR(10),
  is_enabled BOOLEAN DEFAULT false,
  coming_soon_message TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- brands (enhanced to match Firebase)
DROP TABLE IF EXISTS firebase_brands CASCADE;
CREATE TABLE IF NOT EXISTS firebase_brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id VARCHAR(255) UNIQUE,
  name VARCHAR(255),
  description TEXT,
  website VARCHAR(500),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- categories (enhanced to match Firebase)
DROP TABLE IF EXISTS firebase_categories CASCADE;
CREATE TABLE IF NOT EXISTS firebase_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id VARCHAR(255) UNIQUE,
  category VARCHAR(255),
  type VARCHAR(50) -- service, item, etc
);

-- cities (from your Firebase data)
CREATE TABLE IF NOT EXISTS cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id VARCHAR(255) UNIQUE,
  name VARCHAR(255),
  country_code VARCHAR(10),
  description TEXT,
  population INTEGER,
  coordinates JSONB, -- {lat: number, lng: number}
  is_active BOOLEAN DEFAULT true,
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- content_pages (enhanced)
DROP TABLE IF EXISTS firebase_content_pages CASCADE;
CREATE TABLE IF NOT EXISTS firebase_content_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id VARCHAR(255) UNIQUE,
  title VARCHAR(500),
  slug VARCHAR(255),
  content TEXT,
  category VARCHAR(100),
  type VARCHAR(50), -- template, page, etc
  status VARCHAR(50), -- approved, pending, etc
  countries TEXT[], -- array of country codes
  keywords TEXT[],
  meta_description TEXT,
  is_template BOOLEAN DEFAULT false,
  requires_approval BOOLEAN DEFAULT false,
  created_by VARCHAR(255),
  created_at TIMESTAMPTZ
);

-- conversations (from your Firebase data)
DROP TABLE IF EXISTS firebase_conversations CASCADE;
CREATE TABLE IF NOT EXISTS firebase_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id VARCHAR(255) UNIQUE,
  request_id VARCHAR(255),
  request_title VARCHAR(500),
  requester_id VARCHAR(255),
  responder_id VARCHAR(255),
  participant_ids TEXT[], -- array of user IDs
  last_message TEXT,
  last_message_time TIMESTAMPTZ,
  read_status JSONB, -- {userId: boolean}
  created_at TIMESTAMPTZ
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_app_countries_code ON app_countries(code);
CREATE INDEX IF NOT EXISTS idx_cities_country ON cities(country_code);
CREATE INDEX IF NOT EXISTS idx_conversations_request ON firebase_conversations(request_id);

-- Add updated_at triggers for tables that need them
CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_admin_users_updated_at ON admin_users;
CREATE TRIGGER trg_admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_app_countries_updated_at ON app_countries;
CREATE TRIGGER trg_app_countries_updated_at BEFORE UPDATE ON app_countries FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_cities_updated_at ON cities;
CREATE TRIGGER trg_cities_updated_at BEFORE UPDATE ON cities FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
