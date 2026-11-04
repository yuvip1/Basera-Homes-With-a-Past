# Basera: Final Learning Roadmap
*Two tracks, one goal: understand every layer. Entirely free-tier. Built on the 15-phase plan, with the research layer promoted from one late phase to a full track.*

> **Authority:** This is the repository's single authoritative product and research roadmap.
> **Current status:** Phase 1 (database, RLS, security) is complete and verified. Phase 2 (authentication bridge) is next. See [docs/phase-handoffs/](docs/phase-handoffs/) for the latest handoff.
> **Target:** Local portfolio demo first. Expansion milestones are gates within the original dependency path, not permission to start future work early.

**Implementation standard:** Every phase follows the mandatory Claude Code, Ponytail-skill, clean-code, testing, security, and phase-handoff rules in Sections 3A–3B. A phase is not complete merely because it runs once.

---

## 1. What came from where

| Decision | Source | Why |
|---|---|---|
| Turborepo, NestJS API, separate Python vision service | Doc 1 | Service boundaries, API contracts and service-to-service auth are the learning. A single app skips all three. |
| Hand-written RLS and the JWT-to-Postgres bridge | Doc 1 | The mechanism managed platforms hide from you. |
| Queue phase, testing pyramid, CI/CD, observability, OWASP pass, deployment | Doc 1 | Doc 2 dropped these, but they are where production habits come from. |
| ADR per phase, permanent privacy tests, booking status enum, 48h payment expiry | Doc 2 | Concrete and testable. |
| DPDP checklist, retention policy, audit log, kill switch | Doc 2 | Real compliance work. Expanded in Phase 10. |
| Consent, abstention below a confidence threshold, human review, "recommend, never accuse" | Doc 2 | Doc 1's single vision phase is too thin for a paper. |
| Next.js 16 instead of 15 | Doc 2 | Current version. Note the async request APIs (`params`, `cookies`, `headers`). Confirm the version when you scaffold. |
| Minimal CI from Phase 0 | New | Catch drift early instead of in Phase 12. |
| Research track starts on day one | New | Data collection and consent take calendar time, not coding time. |

---

## 2. Locked stack

| Layer | Choice |
|---|---|
| Monorepo | Turborepo (`frontend`, `backend`, `vision`, `shared`) |
| Frontend | Next.js 16 (App Router, TypeScript, Tailwind, shadcn/ui) |
| Backend | NestJS, OpenAPI/Swagger |
| Database | PostgreSQL on Neon, Prisma, raw-SQL migrations for RLS and constraints |
| Auth | Auth.js v5 (Google OAuth + magic link), Passport JWT on the backend |
| Queues | Upstash Redis + BullMQ |
| Payments / Email / Images / Maps | Razorpay (test) / Resend / Cloudinary / Leaflet + OSM |
| Testing | Vitest, Supertest, Playwright, optionally pgTAP for SQL policy tests |
| CI/CD, Observability | GitHub Actions, Sentry + Pino |
| Local dev | Docker Compose (Postgres + Redis) |
| **Research** | Python, PyTorch, OpenCV, kornia, FastAPI |
| **Research tooling** | CVAT or Label Studio (annotation), MLflow or Weights & Biases (experiment tracking), DVC or hashed manifests (data versioning) |
| **Training / serving** | Kaggle or Colab free GPUs for training. Serve on a host with enough RAM for your model. Render's free tier is small for PyTorch, so consider Hugging Face Spaces. |

Verify every free-tier quota yourself in Phase 0. Numbers copied from planning docs go stale.

---

## 3. Working rules (the learning method)

1. **One ADR per phase**: context, options, decision, consequences. Half a page.
2. **Break-it test per phase**: deliberately break the thing you built and watch your guard catch it. Every "Done when" below is written this way.
3. **Hand-write first, then review with Claude Code.** Do these yourself before letting an assistant touch them: RLS policies, JWT verification, webhook signature check, idempotency logic, the Siamese forward pass and loss, evaluation metrics. Use the assistant to critique your version.
4. **The privacy rule is a permanent test.** From Phase 1 onward, "a guest can never read host-to-guest reputation reviews about themselves" runs in CI and is never deleted. This is a direction-scoped restriction: published guest-to-property reviews remain publicly readable, and the test must not be implemented as a blanket ban on all reviews.
5. **Research log.** Every experiment gets an entry: date, config, result, what it taught you.
6. **Freeze the test set before training anything.** Non-negotiable for the paper.
7. **Claude Code protocol is mandatory.** Before each phase, inspect the repository and current diff, discover and use relevant installed Ponytail skills, implement only the active phase, test the change, run a break-it test, and report exact verification evidence. Follow Sections 3A–3B.
8. **Task-specific skill discovery is mandatory.** The root `CLAUDE.md` §3 is the single authoritative skill-discovery policy for this repository; this roadmap references it instead of duplicating it. In short: discover installed skills before meaningful work, read only relevant available instructions, keep Ponytail at `full` by default, use `dataviz` before any chart, dashboard or model-evaluation visualization code, and never claim a skill was used unless it was installed, read and actually applied. Each phase handoff lists skills discovered, read and used, their contribution, and unavailable or intentionally skipped skills.
9. **Document bugs and fixes permanently.** Every meaningful bug must have a source-backed record in `docs/bugs/` and an index entry in `docs/bug-log.md`, following Section 3C.

