-- ============================================================================
-- FIX: Purge bulky base64 data from auth.users & public.profiles
-- Safe script without 'avatar_url' column on public.profiles
-- ============================================================================

-- 1. Tne9iya dyal metadata l'admin mn base64 l'kbir
UPDATE auth.users
SET raw_user_meta_data = jsonb_build_object(
    'full_name', coalesce(raw_user_meta_data->>'full_name', 'Noureddine Makboul'),
    'role', coalesce(raw_user_meta_data->>'role', 'admin'),
    'phone', coalesce(raw_user_meta_data->>'phone', '0725572550')
)
WHERE email = 'noureddinemakboul03@gmail.com'
   OR raw_user_meta_data::text LIKE '%data:image%';

-- 2. Tne9iya dyal ga3 l'comptes li fihom tsawer base64
UPDATE auth.users
SET raw_user_meta_data = (raw_user_meta_data - 'avatar_url') - 'zone'
WHERE raw_user_meta_data::text LIKE '%data:image%';

-- 3. Tne9iya dyal zone f table profiles (ila kan fiha base64)
UPDATE public.profiles
SET zone = regexp_replace(zone, '\s*\[AVATAR:data:image[^\]]+\]', '', 'g')
WHERE zone LIKE '%data:image%';

-- 4. T'akod mn anaho tne9a
SELECT 
    id, 
    email, 
    length(raw_user_meta_data::text) AS metadata_size,
    raw_user_meta_data
FROM auth.users
WHERE email = 'noureddinemakboul03@gmail.com';
