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

-- 3. LOST & FOUND: image URL from storage
ALTER TABLE lost_found
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 4. CAMPUS SECURITY: Add join_pin for campus gatekeeping
ALTER TABLE campuses
ADD COLUMN IF NOT EXISTS join_pin TEXT;

-- 5. CAMPUS ENGAGEMENT: Ensure lost_found has campus_id
ALTER TABLE lost_found
ADD COLUMN IF NOT EXISTS campus_id UUID;

-- 6. VIEWS: Ensure profile data joins for Dashboard/Tabs
DROP VIEW IF EXISTS notes_with_profiles;
CREATE VIEW notes_with_profiles AS
SELECT n.*, p.full_name as author_name, p.avatar_url as author_avatar
FROM academic_notes n
LEFT JOIN profiles p ON n.author_id = p.id;

DROP VIEW IF EXISTS events_with_profiles;
CREATE VIEW events_with_profiles AS
SELECT e.*, p.full_name as author_name, p.avatar_url as author_avatar
FROM campus_events e
LEFT JOIN profiles p ON e.author_id = p.id;

-- 7. STUDY GROUPS: UNLOCK (Fixes RLS Forbidden Error)
ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_group_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view study groups" ON study_groups;
CREATE POLICY "Anyone can view study groups" ON study_groups FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth users can create study groups" ON study_groups;
CREATE POLICY "Auth users can create study groups" ON study_groups FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Members can view membership" ON study_group_members;
CREATE POLICY "Members can view membership" ON study_group_members FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can join study groups" ON study_group_members;
CREATE POLICY "Users can join study groups" ON study_group_members FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 8. STUDY GROUPS NAMES: Ensure names are tracked
ALTER TABLE study_group_messages ADD COLUMN IF NOT EXISTS sender_name TEXT;

-- 9. ACADEMIC NOTES: Fix updated_at and Delete Policy
ALTER TABLE academic_notes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

DROP POLICY IF EXISTS "Authors can delete their own notes" ON academic_notes;
CREATE POLICY "Authors can delete their own notes" ON academic_notes 
FOR DELETE USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can update their own notes" ON academic_notes;
CREATE POLICY "Authors can update their own notes" ON academic_notes 
FOR UPDATE USING (auth.uid() = author_id);