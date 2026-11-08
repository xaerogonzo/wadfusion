#!/usr/bin/env python3
"""
Read-only inventory of the two Xtras packs (Xtras main and Xtras Revised beta).

Nothing is extracted or modified: both archives are only opened for reading. The output is
  merge_manifest.json   machine readable ledger (every file, classification, decision, reason)
  MERGE_NOTES.md        human readable summary generated from the manifest

Usage:
  python xtras/diff_xtras.py --main Wadfusion-Xtras-main.zip --revised Wadfusion-Xtras-Revised_beta.pk3 \
         [--source-wads DIR] [--decisions xtras/merge_decisions.json] [--out xtras]

Classification of each file of the Revised pack against Main:
  1  same normalised path, identical content
  2  same normalised path, different content
  3  different path, identical content (the content exists elsewhere in Main)
  4  different path and content, but the same logical resource name in the same namespace
  5  (definition files) conflicting engine-level definitions, reported in the "definitions" section
  6  unique to Revised but already supplied by another dependency (for example a source WAD)
  U  unique to Revised
Files only in Main are classified M.
"""
import argparse, collections, hashlib, json, os, re, sys, zipfile

PREFIXES = {'main': ('wadfusion-xtras-main/',), 'revised': ('wadfusion-xtras-revised_beta/',)}


def norm(path, which):
    p = path.replace('\\', '/').lower()
    for pre in PREFIXES[which]:
        if p.startswith(pre):
            p = p[len(pre):]
    return p


NAMESPACE_DIRS = ('sprites', 'sounds', 'music', 'maps', 'graphics', 'patches', 'flats', 'textures', 'credits')


def categorise(p):
    base = p.split('/')[-1]
    top = p.split('/')[0] if '/' in p else ''
    stem = os.path.splitext(base)[0]
    if top == 'zscript' or base in ('zscript.txt', 'zscript.zsc', 'zscript'):
        return 'zscript'
    if top == 'acs' or base in ('loadacs',):
        return 'acs'
    if base.startswith('mapinfo') or top == 'mapinfo' or base.startswith('zmapinfo'):
        return 'mapinfo'
    if base.startswith('menudef'):
        return 'menudef'
    if base.startswith('language'):
        return 'language'
    if base.startswith('cvarinfo'):
        return 'cvarinfo'
    if base.startswith('sndinfo'):
        return 'sndinfo'
    if base.startswith('textures.') or base == 'textures' or base.endswith('textures.wad'):
        return 'textures'
    if base.startswith('animdefs'):
        return 'animdefs'
    if base.startswith('fontdefs'):
        return 'fontdefs'
    if base.startswith('trnslate'):
        return 'trnslate'
    if top == 'sprites':
        return 'sprite'
    if top == 'sounds':
        return 'sound'
    if top == 'music':
        return 'music'
    if top == 'maps':
        return 'map'
    if top in ('graphics', 'patches', 'flats'):
        return 'graphic'
    if top == 'credits' or base.startswith('credits') or base.endswith('wadinfo.txt') or base.startswith('d64d2_wadinfo'):
        return 'credits'
    return 'other'


def logical(p, cat):
    top = p.split('/')[0] if '/' in p else ''
    stem = os.path.splitext(p.split('/')[-1])[0]
    if top in ('sprites', 'sounds', 'music', 'maps', 'graphics', 'patches', 'flats'):
        return top + ':' + stem
    return ''


