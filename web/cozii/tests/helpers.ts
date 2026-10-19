import { LocalBackend, type Storage } from '../src/backend/local'
import type { Action } from '../src/core/engine'

export function memStorage(): Storage & { data: Map<string, string> } {
  const data = new Map<string, string>()
  return { data, get: k => data.get(k) ?? null, set: (k, v) => void data.set(k, v), remove: k => void data.delete(k) }
}

export function makeLocal(start = Date.UTC(2026, 9, 20, 3, 0, 0)) {
  const clock = { t: start }
  const storage = memStorage()
  const be = new LocalBackend(storage, () => clock.t)
  let n = 0
  const act = (a: Action, rid?: string) => be.act(a, rid ?? `req-${++n}`)
  return { be, clock, storage, act }
}

export async function onboarded(start?: number) {
  const h = makeLocal(start)
  await h.be.load()
  await h.act({ type: 'onboard', playerName: 'Mai', petName: 'Bông', species: 'capybara', fur: 'cocoa' })
  return h
}
