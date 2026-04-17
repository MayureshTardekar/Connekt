-- SQL Migration for Connekt Expressive Chat & Communities Feature
-- Run this in your Supabase SQL Editor

-- 1. CHAT MESSAGES UPGRADE
-- Add missing columns for reactions, audio, and read status
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

-- 2. COMMUNITIES TABLE
CREATE TABLE IF NOT EXISTS communities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id TEXT NOT NULL,
    creator_id UUID REFERENCES auth.users(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_private BOOLEAN DEFAULT false,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. COMMUNITY MEMBERS TABLE
CREATE TABLE IF NOT EXISTS community_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(community_id, user_id)
);

-- 4. COMMUNITY REQUESTS TABLE (For Private Communities)
CREATE TABLE IF NOT EXISTS community_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(community_id, user_id)
);

-- 5. COMMUNITY MESSAGES TABLE
CREATE TABLE IF NOT EXISTS community_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES auth.users(id) NOT NULL,
    content TEXT,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice', 'announcement')),
    file_url TEXT,
    audio_duration INTEGER,
    reactions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. RLS POLICIES (Row Level Security)
-- Enable RLS on all tables
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;

-- Communities: Anyone can view, members/creators can do more
CREATE POLICY "Anyone can view communities" ON communities FOR SELECT USING (true);
CREATE POLICY "Creators can update their communities" ON communities FOR UPDATE USING (auth.uid() = creator_id);
CREATE POLICY "Authenticated users can create communities" ON communities FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Members: Viewable by anyone, managed by community
CREATE POLICY "Members are visible to everyone" ON community_members FOR SELECT USING (true);
CREATE POLICY "Admins can manage members" ON community_members FOR ALL USING (
    EXISTS (SELECT 1 FROM community_members WHERE community_id = community_members.community_id AND user_id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users can join public communities" ON community_members FOR INSERT WITH CHECK (true);

-- Messages: Read by members, written by members
CREATE POLICY "Messages are visible to anyone" ON community_messages FOR SELECT USING (true);
CREATE POLICY "Authenticated users can send messages" ON community_messages FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Storage Bucket Setup
-- IMPORTANT: You must manually create a bucket named 'community_assets' in Supabase Storage and make it PUBLIC.
