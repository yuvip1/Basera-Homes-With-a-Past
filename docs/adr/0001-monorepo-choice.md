# ADR 0001: Monorepo vs Single App

## Context
Basera combines two independently large goals: a production-style heritage-stay marketplace and a research project on safe image-based condition verification. A single app would skip all three service boundaries, API contracts, and service-to-service auth that constitute the learning.

## Decision
Use a Turborepo monorepo with four packages:
- `apps/web` — Next.js 16 frontend (App Router)
- `apps/api` — NestJS backend with OpenAPI/Swagger
- `apps/vision` — Python/FastAPI research service
- `packages/shared` — shared TypeScript types and utilities

## Consequences
- Service boundaries and API contracts are the learning; a single app skips all three
- Local dev mirrors production infrastructure (Docker Compose Postgres + Redis) instead of SQLite or mocks
- Each package has independent versioning and deployment pipeline

## Status
Adopted. First ADR for the project.