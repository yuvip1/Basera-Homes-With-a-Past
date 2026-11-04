# Basera Project Operating Instructions (`CLAUDE.md`)

## 1. Operating Rules & Documentation Authority
- **Single Source of Truth:** The authoritative product and research roadmap is located at [docs/roadmap/BASERA-ROADMAP.md](docs/roadmap/BASERA-ROADMAP.md). Do not maintain conflicting roadmap instructions in multiple files.
- **Current State:** The repository is on branch `main` at `C:\Users\yuvra\Desktop\BASERA_`. **Phase 1 (database, RLS, security) is complete and verified.** Phase 2 (authentication bridge) is next. See [docs/phase-handoffs/](docs/phase-handoffs/) for the latest handoff.
- **Scope:** Local portfolio demo first. Native mobile apps, SMS, iCal sync, multi-currency, complex payouts, KYC, insurance, and learned recommenders are **explicitly deferred**.

## 2. Locked Architecture & Boundaries
- **Monorepo:** Turborepo (`frontend`, `backend`, `vision`, `shared`).
- **Frontend (`frontend/`):** Next.js 16 (App Router, TypeScript, Tailwind, shadcn/ui).
- **Backend (`backend/`):** NestJS, OpenAPI/Swagger.
- **Database:** PostgreSQL — local development via Docker Compose (`docker compose up` provides Postgres + Redis); deployed target is Neon. Prisma for schema and ordinary migrations; RLS policies, role grants, and exclusion constraints (e.g. booking date overlaps via `btree_gist`) live in raw-SQL migrations, which are authoritative for those.
- **Auth & Trust Bridge:** Auth.js v5 (Google OAuth + magic link), Passport JWT on backend, transaction-local Postgres session variables via a low-privilege application role.
- **Queues & State:** Upstash Redis + BullMQ with stable job IDs and idempotent workers.
- **Production Vision (`vision/`):** Python, PyTorch, OpenCV, Kornia, FastAPI. Production-ready computer vision only; research code must be deliberately promoted after review.
- **Research (`research/`):** Python, PyTorch, OpenCV, Kornia, FastAPI. Frozen Hashed train/val/test splits (room/house level) before training; recommendation-only model output (never automated accusations). Independent workspace outside pnpm/Turborepo.
- **Testing:** Vitest (unit), Supertest (API integration), Playwright (E2E), optionally pgTAP for SQL policy tests. Real Postgres from Docker Compose for database tests — never SQLite or an in-memory stand-in. The permanent privacy test runs in CI from Phase 1 onward.

## 3. Mandatory Skill Discovery Policy
- **Before task execution:** Discover available installed skills, read relevant instructions, and select only applicable skills. Never invent a skill, treat a similarly named skill as equivalent, or claim one was used unless it was installed, read, and applied.
- **Default coding workflow:** `ponytail` at `full` intensity. Laziness is efficiency (YAGNI, shortest working diff, standard library/native features first); it **never** waives tests, security, learning notes, or bug records.
- **Visuals and analytics:** Use the `dataviz` skill before writing the first line of chart, graph, plot, analytics dashboard, or model-evaluation visualization code.
- **Code exploration:** Use the `smart-explore` skill (AST-based structural search) for code navigation. Use `smart_search(query, path)` to discover symbols across files, `smart_outline(file_path)` for structural skeleton, and `smart_unfold(file_path, symbol_name)` for implementation details. Prefer these over Grep/Glob/Read for code files >100 lines.
- **Task-specific selection:** Read and use relevant architecture, design/frontend, testing, debugging/refactoring, security, research, and documentation skills only when their documented scope matches the task. Repository security, correctness, privacy, and user scope override stylistic or speed-oriented skill guidance.
- **Evidence:** Phase handoff reports must state which skills were discovered, read, and used, what each contributed, and which relevant skills were unavailable or intentionally skipped. Tests and verification remain independent evidence.

## 4. Engineering & Safety Invariants
- **Permanent Privacy Test:** A guest can never read host-to-guest reviews about themselves (tested permanently in CI).
- **Database Overlap Protection:** Postgres exclusion constraints via raw SQL migrations for booking date ranges.
- **Payment Security:** Raw-body signature verification and webhook idempotency.
- **Outbox Pattern:** Transactional outbox for event-driven emails and notifications.
- **Bug Journal:** Every meaningful defect requires an entry in `docs/bug-log.md` and `docs/bugs/BUG-YYYY-NNN-*.md` with reproduction evidence, confirmed root cause, minimal fix, and regression test. See roadmap §3C for the required format.
- **ADR per phase:** One short architecture decision record (context, options, decision, consequences) per phase or material decision, in `docs/adr/`. See roadmap §3A for the required handoff report format.
- **Break-it test per phase:** Each phase's "Done when" is a deliberate-break test; the guard must catch the invalid case with observed evidence before the phase is marked complete.
- **Phase handoff report:** Mandatory before any phase is complete, following roadmap §3A: implemented work, files changed, learning notes, exact verification commands with mock-vs-live status, break-it result, security/privacy checks, known limitations, skills used, and next step. A page loading or a passing mock-only test alone never verifies a real boundary.

## 5. Development Workflow & Commands
- **Commands:** `pnpm install`, `pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm build`, `pnpm --filter backend run generate`, `pnpm --filter backend run migrate`, `pnpm --filter backend run dev`, `pnpm --filter frontend run dev`. Do not invent or infer commands; use the verified ones.
- **Configuration:** All secrets and environment variables live outside source control; `.env.example` carries variable names only.

