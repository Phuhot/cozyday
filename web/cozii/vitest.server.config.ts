import { defineConfig } from 'vitest/config'

// Test máy chủ: cần Postgres cục bộ (scripts/dev/pg-local.sh) và biến TEST_DATABASE_URL.
export default defineConfig({
  test: {
    include: ['tests/server/**/*.test.ts'],
    environment: 'node',
    fileParallelism: false,
    testTimeout: 30000,
    hookTimeout: 30000,
  },
})
