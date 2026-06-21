-- ===========================================================================
-- VCloud MVP — initial schema (Phase 1)
-- Run via Supabase SQL editor or `supabase db push`.
-- ===========================================================================

-- ---- profiles (auto-created on auth.users insert) ---------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null unique,
  display_name text not null,
  avatar_url   text,
  created_at   timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data->>'display_name',
      split_part(new.email, '@', 1)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---- chat ------------------------------------------------------------------
create table if not exists public.conversations (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  is_group    boolean not null default false,
  name        text,
  created_by  uuid not null references public.profiles(id)
);
create index if not exists conversations_created_at_idx
  on public.conversations(created_at desc);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  joined_at       timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
create index if not exists conversation_members_user_idx
  on public.conversation_members(user_id);

create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  content         text not null check (char_length(content) between 1 and 4000),
  read_by         jsonb not null default '[]'::jsonb,
  created_at      timestamptz not null default now()
);
create index if not exists messages_conv_created_idx
  on public.messages(conversation_id, created_at desc);

-- mechanical `updated_at` trigger reused by tickets
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

-- ---- attendance ------------------------------------------------------------
create table if not exists public.attendance (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  checkin_time  timestamptz,
  checkout_time timestamptz,
  latitude      double precision,
  longitude     double precision,
  checkin_lat   double precision,
  checkin_lng   double precision,
  created_at    timestamptz not null default now()
);
create index if not exists attendance_user_day_idx
  on public.attendance(user_id, created_at desc);

-- ---- timesheets ------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'timesheet_category') then
    create type public.timesheet_category as enum
      ('ERP','CRM','Meeting','Support','Other');
  end if;
  if not exists (select 1 from pg_type where typname = 'timesheet_duration') then
    create type public.timesheet_duration as enum ('15m','30m','1h','2h');
  end if;
end$$;

create table if not exists public.timesheets (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  task_name   text not null check (char_length(task_name) between 1 and 120),
  category    public.timesheet_category not null,
  duration    public.timesheet_duration not null,
  worked_date date not null default current_date,
  created_at  timestamptz not null default now()
);
create index if not exists timesheets_user_day_idx
  on public.timesheets(user_id, created_at desc);

-- ---- tickets ---------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'ticket_status') then
    create type public.ticket_status as enum ('Todo','Doing','Done');
  end if;
end$$;

create table if not exists public.tickets (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 1 and 120),
  description text,
  status      public.ticket_status not null default 'Todo',
  created_by  uuid not null references public.profiles(id) on delete cascade,
  assigned_to uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists tickets_assigned_status_idx
  on public.tickets(assigned_to, status);
create index if not exists tickets_created_by_idx
  on public.tickets(created_by);

drop trigger if exists tickets_touch on public.tickets;
create trigger tickets_touch before update on public.tickets
  for each row execute function public.touch_updated_at();

-- ---- Row-Level Security ----------------------------------------------------
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.attendance enable row level security;
alter table public.timesheets enable row level security;
alter table public.tickets enable row level security;

-- profiles
drop policy if exists "profiles read" on public.profiles;
create policy "profiles read"
  on public.profiles for select
  using (auth.role() = 'authenticated');

drop policy if exists "profiles self update" on public.profiles;
create policy "profiles self update"
  on public.profiles for update
  using (auth.uid() = id);

-- conversations
drop policy if exists "conv members read" on public.conversations;
create policy "conv members read"
  on public.conversations for select
  using (exists (
    select 1 from public.conversation_members
    where conversation_id = conversations.id and user_id = auth.uid()
  ));

drop policy if exists "conv insert auth" on public.conversations;
create policy "conv insert auth"
  on public.conversations for insert
  with check (auth.role() = 'authenticated');

-- members
drop policy if exists "cm read own or shared" on public.conversation_members;
create policy "cm read own or shared"
  on public.conversation_members for select
  using (
    user_id = auth.uid() or exists (
      select 1 from public.conversation_members m2
      where m2.conversation_id = conversation_members.conversation_id
        and m2.user_id = auth.uid()
    )
  );

drop policy if exists "cm insert self" on public.conversation_members;
create policy "cm insert self"
  on public.conversation_members for insert
  with check (user_id = auth.uid());

-- messages
drop policy if exists "messages read member" on public.messages;
create policy "messages read member"
  on public.messages for select
  using (exists (
    select 1 from public.conversation_members
    where conversation_id = messages.conversation_id
      and user_id = auth.uid()
  ));

drop policy if exists "messages insert self" on public.messages;
create policy "messages insert self"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversation_members
      where conversation_id = messages.conversation_id
        and user_id = auth.uid()
    )
  );

-- self-only resources
drop policy if exists "att self" on public.attendance;
create policy "att self"
  on public.attendance for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "ts self" on public.timesheets;
create policy "ts self"
  on public.timesheets for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- tickets
drop policy if exists "tickets assigned" on public.tickets;
create policy "tickets assigned"
  on public.tickets for select
  using (assigned_to = auth.uid() or created_by = auth.uid());

drop policy if exists "tickets insert self" on public.tickets;
create policy "tickets insert self"
  on public.tickets for insert
  with check (created_by = auth.uid() and assigned_to = auth.uid());

drop policy if exists "tickets update self" on public.tickets;
create policy "tickets update self"
  on public.tickets for update
  using (assigned_to = auth.uid() or created_by = auth.uid())
  with check (assigned_to = auth.uid() or created_by = auth.uid());

drop policy if exists "tickets delete self" on public.tickets;
create policy "tickets delete self"
  on public.tickets for delete
  using (created_by = auth.uid());

-- ---- realtime publications -------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.messages;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.conversations;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.tickets;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.attendance;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.timesheets;
    exception when duplicate_object then null;
    end;
  end if;
end$$;

-- ---- RPC: atomic direct conversation creation ------------------------------
create or replace function public.create_direct_conversation(other_id uuid)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  conv_id uuid;
begin
  -- Look for an existing 1:1 (non-group) conversation between the two users.
  select cm1.conversation_id into conv_id
  from public.conversation_members cm1
  join public.conversation_members cm2
    on cm1.conversation_id = cm2.conversation_id
  where cm1.user_id = auth.uid()
    and cm2.user_id = other_id
    and exists (
      select 1 from public.conversations c
      where c.id = cm1.conversation_id and c.is_group = false
    );

  if conv_id is null then
    insert into public.conversations (created_by, is_group, name)
    values (auth.uid(), false, null)
    returning id into conv_id;

    insert into public.conversation_members (conversation_id, user_id)
      values (conv_id, auth.uid());
    insert into public.conversation_members (conversation_id, user_id)
      values (conv_id, other_id);
  end if;

  return conv_id;
end;
$$;
