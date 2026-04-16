-- FINAL SQL MIGRATION FOR GLOBAL ALIAS & AVATAR SYNC
-- Run this in your Supabase SQL Editor

-- 1. Ensure author_id columns exist in content tables
ALTER TABLE academic_notes ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES auth.users(id);
ALTER TABLE campus_events ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES auth.users(id);

-- 2. Create/Update profiles table to store display_name
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid duplicates
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 4. Create Dynamic Views for Joined Data
-- This ensures name/avatar changes update everywhere automatically.

DROP VIEW IF EXISTS notes_with_profiles CASCADE;
CREATE VIEW notes_with_profiles AS
SELECT 
    n.*,
    p.display_name as author_name,
    p.avatar_url as author_avatar
FROM academic_notes n
LEFT JOIN profiles p ON n.author_id = p.id;

DROP VIEW IF EXISTS events_with_profiles CASCADE;
CREATE VIEW events_with_profiles AS
SELECT 
    e.*,
    p.display_name as author_name,
    p.avatar_url as author_avatar
FROM campus_events e
LEFT JOIN profiles p ON e.author_id = p.id;

-- 5. Grant access to views
GRANT SELECT ON notes_with_profiles TO authenticated;
GRANT SELECT ON events_with_profiles TO authenticated;
GRANT SELECT ON notes_with_profiles TO anon;
GRANT SELECT ON events_with_profiles TO anon;
