const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Space Grotesk"', ...defaultTheme.fontFamily.sans],
        mono: ['"JetBrains Mono"', ...defaultTheme.fontFamily.mono],
      },
      colors: {
        ck: {
          bg:        'var(--ck-bg)',
          card:      'var(--ck-card)',
          raised:    'var(--ck-raised)',
          ink:       'var(--ck-ink)',
          accent:    'var(--ck-accent)',
          secondary: 'var(--ck-secondary)',
          muted:     'var(--ck-muted)',
          line:      'var(--ck-line)',
        }
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
