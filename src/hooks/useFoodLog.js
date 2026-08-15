import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from './useAuth'

export function useFoodLog(logDate) {
  const { user } = useAuth()
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    if (!user) return
    setLoading(true)
    const { data, error } = await supabase
      .from('food_logs')
      .select('*')
      .eq('user_id', user.id)
      .eq('log_date', logDate)
      .order('created_at', { ascending: true })

    if (!error) setLogs(data ?? [])
    setLoading(false)
  }, [user, logDate])

  useEffect(() => {
    refresh()
  }, [refresh])

  const totals = logs.reduce(
    (acc, log) => ({
      kcal: acc.kcal + Number(log.kcal),
      protein_g: acc.protein_g + Number(log.protein_g),
      carbs_g: acc.carbs_g + Number(log.carbs_g),
      fat_g: acc.fat_g + Number(log.fat_g),
    }),
    { kcal: 0, protein_g: 0, carbs_g: 0, fat_g: 0 },
  )

  const addLog = async (entry) => {
    const { error } = await supabase.from('food_logs').insert({
      user_id: user.id,
      log_date: logDate,
      ...entry,
    })
    if (error) throw error
    await refresh()
  }

  const updateLog = async (id, updates) => {
    const { error } = await supabase.from('food_logs').update(updates).eq('id', id)
    if (error) throw error
    await refresh()
  }

  const deleteLog = async (id) => {
    const { error } = await supabase.from('food_logs').delete().eq('id', id)
    if (error) throw error
    await refresh()
  }

  return { logs, totals, loading, addLog, updateLog, deleteLog, refresh }
}
