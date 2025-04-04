-- ============================================================================
-- FIX: Purge bulky base64 data from auth.users & public.profiles
-- This fixes the "400 Request Header Or Cookie Too Large" error permanently.
-- ============================================================================

-- 1. Clean the admin user metadata (remove bloated base64 avatar and zone)
UPDATE auth.users
SET raw_user_meta_data = jsonb_build_object(
    'full_name', coalesce(raw_user_meta_data->>'full_name', 'Noureddine Makboul'),
    'role', coalesce(raw_user_meta_data->>'role', 'admin'),
    'phone', coalesce(raw_user_meta_data->>'phone', '0725572550')
)
WHERE email = 'noureddinemakboul03@gmail.com'
   OR raw_user_meta_data::text LIKE '%data:image%';

-- 2. Clean all other users in auth.users that might have base64 in metadata
UPDATE auth.users
SET raw_user_meta_data = (raw_user_meta_data - 'avatar_url') - 'zone'
WHERE raw_user_meta_data::text LIKE '%data:image%';

-- 3. Clean any base64 images stored in public.profiles table
UPDATE public.profiles
SET zone = regexp_replace(zone, '\s*\[AVATAR:data:image[^\]]+\]', '', 'g')
WHERE zone LIKE '%data:image%';

UPDATE public.profiles
SET avatar_url = 'https://ui-avatars.com/api/?name=Livreur&background=14307A&color=ffffff&bold=true&size=256'
WHERE avatar_url LIKE 'data:image%' OR length(avatar_url) > 500;

-- 4. Verify clean status
SELECT 
    id, 
    email, 
    length(raw_user_meta_data::text) AS metadata_size,
    raw_user_meta_data
FROM auth.users
WHERE email = 'noureddinemakboul03@gmail.com';
