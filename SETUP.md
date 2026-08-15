# FORGE — Setup Guide

Everything needed to go from this codebase to a working app with a real
database, push notifications, and a deployment.

## 1. Create the Supabase project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard) → **New project**.
2. Pick an org, name it (e.g. `forge`), set a database password (save it somewhere), pick a region close to you.
3. Wait for provisioning (~2 min).
4. In **Project Settings → Data API**, copy the **Project URL**.
5. In **Project Settings → API Keys**, copy the **anon public** key.

## 2. Generate VAPID keys (for push notifications)

VAPID keys let your server prove to the browser it's allowed to send push
notifications to a subscribed device.

```bash
npx web-push generate-vapid-keys
```

This prints a **Public Key** and a **Private Key**. Save both — the private
key is a secret, never commit it.

## 3. Fill in your local `.env`

```bash
cp .env.example .env
```

Edit `.env`:

```
VITE_SUPABASE_URL=<Project URL from step 1>
VITE_SUPABASE_ANON_KEY=<anon public key from step 1>
VITE_VAPID_PUBLIC_KEY=<Public Key from step 2>
```

`.env` is already in `.gitignore` — it will not be committed.

## 4. Run the database migrations

Easiest path (no CLI install): open **SQL Editor** in the Supabase dashboard
and run each file in `supabase/migrations/` **in order** (there's currently
just `001_initial_schema.sql`) — paste the contents, click Run.

Alternative (Supabase CLI):

```bash
npm install -g supabase
supabase login
supabase link --project-ref <your-project-ref>   # found in the project URL
supabase db push
```

This creates all tables, RLS policies, the preloaded food/programme library,
and the `handle_new_user` trigger that seeds a new user's supplements and
reminders automatically on sign-up.

## 5. Install dependencies and run locally

```bash
npm install
npm run dev
```

Open the printed local URL, sign up with an email/password. Check your
email for the Supabase confirmation link (or disable email confirmation in
**Authentication → Providers → Email** for faster local testing), then log
in. You should land on the Dashboard with your seeded supplements ready to
check off.

## 6. Deploy the push-notification Edge Function

Requires the Supabase CLI (see step 4's alternative for install/login/link).

```bash
supabase functions deploy send-reminders
```

Set its secrets (these are server-side only, separate from your `.env`):

```bash
supabase secrets set \
  VAPID_PUBLIC_KEY=<Public Key from step 2> \
  VAPID_PRIVATE_KEY=<Private Key from step 2> \
  VAPID_SUBJECT=mailto:you@example.com \
  REMINDER_TIMEZONE=Europe/Helsinki
```

(`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically —
don't set those yourself.)

## 7. Schedule it to run every minute

Open `supabase/functions/send-reminders/schedule.sql`, replace
`<PROJECT_REF>` and `<SERVICE_ROLE_KEY>` (Project Settings → API Keys →
`service_role`, keep this one secret) with your real values, then paste the
whole file into the SQL Editor and run it once. This enables `pg_cron` +
`pg_net` and schedules a call to your function every minute.

## 8. Enable push notifications in the app

In the app, go to **Admin → Personal Targets → Enable notifications** and
accept the browser permission prompt. This stores your push subscription on
your profile row so the Edge Function can reach your device.

## 9. Deploy to Cloudflare Pages

1. Push this repo to GitHub (see below) if you haven't.
2. In the [Cloudflare dashboard](https://dash.cloudflare.com) → **Workers & Pages → Create → Pages → Connect to Git**, pick the repo.
3. Build settings:
   - Build command: `npm run build`
   - Build output directory: `dist`
4. Add environment variables (same three `VITE_*` values from step 3) under **Settings → Environment variables** for both Production and Preview.
5. Deploy. Cloudflare will redeploy automatically on every push to your production branch.

## Day-to-day: adding more preloaded content later

If you add more preloaded foods/programmes, write a new file
`supabase/migrations/002_...sql` rather than editing `001_initial_schema.sql`
— migrations are meant to be append-only so `supabase db push` stays
predictable.
