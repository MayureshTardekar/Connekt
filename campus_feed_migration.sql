-- ============================================================
-- CAMPUS SOCIAL FEED  (run once in Supabase SQL Editor)
-- ============================================================

-- 1. Campus feed posts table (Instagram-style social posts)
CREATE TABLE IF NOT EXISTS campus_feed_posts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campus_id     UUID NOT NULL REFERENCES campuses(id) ON DELETE CASCADE,
  author_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  caption       TEXT,
  image_url     TEXT,                  -- required: the photo
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  likes_count   INT NOT NULL DEFAULT 0
);

-- 2. Feed post likes table
CREATE TABLE IF NOT EXISTS feed_post_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES campus_feed_posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  UNIQUE (post_id, user_id)
);

-- 3. RLS
ALTER TABLE campus_feed_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_post_likes   ENABLE ROW LEVEL SECURITY;

-- Campus members can read all posts for their campus
CREATE POLICY "Members can view feed posts" ON campus_feed_posts
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM campus_members
    WHERE campus_members.campus_id = campus_feed_posts.campus_id
    AND campus_members.user_id = auth.uid()
  )
);

-- Any campus member can create a post
CREATE POLICY "Members can create feed posts" ON campus_feed_posts
FOR INSERT WITH CHECK (
  auth.uid() = author_id AND
  EXISTS (
    SELECT 1 FROM campus_members
    WHERE campus_members.campus_id = campus_feed_posts.campus_id
    AND campus_members.user_id = auth.uid()
  )
);

-- Author or campus creator can delete
CREATE POLICY "Author or creator can delete feed post" ON campus_feed_posts
FOR DELETE USING (
  auth.uid() = author_id
  OR EXISTS (
    SELECT 1 FROM campuses
    WHERE campuses.id = campus_feed_posts.campus_id
    AND campuses.created_by = auth.uid()
  )
);

-- Likes: anyone can insert their own like
CREATE POLICY "Users can like posts" ON feed_post_likes
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Likes: users can delete their own like
CREATE POLICY "Users can unlike posts" ON feed_post_likes
FOR DELETE USING (auth.uid() = user_id);

-- Likes: all authenticated users can read likes
CREATE POLICY "Anyone can read likes" ON feed_post_likes
FOR SELECT USING (auth.uid() IS NOT NULL);

-- 4. View enriched with author profile
CREATE OR REPLACE VIEW campus_feed_posts_with_profiles AS
SELECT 
  cfp.*,
  p.full_name AS author_name,
  p.avatar_url AS author_avatar
FROM campus_feed_posts cfp
LEFT JOIN profiles p ON cfp.author_id = p.id;