---


---

## 3A. Mandatory implementation protocol for Claude Code

**Apply this protocol in every product and research phase.** The roadmap is a learning plan, not permission to generate a large unreviewed code dump. Implement one small, verifiable slice at a time.

### Before writing code
1. Read the relevant roadmap phase, repository `README`, `AGENTS.md` / `CLAUDE.md`, package scripts, environment examples, existing tests, and the current Git diff.
2. Inspect the actual code and types at the call sites. Do not invent files, functions, schemas, environment variables, commands, library APIs, or tool capabilities.
3. Map the current data flow and dependencies before changing architecture. Preserve working behavior unless the phase explicitly requires a change.
4. Write a short plan naming the files to change, the risks, and the tests that will prove the change.
5. Identify assumptions and ask before making an irreversible, security-sensitive, destructive, costly, or scope-expanding decision.
6. **Use the available Ponytail skills for coding.** Follow the skill-discovery policy in the root `CLAUDE.md` §3 (single authority): discover installed skills, read their instructions, select only those relevant to the task, and follow their actual documented workflow. Do not invent skill names or claim usage of anything not installed. If no relevant skill is available, state that briefly and apply the standards in this section.

### Code quality rules
- Prefer small, cohesive modules and explicit interfaces. Keep UI, business logic, persistence, external providers, and research code separated.
- Follow the repository's existing language conventions, formatting, linting, naming, and type-checking rules. Do not introduce a new style or dependency without a reason.
- Use descriptive names, small functions, early validation, explicit return types where supported, and domain-specific errors. Avoid clever one-liners and unnecessary abstraction.
- Avoid giant files, giant functions, duplicated logic, magic numbers, hidden global state, circular imports, and import-time side effects.
- Keep configuration outside source code. Add required keys to `.env.example`, never put secrets in source control, and never print tokens, passwords, private user data, or full sensitive payloads in logs.
- Validate inputs at trust boundaries. Normalize and validate once in the appropriate layer; do not rely on the UI alone for security or correctness.
- Use parameterized database queries, least-privilege credentials, explicit transaction boundaries, safe connection cleanup, and database constraints for invariants where appropriate.
- Treat retries, queues, webhooks, scheduled jobs, and background work as potentially duplicated or interrupted. Design idempotency and failure recovery deliberately.
- Handle errors deliberately: preserve useful context, show safe user-facing messages, and log actionable diagnostic details without leaking secrets. Never silently swallow exceptions.
- Use resource limits, timeouts, pagination, bounded queries, and safe defaults for external calls and user-controlled workloads.
- Add comments to explain intent, invariants, or non-obvious trade-offs—not to narrate every line. Update documentation when behavior or commands change.
- Do not suppress lint/type/test failures, weaken assertions, or delete a failing test merely to make CI green.
- Do not claim that code, tests, migrations, security, deployment, or external integration works unless it was actually verified.

### Testing and verification rules
1. Write or update tests with the implementation. Cover success, invalid input, empty data, boundary values, permission failures, and relevant error paths.
2. Choose the right test layer: unit tests for pure logic, integration tests for real boundaries, and end-to-end tests for critical user flows. Mocks must not be presented as proof of a live integration.
3. Include regression tests for every bug fix. A bug is not considered fixed merely because the page starts.
4. Run the narrowest relevant test first, then lint/typecheck/build and the full test suite where practical. Report exact commands and outcomes.
5. For database work, verify migrations and constraints against a disposable/test database. Never run destructive operations against production or a user's real data.
6. For authorization/privacy rules, test both allowed and denied paths and keep critical privacy/security tests permanently in CI.
7. For ML/research work, fix seeds where useful, prevent data leakage, freeze test splits before model selection, track experiment configuration, and report limitations honestly.
8. If a test cannot run due to missing credentials, unavailable infrastructure, or compute limits, state exactly what remains unverified and give a reproducible next step.
9. Before marking a phase done, run its documented “break-it test” and show evidence that the guard catches the deliberately invalid case.

### Scope and change-control rules
- Implement only the active phase and its stated dependencies. Do not silently start future phases.
- Preserve existing working features and public interfaces; if a breaking change is necessary, explain it and update callers/tests together.
- Prefer the smallest safe patch. Avoid unrelated formatting changes and broad rewrites.
- Do not replace a real integration with a mock, SQLite, an in-memory store, or a different provider unless the phase explicitly permits it.
- Do not overwrite, delete, or migrate user data without explicit confirmation and a tested recovery plan.
- Review `git diff` before finishing and call out all files changed, any new dependencies, migration impact, and any known risks.

### Required phase handoff report
At the end of every phase, provide:
- **Implemented:** what changed and how it works.
- **Files changed:** with the reason for each change.
- **Learning notes:** the concepts the learner should understand and be able to explain.
- **Verification:** exact commands, test counts/results, lint/typecheck/build outcomes, and whether checks used mocks or real services.
- **Break-it test:** what was deliberately broken, expected guard, and observed result.
- **Security/privacy:** relevant checks and any unresolved risks.
- **Known limitations:** what remains incomplete or unverified.
- **Next step:** one recommended action for the next phase, but do not implement it until asked.

---

## 3B. Required repository instructions

