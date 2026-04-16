import os
from supabase import create_client

# Load environment variables manually if needed or assume they are in environment
url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

if not url or not key:
    print("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")
    exit(1)

supabase = create_client(url, key)

sql = """
-- 1. Profiles table update
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_name TEXT;

-- 2. Update existing display_names from full_name if empty
UPDATE public.profiles SET display_name = full_name WHERE display_name IS NULL;

-- 3. Academic Notes table update
-- Add author_id if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='academic_notes' AND column_name='author_id') THEN
        ALTER TABLE public.academic_notes ADD COLUMN author_id UUID REFERENCES auth.users(id);
    END IF;
END $$;

-- 4. Create a View for Note details that updates automatically
CREATE OR REPLACE VIEW public.notes_with_profiles AS
SELECT 
    n.id,
    n.created_at,
    n.campus_id,
    n.title,
    n.description,
    n.category,
    n.file_url,
    n.pages,
    n.author_id,
    COALESCE(p.display_name, n.author, 'Student') as author_name,
    p.avatar_url as author_avatar
FROM public.academic_notes n
LEFT JOIN public.profiles p ON n.author_id = p.id;

-- Ensure RLS and Grants
GRANT SELECT ON public.notes_with_profiles TO anon, authenticated;
"""

try:
    # Using the standard approach to run SQL if the RPC is enabled
    # If not, we might have issues, but let's try.
    res = supabase.postgrest.rpc('run_sql', {'sql': sql}).execute()
    print('SQL Execution Successful')
except Exception as e:
    print(f'Error executing SQL: {e}')