def sha256_of(zf, info):
    h = hashlib.sha256()
    with zf.open(info) as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def file_hash(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def read_archive(path, which):
    zf = zipfile.ZipFile(path)
    entries, collisions, seen = [], [], {}
    for info in zf.infolist():
        if info.filename.endswith('/'):
            continue
        n = norm(info.filename, which)
        if n in seen:
            collisions.append([seen[n], info.filename])
        seen[n] = info.filename
        cat = categorise(n)
        entries.append({
            'archive': which, 'path': info.filename, 'norm': n, 'sha256': sha256_of(zf, info),
            'size': info.file_size, 'category': cat, 'logical': logical(n, cat),
        })
    return zf, entries, collisions


def text_of(zf, entry):
    try:
        return zf.read(entry['path']).decode('utf-8', errors='replace')
    except Exception:
        return ''


# ------------------------------------------------------------------ definition parsers

def strip_comments(t):
    t = re.sub(r'/\*.*?\*/', ' ', t, flags=re.S)
    return re.sub(r'//[^\n]*', '', t)


def parse_zscript(zf, entries):
    classes = {}
    for e in entries:
        if e['category'] != 'zscript' or not e['norm'].endswith(('.zsc', '.zs')):
            continue
        t = strip_comments(text_of(zf, e))
        for m in re.finditer(r'(?m)^[ \t]*(?:extend\s+)?(class|struct)\s+(\w+)\s*(?::\s*(\w+))?([^{;]*)\{', t):
            kind, name, parent, rest = m.group(1), m.group(2), m.group(3) or '', m.group(4)
            start = m.end()
            depth, i = 1, start
            while i < len(t) and depth:
                c = t[i]
                depth += (c == '{') - (c == '}')
                i += 1
            body = t[start:i - 1]
            methods = sorted(set(re.findall(r'(?m)^[ \t]*(?:(?:override|virtual|static|action|play|ui|clearscope|native|final|const|private|protected|deprecated\([^)]*\))\s+)*[\w<>\[\],]+\s+(\w+)\s*\(', body)))
            fields = sorted(set(re.findall(r'(?m)^[ \t]*(?:(?:meta|transient|private|protected|readonly|play|ui|clearscope|static|const)\s+)*(?:int|bool|double|float|String|Name|Color|Class<\w+>|Actor|Sound|TextureID|Vector[234]|Array<[^>]+>|[A-Z]\w+)\s+(\w+)\s*(?:=[^;]*)?;', body)))
            is_extend = bool(re.match(r'\s*extend', m.group(0)))
            key = name.lower()
            digest = hashlib.sha256(re.sub(r'\s+', ' ', body).encode()).hexdigest()
            if key in classes:
                # an "extend class" block or a second definition: accumulate members across all blocks
                c = classes[key]
                c['methods'] = sorted(set(c['methods']) | set(methods))
                c['fields'] = sorted(set(c['fields']) | set(fields))
                c['has_states'] = c['has_states'] or 'States' in body
                c['files'] = sorted(set(c['files']) | {e['norm']})
                c['body_sha256'] = hashlib.sha256((c['body_sha256'] + digest).encode()).hexdigest()
                if parent and not c['parent']:
                    c['parent'] = parent
                continue
            classes[key] = {
                'name': name, 'kind': kind, 'parent': parent, 'file': e['norm'], 'files': [e['norm']], 'flags': ' '.join(rest.split()),
                'methods': methods, 'fields': fields, 'extend_only': is_extend,
                'has_states': 'States' in body, 'body_sha256': digest,
            }
    return classes


def parse_cvarinfo(zf, entries):
    out = {}
    for e in entries:
        if e['category'] != 'cvarinfo':
            continue
        t = strip_comments(text_of(zf, e))
        for m in re.finditer(r'(?im)^\s*((?:\w+\s+)*?)(int|float|bool|string|color)\s+(\w+)\s*(?:=\s*([^;]*))?;', t):
            flags = ' '.join(m.group(1).split()).lower()
            out[m.group(3).lower()] = {'name': m.group(3), 'type': m.group(2).lower(), 'default': (m.group(4) or '').strip(), 'flags': flags, 'file': e['norm']}
    return out


def parse_keyed(zf, entries, category, pattern, valgroup=None):
    out = collections.defaultdict(list)
    for e in entries:
        if e['category'] != category:
            continue
        t = text_of(zf, e)
        for m in re.finditer(pattern, t):
            key = m.group(1).lower()
            val = re.sub(r'\s+', ' ', m.group(valgroup) if valgroup else m.group(0)).strip()
            out[key].append({'value': val, 'file': e['norm']})
    return out


def parse_language(zf, entries):
    out = {}
    for e in entries:
        if e['category'] != 'language':
            continue
        t = text_of(zf, e)
        lang = 'default'
        for line in t.splitlines():
            m = re.match(r'\s*\[([^\]]*)\]', line)
            if m:
                lang = m.group(1).strip().lower()
                continue
            m = re.match(r'\s*([A-Za-z0-9_$]+)\s*=\s*(.*)', line)
            if m:
                out.setdefault((lang, m.group(1).lower()), []).append(m.group(2).strip())
    return {'%s|%s' % k: v[-1] for k, v in out.items()}


def parse_mapinfo(zf, entries):
    maps, episodes = {}, {}
    for e in entries:
        if e['category'] != 'mapinfo' or not e['norm'].endswith(('.txt', '')):
            continue
        t = strip_comments(text_of(zf, e))
        for m in re.finditer(r'(?is)\b(map|episode|cluster|intermission)\s+("?[\w$]+"?)[^{]*\{(.*?)\n\}', t):
            kind, name, body = m.group(1).lower(), m.group(2).strip('"').lower(), m.group(3)
            d = {'file': e['norm'], 'sha256': hashlib.sha256(re.sub(r'\s+', ' ', body).encode()).hexdigest(),
                 'next': (re.search(r'(?i)\bnext\s*=?\s*"?([\w]+)', body) or [None, ''])[1] if kind == 'map' else ''}
            (maps if kind != 'episode' else episodes)['%s:%s' % (kind, name)] = d
    return maps, episodes


def parse_menudef(zf, entries):
    out = {}
    for e in entries:
        if e['category'] != 'menudef':
            continue
        t = strip_comments(text_of(zf, e))
        for m in re.finditer(r'(?im)^\s*(OptionMenu|OptionValue|ListMenu|AddOptionMenu|AddListMenu)\s+"([^"]+)"', t):
            out.setdefault('%s:%s' % (m.group(1).lower(), m.group(2).lower()), []).append(e['norm'])
        for m in re.finditer(r'(?im)^\s*(?:Option|Slider|ColorPicker|ScaleSlider|TextField|NumberField|Control|StaticText|Submenu)\s+"[^"]*"\s*,\s*"?([\w]+)"?', t):
            out.setdefault('cvar-use:%s' % m.group(1).lower(), []).append(e['norm'])
    return out


# ------------------------------------------------------------------ main

def compare_maps(a, b):
    res = {'same': [], 'different': [], 'only_main': sorted(set(a) - set(b)), 'only_revised': sorted(set(b) - set(a))}
    for k in sorted(set(a) & set(b)):
        (res['same'] if a[k].get('sha256') == b[k].get('sha256') else res['different']).append(k)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--main', required=True)
    ap.add_argument('--revised', required=True)
    ap.add_argument('--source-wads', default='')
    ap.add_argument('--decisions', default='')
    ap.add_argument('--out', default='xtras')
    args = ap.parse_args()

    zm, em, colm = read_archive(args.main, 'main')
    zr, er, colr = read_archive(args.revised, 'revised')

    A = {e['norm']: e for e in em}
    sha_a = collections.defaultdict(list)
    log_a = collections.defaultdict(list)
    for e in em:
        sha_a[e['sha256']].append(e['norm'])
        if e['logical']:
            log_a[e['logical']].append(e)
    B = {e['norm']: e for e in er}
    log_b = collections.defaultdict(list)
    for e in er:
        if e['logical']:
            log_b[e['logical']].append(e)
    sha_b = collections.defaultdict(list)
    for e in er:
        sha_b[e['sha256']].append(e['norm'])

    external = {}
    if args.source_wads and os.path.isdir(args.source_wads):
        for f in os.listdir(args.source_wads):
            external[os.path.splitext(f)[0].lower()] = f

    for e in em:
        if e['norm'] in B:
            e['classification'] = '1' if B[e['norm']]['sha256'] == e['sha256'] else '2'
        elif e['sha256'] in sha_b:
            e['classification'] = '3'
            e['same_content_as'] = sorted(sha_b[e['sha256']])[:3]
        elif e['logical'] and e['logical'] in log_b:
            e['classification'] = '4'
            e['same_logical_as'] = sorted(x['norm'] for x in log_b[e['logical']])[:3]
        else:
            e['classification'] = 'M'
        e['decision'] = 'keep-main'
        e['reason'] = {'1': 'identical in both', '2': 'main wins on conflicts', '3': 'identical content exists in revised under another path',
                       '4': 'main wins (same logical resource, different content)', 'M': 'only in main'}[e['classification']]

    for e in er:
        if e['norm'] in A:
            e['classification'] = '1' if A[e['norm']]['sha256'] == e['sha256'] else '2'
        elif e['sha256'] in sha_a:
            e['classification'] = '3'
            e['same_content_as'] = sorted(sha_a[e['sha256']])[:3]
        elif e['logical'] and e['logical'] in log_a:
            e['classification'] = '4'
            e['same_logical_as'] = sorted(x['norm'] for x in log_a[e['logical']])[:3]
        else:
            e['classification'] = 'U'
        if e['category'] == 'map' and e['classification'] in ('U',) and os.path.splitext(e['norm'].split('/')[-1])[0] in external:
            e['classification'] = '6'
            e['supplied_by'] = 'source_wads/' + external[os.path.splitext(e['norm'].split('/')[-1])[0]]
        e['decision'] = {'1': 'reuse-main', '2': 'needs-decision', '3': 'reuse-main', '4': 'needs-decision', 'U': 'import-candidate', '6': 'supplied-elsewhere'}[e['classification']]
        e['reason'] = {'1': 'identical in both', '2': 'same path, different content: main wins, revised version needs a runtime decision',
                       '3': 'identical content already in main', '4': 'same logical resource, different content: needs a runtime decision',
                       'U': 'unique to revised', '6': 'already supplied by a source WAD'}[e['classification']]

    # optional manual decisions (path-or-logical -> {decision, reason, feature, test})
    manual = {}
    if args.decisions and os.path.exists(args.decisions):
        manual = json.load(open(args.decisions, encoding='utf-8'))
        for e in em + er:
            for key in (e['archive'] + ':' + e['norm'], e['archive'] + ':' + e['logical'], e['norm']):
                if key and key in manual:
                    e.update({k: v for k, v in manual[key].items() if k in ('decision', 'reason', 'feature', 'test', 'implementation')})
                    break

    # ---- definition-level comparison
    ca, cb = parse_zscript(zm, em), parse_zscript(zr, er)
    shared = sorted(set(ca) & set(cb))
    class_report = {
        'main_total': len(ca), 'revised_total': len(cb),
        'only_revised': sorted(cb[k]['name'] for k in set(cb) - set(ca)),
        'only_main_count': len(set(ca) - set(cb)),
        'shared': {},
    }
    for k in shared:
        a, b = ca[k], cb[k]
        class_report['shared'][a['name']] = {
            'identical_body': a['body_sha256'] == b['body_sha256'],
            'parent_main': a['parent'], 'parent_revised': b['parent'],
            'methods_only_revised': sorted(set(b['methods']) - set(a['methods'])),
            'methods_only_main': sorted(set(a['methods']) - set(b['methods'])),
            'fields_only_revised': sorted(set(b['fields']) - set(a['fields'])),
            'fields_only_main': sorted(set(a['fields']) - set(b['fields'])),
            'file_main': a['file'], 'file_revised': b['file'],
        }
    class_report['only_revised_detail'] = {cb[k]['name']: {'parent': cb[k]['parent'], 'file': cb[k]['file'], 'methods': cb[k]['methods'], 'fields': cb[k]['fields']} for k in sorted(set(cb) - set(ca))}

    va, vb = parse_cvarinfo(zm, em), parse_cvarinfo(zr, er)
    cvar_report = {'only_revised': {k: vb[k] for k in sorted(set(vb) - set(va))},
                   'only_main_count': len(set(va) - set(vb)),
                   'shared_different': {k: {'main': va[k], 'revised': vb[k]} for k in sorted(set(va) & set(vb))
                                        if (va[k]['type'], va[k]['default'], va[k]['flags']) != (vb[k]['type'], vb[k]['default'], vb[k]['flags'])}}

    def keyed_compare(cat, pat, grp=None):
        a = parse_keyed(zm, em, cat, pat, grp)
        b = parse_keyed(zr, er, cat, pat, grp)
        res = {'only_revised': sorted(set(b) - set(a)), 'only_main': len(set(a) - set(b)), 'conflicting': []}
        for k in sorted(set(a) & set(b)):
            if a[k][-1]['value'] != b[k][-1]['value']:
                res['conflicting'].append({'key': k, 'main': a[k][-1]['value'][:160], 'revised': b[k][-1]['value'][:160]})
        return res

    definitions = {
        'sndinfo': keyed_compare('sndinfo', r'(?im)^\s*([A-Za-z0-9_/$.]+)\s+("?[\w./\\-]+"?)\s*$', 2),
        'animdefs': keyed_compare('animdefs', r'(?im)^\s*(?:texture|flat)\s+(?:optional\s+)?"?(\w+)"?(.*)$', 0),
        'fontdefs': keyed_compare('fontdefs', r'(?im)^\s*(\w+)\s*$', 0),
        'trnslate': keyed_compare('trnslate', r'(?im)^\s*(\w+)\s*=\s*(.*)$', 2),
        'textures': keyed_compare('textures', r'(?im)^\s*(?:Texture|Sprite|Graphic|WallTexture|Flat)\s+(?:optional\s+)?"?([\w\[\]\\]+)"?\s*,(.*)$', 0),
    }
    la, lb = parse_language(zm, em), parse_language(zr, er)
    definitions['language'] = {'only_revised': sorted(set(lb) - set(la))[:400], 'only_revised_count': len(set(lb) - set(la)), 'only_main': len(set(la) - set(lb)),
                               'conflicting': [{'key': k, 'main': la[k][:120], 'revised': lb[k][:120]} for k in sorted(set(la) & set(lb)) if la[k] != lb[k]][:400],
                               'conflicting_count': sum(1 for k in set(la) & set(lb) if la[k] != lb[k])}
    ma, ea = parse_mapinfo(zm, em)
    mb, eb = parse_mapinfo(zr, er)
    definitions['mapinfo_maps'] = compare_maps(ma, mb)
    definitions['mapinfo_episodes'] = compare_maps(ea, eb)
    ua, ub = parse_menudef(zm, em), parse_menudef(zr, er)
    definitions['menudef'] = {'only_revised': sorted(set(ub) - set(ua)), 'only_main': len(set(ua) - set(ub))}

    # ---- sprite / sound / texture logical collisions
    collisions = []
    for lg, lst in log_b.items():
        if lg in log_a and {x['sha256'] for x in lst} != {x['sha256'] for x in log_a[lg]}:
            collisions.append({'logical': lg, 'main': sorted(x['norm'] for x in log_a[lg]), 'revised': sorted(x['norm'] for x in lst)})
    collisions.sort(key=lambda c: c['logical'])

    # ---- PSX map correspondence by content
    maps_a = {e['norm'].split('/')[-1]: e for e in em if e['category'] == 'map'}
    sha_map_a = {e['sha256']: e['norm'].split('/')[-1] for e in em if e['category'] == 'map'}
    psx = {e['norm'].split('/')[-1]: sha_map_a.get(e['sha256'], '') for e in er if e['category'] == 'map'}

    allent = sorted(em + er, key=lambda e: (e['archive'], e['norm']))
    summary = {'main_files': len(em), 'revised_files': len(er)}
    for lab, lst in (('main', em), ('revised', er)):
        c = collections.Counter(e['classification'] for e in lst)
        summary[lab + '_by_class'] = dict(sorted(c.items()))
        uniq = [e for e in lst if e['classification'] in ('U', 'M')]
        summary[lab + '_content_only_here'] = {'files': len(uniq), 'bytes': sum(e['size'] for e in uniq)}
        summary[lab + '_unique_by_category'] = dict(sorted(collections.Counter(e['category'] for e in uniq).items()))
    summary['revised_by_decision'] = dict(sorted(collections.Counter(e['decision'] for e in er).items()))

    manifest = {
        'tool': 'xtras/diff_xtras.py',
        'inputs': {'main': {'path': args.main, 'sha256': file_hash(args.main), 'files': len(em)},
                   'revised': {'path': args.revised, 'sha256': file_hash(args.revised), 'files': len(er)}},
        'case_collisions': {'main': colm, 'revised': colr},
        'summary': summary, 'classes': class_report, 'cvars': cvar_report, 'definitions': definitions,
        'logical_collisions': collisions, 'map_content_correspondence_revised_to_main': psx,
        'files': allent,
    }
    os.makedirs(args.out, exist_ok=True)
    mp = os.path.join(args.out, 'merge_manifest.json')
    with open(mp, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    write_notes(manifest, os.path.join(args.out, 'MERGE_NOTES.md'))
    print('wrote', mp)
    print(json.dumps(summary, indent=1, sort_keys=True))


def write_notes(m, path):
    s = m['summary']
    L = []
    L.append('# Xtras merge ledger (generated by xtras/diff_xtras.py)\n')
    L.append('Do not edit by hand: decisions go in `xtras/merge_decisions.json`, then regenerate.\n')
    L.append('## Inputs\n')
    for k in ('main', 'revised'):
        i = m['inputs'][k]
        L.append('- %s: `%s` (%d files) SHA-256 `%s`' % (k, os.path.basename(i['path']), i['files'], i['sha256']))
    L.append('')
    L.append('## Summary\n')
    L.append('| | Main | Revised |\n|---|---|---|')
    L.append('| files | %d | %d |' % (s['main_files'], s['revised_files']))
    L.append('| content only here | %d files / %.1f MB | %d files / %.1f MB |' % (
        s['main_content_only_here']['files'], s['main_content_only_here']['bytes'] / 1048576,
        s['revised_content_only_here']['files'], s['revised_content_only_here']['bytes'] / 1048576))
    L.append('')
    L.append('Classification of Revised files: ' + ', '.join('%s=%d' % kv for kv in s['revised_by_class'].items()))
    L.append('')
    L.append('Revised files by decision: ' + ', '.join('%s=%d' % kv for kv in s['revised_by_decision'].items()))
    L.append('')
    c = m['classes']
    L.append('## ZScript\n')
    L.append('Main %d classes, Revised %d. Shared names: %d. Revised-only: %s.\n' % (c['main_total'], c['revised_total'], len(c['shared']), ', '.join(c['only_revised']) or 'none'))
    L.append('Shared classes whose bodies differ: %d of %d.\n' % (sum(1 for v in c['shared'].values() if not v['identical_body']), len(c['shared'])))
    L.append('| Shared class | body | revised-only methods | revised-only fields |\n|---|---|---|---|')
    for n, v in sorted(c['shared'].items()):
        L.append('| %s | %s | %s | %s |' % (n, 'same' if v['identical_body'] else 'differs', ', '.join(v['methods_only_revised']) or '-', ', '.join(v['fields_only_revised']) or '-'))
    L.append('')
    L.append('## CVars\n')
    for k, v in m['cvars']['only_revised'].items():
        L.append('- only Revised: `%s` (%s, default `%s`, flags `%s`, %s)' % (v['name'], v['type'], v['default'], v['flags'] or '-', v['file']))
    for k, v in m['cvars']['shared_different'].items():
        L.append('- shared but different: `%s` main=%s revised=%s' % (k, v['main'], v['revised']))
    L.append('')
    L.append('## Definition files\n')
    for k, v in m['definitions'].items():
        if 'only_revised' in v and isinstance(v.get('only_revised'), list) and 'conflicting' in v:
            L.append('- **%s**: only in Revised %d, conflicting %d' % (k, len(v['only_revised']) if 'only_revised_count' not in v else v['only_revised_count'], len(v['conflicting']) if 'conflicting_count' not in v else v['conflicting_count']))
        elif 'same' in v:
            L.append('- **%s**: same %d, different %d, only Revised %d, only Main %d' % (k, len(v['same']), len(v['different']), len(v['only_revised']), len(v['only_main'])))
        else:
            L.append('- **%s**: only in Revised %d' % (k, len(v['only_revised'])))
    L.append('')
    L.append('## Logical-name collisions (same sprite/sound/graphic name, different content)\n')
    L.append('%d collisions. First 40:\n' % len(m['logical_collisions']))
    for col in m['logical_collisions'][:40]:
        L.append('- `%s`: main %s / revised %s' % (col['logical'], col['main'][:1], col['revised'][:1]))
    L.append('')
    L.append('## Revised maps against Main by content\n')
    for k, v in sorted(m['map_content_correspondence_revised_to_main'].items()):
        L.append('- %s -> %s' % (k, v or '(no identical map in Main)'))
    L.append('')
    L.append('## Revised-only files (content not in Main)\n')
    rev = [e for e in m['files'] if e['archive'] == 'revised' and e['classification'] in ('U', '4', '2', '6')]
    bycat = collections.defaultdict(list)
    for e in rev:
        bycat[e['category']].append(e)
    for cat in sorted(bycat):
        L.append('### %s (%d)\n' % (cat, len(bycat[cat])))
        for e in bycat[cat][:200]:
            L.append('- `%s` [%s] %s - %s' % (e['norm'], e['classification'], e['decision'], e['reason']))
        if len(bycat[cat]) > 200:
            L.append('- ... %d more in merge_manifest.json' % (len(bycat[cat]) - 200))
        L.append('')
    open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')


if __name__ == '__main__':
    main()