At Phase 0, create and maintain a root `CLAUDE.md` (or `AGENTS.md`, matching the tool actually used) that summarizes:
- the locked architecture and package boundaries (`frontend/`, `backend/`, `vision/`, `shared/`, `research/`);
- install, run, lint, typecheck, test, build, and migration commands (`pnpm install`, `pnpm --filter backend run dev`, `pnpm --filter frontend run dev`, `pnpm --filter backend run generate`, `pnpm --filter backend run migrate`, etc.);
- naming, formatting, error-handling, logging, and testing standards;
- secrets and environment-variable rules;
- security/privacy invariants and required regression tests;
- instructions to inspect Ponytail skills before coding and to report when none are available;
- the current phase and explicit out-of-scope work.

Keep this file concise and accurate. Update it when commands or architecture change. Do not maintain conflicting instructions in multiple files.

---


---

## 3C. Mandatory bug, root-cause, source, and fix journal

**Maintain a permanent engineering bug journal throughout the project.** Every meaningful bug, failed test, regression, unexpected behavior, and important debugging discovery must be documented with evidence. Do not rely on chat history or memory as the only record.

### Where to keep it
Create and maintain:
- `docs/bug-log.md` — a human-readable index of bugs and their current status.
- `docs/bugs/BUG-YYYY-NNN-short-title.md` — one detailed record per significant bug, using a unique ID (for example, `BUG-2026-001-date-filter-not-applied`).

If the repository already has an issue template or incident format, inspect it first and extend the existing convention instead of creating conflicting systems. Keep the index and individual records linked to each other.

### Required information for each bug
Record the following fields when applicable:

1. **Bug ID and title**
2. **Status:** Open, Investigating, Fixed, Verified, Deferred, or Reopened.
3. **Severity and priority:** Explain the user or system impact.
4. **First observed / fixed / verified dates**
5. **Affected phase, feature, environment, and version/commit**
6. **Expected behavior**
7. **Actual behavior**
8. **Reproduction steps**, including the smallest reliable example
9. **Error messages and relevant logs** with secrets, tokens, personal data, and other sensitive values redacted
10. **Root cause:** Explain the actual mechanism that caused the bug. Mark it as a hypothesis until evidence confirms it.
11. **Source of the diagnosis:** Link to relevant source files, function names, line ranges or commit; include test output, SQL behavior, official documentation, issue links, or other evidence used. Never fabricate citations or links.
12. **Fix applied:** Describe the change and why it addresses the root cause.
13. **Files changed** and the relevant commit/PR when available
14. **Regression test:** Identify the test that fails before the fix and passes after it, or explain why an automated regression test is not feasible.
15. **Verification evidence:** Exact commands and observed outcomes. Separate mocked/unit verification from live integration verification.
16. **Side effects and related risks:** Note what was checked for regressions.
17. **Lessons / prevention:** What rule, test, monitoring, or design change can prevent recurrence?
18. **Related bugs or decisions:** Link related bug IDs and ADRs.

### Required debugging workflow
For each meaningful bug, Claude Code must:
1. Reproduce the issue or clearly state why it cannot be reproduced.
2. Capture the exact error, failing test, incorrect output, or other observable evidence.
3. Trace the data/control flow to the source of the failure before changing code.
4. Distinguish observed facts from hypotheses. Do not state a root cause as confirmed without evidence.
5. Propose the smallest safe fix and identify the regression test before editing.
6. Implement the fix without unrelated refactoring.
7. Add a regression test that would catch the same defect in the future.
8. Run the focused test, relevant neighboring tests, and the full suite where practical.
9. Verify the real integration when required and available; clearly mark checks that used mocks only.
10. Review the diff and check for related regressions.
11. Update the detailed bug record and `docs/bug-log.md` index.
12. Report the bug ID, root cause, source evidence, fix, tests, verification status, and remaining uncertainty in the phase handoff.

### Source and evidence rules
- Use source links that actually support the diagnosis: repository paths/line ranges, commit hashes, failing test output, official library documentation, or reproducible SQL results.
- Record the exact package/library version when behavior may depend on version.
- When external documentation informs a fix, record its title, URL, access date, and the specific claim it supports.
- Do not copy large copyrighted passages; summarize the relevant finding.
- Never store secrets, credentials, access tokens, personal information, or raw sensitive production data in bug reports.
- If the root cause remains uncertain, write **“Root cause not confirmed”** and list the next diagnostic step instead of guessing.
- If a fix is only unit-tested, use **Fixed — integration unverified**, not **Verified**.
- Mark a bug **Verified** only when the documented acceptance checks pass at the appropriate test level.

### Suggested bug-log index format

| ID | Title | Phase | Severity | Status | Root cause confirmed? | Regression test | Verification |
|---|---|---|---|---|---|---|---|
| BUG-2026-001 | Short descriptive title | Phase N | Medium | Fixed | Yes/No | `tests/path::test_name` | Unit / integration / E2E |

### Individual bug record template

