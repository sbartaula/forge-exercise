-- Run this once in the Supabase SQL editor (NOT part of the automatic
-- migration set — it embeds project-specific values you must fill in first).
--
-- 1. Deploy the function:      supabase functions deploy send-reminders
-- 2. Set its secrets:          supabase secrets set VAPID_PUBLIC_KEY=... VAPID_PRIVATE_KEY=... VAPID_SUBJECT=mailto:you@example.com REMINDER_TIMEZONE=Europe/Helsinki
-- 3. Replace <PROJECT_REF> and <SERVICE_ROLE_KEY> below, then run this file.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'send-reminders-every-minute',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-reminders',
    headers := jsonb_build_object(
      'Authorization', 'Bearer <SERVICE_ROLE_KEY>',
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- To stop the schedule later:
-- select cron.unschedule('send-reminders-every-minute');
