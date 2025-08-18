-- Migration 022: Ensure firebase_uid column & strengthen permissions default logic
-- Idempotent / additive

ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(255) UNIQUE;

-- Ensure permissions column exists (safety)
ALTER TABLE users ADD COLUMN IF NOT EXISTS permissions JSONB;

-- Index on firebase_uid
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);

-- Merge permissions helper
CREATE OR REPLACE FUNCTION merge_permissions_json(existing JSONB, incoming JSONB)
RETURNS JSONB AS $$
DECLARE
  result JSONB := '{}';
  key TEXT;
  val_existing JSONB;
  val_incoming JSONB;
BEGIN
  IF existing IS NULL THEN existing := '{}'; END IF;
  IF incoming IS NULL THEN incoming := '{}'; END IF;
  FOR key IN SELECT DISTINCT key FROM (
    SELECT jsonb_object_keys(existing) AS key
    UNION
    SELECT jsonb_object_keys(incoming) AS key
  ) s LOOP
    val_existing := existing -> key;
    val_incoming := incoming -> key;
    IF (val_existing @> 'true'::jsonb) OR (val_incoming @> 'true'::jsonb) THEN
      result := result || jsonb_build_object(key, true);
    ELSE
      result := result || jsonb_build_object(key, false);
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;
