# TP2 — Un lot de données ouvertes avec Bash, awk et Git (SID31 DataOps)

Numéro d'étudiant : **251201** — FAI de référence : **MATTEL** — saison de référence : **Ligue 1 2018/2019**

## Sources (Sources)

| Source | Dépôt | Commit épinglé | Licence telle que publiée | Lue le |
|---|---|---|---|---|
| Échantillon de trafic web (octobre 2025) et résultats du championnat | https://github.com/binorassocies/rimdata | `e8666952ed3c52bbdff47411f7110b7fdc0dc297` | non lue depuis la machine de TP (voir la note) | 2026-11-19 |
| Corpus de phrases en hassaniya (base, contributions, complété) | https://github.com/Hassan-IA/DAH | `fc3e9a318fce778244056d2cb393448991e4f5d0` | non lue depuis la machine de TP (voir la note) | 2026-11-19 |

Note : le seul accès réseau autorisé par la fiche est celui des huit téléchargements épinglés, les fichiers de licence
n'ont donc pas été téléchargés. Le texte de la licence doit être lu sur la page de chaque dépôt avant toute publication ;
d'ici là, aucun chiffre de ce lot ne peut être rediffusé comme donnée ouverte.

Fichiers bruts : `web_2025-10.csv`, `matches.csv`, `dah_d1.csv` à `dah_d5.csv`, `dah_completed.csv`
(sommes de contrôle dans `data/SHA256SUMS`). `data/ref/client_class.csv` est une table de travail faite pour cette mission.

## Reconstruire (How to rebuild)

```bash
export S=251201
bash scripts/00_fetch.sh                      # télécharge (commits épinglés) et vérifie les huit sommes de contrôle
rm -rf data/clean results logs && S=$S bash scripts/run_all.sh   # reconstruit tous les fichiers de M1 et M2
S=$S bash tp2.2026.check.sh m1                # puis m2, m3, m4 (RESULT: OK attendu)
```

`run_all.sh` exécute les étapes `00_fetch.sh` à `10_backlog.sh` dans l'ordre, écrit des lignes START/DONE avec l'heure UTC
dans `logs/run.log` et s'arrête avec un code non nul si une somme de contrôle ou une étape échoue. Deux exécutions donnent
des fichiers identiques dans `results/`. La colonne de hachage du fichier web est supprimée dans `scripts/02_web_clean.sh`
et n'est écrite nulle part.

Règles de découpage en mots (tâche 2.5) : un mot anglais est une suite maximale de lettres `a-z` après passage en
minuscules (ainsi `don't` donne `don` et `t`). Pour `hassaniya-en`, les caractères autorisés sont `a-z` **et les chiffres 0-9**,
car le hassaniya écrit en lettres latines utilise des chiffres comme lettres (3, 7, 2, 5, 6, 9, 4, 8). Les retirer couperait
les mots en morceaux.

## Constats (Findings)

Chaque constat porte trois étiquettes, gardées en anglais comme dans la fiche : Claim (l'affirmation, avec son
dénominateur), Evidence (le fichier et la commande qui la prouvent) et Limit (ce que le résultat ne montre pas).

1. **Claim** — Trois types de fichiers sources doivent être réparés avant usage : `matches.csv` a un CRLF sur ses 2 745 lignes, `dah_completed.csv` sur 100 de ses 101 lignes, et cinq fichiers du corpus (`dah_completed.csv`, `dah_d2.csv` à `dah_d5.csv`) n'ont pas de newline final.
   **Evidence** — `results/inventory.tsv` (`bash scripts/01_inventory.sh`) ; `data/raw/matches.csv` compte 2 744 enregistrements, le fichier web 45 260.
   **Limit** — le tableau compte les champs avec un simple découpage sur les virgules : 323 des 3 003 lignes de `dah_d1.csv` ont un nombre de champs différent de 3, mais seulement à cause de virgules entre guillemets ; le tableau ne montre donc pas s'il existe une vraie erreur de format.

2. **Claim** — L'échantillon web est surtout mobile : 85,51 % des 45 260 enregistrements sont iOS ou Android, et 86,67 % des 44 655 enregistrements dont l'OS est connu (iOS 46,80 %, Android 39,87 % des OS connus).
   **Evidence** — `results/web_profile.txt` (`bash scripts/05_web_profile.sh`) ; 605 enregistrements ont un `os_name` vide.
   **Limit** — le fichier est un échantillon d'un seul mois ; il montre des requêtes, pas des personnes ni des appareils, et l'OS est celui que déclare le client.

