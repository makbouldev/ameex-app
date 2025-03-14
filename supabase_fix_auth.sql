-- ============================================================================
-- DEFINITIVE FIX — no deletes, no recreates.
-- Just patches the existing seeded drivers so sign-in works.
--   • forces all empty-string auth.users token columns from NULL → ''
--   • resets the password (so the hash is fresh and bcrypt verifies)
--   • creates the missing auth.identities rows
-- Safe to re-run.
-- ============================================================================

-- 1. Patch auth.users — GoTrue reads these fields during sign-in and
--    rejects NULL on the token fields. Reset password at the same time.
UPDATE auth.users
SET
  encrypted_password            = crypt('driver123456', gen_salt('bf')),
  email_confirmed_at            = coalesce(email_confirmed_at, now()),
  aud                           = 'authenticated',
  role                          = 'authenticated',
  instance_id                   = coalesce(instance_id, '00000000-0000-0000-0000-000000000000'::uuid),
  raw_app_meta_data             = coalesce(raw_app_meta_data,  '{"provider":"email","providers":["email"]}'::jsonb),
  raw_user_meta_data            = coalesce(raw_user_meta_data, '{}'::jsonb),
  confirmation_token            = coalesce(confirmation_token, ''),
  recovery_token                = coalesce(recovery_token, ''),
  email_change_token_new        = coalesce(email_change_token_new, ''),
  email_change                  = coalesce(email_change, ''),
  phone_change                  = coalesce(phone_change, ''),
  phone_change_token            = coalesce(phone_change_token, ''),
  email_change_token_current    = coalesce(email_change_token_current, ''),
  email_change_confirm_status   = coalesce(email_change_confirm_status, 0),
  reauthentication_token        = coalesce(reauthentication_token, ''),
  is_sso_user                   = coalesce(is_sso_user, false),
  updated_at                    = now()
WHERE id::text LIKE '11111111-1111-1111-1111-00000000000%';

-- 2. Create auth.identities for any seeded driver missing one
INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
)
SELECT
  u.id, u.id,
  jsonb_build_object(
    'sub',            u.id::text,
    'email',          u.email,
    'email_verified', true,
    'phone_verified', false
  ),
  'email',
  u.id::text,
  now(), now(), now()
FROM auth.users u
WHERE u.id::text LIKE '11111111-1111-1111-1111-00000000000%'
ON CONFLICT (provider, provider_id) DO NOTHING;

-- 3. Verify
SELECT
  u.email,
  CASE WHEN u.encrypted_password IS NULL THEN 'MISSING' ELSE 'OK' END AS password,
  u.email_confirmed_at IS NOT NULL AS confirmed,
  (SELECT count(*) FROM auth.identities i WHERE i.user_id = u.id) AS identities,
  (SELECT count(*) FROM public.profiles  p WHERE p.id      = u.id) AS profile
FROM auth.users u
WHERE u.id::text LIKE '11111111-1111-1111-1111-00000000000%'
ORDER BY u.email;
