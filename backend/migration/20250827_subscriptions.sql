-- Subscriptions + usage limits + PPC clicks
-- Safe to run multiple times (use IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  audience TEXT NOT NULL CHECK (audience IN ('normal','business')),
  model TEXT NOT NULL CHECK (model IN ('monthly','ppc')),
  price_cents INTEGER,
  currency TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  plan_id UUID REFERENCES subscription_plans(id),
  status TEXT NOT NULL CHECK (status IN ('active','canceled','expired','trialing')),
  start_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT false,
  provider TEXT NOT NULL DEFAULT 'internal',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_active ON subscriptions(user_id, status);

-- Monthly usage counts for normal users (responses per month)
CREATE TABLE IF NOT EXISTS usage_monthly (
  user_id UUID NOT NULL,
  year_month CHAR(6) NOT NULL,
  response_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, year_month)
);

-- Business price comparison mode
CREATE TABLE IF NOT EXISTS price_comparison_business (
  business_id UUID PRIMARY KEY,
  mode TEXT NOT NULL CHECK (mode IN ('ppc','monthly')),
  monthly_plan_id UUID REFERENCES subscription_plans(id),
  ppc_price_cents INTEGER,
  currency TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Per-click charges
CREATE TABLE IF NOT EXISTS ppc_clicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL,
  request_id UUID NOT NULL,
  click_type TEXT NOT NULL CHECK (click_type IN ('view_contact','message','call')),
  cost_cents INTEGER NOT NULL,
  currency TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ppc_clicks_business ON ppc_clicks(business_id);
CREATE INDEX IF NOT EXISTS idx_ppc_clicks_request ON ppc_clicks(request_id);
