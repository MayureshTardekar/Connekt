-- 1. FIX INFINITE RECURSION ERROR IN COMMUNITY MEMBERS
CREATE OR REPLACE FUNCTION is_community_admin(check_community_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM community_members
    WHERE community_id = check_community_id AND user_id = auth.uid() AND role = 'admin'
  );
$$;

DROP POLICY IF EXISTS "Admins can manage members" ON community_members;

CREATE POLICY "Admins can manage members" ON community_members FOR ALL USING (
    is_community_admin(community_id)
);

-- 2. ENSURE ALL GHOST AND COMMUNITY COLUMNS EXIST
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS audio_url TEXT,
ADD COLUMN IF NOT EXISTS audio_duration INTEGER,
ADD COLUMN IF NOT EXISTS shared_card_type TEXT,
ADD COLUMN IF NOT EXISTS shared_data JSONB,
ADD COLUMN IF NOT EXISTS reply_to_id UUID,
ADD COLUMN IF NOT EXISTS reply_to_text TEXT,
ADD COLUMN IF NOT EXISTS reply_to_name TEXT;

ALTER TABLE ghost_posts 
ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS audio_url TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS reply_to_id UUID,
ADD COLUMN IF NOT EXISTS reply_to_text TEXT,
ADD COLUMN IF NOT EXISTS reply_to_name TEXT;

ALTER TABLE community_messages
ADD COLUMN IF NOT EXISTS reply_to_id UUID,
ADD COLUMN IF NOT EXISTS reply_to_text TEXT,
ADD COLUMN IF NOT EXISTS reply_to_name TEXT;

-- 3. LOST & FOUND: image URL from storage (app inserts `image_url` in campus_repository)
ALTER TABLE lost_found
ADD COLUMN IF NOT EXISTS image_url TEXT;
