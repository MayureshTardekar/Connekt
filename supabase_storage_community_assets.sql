-- Run in Supabase → SQL Editor (once per project).
-- Fixes: Ghost / Community / Chat / Study uploads to bucket `community_assets`.
--
-- 1) Create public bucket if missing (Dashboard → Storage can also create it).
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('community_assets', 'community_assets', true, 52428800)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- 2) Policies on storage.objects (replace if you already have conflicting names).

DROP POLICY IF EXISTS "community_assets_insert_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "community_assets_select_public" ON storage.objects;
DROP POLICY IF EXISTS "community_assets_update_own" ON storage.objects;
DROP POLICY IF EXISTS "community_assets_delete_own" ON storage.objects;

-- Authenticated users can upload (ghost_images/, ghost_audio/, messages/, chat_images/, study_group_files/, …)
CREATE POLICY "community_assets_insert_authenticated"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'community_assets');

-- Public read (matches getPublicUrl() usage in the app)
CREATE POLICY "community_assets_select_public"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'community_assets');

-- Optional: allow users to replace/delete their own objects (path contains user id)
CREATE POLICY "community_assets_update_own"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'community_assets')
WITH CHECK (bucket_id = 'community_assets');

CREATE POLICY "community_assets_delete_own"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'community_assets');
