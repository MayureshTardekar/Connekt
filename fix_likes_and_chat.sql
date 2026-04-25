-- =============================================================================
-- FINAL DATABASE STABILIZATION & LIKES SCHEMA FIX
-- =============================================================================

-- 1) Ensure all content tables have likes_count columns
ALTER TABLE public.academic_notes ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0;
ALTER TABLE public.campus_events ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0;
ALTER TABLE public.lost_found ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0;
ALTER TABLE public.campus_feed_posts ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0;
ALTER TABLE public.ghost_posts ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0;
ALTER TABLE public.ghost_posts ADD COLUMN IF NOT EXISTS likes INT DEFAULT 0; -- For GhostPost model compatibility

-- 2) Create missing Like tables
-- Note Likes
CREATE TABLE IF NOT EXISTS public.note_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES public.academic_notes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(note_id, user_id)
);

-- Event Likes
CREATE TABLE IF NOT EXISTS public.event_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.campus_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

-- Lost & Found Likes
CREATE TABLE IF NOT EXISTS public.lost_found_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES public.lost_found(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(item_id, user_id)
);

-- Ghost Likes
CREATE TABLE IF NOT EXISTS public.ghost_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.ghost_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(post_id, user_id)
);

-- Feed Post Likes (Ensure it exists)
CREATE TABLE IF NOT EXISTS public.feed_post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.campus_feed_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(post_id, user_id)
);

-- 3) Fix Chat Schema for "Advanced" features
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS audio_url TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS audio_duration INT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS shared_card_type TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS shared_data JSONB;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.chat_messages(id);
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS reply_to_text TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS reply_to_name TEXT;

-- Ensure chat_conversations has is_archived
ALTER TABLE public.chat_conversations ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT false;

-- 4) Create missing messages table if it was renamed/lost to prevent crashes
-- The user mentioned "messages" table missing. If the app still refers to it anywhere:
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id),
    receiver_id UUID REFERENCES auth.users(id),
    text TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5) RLS Policies (Minimum to allow testing)
-- We enable RLS and add basic policies so authenticated users can interact.
ALTER TABLE public.note_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lost_found_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ghost_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_post_likes ENABLE ROW LEVEL SECURITY;

-- Note: In production, these should be more restrictive, but for stabilization we allow authenticated users.
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated likes' AND tablename = 'note_likes') THEN
        CREATE POLICY "Allow authenticated likes" ON public.note_likes FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated likes' AND tablename = 'event_likes') THEN
        CREATE POLICY "Allow authenticated likes" ON public.event_likes FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated likes' AND tablename = 'lost_found_likes') THEN
        CREATE POLICY "Allow authenticated likes" ON public.lost_found_likes FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated likes' AND tablename = 'ghost_likes') THEN
        CREATE POLICY "Allow authenticated likes" ON public.ghost_likes FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated likes' AND tablename = 'feed_post_likes') THEN
        CREATE POLICY "Allow authenticated likes" ON public.feed_post_likes FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;

-- Allow a student to leave their current campus so they can join another one.
-- Required if RLS is enabled on public.campus_members.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'campus_members'
          AND policyname = 'Users can leave their campus'
    ) THEN
        CREATE POLICY "Users can leave their campus"
        ON public.campus_members
        FOR DELETE
        TO authenticated
        USING (auth.uid() = user_id);
    END IF;
END $$;

-- 6) Ghost Posts missing author_name? (Sometimes needed for models)
ALTER TABLE public.ghost_posts ADD COLUMN IF NOT EXISTS author_name TEXT DEFAULT 'Ghost';
