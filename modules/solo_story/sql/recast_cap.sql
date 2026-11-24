-- solo_story : toute capacité de job dont le délai de réutilisation dépasse 5 min est ramenée à 5 min
-- (dont les capacités "2h"/SP à 1 h). Côté serveur uniquement : le client affiche le délai envoyé par le serveur.
UPDATE abilities SET recastTime = 300 WHERE recastTime > 300 AND job > 0;
