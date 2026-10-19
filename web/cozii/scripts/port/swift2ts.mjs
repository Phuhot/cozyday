// Công cụ một lần: chuyển code vẽ SwiftUI (GraphicsContext) của bản iOS sang TypeScript dùng lớp GC (src/art/gc.ts).
// Không phải trình biên dịch Swift: chỉ xử lý đúng các mẫu code vẽ của dự án, phần còn lại được sửa tay sau khi chạy tsc.
// Dùng: node scripts/port/swift2ts.mjs <file.swift> > out.ts
import fs from 'node:fs'

const src = fs.readFileSync(process.argv[2], 'utf8')

// ---------- tiện ích phân tích ngoặc ----------
function findClose(s, open) {
  // s[open] là '(' hoặc '[' hoặc '{'; trả về vị trí ngoặc đóng tương ứng (bỏ qua chuỗi).
  const pairs = { '(': ')', '[': ']', '{': '}' }
  const stack = [pairs[s[open]]]
  let i = open + 1
  let inStr = false
  while (i < s.length) {
    const ch = s[i]
    if (inStr) {
      if (ch === '\\') { i += 2; continue }
      if (ch === '"') inStr = false
    } else if (ch === '"') inStr = true
    else if (pairs[ch]) stack.push(pairs[ch])
    else if (ch === ')' || ch === ']' || ch === '}') {
      stack.pop()
      if (stack.length === 0) return i
    }
    i++
  }
  return -1
}

function splitTop(s) {
  const parts = []
  let depth = 0, start = 0, inStr = false
  for (let i = 0; i < s.length; i++) {
    const ch = s[i]
    if (inStr) { if (ch === '\\') { i++; continue } if (ch === '"') inStr = false; continue }
    if (ch === '"') { inStr = true; continue }
    if ('([{'.includes(ch)) depth++
    else if (')]}'.includes(ch)) depth--
    else if (ch === ',' && depth === 0) { parts.push(s.slice(start, i)); start = i + 1 }
  }
  parts.push(s.slice(start))
  return parts.map(p => p.trim()).filter((p, i, a) => !(p === '' && a.length === 1))
}

function labeled(arg) {
  const m = /^([A-Za-z_]\w*)\s*:\s([\s\S]*)$/.exec(arg)
  return m ? { label: m[1], value: m[2] } : { label: null, value: arg }
}

// Thay mọi lời gọi `name(...)` (không đứng sau dấu chấm/chữ) bằng fn(args).
function replaceCall(s, name, fn, { dotted = false } = {}) {
  let out = ''
  let i = 0
  const re = new RegExp((dotted ? '' : '(?<![\\w.])') + name.replace(/[.]/g, '\\.') + '\\(', 'g')
  while (true) {
    re.lastIndex = i
    const m = re.exec(s)
    if (!m) { out += s.slice(i); break }
    const open = m.index + m[0].length - 1
    const close = findClose(s, open)
    if (close < 0) { out += s.slice(i); break }
    const inner = s.slice(open + 1, close)
    const args = splitTop(inner).map(labeled)
    const rep = fn(args, inner)
    if (rep == null) { out += s.slice(i, close + 1); i = close + 1; continue }
    out += s.slice(i, m.index) + rep
    i = close + 1
  }
  return out
}

let s = src

// ---------- bước 1: dọn dòng ----------
s = s.replace(/^import .*\n/gm, '')
s = s.replace(/\/\/\/ ?/g, '// ')
s = s.replace(/@discardableResult\s*/g, '')
s = s.replace(/\bCGFloat\.pi\b|\bDouble\.pi\b|(?<![\w)])\.pi\b/g, 'Math.PI')