3. **Claim** — 2 430 des 45 260 enregistrements (5,37 %) ont un client absent de la table de référence et reçoivent la classe `unmapped` ; `Other` en représente à lui seul 2 361.
   **Evidence** — `results/unmapped_clients.csv` et `results/isp_client_class.csv` (`bash scripts/06_web_join.sh`).
   **Limit** — la table est une classification de travail fondée sur le nom du client ; `Other` cache son contenu, donc la part `unmapped` peut contenir des robots, des navigateurs ou des bibliothèques.

4. **Claim** — Pour MATTEL, 780 de ses 6 699 enregistrements (11,64 %) appartiennent à la classe `bot`.
   **Evidence** — `results/web_daily_isp_251201.csv` (somme des colonnes `bot` et `records` pour MATTEL, `bash scripts/07_web_daily_isp.sh`).
   **Limit** — `bot` est une classe de travail fondée uniquement sur le nom du client (ici `FacebookBot`) ; ce n'est pas une mesure de l'automatisation, et les 415 enregistrements MATTEL de classe `unmapped` ne sont pas comptés.

5. **Claim** — MATTEL a quatre jours chargés en octobre 2025 (1er, 2, 3 et 6 octobre, avec 596, 432, 329 et 375 enregistrements) : le 90e centile (méthode du rang le plus proche) de ses 31 comptes journaliers est la valeur de rang 28, soit 329.
   **Evidence** — colonne `busy_flag` de `results/web_daily_isp_251201.csv` (le seuil est affiché par `scripts/07_web_daily_isp.sh`).
   **Limit** — le seuil est relatif au mois de MATTEL, donc un jour chargé n'est pas comparable d'un opérateur à l'autre, et cela ne dit pas pourquoi ces jours sont élevés (les 1er, 2 et 3 octobre sont chargés pour les quatre opérateurs).

6. **Claim** — 3 339 des 45 260 enregistrements web (7,38 %) n'ont pas de `city_name` ; rien n'a été inventé pour les remplir.
   **Evidence** — `results/web_profile.txt` (ligne `pct_without_city_name`).
   **Limit** — le fichier ne dit pas pourquoi la ville manque (échec de géolocalisation ou masquage), donc aucun classement par ville ne doit être publié sans cette part.

7. **Claim** — En Ligue 1 2018/2019 (14 équipes, 26 matchs chacune), les trois premiers sont Nouadhibou (59 points), ASAC Concorde (47) et Kedia (44).
   **Evidence** — `results/tables/Ligue_1_2018_2019.csv` (`bash scripts/08_league_tables.sh`) ; 182 matchs, autant qu'attendu.
   **Limit** — le classement suit la règle de points de la fiche (3-1-0) et son ordre de tri ; il ignore toute sanction ou tout forfait que le fichier de résultats ne montre pas.

8. **Claim** — Le test de complétude signale deux des 18 saisons : Championnat D1 2007/2008 (130 matchs pour 132 attendus) et Ligue 1 2020/2021 (32 pour 56).
   **Evidence** — `results/season_summary.csv` ; la règle de travail sur les dates échoue aussi sur 57 des 2 326 dates complètes des saisons à deux années (`results/date_rule_test.txt`).
   **Limit** — le signalement montre des lignes manquantes, pas leur cause (saison arrêtée, lacune de la source) ; les 154 dates déduites (Ligue 1 2024/2025, de janvier à mai) viennent de la règle, et les 57 échecs montrent que la règle peut se tromper pour une saison décalée.

9. **Claim** — Le corpus de base compte 3 002 paires de phrases, 2 985 phrases anglaises distinctes, 16 phrases qui apparaissent plus d'une fois et 17 lignes en trop ; la longueur moyenne est de 6,06 mots par phrase anglaise (3 002 paires).
   **Evidence** — `results/hass_profile.txt` (`bash scripts/09_corpus_profile.sh`).
   **Limit** — la comparaison se fait sur le texte nettoyé exact, donc deux phrases qui ne diffèrent que par la casse ou la ponctuation comptent comme différentes.

10. **Claim** — Sur les 400 lignes de contribution, 295 sont `todo`, 99 `filled`, 3 `in_base` et 3 `prefilled`.
    **Evidence** — `results/backlog_status.csv` (à partir de `data/clean/hass_backlog.tsv`, `bash scripts/10_backlog.sh`).
    **Limit** — `filled` et `in_base` reposent sur une correspondance exacte de la phrase anglaise ; quatre lignes de `dah_completed.csv` portent un `x` dans une colonne supplémentaire qui est ignorée, et la qualité des traductions n'a pas été vérifiée.

