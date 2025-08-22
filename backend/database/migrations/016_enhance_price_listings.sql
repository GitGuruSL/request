-- Add missing fields to price_listings table for comprehensive price comparison
-- This migration adds fields needed for business pricing, delivery, contact info, and images

-- Add missing columns to price_listings table
ALTER TABLE price_listings 
ADD COLUMN IF NOT EXISTS master_product_id UUID REFERENCES master_products(id),
ADD COLUMN IF NOT EXISTS delivery_charge DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS website VARCHAR(255),
ADD COLUMN IF NOT EXISTS whatsapp VARCHAR(20);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_price_listings_master_product ON price_listings(master_product_id);
CREATE INDEX IF NOT EXISTS idx_price_listings_business_product ON price_listings(business_id, master_product_id);
CREATE INDEX IF NOT EXISTS idx_price_listings_country_active ON price_listings(country_code, is_active);
CREATE INDEX IF NOT EXISTS idx_price_listings_price ON price_listings(price);

-- Update business_id to be consistent with user_id from business verifications
-- This ensures price_listings.business_id references the user who owns the business
COMMENT ON COLUMN price_listings.business_id IS 'References users.id (firebase_uid) of the business owner';

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_price_listings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS update_price_listings_updated_at ON price_listings;
CREATE TRIGGER update_price_listings_updated_at
    BEFORE UPDATE ON price_listings
    FOR EACH ROW
    EXECUTE FUNCTION update_price_listings_updated_at();

-- Ensure business_products table exists with proper structure
-- This should already exist from migration 011, but ensure it's there
CREATE TABLE IF NOT EXISTS business_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL, -- references users.id (business owner)
  master_product_id UUID NOT NULL REFERENCES master_products(id) ON DELETE CASCADE,
  country_code VARCHAR(10) NOT NULL DEFAULT 'LK',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id, master_product_id, country_code)
);

-- Ensure indexes exist
CREATE INDEX IF NOT EXISTS idx_business_products_business ON business_products(business_id);
CREATE INDEX IF NOT EXISTS idx_business_products_country ON business_products(country_code);
CREATE INDEX IF NOT EXISTS idx_business_products_master_product ON business_products(master_product_id);

-- Ensure updated_at trigger exists for business_products
CREATE OR REPLACE FUNCTION update_business_products_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_business_products_updated_at ON business_products;
CREATE TRIGGER update_business_products_updated_at
    BEFORE UPDATE ON business_products
    FOR EACH ROW
    EXECUTE FUNCTION update_business_products_updated_at();