// ---------- bước 2: các hàm tạo đặc biệt ----------
s = replaceCall(s, 'CGPoint', a => `pt(${a[0].value}, ${a[1].value})`)
s = replaceCall(s, 'CGSize', a => `{ width: ${a[0].value}, height: ${a[1].value} }`)
s = replaceCall(s, 'CGRect', a => a.length === 4 ? `R(${a.map(x => x.value).join(', ')})` : null)
s = replaceCall(s, 'Color.dynamic', a => `rgb(${a[0].value})`, { dotted: true })
s = replaceCall(s, 'Color', a => a[0]?.label === 'red' ? `Color.rgb01(${a.map(x => x.value).join(', ')})` : null)
s = replaceCall(s, 'Path', a => {
  if (a.length === 0 || (a.length === 1 && a[0].value === '')) return 'new Path()'
  if (a[0].label === 'ellipseIn') return `Path.ellipse(${a[0].value})`
  if (a[0].label === 'roundedRect') return `Path.roundedRect(${a[0].value}, ${a[1].value})`
  if (a.length === 1 && !a[0].label) return `Path.rect(${a[0].value})`
  return null
})
s = s.replace(/cornerSize:\s*\{ width: ([^,]+), height: [^}]+\}/g, '$1')
s = replaceCall(s, 'StrokeStyle', a => {
  const w = a.find(x => x.label === 'lineWidth')?.value ?? '1'
  const dash = a.find(x => x.label === 'dash')?.value
  return dash ? `${w}, { dash: ${dash} }` : w
})
// ctx.draw(Text("✦").font(.system(size: 6[, weight: .bold])).foregroundColor(C), at: P) → ctx.text("✦", 6, C, P[, 'bold'])
s = replaceCall(s, '.draw', (args, inner) => {
  if (!inner.startsWith('Text(')) return null
  const [textExpr, atArg] = args
  const m = /^Text\(("(?:[^"\\]|\\.)*")\)\.font\(\.system\(size: ([^,)]+)(?:, weight: \.(\w+))?(?:, design: \.\w+)?\)\)\.foregroundColor\(([\s\S]*)\)$/.exec(textExpr.value)
  if (!m) return null
  const [, str, size, weight, color] = m
  return `.text(${str}, ${size}, ${color}, ${atArg.value}${weight ? `, '${weight}'` : ''})`
}, { dotted: true })

s = s.replace(/\.degrees\(/g, 'deg(')
s = s.replace(/(?<![\w)])\.color\(/g, '(')
s = s.replace(/(?<![\w)\]])\.(white|black|clear)\b/g, 'Color.$1')
s = s.replace(/\bColor\.(white|black|clear)\b/g, 'Color.$1')

// ---------- bước 3: khai báo hàm ----------
const typeMap = t => {
  t = t.trim()
  const map = {
    CGFloat: 'number', Double: 'number', Int: 'number', Float: 'number', TimeInterval: 'number',
    GraphicsContext: 'GC', CGPoint: 'Pt', CGRect: 'Rect', CGSize: '{ width: number; height: number }',
    String: 'string', Bool: 'boolean', Color: 'Color', Path: 'Path', 'String?': 'string | undefined | null',
  }
  if (map[t]) return map[t]
  if (/^\[(\w+)\]$/.test(t)) return `${typeMap(t.slice(1, -1))}[]`
  if (t.endsWith('?')) return `${typeMap(t.slice(0, -1))} | null | undefined`
  if (t.startsWith('(')) return 'any'
  return t
}

s = s.replace(/^(\s*)(private |fileprivate )?(static )?(mutating )?func (\w+)\(([^)]*(?:\([^)]*\)[^)]*)*)\)(?:\s*->\s*([^{]+?))?\s*\{/gm,
  (_m, ind, priv, stat, _mut, name, params, ret) => {
    const ps = splitTop(params).filter(Boolean).map(p => {
      // `_ ctx: T`, `label name: T = d`, `name: T`
      const m = /^(?:(\w+)\s+)?(\w+)\s*:\s*(.+?)(?:\s*=\s*(.+))?$/.exec(p.trim())
      if (!m) return `/*?*/${p}`
      const [, , n, t, d] = m
      return `${n}: ${typeMap(t)}${d ? ` = ${d}` : ''}`
    })
    const r = ret ? `: ${typeMap(ret)}` : ''
    const exp = stat && !priv ? 'export ' : ''
    return `${ind}${exp}function ${name}⟦${ps.join(', ')}⟧${r} {`
  })

// ---------- bước 4: bỏ nhãn tham số trong mọi lời gọi; tuple → mảng ----------
function stripLabels(s) {
  let out = ''
  let i = 0
  while (i < s.length) {
    const ch = s[i]
    if (ch === '"') {
      const j = s.indexOf('"', i + 1)
      out += s.slice(i, j + 1); i = j + 1; continue
    }
    if (ch === '(') {
      const close = findClose(s, i)
      if (close < 0) { out += s.slice(i); break }
      const before = out.replace(/\s+$/, '')
      const prev = before[before.length - 1] ?? ''
      const isCall = /[\w)\]?!>]/.test(prev)
      const inner = s.slice(i + 1, close)
      const parts = splitTop(inner)
      const conv = parts.map(p => stripLabels(isCall ? labeled(p).value : p))
      // Tuple (không phải lời gọi, có dấu phẩy ở mức ngoài) → mảng. Bỏ qua nhóm điều kiện.
      const isTuple = !isCall && parts.length > 1 && !/\b(if|while|switch|for|guard|return)\s*$/.test(before) || (!isCall && parts.length > 1 && /return\s*$/.test(before))
      if (isTuple) out += '[' + conv.map(p => (labeled(p).label ? labeled(p).value : p)).join(', ') + ']'
      else out += '(' + conv.join(', ') + ')'
      i = close + 1
      continue
    }
    out += ch
    i++
  }
  return out
}
s = stripLabels(s)
s = s.replace(/⟦/g, '(').replace(/⟧/g, ')')

