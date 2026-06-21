#!/usr/bin/env bash
#
# Apply the VCloud database migration to a Supabase project.
#
# Why this exists: executing SQL via the project's `pg-meta` endpoint
# requires the secret key, which must NEVER be stored on developers'
# machines or in source control. Use one of two paths:
#
#   1. Manually: open Supabase dashboard → SQL editor →
#      paste `supabase/migrations/0001_init.sql` → run.
#
#   2. CLI: install supabase CLI, link the project, then run:
#        supabase db push
#
# This script prints the dashboard URL and the file so you don't have
# to remember them.

cat <<'EOF'

=== VCloud migration ===

Manual path (recommended for first run):
   1. Open:
      https://supabase.com/dashboard/project/ccjldpmsvzxudqjemtkw/sql/new
   2. Copy the contents of supabase/migrations/0001_init.sql
   3. Paste → Run

Or with the Supabase CLI:
   supabase login
   supabase link --project-ref ccjldpmsvzxudqjemtkw
   supabase db push

Remember: in the dashboard go to
   Authentication → Providers → Email
and DISABLE "Confirm email" for the MVP.

Authentication → URL Configuration:
   Redirect URLs: vcloud://login-callback

EOF
