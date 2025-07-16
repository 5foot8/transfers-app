/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        terminal: {
          '1': '#3B82F6', // blue
          '2': '#10B981', // green
          '3': '#F59E0B', // orange
        }
      }
    },
  },
  plugins: [],
} 