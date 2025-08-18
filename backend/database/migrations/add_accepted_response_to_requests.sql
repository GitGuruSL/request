-- Add accepted_response_id to requests to allow owners to accept one response (guarded if responses table exists)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='responses') THEN
    BEGIN
      ALTER TABLE requests ADD COLUMN IF NOT EXISTS accepted_response_id UUID REFERENCES responses(id) ON DELETE SET NULL;
    EXCEPTION WHEN undefined_table THEN
      -- responses table still missing, skip silently
      RAISE NOTICE 'responses table missing at runtime, skipping accepted_response_id addition (will be handled later)';
    END;
    CREATE INDEX IF NOT EXISTS idx_requests_accepted_response ON requests(accepted_response_id);
  ELSE
    RAISE NOTICE 'responses table not present yet; accepted_response_id skipped';
  END IF;
END $$;
