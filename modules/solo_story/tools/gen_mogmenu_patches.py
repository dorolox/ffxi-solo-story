#!/usr/bin/env python3
"""
solo_story : génère les correctifs de zone qui ajoutent `mogmenu` au champ `misc` de chaque zone.

Le cœur n'autorise Mog Safe / Safe 2 / changement de job / Mog Locker "toutes zones" que dans la
Mog House ou une zone avec `mogmenu` (packets/c2s/0x029_item_move.cpp, 0x100_myroom_job.cpp,
charutils::hasMogLockerAccess). La commande !mog (lua/mog_anywhere.lua) a donc besoin de ce flag.

Les correctifs (RFC 7396) remplacent les listes en entier : chaque fichier reprend la liste `misc`
d'origine + `mogmenu`. Sortie : modules/solo_story/data/zones/<zone>/zone.yaml
(chargés via l'entrée `solo_story/lua/` de modules/init.txt -> modules/solo_story/data/).

Usage (racine du dépôt) : python3 modules/solo_story/tools/gen_mogmenu_patches.py
À relancer après une mise à jour de LSB qui modifie data/zones/*/zone.yaml.
"""
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'modules/solo_story/data/zones'
EXCLUDE = {
    'mordion_gaol',   # prison des GM
    'west_ronfaure',  # le test C++ de LSB src/test/tests/data/zones/settings_tests.cpp:109 fige son `misc` ;
                      # s'il échoue, xi_test saute toute la suite Lua (src/test/main.cpp:42)
}


def main():
    written = skipped = 0
    for zone_file in sorted((ROOT / 'data/zones').glob('*/zone.yaml')):
        zone = zone_file.parent.name
        misc = (yaml.safe_load(zone_file.read_text()) or {}).get('misc') or []
        if zone in EXCLUDE or 'mogmenu' in misc:
            skipped += 1
            continue

        target = OUT / zone / 'zone.yaml'
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            '# solo_story : GÉNÉRÉ par modules/solo_story/tools/gen_mogmenu_patches.py, ne pas éditer.\n'
            '# Ajoute mogmenu (menu du Moogle hors Mog House, commande !mog).\n'
            f'misc: [{", ".join(list(misc) + ["mogmenu"])}]\n'
        )
        written += 1

    print(f'{written} correctifs écrits dans {OUT.relative_to(ROOT)}, {skipped} zones ignorées (déjà mogmenu ou exclues)')


if __name__ == '__main__':
    main()
