import { NavLink } from 'react-router-dom'
import { Home, Utensils, Dumbbell, LineChart, Settings } from 'lucide-react'

const TABS = [
  { to: '/', label: 'Home', icon: Home, end: true },
  { to: '/nutrition', label: 'Nutrition', icon: Utensils },
  { to: '/workout', label: 'Workout', icon: Dumbbell },
  { to: '/progress', label: 'Progress', icon: LineChart },
  { to: '/admin', label: 'Admin', icon: Settings },
]

export default function Nav() {
  return (
    <nav className="safe-bottom fixed inset-x-0 bottom-0 z-50 border-t border-white/10 bg-surface">
      <div className="mx-auto flex max-w-md justify-between px-2">
        {TABS.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              `flex flex-1 flex-col items-center gap-1 py-2.5 text-[11px] font-medium transition ${
                isActive ? 'text-accent' : 'text-white/40'
              }`
            }
          >
            <Icon size={22} strokeWidth={2} />
            {label}
          </NavLink>
        ))}
      </div>
    </nav>
  )
}
