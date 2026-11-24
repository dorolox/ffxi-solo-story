#!/usr/bin/env python3
"""
solo_story : génère modules/solo_story/lua/spell_shop_data.lua (boutique de sorts).

Sources (toutes dans le dépôt, aucune base de données nécessaire) :
  - scripts/items/scroll_of_*.lua     : parchemin -> sort enseigné
  - sql/item_basic.sql                : nom du parchemin -> id d'objet
  - scripts/enum/magic.lua, item.lua  : noms -> ids
  - sql/spell_list.sql                : niveau d'apprentissage par job (jobs, 22 octets, octet jobId-1)
  - scripts/zones/*/npcs/*.lua        : prix des marchands PNJ (le moins cher)
  - ahbot/items.csv                   : prix AH de repli (prix ffxiah.com du bot)
Prix : PNJ, sinon AH, sinon FALLBACK_PRICE.

Usage (depuis la racine du dépôt) : python3 modules/solo_story/tools/gen_spell_shop.py
"""
import csv
import glob
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'modules/solo_story/lua/spell_shop_data.lua'
FALLBACK_PRICE = 20000


def enum_values(path, table):
    """Valeurs du seul bloc `table = { ... }` (un fichier enum peut en contenir plusieurs)."""
    text = (ROOT / path).read_text(errors='ignore')
    start = re.search(r'^' + re.escape(table) + r'\s*=\s*\n\{', text, re.M)
    if not start:
        raise SystemExit(f'bloc {table} introuvable dans {path}')
    block = text[start.end():]
    block = block[:re.search(r'^\}', block, re.M).start()]
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'^\s*([A-Z0-9_]+)\s*=\s*(\d+),', block, re.M)}


def main():
    spell_enum = enum_values('scripts/enum/magic.lua', 'xi.magic.spell')
    item_enum = enum_values('scripts/enum/item.lua', 'xi.item')

    # Id d'objet pris dans sql/item_basic.sql via le nom du fichier : les commentaires "-- ID:" des
    # scripts ne sont pas fiables (ex. scroll_of_hyoton_ni.lua annonce 4931 au lieu de 4932).
    item_ids = {m.group(2): int(m.group(1)) for m in re.finditer(
        r"INSERT INTO `item_basic` VALUES \((\d+),\d+,'([a-z0-9_-]+)'", (ROOT / 'sql/item_basic.sql').read_text(errors='ignore'))}

    scrolls = {}  # itemId -> spellId
    for f in glob.glob(str(ROOT / 'scripts/items/scroll_of_*.lua')):
        if f.endswith('_ex.lua'):  # parchemins Exclusive (récompenses de quête, non vendables)
            continue
        iid = item_ids.get(Path(f).stem)
        msp = re.search(r'addSpell\(xi\.magic\.spell\.([A-Z0-9_]+)', Path(f).read_text(errors='ignore'))
        if iid and msp and msp.group(1) in spell_enum:
            scrolls[iid] = spell_enum[msp.group(1)]

    levels = {}  # spellId -> {jobId: level}
    for m in re.finditer(r'INSERT INTO `spell_list` VALUES \((\d+),\'[^\']*\',0x([0-9A-Fa-f]+),',
                         (ROOT / 'sql/spell_list.sql').read_text(errors='ignore')):
        raw = bytes.fromhex(m.group(2))
        levels[int(m.group(1))] = {i + 1: b for i, b in enumerate(raw) if 0 < b <= 99}

    npc = {}
    for f in glob.glob(str(ROOT / 'scripts/zones/*/npcs/*.lua')):
        for m in re.finditer(r'\{\s*xi\.item\.(SCROLL_OF_[A-Z0-9_]+)\s*,\s*(\d+)', Path(f).read_text(errors='ignore')):
            iid = item_enum.get(m.group(1))
            if iid in scrolls:
                npc[iid] = min(int(m.group(2)), npc.get(iid, 10**9))

    ah = {}
    with open(ROOT / 'ahbot/items.csv', newline='') as fh:
        for row in csv.DictReader(fh, skipinitialspace=True):
            row = {k.strip(): v.strip() for k, v in row.items()}
            if int(row['itemid']) in scrolls and int(row['price_single']) > 0:
                ah[int(row['itemid'])] = int(row['price_single'])

    entries, stats = [], {'npc': 0, 'ah': 0, 'fallback': 0, 'no_job': 0}
    for iid, sid in sorted(scrolls.items()):
        jobs = levels.get(sid, {})
        if not jobs:
            stats['no_job'] += 1
            continue
        if iid in npc:
            price, src = npc[iid], 'npc'
        elif iid in ah:
            price, src = ah[iid], 'ah'
        else:
            price, src = FALLBACK_PRICE, 'fallback'
        stats[src] += 1
        job_str = ', '.join(f'[{j}] = {lv}' for j, lv in sorted(jobs.items()))
        entries.append(f'    {{ item = {iid}, spell = {sid}, price = {price}, jobs = {{ {job_str} }} }}, -- {src}')

    OUT.write_text(
        '-----------------------------------\n'
        '-- solo_story : données de la boutique de sorts (GÉNÉRÉ, ne pas éditer à la main)\n'
        '-- Regénérer : python3 modules/solo_story/tools/gen_spell_shop.py\n'
        '-- jobs = { [xi.job] = niveau d\'apprentissage }\n'
        '-----------------------------------\n'
        'return\n{\n' + '\n'.join(entries) + '\n}\n'
    )
    print(f'{len(entries)} parchemins écrits dans {OUT.relative_to(ROOT)} | prix : {stats}')


if __name__ == '__main__':
    main()
