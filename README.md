[![CI](https://github.com/frogr/hub/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/frogr/hub/actions/workflows/ci.yml)
[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-blue.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Rails 8.0.2 · Ruby 3.4.4](https://img.shields.io/badge/Rails-8.0.2-blue?logo=ruby-on-rails)](https://rubyonrails.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Good First Issues](https://img.shields.io/github/issues/frogr/hub/good%20first%20issue.svg)](https://github.com/frogr/hub/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
[![Powered by Rails](https://img.shields.io/badge/powered_by-rails-red.svg?logo=ruby-on-rails)](https://rubyonrails.org/)
[![Made with Love](https://img.shields.io/badge/made%20with-%E2%9D%A4%20by%20AustinCo-red.svg)](https://github.com/frogr)

# hub
Hub is an opinionated tool that makes it easy for you to start your own Rails projects. Instead of wasting your first week of development gathering boilerplate, assembling packages, ensuring versions are correct, this repo can be forked, cloned, or otherwise altered to provide a great starting point.

## Prerequisites
- **Ruby** 3.3.x (with `rbenv` or `asdf`)
- **Bundler** `gem install bundler`
- **Node >= 20** and **npm >= 10** (or pnpm/yarn if you prefer)
- **PostgreSQL** 15+
- **Redis** (optional – only when you turn on Solid Queue/Cable)

## Getting Started

```bash
# 1. Clone & bootstrap
git clone https://github.com/frogr/hub.git
cd hub
bundle install
npm install

# 2. ENV
cp .env.example .env

# 3. DB
bin/rails db:prepare

# 4. Run
bin/dev
bundle exec rspec
```

### Environment Variables
| Key | Purpose | Example |
|-----|---------|---------|
| `DATABASE_URL` | Postgres connection | `postgres://hub:secret@localhost/hub_dev` |
| `MAIL_FROM_ADDRESS` | Devise mailer | `no-reply@hub.test` |
| `STRIPE_SECRET_KEY` | Payments (coming soon) | `sk_live_…` |


### Contributing
1. Fork & branch off `main`
2. `bin/setup && bin/rspec` must pass
3. Follow the linter (`bin/rubocop -A`)
4. Open a PR with a succinct title + why

### Roadmap
- [ ] Stripe payments via Pay
- [ ] Optional multi-tenant mode (ActsAsTenant)
- [ ] Observability stack (Sentry + Ahoy/Blazer)
- [ ] Cron & async with Solid Queue
- [ ] JSON API v1
- [ ] Static-site generator for marketing pages
- [ ] Docker & Compose

**Done:**
- Devise for logins, passwordless by default
- PostgresQL DB
- Rspec and Factorybot for quick testing
- Rubocop and Standard for linting
- Tailwindcss for beautiful UI styling
- Turbo and Stimulus
- Latest Ruby and Rails versions, supporting `solid_cache`, `solid_queue`, and `solid_cable`