```markdown
# BUG-YYYY-NNN: Short descriptive title

- **Status:** Open
- **Severity / priority:** Medium / P2
- **Phase / feature:**
- **Environment and version/commit:**
- **First observed:**
- **Fixed / verified:**

## Expected behavior

## Actual behavior

## Reproduction steps

## Evidence
- Error/output:
- Relevant file/function/line:
- Test or command:
- External source/documentation (title, URL, access date), if used:

## Root-cause analysis
- Confirmed facts:
- Hypotheses:
- Root cause status: Confirmed / Not confirmed

## Fix
- Changes made:
- Files changed:
- Why this addresses the root cause:

## Regression coverage
- Test added/updated:
- Demonstrates failure before fix:
- Result after fix:

## Verification
- Commands run:
- Unit tests:
- Integration/E2E tests:
- Live service/database verification:
- Unverified items:

## Regression and security review

## Prevention / lessons learned

## Related bugs / ADRs / commits
```

A bug record is part of the definition of done for every meaningful defect. Keep records concise but reproducible, and update an existing record when a bug is reopened rather than creating duplicates for the same root cause.


## 4. Schedule overview

The research track runs in the background from day one. Real-world data collection and consent are the long pole.

| Product track | Research track running alongside |
|---|---|
| Phase 0 Foundations | R0 Problem, literature, ethics plan |
| Phases 1–3 DB, auth, API | R1 Dataset protocol, consent, pilot capture, annotation |
| Phases 4–5 Frontend, dossier | R2 Classical baseline and alignment |
| Phases 6–8 Jobs, payments, reviews | R3 Learned models |
| Phases 9–10 Messaging, admin, legal | R4 Calibration and abstention, R5 Evaluation |
| Phase 11 Vision service and review loop | Integration of the R-track model |
| Phases 12–14 Testing, hardening, deploy | R6 Paper writing and artifacts |

## 4A. Canonical implementation sequence and expansion reconciliation

The original Product Phases 0–14 and Research Phases R0–R6 remain authoritative. The expansion labels are integration gates placed in the sequence below; they reuse original work and must not create second implementations of queues, payments, reviews, messaging, administration, or observability. **6A, 6B, 7A, 8A, 9A and 10A are portfolio milestone labels, not strict sub-phases of the similarly numbered original phases.** Their position in the sequence is dependency-driven, which is why 6A/6B land before Phase 6 (they need only Phases 3–5) and 8A/9A land before Phases 11–13 (they are built against frozen research artifacts and Phase 10 authorization, not against the live vision service or full telemetry).

1. Phase 0 — foundations and minimal CI.
2. R0–R1 begin in parallel — problem/literature, provenance, protocol, synthetic and licensed-public data, then frozen hashed splits.
3. Phases 1–5 — database/RLS, authentication bridge, core API, frontend/search/maps, and host dossier.
4. **Phase 6A — Host and Property Operations:** host onboarding, multi-property ownership, internal availability/blocked-date calendar, listing readiness, guest wishlists, and saved searches. Reuses Phase 3 ownership/booking models and Phase 5 authorization.
5. **Phase 6B — Discovery and Marketplace Intelligence:** bounded server-side filters, pagination/sorting, nearby search, deterministic explainable recommendations, and aggregate search events. Reuses Phase 4 search/contracts; no learned recommender.
6. Phase 6 — BullMQ completion/expiry/reminder/retry jobs. This is the only queue implementation.
7. Phase 7 — Razorpay order/checkout, raw-body verification, webhook idempotency, cancellation/refund policy. This is the only payment integration.
8. Phase 8 — both review flows, 14-day and once-per-booking rules, serious-claim evidence gate, override and audit. This is the only review domain implementation.
9. Phase 9 — RLS booking chat and transactional-outbox email. This is the only messaging/notification implementation.
10. **Phase 7A — Marketplace Workflow Engine gate:** verify one audited booking state machine across Phases 3, 6, 7 and 9; add idempotency keys, cancellation/refund requests, dispute intake and an explanatory timeline. Reuse existing workers/providers instead of duplicating them.
11. Phase 10 — moderation/admin actions, retention, audit export, disclosures and review kill switch.
12. R2–R5 — alignment baseline, learned models, calibration/abstention, robustness and error analysis. These may proceed beside product work after R1, but production/reviewer feedback never enters held-out evaluation.
13. **Phase 8A — AI Evidence and Review Workspace (offline-artifact scope):** evidence pairs, region proposals, class/confidence/model version, reviewer decisions, evaluation views and versioned decision exports, all rendered from frozen R-track artifacts (R3–R5 experiment outputs and manifests). It does not retrain on held-out data and does not call the live vision service; Phase 11 later connects queued live inference into this existing workspace.
14. Phase 11 — authenticated FastAPI inference, queued jobs, recommendation-only output, human review and graceful degradation. Model output alone can never trigger financial, moderation or adverse guest action.
15. **Phase 9A — Operations and Support Console (initial scope):** least-privilege booking/listing/review/dispute/refund tools, support notes, audit-event search over Phase 7A/10 records, bounded operational aggregates and audited feature controls. Reuses Phase 10 authorization. End-to-end request-ID trace correlation across services depends on Phase 13 telemetry; that integration is deferred to Phase 10A and 9A ships with request-ID capture on records only.
16. Phases 12–13 — testing/CI/CD, then Sentry/Pino, rate limits, OWASP, secrets and dependency audit.
17. **Phase 10A — Observability, Reliability and Demo Operations gate:** reuse Phase 12/13 checks and telemetry; add health/readiness, queue/provider diagnostics, failure simulation, disposable seed/demo/reset, and incident/demo runbooks. Do not build a second observability stack.
18. Phase 14 — staging/live deployment and the complete privacy-preserving smoke test.
19. R6 — paper and independently reproducible artifacts.

