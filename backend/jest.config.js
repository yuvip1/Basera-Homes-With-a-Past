export default {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts'],
  moduleFileExtensions: ['ts', 'js', 'json'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.test.ts'],
  coverageDirectory: 'coverage',
  verbose: true,
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@prisma/(.*)$': '<rootDir>/src/prisma/$1',
    '^@auth/(.*)$': '<rootDir>/src/auth/$1',
  },
  transformIgnorePatterns: [
    'node_modules/(?!(jose|@nestjs|@prisma)/)',
  ],
};