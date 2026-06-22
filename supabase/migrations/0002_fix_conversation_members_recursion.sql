-- ===========================================================================
-- Fix infinite recursion (Postgres 42P17) in conversation_members RLS
-- ===========================================================================
--
-- Symptom (from app):
--   PostgrestException(message: infinite recursion detected in policy for
--   relation "conversation_members", code: 42P17)
--
-- Root cause:
--   Migration 0001 defined a SELECT policy on public.conversation_members
--   whose USING expression self-referenced the SAME table:
--
--     create policy "cm read own or shared"
--       on public.conversation_members for select
--       using (
--         user_id = auth.uid() or exists (
--           select 1 from public.conversation_members m2
--           where m2.conversation_id = conversation_members.conversation_id
--             and m2.user_id = auth.uid()
--         )
--       );
--
--   To evaluate that inner SELECT Postgres re-applies conversation_members'
--   own policies, including the one above, which re-runs the inner SELECT,
--   and so on. Postgres detects the cycle and aborts with 42P17.
--
--   The other two policies that did a non-self EXISTS join against
--   conversation_members — on conversations and messages — then fail too,
--   because *every* access to conversation_members routes through the
--   recursive policy.
--
-- Fix:
--   Hoist the membership lookup into a SECURITY DEFINER function. SECURITY
--   DEFINER runs as the function owner (postgres), so its inner SELECT
--   bypasses RLS and the cycle is broken at the source.
--
--   We rewrite all three policies to use the helper so the codebase stays
--   uniform and avoids the same trap if anyone later adds another policy
--   that needs the conversation_members lookup.

-- ---- helper function (SECURITY DEFINER bypasses RLS) ----------------------
create or replace function public.am_conversation_member(conv_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.conversation_members
    where conversation_id = conv_id
      and user_id = auth.uid()
  );
$$;

-- Revoke EXECUTE from anon and authenticated so it can't be abused outside
-- of RLS evaluation; the function marks itself trusted via SECURITY DEFINER.
revoke all on function public.am_conversation_member(uuid) from public;
grant execute on function public.am_conversation_member(uuid) to authenticated;

-- ---- conversations: see a conversation only if you're a member ----------
drop policy if exists "conv members read" on public.conversations;
create policy "conv members read"
  on public.conversations for select
  using (public.am_conversation_member(conversations.id));

-- ---- conversation_members: see your own row, or rows from any
--      conversation you're a member of (the originally-recursive one) -----
drop policy if exists "cm read own or shared" on public.conversation_members;
create policy "cm read own or shared"
  on public.conversation_members for select
  using (
    user_id = auth.uid()
    or public.am_conversation_member(conversation_members.conversation_id)
  );

-- ---- messages: read messages from any conversation you're a member of ---
drop policy if exists "messages read member" on public.messages;
create policy "messages read member"
  on public.messages for select
  using (public.am_conversation_member(messages.conversation_id));
