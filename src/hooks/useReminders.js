import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from './useAuth'

export function useReminders() {
  const { user } = useAuth()
  const [reminders, setReminders] = useState([])
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    if (!user) return
    setLoading(true)
    const { data } = await supabase
      .from('reminders')
      .select('*')
      .eq('user_id', user.id)
      .order('time_of_day', { ascending: true })
    setReminders(data ?? [])
    setLoading(false)
  }, [user])

  useEffect(() => {
    refresh()
  }, [refresh])

  const addReminder = async (entry) => {
    const { error } = await supabase.from('reminders').insert({ user_id: user.id, ...entry })
    if (error) throw error
    await refresh()
  }

  const updateReminder = async (id, updates) => {
    const { error } = await supabase.from('reminders').update(updates).eq('id', id)
    if (error) throw error
    await refresh()
  }

  const deleteReminder = async (id) => {
    const { error } = await supabase.from('reminders').delete().eq('id', id)
    if (error) throw error
    await refresh()
  }

  const toggleActive = async (reminder) => {
    await updateReminder(reminder.id, { is_active: !reminder.is_active })
  }

  return { reminders, loading, addReminder, updateReminder, deleteReminder, toggleActive }
}
