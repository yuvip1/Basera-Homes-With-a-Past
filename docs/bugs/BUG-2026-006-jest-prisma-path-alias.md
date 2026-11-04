# BUG-2026-006: Jest module resolution for PrismaService path alias

- **Status:** Open
- **Severity / priority:** Medium / P2
- **Phase / feature:** Phase 2 — Authentication backend testing
- **Environment and version/commit:** Node.js 20.x, Jest 29.7.0, ts-jest 29.1.2, pnpm 12.16.1
- **First observed:** 2026-11-04
- **Fixed / verified:** Not yet

## Expected behavior
`import { PrismaService } from '../../prisma/prisma.service.js'` resolves correctly in test files.

## Actual behavior
```
Cannot find module '../../prisma/prisma.service.js' or its corresponding type declarations.
```

## Reproduction steps
1. `cd C:\Users\yuvra\Desktop\Basera-Homes with a Past\backend`
2. `pnpm test`
3. Observe module resolution error for `@prisma/prisma.service` path alias

## Evidence
- Error output from `pnpm test`:
  ```
  Cannot find module '../prisma/prisma.service.js' or its corresponding type declarations.
  ```

## Root-cause analysis
- **Confirmed facts**: 
  - `@prisma/*` path alias defined in `tsconfig.json` but not in Jest `moduleNameMapper`
  - Jest doesn't use TypeScript path aliases by default
  - `ts-jest` with ESM preset needs explicit `moduleNameMapper` for path aliases

## Fix
- Update `jest.config.js` with complete `moduleNameMapper` for `@prisma/*` alias
- Ensure `moduleNameMapper` includes `'^@prisma/(.*)$': '<rootDir>/src/prisma/$1'`

## Files changed
- `backend/jest.config.js` — to be updated
- `backend/tsconfig.json` — may need `isolatedModules: true`

## Regression coverage
- Test added/updated: `src/auth/__tests__/auth.service.test.ts` — will be verified once module resolution fixed

## Verification
- Commands run: `pnpm --filter backend run test`
- Unit tests: Not yet passing
- Integration/E2E tests: Not applicable
- Live service/database verification: Not applicable

## Related bugs / ADRs / commits
- BUG-2026-005: Jest module resolution for @nestjs/testing and path aliases
- ADR 003: JWT-to-Postgres trust bridge decision