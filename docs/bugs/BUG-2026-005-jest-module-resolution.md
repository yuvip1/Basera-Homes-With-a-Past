# BUG-2026-005: Jest module resolution for @nestjs/testing and path aliases

- **Status:** Open
- **Severity / priority:** Medium / P2
- **Phase / feature:** Phase 2 — Authentication backend testing
- **Environment and version/commit:** Node.js 20.x, Jest 29.7.0, ts-jest 29.1.2, pnpm 12.16.1
- **First observed:** 2026-11-04
- **Fixed / verified:** Not yet

## Expected behavior
`pnpm --filter backend run test` executes unit tests successfully.

## Actual behavior
`pnpm --filter backend run test` fails with module resolution errors:
```
Cannot find module '@nestjs/testing' or its corresponding type declarations.
Cannot find module '../prisma/prisma.service.js' or its corresponding type declarations.
Cannot find module '../config/config.service.js' or its corresponding type declarations.
```

## Reproduction steps
1. `cd C:\Users\yuvra\Desktop\Basera-Homes with a Past\backend`
2. `pnpm test`
3. Observe module resolution errors

## Evidence
- Error output from `pnpm test`:
  ```
  Cannot find module '@nestjs/testing' or its corresponding type declarations.
  Cannot find module '../prisma/prisma.service.js' or its corresponding type declarations.
  Cannot find module '../config/config.service.js' or its corresponding type declarations.
  ```

## Root-cause analysis
- **Confirmed facts**: 
  - `@nestjs/testing` is listed in `devDependencies` in `package.json`
  - Path aliases (`@/*`, `@prisma/*`, `@auth/*`) defined in `tsconfig.json` are not resolved by Jest
  - `ts-jest` with ESM preset requires `moduleNameMapper` configuration for path aliases
  - The test file uses `.js` extensions in imports (ESM), but Jest resolver expects TypeScript paths

- **Hypotheses**:
  1. Jest moduleNameMapper doesn't include all required path aliases
  2. `ts-jest` ESM preset requires `moduleNameMapper` to map `@/*`, `@prisma/*`, `@auth/*` to `<rootDir>/src/*`
  3. `@nestjs/testing` types may not be properly resolved in test environment

- **Root cause status**: Not confirmed

## Fix
- Update `jest.config.js` with complete `moduleNameMapper` for all path aliases
- Add `transformIgnorePatterns` for ESM modules
- Ensure `moduleNameMapper` maps `@/*`, `@prisma/*`, `@auth/*` correctly

## Files changed
- `backend/jest.config.js` — to be updated
- `backend/tsconfig.json` — may need `isolatedModules: true`
- `backend/src/auth/__tests__/auth.service.test.ts` — may need import path fixes

## Regression coverage
- Test added/updated: `src/auth/__tests__/auth.service.test.ts` — tests for `generateApiToken`, `verifyToken`, `validateUser`, `exchangeCredentialForApiToken`

## Verification
- Commands run: `pnpm --filter backend run test`
- Unit tests: Not yet passing
- Integration/E2E tests: Not applicable
- Live service/database verification: Not applicable

## Related bugs / ADRs / commits
- BUG-2026-006: Jest module resolution for PrismaService path alias
- ADR 003: JWT-to-Postgres trust bridge decision