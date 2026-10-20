# Bọc thân mỗi `case` (do swift2ts sinh ra) trong { } để khai báo const không trùng phạm vi.
import re, sys
def count(line):
    line = re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)
    line = re.sub(r"'(?:[^'\\]|\\.)*'", "''", line)
    line = re.sub(r'//.*$', '', line)
    return line.count('{') - line.count('}')
CASE = re.compile(r'^(\s*)(break; )?((?:case .+?:\s*)+|default:\s*)(.*)$')
for f in sys.argv[1:]:
    lines = open(f).read().split('\n')
    i = 0
    while i < len(lines):
        if re.match(r'^\s*switch \(.*\) \{\s*$', lines[i]):
            depth = 1          # bên trong thân switch
            opened = False
            j = i + 1
            while j < len(lines):
                line = lines[j]
                level = 2 if opened else 1
                m = CASE.match(line)
                if depth == level and m and (m.group(3).startswith('case') or m.group(3).startswith('default')):
                    ind, brk, labels, rest = m.groups()
                    prefix = '} ' if opened else ''
                    lines[j] = f"{ind}{prefix}{brk or ''}{labels.rstrip()} {{ {rest}"
                    opened = True
                    depth = 2 + count(rest)
                    j += 1
                    continue
                d = count(line)
                if depth + d == level - 1:
                    # dòng đóng switch
                    if opened:
                        lines[j] = re.sub(r'^(\s*)\}', r'\1} }', line, count=1)
                    break
                depth += d
                j += 1
        i += 1
    open(f, 'w').write('\n'.join(lines))
