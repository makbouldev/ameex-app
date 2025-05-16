-- ============================================================================
-- ADD is_online & status columns to public.profiles table
-- Run this in Supabase SQL Editor so profiles table natively supports online tracking
-- ============================================================================

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'offline';

-- Optional: Mark any driver who logged in recently as online
-- UPDATE public.profiles SET is_online = true, status = 'online' WHERE role = 'driver';
