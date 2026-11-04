# Basera — Heritage Homestay Booking Platform

A heritage-stay marketplace with a host-only guest reputation dossier, plus an independent research track on safe image-based property condition verification. Built as a local portfolio demo first; not a public beta.

> The authoritative product and research roadmap lives in [docs/roadmap/BASERA-ROADMAP.md](docs/roadmap/BASERA-ROADMAP.md). Repository operating rules live in [CLAUDE.md](CLAUDE.md).

## Architecture

Turborepo + pnpm monorepo. Four production workspaces and one independent research workspace.

```
frontend/        Next.js 16 (App Router, TypeScript, Tailwind) — frontend
backend/         NestJS + Prisma + PostgreSQL — backend, business logic, RLS
vision/          FastAPI + PyTorch — production computer-vision service (placeholder; built at Phase 11)
shared/          Shared TypeScript contracts (placeholder; filled when a real consumer exists)
research/        Independent academic workspace — see research/README.md
docs/            ADRs, bug journal, roadmap, phase handoffs
```

| Directory | Purpose |
|---|---|
| `frontend/` | All frontend code: pages, layouts, components, hooks, styling, API client integrations. No backend business logic. |
| `backend/` | All backend code: NestJS modules, controllers, services, auth, Prisma schema and migrations, validation, background jobs, API endpoints. No frontend components. |
| `vision/` | Production-ready computer vision only: FastAPI app, image-processing services, model inference, production tests. Code is promoted here deliberately after review — never automatically from `research/`. |
| `shared/` | TypeScript contracts shared between `frontend` and `backend`. Created when the first real consumer needs it. |
| `research/` | Literature, datasets, notebooks, experiments, model evaluations, IEEE paper drafts. Isolated Python environments. Outside the pnpm/Turborepo graph. |
| `docs/adr` | Architecture Decision Records, one per phase or material decision. |
| `docs/bugs` | Source-backed bug journal; index in [docs/bug-log.md](docs/bug-log.md). |
| `docs/roadmap` | The single authoritative roadmap. |
| `docs/phase-handoffs` | Mandatory per-phase handoff reports. |
| `docker-compose.yml` | Local PostgreSQL 16 + Redis 7. Stays at the repository root. |

## Stack

| Layer | Choice |
|---|---|
| Monorepo | Turborepo + pnpm |
| Frontend | Next.js 16, TypeScript, Tailwind |
| Backend | NestJS, Prisma, PostgreSQL (Docker Compose local / Neon target) |
| Auth | Auth.js v5 + Passport JWT trust bridge (Phase 2) |
| Queues | Upstash Redis + BullMQ (Phase 6) |
| Research | Python, PyTorch, OpenCV, Kornia, FastAPI |

Database invariants enforced in raw-SQL migrations (authoritative for RLS, role grants and exclusion constraints): a guest can never read host-to-guest reputation reviews about themselves, while published guest-to-property reviews remain publicly readable. Booking date overlaps are blocked by a Postgres exclusion constraint.

## Getting started

```bash
pnpm install
docker compose up -d          # Postgres + Redis
cp env.example .env           # fill in local values; never commit .env
pnpm --filter backend run generate
pnpm --filter backend run migrate
pnpm dev                      # or: pnpm --filter frontend run dev / --filter backend run dev
```

Verification commands: `pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm build`.

## Status

Phase 0 (foundations) and Phase 1 (database + RLS) are complete and verified. Phase 2 (authentication and the JWT-to-Postgres bridge) is next. See [docs/phase-handoffs/](docs/phase-handoffs/) for completed phase reports.