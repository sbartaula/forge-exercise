// FORGE — send-reminders Edge Function
//
// Invoked once a minute (see schedule.sql in this folder) to check the
// `reminders` table for anything due right now and push a Web Push
// notification to the owning user's stored subscription.
//
// Required secrets (set with `supabase secrets set NAME=value`):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT (e.g. "mailto:you@example.com")
//   REMINDER_TIMEZONE (IANA tz, e.g. "Europe/Helsinki" — defaults to UTC)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-injected by the edge runtime.

import { createClient } from 'npm:@supabase/supabase-js@2'
import webpush from 'npm:web-push@3.6.7'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const VAPID_PUBLIC_KEY = Deno.env.get('VAPID_PUBLIC_KEY')!
const VAPID_PRIVATE_KEY = Deno.env.get('VAPID_PRIVATE_KEY')!
const VAPID_SUBJECT = Deno.env.get('VAPID_SUBJECT') ?? 'mailto:admin@example.com'
const REMINDER_TIMEZONE = Deno.env.get('REMINDER_TIMEZONE') ?? 'UTC'

webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY)

// A reminder's only_on condition matches a "combo" day type too
// (e.g. a 'gym' reminder should still fire on a 'gymfootball' day).
function matchesCondition(onlyOn: string | null, dayType: string | undefined) {
  if (!onlyOn) return true
  if (!dayType) return false
  if (onlyOn === dayType) return true
  if ((onlyOn === 'gym' || onlyOn === 'football') && dayType === 'gymfootball') return true
  return false
}

Deno.serve(async () => {
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const now = new Date()
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-GB', {
      timeZone: REMINDER_TIMEZONE,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      weekday: 'short',
    })
      .formatToParts(now)
      .map((p) => [p.type, p.value]),
  )

  const currentTime = `${parts.hour}:${parts.minute}`
  const currentDate = `${parts.year}-${parts.month}-${parts.day}`
  const currentDay = parts.weekday.toLowerCase().slice(0, 3)

  const { data: reminders, error } = await supabase
    .from('reminders')
    .select('*')
    .eq('is_active', true)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  const due = (reminders ?? []).filter(
    (r) => r.time_of_day.slice(0, 5) === currentTime && r.days?.includes(currentDay),
  )

  if (due.length === 0) {
    return new Response(JSON.stringify({ due: 0, sent: 0 }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const userIds = [...new Set(due.map((r) => r.user_id))]

  const [{ data: dayTypes }, { data: profiles }] = await Promise.all([
    supabase.from('day_type_logs').select('user_id, day_type').eq('log_date', currentDate).in('user_id', userIds),
    supabase.from('profiles').select('id, push_subscription').in('id', userIds),
  ])

  const dayTypeByUser = Object.fromEntries((dayTypes ?? []).map((d) => [d.user_id, d.day_type]))
  const subscriptionByUser = Object.fromEntries((profiles ?? []).map((p) => [p.id, p.push_subscription]))

  let sent = 0
  const errors: Array<{ reminderId: string; error: string }> = []

  for (const reminder of due) {
    if (!matchesCondition(reminder.only_on, dayTypeByUser[reminder.user_id])) continue

    const subscription = subscriptionByUser[reminder.user_id]
    if (!subscription) continue

    try {
      await webpush.sendNotification(
        subscription,
        JSON.stringify({ title: 'FORGE', body: reminder.message || reminder.label, url: '/' }),
      )
      sent += 1
    } catch (err) {
      errors.push({ reminderId: reminder.id, error: String(err) })
      const statusCode = (err as { statusCode?: number })?.statusCode
      if (statusCode === 404 || statusCode === 410) {
        await supabase.from('profiles').update({ push_subscription: null }).eq('id', reminder.user_id)
      }
    }
  }

  return new Response(JSON.stringify({ due: due.length, sent, errors }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
