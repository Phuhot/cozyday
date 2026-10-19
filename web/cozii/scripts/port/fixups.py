# Sửa các mẫu mà swift2ts.mjs chưa xử lý (chạy sau swift2ts, trước wrap-switch).
import re, glob
OUT = 'src/art/ported'
for f in glob.glob(OUT + '/*.ts'):
    s = open(f).read()
    s = re.sub(r'for \(([\w, ]+)\) in (\[[\s\S]*?\])\.enumerated\(\) \{', lambda m: f'for (const [{m.group(1)}] of {m.group(2)}.entries()) {{', s)
    s = re.sub(r'for \(([\w, ]+)\) in (\[[\s\S]*?\]) \{', lambda m: f'for (const [{m.group(1)}] of {m.group(2)}) {{', s)
    s = re.sub(r'private enum (\w+) \{ case ([\w, ]+) \}', lambda m: 'type ' + m.group(1) + ' = ' + ' | '.join("'" + x.strip() + "'" for x in m.group(2).split(',')), s)
    s = re.sub(r'\[\((-?[\d.]+)\), \((-?[\d.]+)\)(?:, \((-?[\d.]+)\))?\]', lambda m: '[' + ', '.join(g for g in m.groups() if g is not None) + ']', s)
    s = re.sub(r'(for \(const \[[\w, ]+\] of \[[\s\S]*?\]\])( \{)', lambda m: m.group(1) + (')' if not m.group(1).endswith(')') else '') + m.group(2), s)
    s = re.sub(r'for \(([\w, ]+)\) in (\[[\s\S]*?\])\.entries\(\)\) \{', lambda m: f'for (const [{m.group(1)}] of {m.group(2)}.entries()) {{', s)
    # Mảng tuple hằng → `as const` để giữ kiểu từng phần tử.
    s = re.sub(r'(for \(const \[[\w, ]+\] of )(\[\[[\s\S]*?\]\])(\.entries\(\))?\) \{', lambda m: f'{m.group(1)}({m.group(2)} as const){m.group(3) or ""}) {{', s)
    s = re.sub(r'(const \w+ = )(\[\[[^;]*?\]\])(\s*\n)', lambda m: f'{m.group(1)}{m.group(2)} as const{m.group(3)}', s)
    # Biến cục bộ trùng tên hàm pt.
    s = re.sub(r'\bconst pt = pt\(', 'const pp = pt(', s)
    s = re.sub(r'if let (\w+) = ([\w.]+) \{ (.*) \}$', r'{ const \1 = \2; if (\1) { \3 } }', s, flags=re.M)
    open(f, 'w').write(s)

def edit(name, pairs):
    f = f'{OUT}/{name}.ts'
    s = open(f).read()
    for a, b in pairs:
        if a not in s:
            print(f'!! {name}: không thấy: {a[:70]}')
        s = s.replace(a, b)
    open(f, 'w').write(s)

edit('BedroomArt', [
    ("pattern: any): Void)? = nil) {", "pattern?: (g: GC) => void) {"),
    ("pattern?(b)", "pattern?.(b)"),
])
edit('CostumeArt', [
    ("const s = 2.5, ox: CGFloat = 26.25, oy: CGFloat = 44.5", "const s = 2.5, ox = 26.25, oy = 44.5"),
    ("for (let col = Array(1; col <= 7) + Array(11...17); col++) {", "for (const col of [1,2,3,4,5,6,7,11,12,13,14,15,16,17]) {"),
    ("for (let col = Array(2; col <= 6) + Array(12...16); col++) {", "for (const col of [2,3,4,5,6,12,13,14,15,16]) {"),
    ("for (let col = Array(3; col <= 5) + Array(13...15); col++) {", "for (const col of [3,4,5,13,14,15]) {"),
])
edit('ItemPainter', [
    ("""export function isScene(id: string): boolean { Catalog.item(id)?.slot.isTheme ?? false }

export function draw(id: string, ctx: GC) {
    if StudyArt.draw(id, ctx) || BedroomArt.draw(id, ctx) || KitchenArt.draw(id, ctx)
        || BathArt.draw(id, ctx) || GardenArt.draw(id, ctx) {
        return
    }""", """export function draw(id: string, ctx: GC) {
    if (StudyArt.draw(id, ctx) || BedroomArt.draw(id, ctx) || KitchenArt.draw(id, ctx)
        || BathArt.draw(id, ctx) || GardenArt.draw(id, ctx)) {
        return
    }"""),
    ("import { Palette } from '../palette'", "import { Palette } from '../palette'\nimport { StudyArt } from './StudyArt'\nimport { BedroomArt } from './BedroomArt'\nimport { KitchenArt } from './KitchenArt'\nimport { BathArt } from './BathArt'\nimport { GardenArt } from './GardenArt'"),
])


def as_const_multiline(s):
    out = []
    i = 0
    pat = re.compile(r'const \w+ = \[\s*\n\s*\[')
    while True:
        m = pat.search(s, i)
        if not m:
            out.append(s[i:]); break
        start = m.end() - 1 - len(m.group(0)) + m.group(0).index('[')
        # vị trí '[' ngoài cùng
        open_ = m.start() + m.group(0).index('[')
        depth = 0; j = open_
        while j < len(s):
            if s[j] == '[': depth += 1
            elif s[j] == ']':
                depth -= 1
                if depth == 0: break
            j += 1
        out.append(s[i:j+1])
        if not s[j+1:j+10].startswith(' as const'):
            out.append(' as const')
        i = j + 1
    return ''.join(out)

