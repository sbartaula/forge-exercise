import { useEffect, useState } from 'react'
import { X, Plus } from 'lucide-react'

export default function RestTimer({ duration, onDone }) {
  const [remaining, setRemaining] = useState(duration)

  useEffect(() => {
    if (remaining <= 0) {
      onDone()
      return
    }
    const t = setTimeout(() => setRemaining((r) => r - 1), 1000)
    return () => clearTimeout(t)
  }, [remaining, onDone])

  const mm = String(Math.floor(remaining / 60)).padStart(2, '0')
  const ss = String(remaining % 60).padStart(2, '0')
  const pct = duration > 0 ? ((duration - remaining) / duration) * 100 : 0

  return (
    <div className="fixed inset-x-0 bottom-16 z-40 flex justify-center px-4">
      <div className="flex w-full max-w-md items-center gap-3 rounded-2xl border border-white/10 bg-surface2 p-3 shadow-lg">
        <div className="relative h-12 w-12 shrink-0">
          <svg viewBox="0 0 36 36" className="h-full w-full -rotate-90">
            <circle cx="18" cy="18" r="16" fill="none" stroke="currentColor" strokeWidth="4" className="text-white/10" />
            <circle
              cx="18"
              cy="18"
              r="16"
              fill="none"
              stroke="currentColor"
              strokeWidth="4"
              strokeLinecap="round"
              strokeDasharray={2 * Math.PI * 16}
              strokeDashoffset={2 * Math.PI * 16 * (1 - pct / 100)}
              className="text-accent"
            />
          </svg>
        </div>

        <div className="flex-1">
          <p className="text-xs uppercase tracking-wide text-white/40">Rest</p>
          <p className="text-lg font-bold text-white">
            {mm}:{ss}
          </p>
        </div>

        <button
          onClick={() => setRemaining((r) => r + 15)}
          className="flex items-center gap-1 rounded-full bg-surface px-3 py-2 text-xs font-medium text-white/70"
        >
          <Plus size={14} />
          15s
        </button>

        <button onClick={onDone} className="text-white/50">
          <X size={20} />
        </button>
      </div>
    </div>
  )
}
