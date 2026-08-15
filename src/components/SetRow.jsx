import { Check, Trash2 } from 'lucide-react'

export default function SetRow({
  index,
  set,
  placeholder,
  onChangeKg,
  onChangeReps,
  onToggleComplete,
  onRemove,
  canRemove,
}) {
  return (
    <div className="flex items-center gap-2">
      <span className="w-5 text-center text-xs text-white/40">{index + 1}</span>

      <input
        type="number"
        inputMode="decimal"
        value={set.kg}
        onChange={(e) => onChangeKg(e.target.value)}
        placeholder={placeholder?.kg != null ? String(placeholder.kg) : '—'}
        className="w-16 rounded-lg border border-white/10 bg-surface2 px-2 py-2 text-center text-white outline-none focus:border-accent"
      />
      <span className="text-xs text-white/30">kg ×</span>
      <input
        type="number"
        inputMode="numeric"
        value={set.reps}
        onChange={(e) => onChangeReps(e.target.value)}
        placeholder={placeholder?.reps != null ? String(placeholder.reps) : '—'}
        className="w-16 rounded-lg border border-white/10 bg-surface2 px-2 py-2 text-center text-white outline-none focus:border-accent"
      />
      <span className="text-xs text-white/30">reps</span>

      <button
        onClick={onToggleComplete}
        className={`ml-auto flex h-8 w-8 items-center justify-center rounded-full border ${
          set.completed ? 'border-accent bg-accent text-black' : 'border-white/20 text-transparent'
        }`}
      >
        <Check size={16} />
      </button>

      {canRemove && (
        <button onClick={onRemove} className="text-white/30 hover:text-red-400">
          <Trash2 size={16} />
        </button>
      )}
    </div>
  )
}