for f in glob.glob(OUT + '/*.ts'):
    s = open(f).read()
    s = as_const_multiline(s)
    s = re.sub(r'^\s*function pt\(x: number, y: number\): Pt \{ pt\(x, y\) \}\s*$\n', '', s, flags=re.M)
    s = re.sub(r'^(\s*(?:export )?function \w+\([^)]*\): (?!void)[\w\[\] |]+ \{ )(?!return)(.+) \}\s*$', r'\1return \2 }', s, flags=re.M)
    s = re.sub(r'\.count\b', '.length', s)
    s = re.sub(r'\.append\(', '.push(', s)
    s = re.sub(r'\[\[CGFloat, CGFloat, CGFloat\]\]', 'ReadonlyArray<readonly [number, number, number]>', s)
    s = re.sub(r'\bCGFloat\b', 'number', s)
    s = re.sub(r'^(\s*)let pts = \[\]', r'\1const pts: Pt[] = []', s, flags=re.M)
    s = re.sub(r'^(\s*)_ = ', r'\1', s, flags=re.M)
    s = re.sub(r"'zero'", 'pt(0, 0)', s)
    s = re.sub(r'=> \{ ([^{};\n]+?) \}', r'=> (\1)', s)
    s = re.sub(r'\[x, y, _, _\]', '[x, y]', s)
    open(f, 'w').write(s)

edit('ItemPainter', [("export const ItemPainter = { isScene, draw }", "export const ItemPainter = { draw }")])

# PetPainter: struct → hàm drawPet với closure.
f = f'{OUT}/PetPainter.ts'
s = open(f).read()
head = open('scripts/port/petpainter-head.ts.txt').read()
i = s.index('    const stageScale')
body = s[i:].rstrip()
assert body.endswith('}')
body = body[:-1]
s = head + body + '    draw(base0)\n}\n'
s = s.replace('FurPalette.of(', 'furPalette(').replace('((): CGFloat =>', '((): number =>')
s = re.sub(r'if let (\w+) = ([\w.]+) \{ (.*) \}$', r'{ const \1 = \2; if (\1) { \3 } }', s, flags=re.M)
s = s.replace("""        if let hat = appearance.hat {
            drawHat(ctx, hat)
            // Tai thỏ dài: thò ra ngoài mũ len / mũ cói thay vì bị che mất.
            if (appearance.species == 'bunny' && (hat == "hat.beanie" || hat == "hat.straw")) { drawEars(ctx, fur) }
        }""", """        const hat = appearance.hat
        if (hat) {
            drawHat(ctx, hat)
            // Tai thỏ dài: thò ra ngoài mũ len / mũ cói thay vì bị che mất.
            if (appearance.species == 'bunny' && (hat == "hat.beanie" || hat == "hat.straw")) { drawEars(ctx, fur) }
        }""")
s = s.replace("""            switch (faceMood) {
            case 'idle' where !closed && appearance.species == 'capybara': """, """            if (faceMood == 'idle' && !closed && appearance.species == 'capybara') {""")
s = s.replace("""            break; case 'idle' where !closed: """, """            } else if (faceMood == 'idle' && !closed) {""")
s = s.replace("""            break; case 'low' where !pose.blink: """, """            } else if (faceMood == 'low' && !pose.blink) {""")
a = s.index("} else if (faceMood == 'low' && !pose.blink) {")
b = s.index("        // má hồng")
blk = s[a:b]
blk = blk.replace("            break; case 'idle': case 'low': ", "            } else if (faceMood == 'idle' || faceMood == 'low') {")
blk = blk.replace("            break; case 'happy': ", "            } else if (faceMood == 'happy') {")
blk = blk.replace("            break; case 'focus': ", "            } else if (faceMood == 'focus') {")
blk = blk.replace("            break; case 'rest': ", "            } else if (faceMood == 'rest') {")
s = s[:a] + blk + s[b:]
s = s.replace("const step = pose.walk.map { Math.sin($0) * 2.2 } ?? 0", "const step = pose.walk != null ? Math.sin(pose.walk) * 2.2 : 0")
s = s.replace("const feet = [[41, 80 - step + dangle, -1], [59, 80 + step + dangle, 1]]", "const feet = [{ x: 41, y: 80 - step + dangle, side: -1 }, { x: 59, y: 80 + step + dangle, side: 1 }]")
s = s.replace("if ((!(let p = pose.hearts))) { return }", "const p = pose.hearts; if (p == null) { return }")
open(f, 'w').write(s)

edit('CostumeArt', [("import { Palette } from '../palette'", "import { Palette } from '../palette'\nimport type { PetAppearance } from '../../content/pet'\nimport { furPalette, type FurPalette } from './PetPainter'")])
for _n in ['BedroomArt']:
    _f = f'{OUT}/{_n}.ts'; _s = open(_f).read().replace("const fx = (x) =>", "const fx = (x: number) =>"); open(_f, 'w').write(_s)
edit('BathArt', [("shell.addLine(pt)", "shell.addLine(pp)"), ("shell.addQuadCurve(pt, ctrl)", "shell.addQuadCurve(pp, ctrl)")])
_f = f'{OUT}/CostumeArt.ts'; _s = open(_f).read().replace('FurPalette.of(', 'furPalette('); open(_f, 'w').write(_s)
