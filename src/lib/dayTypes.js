export const DAY_TYPES = [
  { value: 'gym', label: 'Gym' },
  { value: 'football', label: 'Football' },
  { value: 'gymfootball', label: 'Gym + Football' },
  { value: 'rest', label: 'Rest' },
]

export const TARGET_KCAL_FIELD = {
  gym: 'target_kcal_gym',
  football: 'target_kcal_football',
  gymfootball: 'target_kcal_gymfootball',
  rest: 'target_kcal_rest',
}

export function todayISO() {
  return new Date().toISOString().slice(0, 10)
}

export function addDaysISO(dateISO, delta) {
  const d = new Date(`${dateISO}T00:00:00`)
  d.setDate(d.getDate() + delta)
  return d.toISOString().slice(0, 10)
}
