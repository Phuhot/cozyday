import { useEffect, useState } from 'react'

export interface Route {
  path: string[]
  raw: string
}

function parse(): Route {
  const raw = location.hash.replace(/^#\/?/, '')
  return { raw, path: raw.split('/').filter(Boolean).map(decodeURIComponent) }
}

export function useRoute(): Route {
  const [r, setR] = useState(parse)
  useEffect(() => {
    const on = () => setR(parse())
    window.addEventListener('hashchange', on)
    return () => window.removeEventListener('hashchange', on)
  }, [])
  return r
}

let depth = 0

export function go(path: string, replace = false) {
  const h = '#/' + path.replace(/^\/+/, '')
  if (replace) {
    history.replaceState(null, '', h)
    window.dispatchEvent(new HashChangeEvent('hashchange'))
  } else if (location.hash !== h) {
    depth += 1
    location.hash = h
  }
}

/** Quay lại màn trước trong app; nếu mở thẳng từ liên kết thì về `fallback`. */
export function back(fallback = 'home') {
  if (depth > 0) {
    depth -= 1
    history.back()
  } else go(fallback, true)
}
