-- Add accepted_response_id to requests to allow owners to accept one response
ALTER TABLE requests
  ADD COLUMN IF NOT EXISTS accepted_response_id UUID REFERENCES responses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_requests_accepted_response ON requests(accepted_response_id);
