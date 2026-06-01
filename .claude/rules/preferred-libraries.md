---
---

# Preferred OSS Libraries

## Go
- DI: `samber/do/v2`
- Functional utils: `samber/lo`
- HTTP: `gofiber/fiber/v2`
- GraphQL: `99designs/gqlgen` (schema-first)
- ORM: `gorm.io/gorm` + `gorm.io/gen`
- PostgreSQL: `jackc/pgx/v5`
- Validation: `go-playground/validator/v10`
- Job queue: `riverqueue/river`
- JWT/JOSE: `lestrrat-go/jwx`
- CLI: `urfave/cli/v3`
- CloudSQL: `cloud.google.com/go/cloudsqlconn` (Go connector with IAM auth)

## Frontend (SSR Go) — PREFERRED for new frontends
- HTTP: `gofiber/fiber/v2`
- Templates: `html/template` (stdlib) + `embed.FS` for view assets
- Interactivity: HTMX 2.x (`htmx.org`)
- Styling: Tailwind CSS (CDN for prototypes, CLI build for prod)
- Forms/validation: `go-playground/validator/v10` server-side
- Sessions: encrypted cookies via fiber middleware
- Auth: OIDC via `coreos/go-oidc/v3` + `golang.org/x/oauth2`

Use SSR Go as the default frontend stack. Reach for the React stack
below only when the app genuinely needs heavy client-side state, offline
support, or a rich interactive canvas that HTMX cannot serve.

## Frontend (React/TypeScript) — only when SSR insufficient
- Framework: React 19, React Router 7
- GraphQL: Apollo Client 4
- UI: MUI v7 + Emotion
- State: Zustand 5 (client), Apollo cache (server)
- Validation: Zod 4
- i18n: i18next + react-i18next
- REST clients: openapi-fetch
- Charts: Recharts 3
- Dates: date-fns 4

## Infrastructure
- IaC: Terraform (hashicorp/google, hashicorp/google-beta)
- Cloud: Google Cloud Platform
- Reverse proxy: Caddy