### Expansion mapping

| Expansion | Existing phases reused | Genuine new work | Blocking dependencies | Objective acceptance evidence |
|---|---|---|---|---|
| 6A | 3–5 | Multi-property operations, listing readiness, internal calendar, owned wishlists/saved searches | Verified ownership, RLS and booking contracts | Real-Postgres ownership tests and E2E proving cross-host/cross-guest denial |
| 6B | 4, 6A | Bounded facets/pagination/nearby search, deterministic recommendation reasons, aggregate events | Stable listing schema, indexes and generated contracts | Seeded filter/boundary tests; invalid or oversized queries fail safely |
| 7A | 3, 6, 7, 9 | Cross-cutting transition service, idempotency keys, dispute/refund intake, timeline | Stable booking states, jobs, payments and outbox | Duplicate/reordered/crash tests produce one business effect and a complete audit timeline |
| 8A | R0–R5, 10 | Offline reviewer/evidence workspace, feedback records, evaluation views, decision export, all from frozen experiment artifacts | Frozen artifacts, calibration/abstention, reviewer roles. Phase 11 live inference is **not** required | Low-confidence route reaches review; held-out manifest remains unchanged; irreversible model mutation is rejected |
| 9A | 7A, 8A, 10 | Support console, escalation notes, bounded operational views and audited feature controls | Least-privilege admin, audit records, request-ID capture on records and safe redaction. Cross-service request-ID trace requires Phase 13 telemetry — integrated in Phase 10A, not 9A | Non-admin denial; end-to-end request-ID trace for one booking is verified at 9A only within audit records, and cross-service after 10A |
| 10A | 12–14 | Readiness, failure simulation, reproducible local demo/reset and runbooks | Stable flows, telemetry and disposable environment | Fresh setup runs demo, survives a dependency failure in degraded mode and resets safely |

Every original requirement not explicitly described above remains in force in its original phase section.

## 4B. Mandatory learning gate for every phase

Before any Product, Research or Expansion phase is marked complete, its handoff must record:

1. prerequisites and blockers;
2. objective, in-scope work and explicit non-goals;
3. existing contracts/components reused;
4. database, API, UI, worker, provider and research impacts as applicable;
5. security/privacy invariants and trust boundaries;
6. migration, rollback and compatibility implications when data/contracts change;
7. success, invalid-input, boundary, permission and relevant error-path tests at the correct unit/integration/E2E level;
8. one deliberate break-it test, expected guard and observed evidence;
9. exact commands, counts/results, versions and mock-versus-live verification status;
10. meaningful bug-journal updates with facts separated from hypotheses, confirmed root cause evidence, minimal fix and regression coverage;
11. concepts the learner can explain without AI; and
12. remaining risks, unresolved decisions, ADRs and known unverified items.

A page loading or a mocked/unit test alone cannot verify a real database, provider, authorization boundary or deployment. The status must remain **integration unverified** until the appropriate boundary check passes.

## 4C. Phase 0 documentation register

Phase 0 creates these files only when their owning work begins; this revision does not create them:

| Artifact | Purpose | Update owner/trigger | Creation milestone |
|---|---|---|---|
| `README.md` | Accurate setup and project overview | Maintainer; command/architecture changes | Phase 0 |
| `docs/adr/` | Context/options/decision/consequences records | Decision owner; one per phase/material decision | Phase 0 onward |
| `docs/bug-log.md`, `docs/bugs/` | Meaningful defect index and source-backed records | Fix author; every meaningful defect | Phase 0 structure, then continuously |
| `docs/architecture/` | Diagrams of implemented—not aspirational—boundaries | Maintainer; boundary changes | Phase 0 skeleton, then relevant phases |
| `docs/free-tier-audit.md` | Dated provider limits with source links | Phase owner; before provider selection | Phase 0 and provider phases |
| `docs/runbooks/setup.md`, `verification.md` | Reproducible setup/check commands | Maintainer; commands/gates change | Phase 0 |
| `docs/research/problem-statement.md`, `data-card.md`, `manifests/`, `experiment-log.md` | RQs, provenance, frozen hashes and experiments | Research owner; dataset/experiment changes | R0–R2 |
| `docs/contracts/` | API/event/research contracts not fully represented by generated OpenAPI | Contract owner; contract changes | Phases 3, 7A, 8A |
| `docs/runbooks/incident.md`, `demo.md` | Failure response and reproducible demo/reset | Operations/portfolio owner; behavior changes | Phase 10A |

Do not create duplicate roadmap, ADR, bug or research-record systems when an equivalent convention exists.

---

# PRODUCT TRACK

## Phase 0: Environment and Foundations
**Build:** Turborepo scaffold with top-level workspaces (`frontend/`, `backend/`, `vision/`, `shared/`). Docker Compose for Postgres + Redis. ESLint/Prettier, commit hooks, `.env.example`, `CLAUDE.md` for your assistant. **Minimal CI** (lint + typecheck on every push). Free-tier audit: a one-page table of real current limits for Neon, Upstash, Resend, Cloudinary, Render/Hugging Face, Vercel.
**Learn:** Monorepo and shared-package patterns. Why local dev mirrors production infrastructure instead of using SQLite or mocks.
**Done when:** `docker compose up` gives working Postgres + Redis, `frontend/`, `backend/`, `vision/` boot, and a deliberately bad lint error fails CI.
**ADRs:** Monorepo vs single app. Neon vs alternatives.

