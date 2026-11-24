# solo_story — patchs du cœur LSB

Tout le reste de solo_story passe par des modules Lua (`modules/solo_story/lua/`) et `settings/*.lua`.
Chaque patch C++ ci-dessous est minimal, désactivable par réglage, et couvert par un test
(`modules/solo_story/tests/`). À revérifier à chaque mise à jour de LSB (`git merge upstream/base`).

## 1. Mobs trop forts : pas d'agression spontanée

- **Fichier** : `src/map/zone_entities.cpp`, fonction `CZoneEntities::tapMobAggro` (+ `#include "common/settings.h"`).
- **Commit LSB de référence** : `fc22b012a4`.
- **Raison** : certaines quêtes imposent de traverser des donjons pleins de mobs 8-10 niveaux au-dessus,
  souvent à détection vraie (Sneak/Invisible inutiles). Aucun point d'accroche Lua n'existe dans le chemin
  d'agression (`tapMobAggro` -> `CMobController::CanAggroTarget` -> `CanDetectTarget`).
- **Comportement** : un mob dont le niveau est ≥ niveau principal du joueur + `NO_AGGRO_LEVEL_DIFF`
  n'engage pas le joueur de lui-même (symétrique de la règle retail « Too Weak »), NM compris,
  même avec `ALWAYS_AGGRO` ou si le joueur est assis. Il reste attaquable et riposte ;
  l'aide entre mobs (« link ») d'un mob déjà engagé n'est pas modifiée.
- **Réglage** : `settings/solo_story.lua` → `NO_AGGRO_LEVEL_DIFF` (0 ou absent = comportement retail).
  Lu côté C++ : redémarrer les serveurs après modification.
- **Diff** :

```cpp
    bool validAggro = mobCheck > EMobDifficulty::TooWeak || PChar->isSitting() || PCurrentMob->getMobMod(xi::MobMod::AlwaysAggro);

    // solo_story patch (modules/solo_story/PATCHES.md): ...
    const auto noAggroLevelDiff = settings::get<uint8>("solo_story.NO_AGGRO_LEVEL_DIFF");
    if (noAggroLevelDiff > 0 && PCurrentMob->GetMLevel() >= PChar->GetMLevel() + noAggroLevelDiff)
    {
        validAggro = false;
    }
```

- **Test** : `modules/solo_story/tests/no_aggro.lua`.

## 2. Plafond de hâte des capacités (Job Ability Haste) à 30 %

- **Fichier** : `src/map/entities/battle_entity.cpp`, `CBattleEntity::GetWeaponDelay` (calcul du délai d'attaque).
- **Commit LSB de référence** : `fc22b012a4`.
- **Raison** : rééquilibrage CatsEyeXI (« Job Ability Haste caps at 30% instead of 25% »). La hâte d'équipement reste
  plafonnée à 25 % et la hâte magique à 43,75 % (inchangées). Aucun point d'accroche Lua : le plafond était codé en dur.
- **Réglage** : `settings/solo_story.lua` → `JA_HASTE_CAP` (0,30). Absent ou 0 = 0,25 (retail). Redémarrer après modification.
- **Diff** :

```cpp
-                hasteAbility = std::clamp<float>(hasteAbility, -0.25f, 0.25f);
+                const float jaHasteCap = settings::get<float>("solo_story.JA_HASTE_CAP");
+                hasteAbility           = std::clamp<float>(hasteAbility, -0.25f, jaHasteCap > 0.0f ? jaHasteCap : 0.25f);
```

- **Test** : pas de test Lua possible (aucune fonction Lua n'expose le délai après hâte) ; vérifié par compilation
  (`-Werror`) et lecture du code.

## Recompiler après un patch C++ : piège du cache

`docker compose --profile build build build` réutilise un cache de build Docker. Le générateur d'enums
(`tools/codegen`) écrit `scripts/enum/*.codegen.lua` dans les sources mais ne s'exécute que si son marqueur
(`build/generated/.enum_codegen.stamp`, dans le cache) est périmé. Sur une recompilation, l'image peut donc
sortir **sans** ces fichiers : tous les scripts plantent (`xi.job`, `xi.zone`... nil).

Parade (fichiers ignorés par git, à refaire si `data/enums/*.yaml` change) :

```bash
docker run --rm --entrypoint sh -u 1000:1000 -v "$PWD":/src -w /src landsandboat/server:local \
  -c 'python -m tools.codegen /tmp/codegen-out'
docker compose --profile build build build
docker run --rm --entrypoint sh landsandboat/server:local -c 'ls /server/scripts/enum/*.codegen.lua | wc -l'  # 62 attendus
```
