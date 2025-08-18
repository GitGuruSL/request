-- Core whitelist tables not previously migrated (cities, variable_types, vehicle_types, subscription_plans)
-- Idempotent: uses IF NOT EXISTS

CREATE TABLE IF NOT EXISTS cities (
  id VARCHAR(255) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  country_code VARCHAR(10),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cities_country ON cities(country_code);

CREATE TABLE IF NOT EXISTS variable_types (
  id VARCHAR(255) PRIMARY KEY,
  code VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  data_type VARCHAR(50) NOT NULL DEFAULT 'text',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_variable_types_code ON variable_types(code);
CREATE INDEX IF NOT EXISTS idx_variable_types_active ON variable_types(is_active);

CREATE TABLE IF NOT EXISTS subscription_plans (
  id VARCHAR(255) PRIMARY KEY,
  code VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  price_cents INTEGER NOT NULL DEFAULT 0,
  billing_interval VARCHAR(50) NOT NULL DEFAULT 'monthly',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_subscription_plans_code ON subscription_plans(code);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON subscription_plans(is_active);

CREATE TABLE IF NOT EXISTS vehicle_types (
  id VARCHAR(255) PRIMARY KEY,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_vehicle_types_category ON vehicle_types(category_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_types_active ON vehicle_types(is_active);

-- Touch helpers
DO $$
BEGIN
  CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS TRIGGER AS $$
  BEGIN 
    NEW.updated_at = NOW(); 
    RETURN NEW; 
  END; $$ LANGUAGE plpgsql;
EXCEPTION WHEN others THEN NULL; 
END $$;

DO $$
BEGIN
  CREATE TRIGGER trg_cities_updated BEFORE UPDATE ON cities FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
EXCEPTION WHEN others THEN NULL; END $$;
DO $$
BEGIN
  CREATE TRIGGER trg_variable_types_updated BEFORE UPDATE ON variable_types FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
EXCEPTION WHEN others THEN NULL; END $$;
DO $$
BEGIN
  CREATE TRIGGER trg_subscription_plans_updated BEFORE UPDATE ON subscription_plans FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
EXCEPTION WHEN others THEN NULL; END $$;
DO $$
BEGIN
  CREATE TRIGGER trg_vehicle_types_updated BEFORE UPDATE ON vehicle_types FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
EXCEPTION WHEN others THEN NULL; END $$;