## Phase 1: Database Design and Row-Level Security (by hand)
**Build:** Full Prisma schema (users, properties, bookings, reviews, tags). Booking status enum: `REQUESTED, DECLINED, AWAITING_PAYMENT, CONFIRMED, COMPLETED, CANCELLED`. RLS policies in raw SQL, scoped by review direction:
- **Host-to-guest reputation reviews:** visible only to hosts (and admins); a guest can never read the ones about themselves. This is the permanent privacy invariant.
- **Guest-to-property reviews:** public once published, readable by any user per Phase 8's rules; RLS must not hide these from guests. This remains publicly readable and distinct from host-to-guest reputation reviews.
- Admins see all.
**Learn:** `CREATE POLICY`, `USING` vs `WITH CHECK`, session variables. The pitfalls that make RLS silently do nothing:
- Table owners and `BYPASSRLS` roles skip policies unless you use `FORCE ROW LEVEL SECURITY`. Neon's default role is an owner, so create a separate low-privilege app role.
- With pooled connections, set the user variable with `set_config(..., true)` inside a transaction, or it can leak between requests.
**Done when:** In raw `psql` as the app role, a guest's `SELECT` on host-to-guest reviews about themselves returns zero rows, while the same guest's `SELECT` on published guest-to-property reviews still succeeds — proving the privacy policy is scoped by direction and not a blanket review ban. The same host-to-guest query as the owner role (deliberately) shows why the app role matters.
**ADRs:** RLS policy structure. App role vs owner role.

## Phase 2: Authentication and the JWT-to-Postgres Trust Bridge
**Build:** Auth.js (Google + magic link) on the frontend. Passport JWT on NestJS. Middleware that sets the verified user ID and role as transaction-local Postgres variables. Roles: `GUEST / HOST / BOTH / ADMIN`.
**Learn:** The full OAuth/JWT handshake. Auth.js session tokens are encrypted (JWE) by default, so the backend cannot verify them like a plain signed JWT. Decide how to bridge: override encode/decode to issue signed JWTs, or exchange the session for a short-lived API token. Write that decision down.
**Done when:** A test impersonating two users proves each user's queries are scoped by RLS, and a forged or expired token is rejected before any query runs.
**ADRs:** Token format and storage. Role hierarchy and session lifetime.

## Phase 3: Core Backend API (NestJS)
**Build:** Listings CRUD (heritage story, house rules, property type, `DRAFT → PUBLISHED`), booking requests, role guards, OpenAPI spec. **Date-overlap protection at the database level**: a Postgres exclusion constraint on a date range (needs the `btree_gist` extension, added via raw SQL migration since Prisma cannot model it).
**Learn:** Modules, providers, guards, interceptors, DI. Why an app-level overlap check has a race condition and a DB constraint does not. Add a request ID to every request now; you will need it in Phase 13.
**Done when:** Two concurrent booking requests for overlapping dates result in exactly one success (test fires them in parallel). Supertest coverage written alongside the code.
**ADRs:** Overlap enforcement. Module boundaries.

## Phase 4: Frontend Shell, Search and Maps
**Build:** Next.js UI in `frontend/` using types generated from the OpenAPI spec. Public listing pages, search (city, dates, guests, price), Leaflet map with real coordinates. A visible "your stay will be rated" notice on the booking flow.
**Learn:** Type-safe API consumption without a shared monolith. Why generated types beat hand-copied interfaces.
**Done when:** Search filters hit the backend, the map renders real coordinates, and changing the API response shape breaks the frontend type-check.

## Phase 5: The Host Dossier (core feature)
**Build:** Guest reputation model: dimension ratings, tags (`careful_with_antiques`, `party`, `damage`, `theft_suspected`), attributed to the reviewing host and visible only to hosts. `/host/requests/[id]` dossier UI in `frontend/`. Guest self-view shows only a completed-stay count.
**Learn:** Turning a business rule into layered enforcement: RLS, API checks, and a UI that never requests the forbidden data.
**Done when:** Playwright e2e as a guest: `GET /api/reviews/guest?guestId=` returns 403 or empty. Then disable each layer one at a time and confirm the other layers still hold.
**ADRs:** Review visibility model and UI shaping.

## Phase 6: Background Jobs and Queues
**Build:** BullMQ workers in `backend/` for `CONFIRMED → COMPLETED` after checkout, **unpaid-booking expiry after 48 hours (configurable)**, review-window reminders, webhook retries.
**Learn:** At-least-once delivery, retries with backoff, idempotency via stable job IDs. Why "run on a schedule" and "run reliably" are different problems. BullMQ can consume many Redis commands on Upstash's free tier, so measure your usage and tune worker settings.
**Done when:** Killing a worker mid-job and restarting neither double-processes nor loses the job. Expiry fires within a defined tolerance.
**ADRs:** Payment expiry. Job idempotency strategy.

