-- 025_add_password_to_admin_users.sql
-- Add password_hash field to admin_users table and set password for existing admin

ALTER TABLE admin_users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Set password for existing admin (password: StrongPassword123!)
UPDATE admin_users 
SET password_hash = crypt('StrongPassword123!', gen_salt('bf', 12))
WHERE email = 'superadmin@request.lk' AND password_hash IS NULL;
