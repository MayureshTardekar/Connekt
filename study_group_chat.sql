-- =============================================================================
-- Study Groups + Chat (Supabase SQL Editor)
-- =============================================================================
-- A app usa: study_groups, study_group_members, study_group_messages
-- Se já criaste só study_group_messages e deu erro, executa antes:
--   DROP TABLE IF EXISTS public.study_group_messages;
-- =============================================================================

-- 1) Grupos de estudo
create table if not exists public.study_groups (
  id uuid primary key default gen_random_uuid(),
  campus_id uuid not null,
  creator_id uuid not null references auth.users (id) on delete cascade,
  creator_name text,
  subject text not null default '',
  description text default '',
  date_time timestamptz not null default now(),
  location text not null default '',
  max_members int not null default 5
    check (max_members >= 2 and max_members <= 50),
  member_count int not null default 1
    check (member_count >= 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_study_groups_campus
  on public.study_groups (campus_id);

create index if not exists idx_study_groups_created
  on public.study_groups (created_at desc);

-- 2) Membros (pending / approved)
create table if not exists public.study_group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.study_groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create index if not exists idx_study_group_members_group
  on public.study_group_members (group_id);

create index if not exists idx_study_group_members_user
  on public.study_group_members (user_id);

-- 3) Mensagens + fixar + reações
create table if not exists public.study_group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.study_groups (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  message_type text not null default 'text'
    check (message_type in ('text', 'image', 'file')),
  content text,
  file_url text,
  file_name text,
  reply_to_id uuid references public.study_group_messages (id) on delete set null,
  reactions jsonb not null default '{}'::jsonb,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_study_group_messages_group
  on public.study_group_messages (group_id, created_at desc);

-- =============================================================================
-- RLS (ajusta à tua política de campus). Exemplo mínimo para desenvolvimento:
-- =============================================================================
-- alter table public.study_groups enable row level security;
-- alter table public.study_group_members enable row level security;
-- alter table public.study_group_messages enable row level security;
--
-- create policy "study_groups_read" on public.study_groups
--   for select to authenticated using (true);
-- create policy "study_groups_insert" on public.study_groups
--   for insert to authenticated with check (auth.uid() = creator_id);
-- create policy "study_groups_update" on public.study_groups
--   for update to authenticated using (auth.uid() = creator_id);
--
-- create policy "members_read" on public.study_group_members
--   for select to authenticated using (true);
-- create policy "members_write" on public.study_group_members
--   for all to authenticated using (true) with check (true);
--
-- create policy "msg_read" on public.study_group_messages
--   for select to authenticated using (true);
-- create policy "msg_insert" on public.study_group_messages
--   for insert to authenticated with check (auth.uid() = sender_id);
-- create policy "msg_update" on public.study_group_messages
--   for update to authenticated using (true);
-- create policy "msg_delete" on public.study_group_messages
--   for delete to authenticated using (auth.uid() = sender_id);