## Phase 7: Payments (Razorpay, test mode)
**Build:** Order creation, checkout, webhook handler in `backend/` with signature verification, cancellation and refund policy logic.
**Learn:** Signature verification is computed over the **raw request body**, so parse it before JSON middleware touches it. Idempotent webhook handling: what happens when a webhook arrives twice, late, or out of order.
**Done when:** A malformed signature returns 400 and the booking stays `AWAITING_PAYMENT`. The same valid webhook sent twice changes state once.
**ADRs:** Payment states and refund policy.

## Phase 8: Reviews and Moderation Gating
**Build:** Two flows from the same `COMPLETED` booking, same 14-day window, once per booking each:
- Guest → Property: public review, visible on the listing immediately.
- Host → Guest: host-only review with dimension ratings and tags. `damage` and `theft_suspected` require a photo (Cloudinary) or go to an admin queue before becoming visible. Admin override is allowed, with an audit-log entry.
**Learn:** Trust-system design under legal exposure. Attributed reviews carry defamation risk, so serious claims need a higher evidence bar. Modeling two reviews with one trigger and opposite visibility rules.
**Done when:** A `theft_suspected` tag without a photo lands in a pending state. An admin override writes an audit record. The property review is public immediately. The guest still cannot fetch the host review.
**ADRs:** Photo evidence requirement and override. Audit log design.

## Phase 9: Messaging and Transactional Email
**Build:** Booking-threaded chat in `backend/` visible only to the two parties (RLS-enforced). Resend emails for request, accepted, declined, payment, reminder, review-open, cancel. Emails are triggered from state changes, using a **transactional outbox** so a crash cannot lose or duplicate a notification.
**Learn:** Event-driven notification design. Why scattering `sendEmail()` calls through business logic fails.
**Done when:** Every booking state transition produces exactly one email in tests with a mocked provider, including after a simulated crash between the DB commit and the send.
**ADRs:** Outbox vs direct calls. Messaging privacy boundaries.

## Phase 10: Admin Panel and Legal/Compliance
**Build:** Moderation queues, suspend listing, hide review, refund override, audit-log export in `backend/`. Privacy Policy, Terms, and a plain-language "How it works" page explaining host-only reviews. Retention policy (for example: reviews archived after 3 years, sessions with a short TTL). A `REVIEW_ENABLED` kill switch that disables all review endpoints. DPDP checklist: consent, data-principal rights, breach procedure. Check current Rules and commencement dates.
**Learn:** How platforms operationalize policy. One real design tension to resolve in an ADR: the DPDP Act gives people rights over their personal data (access, correction, erasure, with exceptions), while Basera deliberately hides guest reviews from the guest. How do you reconcile that: an appeals workflow, a legitimate-use position, limits on what is stored? Not legal advice. Discuss it with your project guide.
**Done when:** An admin hides a live review and the host dossier reflects it immediately. Flipping the kill switch returns a defined error from every review endpoint.
**ADRs:** Moderation and appeals. Hidden reviews vs data-principal rights. Retention.

## Phase 11: Vision Microservice and Human Review Loop
**Build:** A check-in/check-out photo capture flow attached to a booking, with upfront notice and consent. FastAPI service in `vision/` wrapping your best research model (see R3–R4). Service-to-service auth between `backend/` (NestJS) and `vision/` (FastAPI) via HMAC-signed requests or short-lived JWTs. Inference runs as a queued job. Output is a **recommendation** with region, change class and confidence. Below the abstention threshold it goes to a human review queue. **No automated accusation, ever.**
**Learn:** Polyglot service architecture, safe inter-service trust, graceful degradation, model versioning, and why ML output must not directly drive an irreversible action.
**Done when:** Two staged photos with one moved object return a region, class and confidence. A low-confidence pair lands in the review queue and never auto-flags. Killing the vision service leaves booking and check-out fully working, with the pair marked "pending analysis".
**ADRs:** Research pipeline separation from product. Recommendation-only policy. Model serving and versioning.

## Phase 12: Testing Pyramid and CI/CD
**Build:** Vitest unit coverage on business logic in `backend/` and `frontend/`, Supertest on API routes in `backend/`, Playwright on critical flows in `frontend/` (booking, dossier visibility, payment webhook). Pipeline: lint, typecheck, test, build, deploy to staging.
**Learn:** What "production-ready" gates on: a pipeline that mechanically blocks a bad merge.
**Done when:** A deliberately broken PR (reintroducing the guest-visibility bug) fails CI before it can merge.

## Phase 13: Observability and Security Hardening
**Build:** Sentry, Pino structured logs in `backend/` (with the request ID from Phase 3), rate limiting on auth endpoints, an OWASP API Top 10 pass (especially broken object-level authorization), secrets audit, dependency audit.
**Learn:** How teams find out something broke after deploy, and how they audit for mistakes they have not made yet.
**Done when:** A deliberately thrown error appears in Sentry with user, route and request ID within seconds.

## Phase 14: Deployment and Stretch
**Build:** Vercel (`frontend/`), Render (`backend/`), Neon, Upstash, plus `vision/` on a host with enough memory for your model. Full production smoke test: guest request, host sees dossier, accept, pay with test card, complete stay, both reviews, guest cannot fetch their own review.
**Stretch:** Deploy `backend/` manually to an Oracle Cloud Always Free instance with Docker + Caddy to see what the PaaS was doing for you. Availability and signup can be finicky, so treat it as optional.
**Done when:** The smoke test passes on the live URL, not just locally.

---

# RESEARCH TRACK

