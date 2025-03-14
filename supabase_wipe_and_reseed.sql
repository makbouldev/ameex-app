-- ============================================================================
-- WIPE the 10 seeded drivers and their orders, then re-run supabase_seed.sql
-- Only use if you want a clean reset.
-- The quick path is just supabase_change_emails.sql — no wipe needed.
-- ============================================================================

-- 1. Remove orders assigned to the seeded drivers
DELETE FROM public.orders
WHERE assigned_driver_id::text LIKE '11111111-1111-1111-1111-00000000000%';

-- 2. Remove the pending/unassigned seeded orders too (by tracking range)
DELETE FROM public.orders
WHERE tracking_number LIKE 'AMX1%ABC'
   OR tracking_number LIKE 'AMX1%DEF'
   OR tracking_number LIKE 'AMX1%GHI'
   OR tracking_number LIKE 'AMX1%JKL'
   OR tracking_number LIKE 'AMX1%MNO'
   OR tracking_number LIKE 'AMX1%PQR'
   OR tracking_number LIKE 'AMX1%STU'
   OR tracking_number LIKE 'AMX1%VWX'
   OR tracking_number LIKE 'AMX1%YZA'
   OR tracking_number LIKE 'AMX1%BCD'
   OR tracking_number LIKE 'AMX1%EFG'
   OR tracking_number LIKE 'AMX1%HIJ'
   OR tracking_number LIKE 'AMX1%KLM'
   OR tracking_number LIKE 'AMX1%NOP'
   OR tracking_number LIKE 'AMX1%QRS'
   OR tracking_number LIKE 'AMX1%TUV'
   OR tracking_number LIKE 'AMX2%'
   OR tracking_number LIKE 'AMX3%'
   OR tracking_number LIKE 'AMX4%'
   OR tracking_number LIKE 'AMX5%';

-- 3. Remove the 10 driver profiles
DELETE FROM public.profiles
WHERE id::text LIKE '11111111-1111-1111-1111-00000000000%';

-- 4. Remove the 10 driver identities
DELETE FROM auth.identities
WHERE user_id::text LIKE '11111111-1111-1111-1111-00000000000%';

-- 5. Remove the 10 driver auth.users
DELETE FROM auth.users
WHERE id::text LIKE '11111111-1111-1111-1111-00000000000%';

-- Verify clean
SELECT 'drivers remaining' AS what, count(*) FROM public.profiles WHERE id::text LIKE '11111111-%'
UNION ALL
SELECT 'auth users remaining', count(*) FROM auth.users WHERE id::text LIKE '11111111-%';

-- ============================================================================
-- Now go run supabase_seed.sql (the updated one with @gmail.com)
-- Then run supabase_seed_fix.sql to add the auth.identities rows.
-- ============================================================================