// ---------- bước 5: biểu thức ----------
s = s.replace(/\bCGFloat\(|\bDouble\(|\bFloat\(/g, '(')
s = s.replace(/\bInt\(/g, 'Math.trunc(')
s = s.replace(/(?<![\w.])(abs|sin|cos|max|min|pow|floor|ceil|sqrt|atan2|hypot)\(/g, 'Math.$1(')
s = s.replace(/ as \[\[[^\]\n]*\]\]/g, '')
s = s.replace(/ as \[[^\]\n]*\]/g, '')
s = s.replace(/([A-Za-z_)\]])\.(\d+)\b/g, '$1[$2]')
// x.truncatingRemainder(y) — người nhận là định danh hoặc nhóm ngoặc.
s = s.replace(/((?:\w|\.)+|\([^()]*\))\.truncatingRemainder\(([^()]*(?:\([^()]*\))?[^()]*)\)/g, '($1 % ($2))')

// ---------- bước 6: khai báo biến ----------
s = s.replace(/^(\s*)(?:private |fileprivate )?(?:static )?let (\w+)\s*:\s*[^=\n{]+=/gm, '$1const $2 =')
s = s.replace(/^(\s*)(?:private |fileprivate )?(?:static )?var (\w+)\s*:\s*[^=\n{]+=/gm, '$1⟦LET⟧ $2 =')
s = s.replace(/^(\s*)(?:private |fileprivate )?(?:static )?let /gm, '$1const ')
s = s.replace(/^(\s*)(?:private |fileprivate )?(?:static )?var /gm, '$1⟦LET⟧ ')
s = s.replace(/⟦LET⟧/g, 'let')
s = s.replace(/^(\s*)let (\w+) = (ctx|base|context|clipped|dome|layer)\s*$/gm, '$1const $2 = $3.copy()')

// ---------- bước 7: điều khiển ----------
s = s.replace(/^(\s*)for \((.+?)\) in (.+?)\.enumerated\(\) \{/gm, '$1for (const [$2] of $3.entries()) {')
s = s.replace(/^(\s*)for \(([\w, ]+?)\) in (.+?) \{/gm, '$1for (const [$2] of $3) {')
s = s.replace(/^(\s*)for (\w+) in ([^.\n]+?)\.\.<(.+?) where (.+?) \{/gm, '$1for (let $2 = $3; $2 < $4; $2++) { if (!($5)) continue;')
s = s.replace(/^(\s*)for (\w+) in ([^.\n]+?)\.\.<(.+?) \{/gm, '$1for (let $2 = $3; $2 < $4; $2++) {')
s = s.replace(/^(\s*)for (\w+) in ([^.\n]+?)\.\.\.(.+?) \{/gm, '$1for (let $2 = $3; $2 <= $4; $2++) {')
s = s.replace(/^(\s*)for (\w+) in stride\((.+?), (.+?), (.+?)\) \{/gm, '$1for (let $2 = $3; $2 < $4; $2 += $5) {')
s = s.replace(/^(\s*)for \[(.+?)\] in (.+?)\.enumerated\(\) \{/gm, '$1for (const [$2] of $3.entries()) {')
s = s.replace(/^(\s*)for \[(.+?)\] in (.+?) \{/gm, '$1for (const [$2] of $3) {')
s = s.replace(/^(\s*)for (\w+) in (.+?) where (.+?) \{/gm, '$1for (const $2 of $3) { if (!($4)) continue;')
s = s.replace(/^(\s*)for (\w+) in (.+?) \{/gm, '$1for (const $2 of $3) {')
s = s.replace(/^(\s*)guard (.+?) else \{ (.*?) \}\s*$/gm, '$1if (!($2)) { $3 }')
s = s.replace(/^(\s*)(\} else )?if (.+?) \{(.*)$/gm, (m, ind, els, cond, rest) =>
  /^let /.test(cond) ? m : `${ind}${els ?? ''}if (${cond}) {${rest}`)
s = s.replace(/^(\s*)while (.+?) \{/gm, '$1while ($2) {')
s = s.replace(/^(\s*)switch (.+?) \{/gm, '$1switch ($2) {')

// ---------- bước 8: case trong switch (theo dòng, có ngăn xếp) ----------
{
  const lines = s.split('\n')
  const out = []
  const stack = [] // {depth, first}
  let depth = 0
  for (let line of lines) {
    const trimmed = line.trim()
    const top = stack[stack.length - 1]
    const caseM = /^(\s*)case (.+?):\s*(.*)$/.exec(line)
    const defM = /^(\s*)default:\s*(.*)$/.exec(line)
    if (top && depth === top.depth + 1 && (caseM || defM)) {
      if (caseM) {
        const [, ind, pats, rest] = caseM
        const labels = splitTop(pats).map(p => `case ${p.replace(/(?<![\w)\]])\.(\w+)/g, "'$1'")}:`).join(' ')
        line = `${ind}${top.first ? '' : 'break; '}${labels} ${rest}`
      } else {
        line = `${defM[1]}${top.first ? '' : 'break; '}default: ${defM[2]}`
      }
      top.first = false
    }
    if (/^switch \(.+\) \{$/.test(trimmed)) stack.push({ depth, first: true })
    for (const ch of line.replace(/"(?:[^"\\]|\\.)*"/g, '""')) {
      if (ch === '{') depth++
      if (ch === '}') {
        depth--
        if (stack.length && depth === stack[stack.length - 1].depth) stack.pop()
      }
    }
    out.push(line)
  }
  s = out.join('\n')
}

// ---------- bước 9: closure theo sau ----------
{
  let out = ''
  const closers = []
  let i = 0
  let depth = 0
  while (i < s.length) {
    const ch = s[i]
    if (ch === '"') { const j = s.indexOf('"', i + 1); out += s.slice(i, j + 1); i = j + 1; continue }
    if (ch === '{') {
      const m = /^\{\s*(\w+|\(\w+(?:, \w+)*\))\s+in\b/.exec(s.slice(i))
      if (m) {
        const params = m[1].startsWith('(') ? m[1] : `(${m[1]})`
        const trimmed = out.replace(/\s+$/, '')
        if (trimmed.endsWith(')')) {
          const inner = trimmed.slice(0, -1)
          const sep = inner.endsWith('(') ? '' : ', '
          out = inner + sep + `${params} => {`
          closers.push(depth)
        } else {
          out += `${params} => {`
          closers.push(-1 - depth)
        }
        depth++
        i += m[0].length
        continue
      }
      depth++
      out += ch
      i++
      continue
    }
    if (ch === '}') {
      depth--
      if (closers.length && (closers[closers.length - 1] === depth)) {
        closers.pop()
        out += '})'
        i++
        continue
      }
      if (closers.length && closers[closers.length - 1] === -1 - depth) closers.pop()
      out += ch
      i++
      continue
    }
    out += ch
    i++
  }
  s = out
}

// ---------- bước 10: enum dạng shorthand → chuỗi; dọn ----------
s = s.replace(/(==|!=|\? |: |return |, |\(|= |\?\? )\s*\.([a-z]\w*)\b(?!\()/g, (m, op, name) => `${op} '${name}'`)
s = s.replace(/'(\w+)' as const/g, "'$1'")

// ---------- bước 11: thuộc tính tính toán tĩnh, bỏ vỏ enum ----------
{
  const lines = s.split('\n')
  for (let i = 0; i < lines.length; i++) {
    const m = /^(\s*)let (\w+): ([^={]+?) \{\s*$/.exec(lines[i])
    if (!m) continue
    let depth = 0, j = i
    for (; j < lines.length; j++) {
      for (const ch of lines[j]) { if (ch === '{') depth++; if (ch === '}') depth-- }
      if (depth === 0) break
    }
    const body = lines.slice(i + 1, j)
    const hasReturn = body.some(l => /\breturn\b/.test(l))
    const repl = hasReturn
      ? [`${m[1]}const ${m[2]} = ((): ${m[3]} => {`, ...body, `${m[1]}})()`]
      : [`${m[1]}const ${m[2]} = (`, ...body, `${m[1]})`]
    lines.splice(i, j - i + 1, ...repl)
  }
  // enum/struct ở mức ngoài cùng chỉ chứa hàm tĩnh → module.
  const out = []
  const exported = new Map()
  let current = null, depth = 0
  for (const line of lines) {
    const em = /^enum (\w+) \{\s*$/.exec(line)
    if (em && depth === 0) { current = em[1]; exported.set(current, []); depth = 1; continue }
    const before = depth
    for (const ch of line.replace(/"(?:[^"\\]|\\.)*"/g, '""')) { if (ch === '{') depth++; if (ch === '}') depth-- }
    if (current && before === 1 && depth === 0 && line.trim() === '}') { current = null; continue }
    if (current) {
      const fm = /^    export function (\w+)/.exec(line)
      if (fm) exported.get(current).push(fm[1])
      out.push(line.replace(/^    /, ''))
    } else out.push(line)
  }
  s = out.join('\n')
  for (const [name, fns] of exported) s += `\nexport const ${name} = { ${fns.join(', ')} }\n`
}

process.stdout.write('// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.\n' + s)
