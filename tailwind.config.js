/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        base: '#0a0a0a',
        surface: '#151515',
        surface2: '#1e1e1e',
        accent: '#c8f135',
      },
    },
  },
  plugins: [],
}