## 6. Git Authorship and Commit Conventions

### 6.1 Sole Git Attribution
- Use the Git author name and email configured by the repository owner.
- Use the same configured identity for the committer.
- Never add Claude as a Git co-author.
- Never add `Co-authored-by: Claude` or any Claude-related co-author trailer.
- Do not add AI assistant names or email addresses to commit metadata.
- Do not change the repository owner's Git identity without explicit permission.

### 6.2 Commit Message Conventions
Use clear, descriptive Conventional Commit messages.
Examples:
- `feat(phase-0): establish project foundation`
- `feat(phase-1): implement core application`
- `feat(phase-2): implement authentication and authorization`
- `fix(api): resolve authentication validation issue`
- `docs: update project documentation`
- `refactor(web): improve component structure`

### 6.3 Commit Safety
- Never commit without the repository owner's explicit approval.
- Review staged changes using `git diff --cached` before committing.
- Never include secrets, `.env` files, credentials, build artifacts or generated files unless explicitly required.
- Never combine unrelated phases or features into one commit.
- Preserve meaningful phase-wise commit separation when requested.
- Never force-push, reset or rewrite Git history without explicit approval.

### 6.4 Phase-Wise Commit Requirements
When the repository owner requests separate phase commits:
- Identify the exact files belonging to each phase.
- Inspect implementation and dependencies before assigning files.
- Separate Phase 0, Phase 1 and Phase 2 changes.
- Identify shared files and mixed-phase changes.
- Do not guess historical ownership when evidence is unavailable.
- Present the complete staging plan for approval before creating commits.

### 6.5 Verification
Before and after creating approved commits, verify:
```
git config user.name
git config user.email
git log --format=fuller -5
```
Confirm that the configured repository owner's identity is used and no Claude co-author trailer is present.

## 7. Documentation Standards

### 7.1 Documentation Structure
- **Phase Handoffs**: `docs/phase-handoffs/` — Mandatory before any phase is complete. Include chronological, dated entries with unique IDs, linking to relevant ADRs and bug reports.
- **ADRs**: `docs/adr/` — One per phase or material decision. Include architectural decisions and their implementation impacts.
- **Bug Log**: `docs/bug-log.md` and `docs/bugs/` — Permanent record of defects, including symptoms, root cause, fix, affected files, and verification evidence.
- **Roadmap**: `docs/roadmap/BASERA-ROADMAP.md` — Authoritative product and research roadmap.
- **Architecture**: `docs/architecture/` — Only created when genuinely needed for architecture diagrams or documents that cannot be included in ADRs or phase handoffs.

### 7.2 Implementation Documentation
- Record learning notes, internal execution flows, function relationships, API interactions, database operations, and component connections within phase handoffs and ADRs.
- Maintain a chronological implementation log with dated entries and unique IDs, linking to relevant phase handoffs, ADRs, and bug reports.
- Include actual implementation steps, file changes, verification results, and problem documentation.

### 7.3 Problem Documentation
- Record meaningful problems encountered during development, including application bugs, build failures, dependency issues, integration problems, migration failures, and environment/configuration problems.
- Document symptoms, root cause, fix, affected files, and verification evidence. Do not claim a root cause or successful fix without evidence.

### 7.4 Ponytail Skills Usage
- **Ponytail Skills**: Report which skills were discovered, read, and actually used. Explain what each skill contributed. Do not claim a skill was used merely because it is listed in CLAUDE.md.

### 7.5 Code Quality Requirements
- Maintain clean, reusable, strongly typed, robust, and production-quality code.
- Avoid unnecessary files, dependencies, over-engineering, duplicated logic, and long or repetitive implementations.
- Prioritize correctness, security, maintainability, and simplicity over reducing line count.

## 8. Repository Organization Rules
- **Frontend (`frontend/`):** Next.js pages, layouts, React components, hooks, UI, styling, API client integrations. No backend business logic.
- **Backend (`backend/`):** NestJS modules, controllers, services, authentication/authorization, Prisma, business logic, validation, background jobs, API endpoints. No frontend components.
- **Production Vision (`vision/`):** FastAPI app, image-processing services, model inference, production model integration, production tests. Only deliberately reviewed and validated code promoted from `research/` lands here — never automatically.
- **Research (`research/`):** Independent academic workspace for literature, datasets, notebooks, experiments, model evaluations and IEEE paper drafts. Kept out of `pnpm-workspace.yaml` and `turbo.json`. Python dependencies live in isolated venvs and `requirements.txt` files inside `research/`, never in the root Node configuration. See [research/README.md](research/README.md).
- **Documentation (`docs/`):** ADRs → `docs/adr/`, bug reports → `docs/bugs/`, roadmap → `docs/roadmap/`, phase handoffs → `docs/phase-handoffs/`. Architecture diagrams and API docs go to `docs/architecture/` when they exist.
- **Infrastructure:** `docker-compose.yml` stays at the repository root. Deployment scripts and Docker supporting configs belong in `infrastructure/` when they exist.
- **No empty directories:** create a directory only when it has a real purpose or immediate content. Do not scaffold placeholder folders or files to complete a tree.
- **Moves use `git mv`:** preserve history; verify `git status` after every move.
- **One repository:** never initialize a nested Git repository inside `research/`.
- **Cross-phase consistency:** inspect existing implementations before adding features; reuse existing code, utilities, and patterns; avoid duplication; preserve backward compatibility; do not introduce breaking changes without a phase handoff and ADR.