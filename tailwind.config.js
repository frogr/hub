module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'primary': {
          900: '#210F37', // Deep purple
          800: '#2F1646',
          700: '#3D1D55',
          600: '#4F1C51', // Medium purple
          500: '#6B2870',
          400: '#87348F',
          300: '#A340AE',
          200: '#C366D0',
          100: '#E39EED',
          50: '#F5D9F9',
        },
        'accent': {
          900: '#7A3E35',
          800: '#8F4A3F',
          700: '#A55B4B', // Warm terracotta
          600: '#B36D5F',
          500: '#C17F73',
          400: '#CF9187',
          300: '#DDA39B',
          200: '#E5BDB5',
          100: '#EDD7CF',
          50: '#F7ECE8',
        },
        'gold': {
          900: '#8A5E3B',
          800: '#A87247',
          700: '#C68653',
          600: '#DCA06D', // Warm gold
          500: '#E4B488',
          400: '#ECC8A3',
          300: '#F0D2B3',
          200: '#F4DCC3',
          100: '#F8E6D3',
          50: '#FCF5EC',
        },
        'neutral': {
          950: '#0A0A0A',
          900: '#171717',
          800: '#262626',
          700: '#404040',
          600: '#525252',
          500: '#737373',
          400: '#A3A3A3',
          300: '#D4D4D4',
          200: '#E5E5E5',
          100: '#F5F5F5',
          50: '#FAFAFA',
        },
        'surface': {
          DEFAULT: '#FFFFFF',
          soft: '#FAFAFA',
          raised: '#FFFFFF',
        },
        'success': '#10B981',
        'warning': '#F59E0B',
        'error': '#EF4444',
        'info': '#3B82F6',
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', 'Inter', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'],
        mono: ['SF Mono', 'Monaco', 'Consolas', 'Liberation Mono', 'Courier New', 'monospace'],
      },
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1.125rem' }],
        'sm': ['0.875rem', { lineHeight: '1.375rem' }],
        'base': ['1rem', { lineHeight: '1.625rem' }],
        'lg': ['1.125rem', { lineHeight: '1.875rem' }],
        'xl': ['1.25rem', { lineHeight: '2rem' }],
        '2xl': ['1.5rem', { lineHeight: '2.25rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.5rem' }],
        '4xl': ['2.25rem', { lineHeight: '3rem' }],
        '5xl': ['3rem', { lineHeight: '3.75rem' }],
        '6xl': ['3.75rem', { lineHeight: '4.5rem' }],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      borderRadius: {
        'sm': '0.25rem',
        'DEFAULT': '0.5rem',
        'md': '0.625rem',
        'lg': '0.875rem',
        'xl': '1rem',
        '2xl': '1.25rem',
        '3xl': '1.5rem',
      },
      boxShadow: {
        'xs': '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        'sm': '0 2px 4px -1px rgb(0 0 0 / 0.07), 0 1px 2px -1px rgb(0 0 0 / 0.03)',
        'DEFAULT': '0 4px 6px -2px rgb(0 0 0 / 0.05), 0 2px 4px -2px rgb(0 0 0 / 0.03)',
        'md': '0 6px 10px -3px rgb(0 0 0 / 0.04), 0 3px 6px -3px rgb(0 0 0 / 0.02)',
        'lg': '0 10px 15px -3px rgb(0 0 0 / 0.08), 0 4px 6px -4px rgb(0 0 0 / 0.02)',
        'xl': '0 20px 25px -5px rgb(0 0 0 / 0.08), 0 8px 10px -6px rgb(0 0 0 / 0.02)',
        '2xl': '0 25px 50px -12px rgb(0 0 0 / 0.12)',
        'inner': 'inset 0 2px 4px 0 rgb(0 0 0 / 0.05)',
        'none': 'none',
        // Skeuomorphic shadows
        'neumorphic': '20px 20px 60px #d9d9d9, -20px -20px 60px #ffffff',
        'neumorphic-sm': '5px 5px 15px #d9d9d9, -5px -5px 15px #ffffff',
        'neumorphic-inset': 'inset 5px 5px 10px #d9d9d9, inset -5px -5px 10px #ffffff',
      },
      backgroundImage: {
        'gradient-primary': 'linear-gradient(135deg, #4F1C51 0%, #210F37 100%)',
        'gradient-accent': 'linear-gradient(135deg, #DCA06D 0%, #A55B4B 100%)',
        'gradient-subtle': 'linear-gradient(180deg, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0) 100%)',
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.9)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}