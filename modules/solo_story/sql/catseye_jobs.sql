-- ---------------------------------------------------------------------------------------------
-- solo_story : rééquilibrage des jobs repris de CatsEyeXI (bg-wiki CatsEyeXI_Systems/Jobs, rév. 2026-11-03)
-- Uniquement ce qui AVANCE une capacité ou en AJOUTE une par rapport au retail ; rien n'est retiré.
-- Rejoué par dbtool (service database-update) : toutes les requêtes sont idempotentes.
-- Jobs : 1 WAR 2 MNK 3 WHM 4 BLM 5 RDM 6 THF 8 DRK 9 BST 10 BRD 11 RNG 12 SAM 13 NIN 14 DRG 15 SMN 16 BLU 19 DNC 20 SCH
-- ---------------------------------------------------------------------------------------------

-- ===== Traits (niveau d'obtention) =====
UPDATE traits SET level = 40 WHERE name = 'shield mastery'   AND job = 1  AND `rank` = 1;  -- WAR 80 -> 40
UPDATE traits SET level = 37 WHERE name = 'smite'            AND job = 2  AND `rank` = 1;  -- MNK 40 -> 37
UPDATE traits SET level = 75 WHERE name = 'smite'            AND job = 2  AND `rank` = 2;  -- MNK 80 -> 75
UPDATE traits SET level = 75 WHERE name = 'tactical guard'   AND job = 2  AND `rank` = 1;  -- MNK 77 -> 75
UPDATE traits SET level = 60 WHERE name = 'occult acumen'    AND job = 4  AND `rank` = 1;  -- BLM 85 -> 60
UPDATE traits SET level = 75 WHERE name = 'occult acumen'    AND job = 4  AND `rank` = 2;  -- BLM 95 -> 75
UPDATE traits SET level = 70 WHERE name = 'mag. burst bonus' AND job = 5  AND `rank` = 1;  -- RDM 85 -> 70
UPDATE traits SET level = 75 WHERE name = 'magic atk. bonus' AND job = 5  AND `rank` = 3;  -- RDM 86 -> 75
UPDATE traits SET level = 20 WHERE name = 'dual wield'       AND job = 6  AND `rank` = 1;  -- THF 83 -> 20
UPDATE traits SET level = 40 WHERE name = 'dual wield'       AND job = 6  AND `rank` = 2;  -- THF 90 -> 40
UPDATE traits SET level = 37 WHERE name = 'occult acumen'    AND job = 8  AND `rank` = 1;  -- DRK 45 -> 37
UPDATE traits SET level = 60 WHERE name = 'fencer'           AND job = 9  AND `rank` = 1;  -- BST 80 -> 60
UPDATE traits SET level = 75 WHERE name = 'fencer'           AND job = 9  AND `rank` = 2;  -- BST 87 -> 75
UPDATE traits SET level = 75 WHERE name = 'stout servant'    AND job = 9  AND `rank` = 1;  -- BST 78 -> 75
UPDATE traits SET level = 75 WHERE name = 'fencer'           AND job = 10 AND `rank` = 1;  -- BRD 85 -> 75
UPDATE traits SET level = 75 WHERE name = 'skillchain bonus' AND job = 12 AND `rank` = 1;  -- SAM 78 -> 75
UPDATE traits SET level = 75 WHERE name = 'mag. burst bonus' AND job = 13 AND `rank` = 1;  -- NIN 80 -> 75
UPDATE traits SET level = 75 WHERE name = 'tactical parry'   AND job = 13 AND `rank` = 1;  -- NIN 77 -> 75
UPDATE traits SET level = 75 WHERE name = 'tactical parry'   AND job = 19 AND `rank` = 1;  -- DNC 77 -> 75
UPDATE traits SET level = 75 WHERE name = 'crit. atk. bonus' AND job = 19 AND `rank` = 1;  -- DNC 80 -> 75
UPDATE traits SET level = 60 WHERE name = 'occult acumen'    AND job = 20 AND `rank` = 1;  -- SCH 78 -> 60
UPDATE traits SET level = 75 WHERE name = 'occult acumen'    AND job = 20 AND `rank` = 2;  -- SCH 88 -> 75

-- MNK : Attack Bonus I/II/III aux niveaux 30/55/70 (absent du MNK retail ; valeurs du WAR)
DELETE FROM traits WHERE traitid = 3 AND job = 2;
INSERT INTO traits (traitid, name, job, level, `rank`, modifier, value, content_tag, meritid) VALUES
    (3, 'attack bonus', 2, 30, 1, 23, 10, NULL, 0), (3, 'attack bonus', 2, 30, 1, 24, 10, NULL, 0),
    (3, 'attack bonus', 2, 55, 2, 23, 22, NULL, 0), (3, 'attack bonus', 2, 55, 2, 24, 22, NULL, 0),
    (3, 'attack bonus', 2, 70, 3, 23, 35, NULL, 0), (3, 'attack bonus', 2, 70, 3, 24, 35, NULL, 0);

-- ===== Capacités de job (niveau / délai de réutilisation) =====
UPDATE abilities SET level = 75 WHERE name = 'blood_rage';                         -- WAR 87 -> 75
UPDATE abilities SET recastTime = 60 WHERE name = 'retaliation';                   -- WAR posture : 180 -> 60 s
UPDATE abilities SET recastTime = 60 WHERE name = 'counterstance';                 -- MNK posture : 300 -> 60 s
UPDATE abilities SET level = 75 WHERE name IN ('perfect_counter', 'impetus');      -- MNK 79/88 -> 75
UPDATE abilities SET level = 75 WHERE name = 'enmity_douse';                       -- BLM 87 -> 75
UPDATE abilities SET level = 40 WHERE name IN ('accomplice', 'collaborator');      -- THF 65 -> 40
UPDATE abilities SET level = 50 WHERE name = 'assassins_charge';                   -- THF 75 -> 50
UPDATE abilities SET level = 60 WHERE name = 'bully';                              -- THF 93 -> 60
UPDATE abilities SET level = 75 WHERE name IN ('conspirator', 'despoil');          -- THF 87/77 -> 75
UPDATE abilities SET level = 75 WHERE name IN ('nether_void', 'scarlet_delirium'); -- DRK 78/95 -> 75
UPDATE abilities SET level = 10 WHERE name = 'call_beast';                         -- BST 23 -> 10
UPDATE abilities SET level = 55 WHERE name = 'bounty_shot';                        -- RNG 87 -> 55
UPDATE abilities SET level = 75 WHERE name = 'futae';                              -- NIN 77 -> 75
UPDATE abilities SET level = 75 WHERE name = 'fly_high';                           -- DRG 96 -> 75
UPDATE abilities SET level = 75 WHERE name = 'mana_cede';                          -- SMN 87 -> 75
UPDATE abilities SET level = 75 WHERE name = 'unbridled_learning';                 -- BLU 95 -> 75
UPDATE abilities SET level = 60 WHERE name = 'divine_waltz_ii';                    -- DNC 78 -> 60
UPDATE abilities SET level = 65 WHERE name = 'feather_step';                       -- DNC 83 -> 65
UPDATE abilities SET level = 75 WHERE name = 'presto';                             -- DNC 77 -> 75
UPDATE abilities SET level = 75 WHERE name IN ('immanence', 'perpetuance');        -- SCH 87 -> 75

-- ===== Sorts (niveau par job : octet n° jobId de spell_list.jobs) =====
UPDATE spell_list SET jobs = INSERT(jobs, 3, 1, CHAR(65)) WHERE name = 'baramnesra';    -- WHM 78 -> 65
UPDATE spell_list SET jobs = INSERT(jobs, 5, 1, CHAR(65)) WHERE name = 'baramnesia';    -- RDM 78 -> 65
UPDATE spell_list SET jobs = INSERT(jobs, 3, 1, CHAR(75)) WHERE name = 'enlight';       -- WHM 75 (ajout ; PLD 85 conservé)
UPDATE spell_list SET jobs = INSERT(jobs, 8, 1, CHAR(75)) WHERE name = 'absorb-attri';  -- DRK 91 -> 75
UPDATE spell_list SET jobs = INSERT(jobs, 3, 1, CHAR(75)), mpCost = 150, castTime = 10000 WHERE name = 'arise'; -- WHM 99 -> 75, 150 MP, 10 s