Goal: a publishable study of image-based property condition verification for heritage homes. The task: given check-in and check-out photos of the same room, localize changes and classify them as *no change / benign rearrangement / damage / missing item / lighting variation*. You have already built a CNN classification pipeline, so this track skips "train a CNN" fundamentals. The new ground is **paired inputs, dense outputs, alignment, calibration, and rigorous evaluation under distribution shift**.

## R0: Problem Definition and Literature
**Build:** A two-page problem statement. Reading notes on roughly 15 papers: classical change detection (image differencing, registration with SIFT/ORB + RANSAC), Siamese change detection (FC-Siam-conc/diff), transformer change detection (ChangeFormer), pretrained-feature approaches (DINOv2, CLIP), learned matching (LoFTR). Survey existing datasets (LEVIR-CD, OSCD, VL-CMU-CD, PCD). None is likely to cover indoor heritage interiors, but confirm that in your review, because that gap is your motivation. Draft research questions, for example:
- RQ1: How do classical, pretrained-feature and trained Siamese approaches compare on staged changes in heritage-style interiors?
- RQ2: Does confidence-based abstention meaningfully reduce false damage flags, and at what coverage cost?
- RQ3: Does synthetic-edit pretraining help on real staged data?
**Done when:** A one-page paper skeleton (title, RQs, contributions, planned tables and figures) that your project guide has seen.

## R1: Dataset Design, Consent and Ethics
**Build:**
- Capture protocol: viewpoints, lighting conditions, phone models, list of staged changes per room, naming and EXIF conventions.
- Consent form and participant information sheet. Keep faces and personal documents out of frame. Ask your guide whether institutional ethics review applies.
- Annotation schema and tooling (CVAT or Label Studio). A second annotator labels a subset.
- Synthetic subset (pasted objects, lighting jitter), kept clearly separate from real data.
- Data card documenting sources, consent, splits and known biases.
**Learn:** Dataset construction as research. Leakage: **split by room or house, never by image**. Class imbalance. Inter-annotator agreement (Cohen's kappa).
**Done when:** A pilot set (start with a handful of rooms) is captured with signed consent, annotated, kappa computed, splits frozen and hashed before any model training. Scale the target with your guide.

## R2: Classical Baseline and Alignment
**Build:** OpenCV pipeline: feature matching, RANSAC homography, warp, difference (abs diff or SSIM), morphological cleanup, thresholding. Then swap in a learned matcher (LoFTR via kornia) and compare.
**Learn:** Homography assumptions and why they break for 3D scenes with parallax. How alignment error propagates into false changes. Pixel-level metrics (IoU, F1) vs region-level detection metrics.
**Done when:** One command reproduces a baseline results table on the validation set.

## R3: Learned Models
**Build:**
- (a) Frozen DINOv2/CLIP patch-feature differencing, no training.
- (b) Siamese CNN trained on your data, with and without synthetic pretraining.
- (c) Optionally a transformer-based change detector, if compute allows.
PyTorch, experiment tracking, seeded runs.
**Learn:** Weight sharing in Siamese networks. Losses for imbalanced dense prediction (BCE, Dice, focal). Transfer learning. Ablations. Reporting mean ± std over multiple seeds instead of one lucky run. Hand-write the forward pass and loss first.
**Done when:** Every model is compared against the classical baseline over at least 3 seeds, with an ablation table (synthetic pretraining on/off, alignment on/off).

## R4: Change-Type Classification, Calibration and Abstention
**Build:** Region-level change-type classifier. Calibration (temperature scaling, ECE). Risk-coverage curves. Abstention rule: treat a confidence threshold such as 0.6 as a starting hypothesis to test, not a given.
**Learn:** Calibration vs accuracy. Selective prediction. Asymmetric costs: a false damage accusation is far worse than a missed one, so make **false-accusation rate** a headline metric.
**Done when:** A risk-coverage curve exists, the chosen threshold is justified with numbers, and false-accusation rate at that operating point is reported.

## R5: Evaluation, Robustness and Error Analysis
**Build:** Stress tests: lighting shift, camera change, clutter, viewpoint offset, dark ornate interiors, mirrors and glass. Per-class and per-room breakdowns. Bootstrap confidence intervals. A failure gallery.
**Learn:** Error analysis as a skill, and writing an honest threats-to-validity section (small dataset, staged rather than natural damage, limited camera diversity).
**Done when:** A robustness table, a failure gallery, and a written limitations section.

## R6: Paper and Artifacts
**Build:** IEEE-template draft: introduction, related work, dataset, method, experiments, ablations, limitations, ethics statement. Reproducibility package: code, configs, data card, and whatever portion of the dataset your consent terms allow you to release. Internal review by your guide before submission. Choose a target venue early and check its deadlines and scope.
**Done when:** A colleague who was not involved can reproduce your headline table from the repo.

---

## Out of scope
Native apps, iCal/Airbnb or other external-marketplace synchronization, multi-currency, automated/complex payout routing, Aadhaar KYC, SMS/OTP, multi-language UI, host insurance, shareable wishlists, GST invoices, and learned recommenders. Internal guest-owned wishlists and internal property availability calendars are in Phase 6A; they do not imply external calendar synchronization. Revisit deferred items only after the active roadmap is solid and an evidence-backed dependency justifies reconsideration.
