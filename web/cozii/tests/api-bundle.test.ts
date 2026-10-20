import { execFileSync } from 'node:child_process'
import { describe, expect, it } from 'vitest'

describe('api/cozii.js', () => {
  it('khớp với server/ (đã chạy npm run build:api trước khi commit)', () => {
    expect(() => execFileSync('node', ['scripts/build-api.mjs', '--check'], { stdio: 'pipe' })).not.toThrow()
  })
})
