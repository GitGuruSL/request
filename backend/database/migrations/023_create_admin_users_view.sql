-- 023_create_admin_users_view.sql
-- Provide a logical admin_users view so you can SELECT * FROM admin_users in RDS.
-- This does not duplicate data; it filters the users table.

CREATE OR REPLACE VIEW admin_users AS
SELECT 
  id,
  email,
  display_name AS name,
  role,
  is_active,
  email_verified,
  phone_verified,
  permissions,
  created_at,
  updated_at
FROM users
WHERE role IN ('admin','super_admin');

-- Optional index hints: underlying users indexes already handle typical filters.
