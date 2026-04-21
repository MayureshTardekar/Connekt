-- ============================================================
-- CONNEKT DATABASE UPDATE (LATEST FEATURES ONLY)
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. CAMPUS SOCIAL FEED: Table for Instagram-style posts
CREATE TABLE IF NOT EXISTS campus_feed_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id UUID NOT NULL REFERENCES campuses(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    caption TEXT,
    image_url TEXT NOT NULL,
    likes_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS for feed posts
ALTER TABLE campus_feed_posts ENABLE ROW LEVEL SECURITY;

-- Feed Policies
DROP POLICY IF EXISTS "Anyone can view feed posts" ON campus_feed_posts;
CREATE POLICY "Anyone can view feed posts" ON campus_feed_posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert feed posts" ON campus_feed_posts;
CREATE POLICY "Authenticated users can insert feed posts" ON campus_feed_posts FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can delete their own feed posts" ON campus_feed_posts;
CREATE POLICY "Authors can delete their own feed posts" ON campus_feed_posts FOR DELETE USING (
  auth.uid() = author_id
  OR EXISTS (
    SELECT 1 FROM campuses 
    WHERE campuses.id = campus_feed_posts.campus_id 
    AND campuses.created_by = auth.uid()
  )
);

-- Social Feed View with Profile Details
DROP VIEW IF EXISTS campus_feed_posts_with_profiles;
CREATE VIEW campus_feed_posts_with_profiles AS
SELECT 
    cfp.*,
    p.full_name AS author_full_name,
    p.display_name AS author_display_name,
    p.avatar_url AS author_avatar_url
FROM campus_feed_posts cfp
LEFT JOIN profiles p ON cfp.author_id = p.id;

-- 2. CHAT MEDIA & AVATARS: Support for images and profile pictures in messages
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE community_messages ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS sender_avatar TEXT;
ALTER TABLE community_messages ADD COLUMN IF NOT EXISTS sender_avatar TEXT;
