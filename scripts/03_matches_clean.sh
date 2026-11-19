#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean results
tr -d '\r' < data/raw/matches.csv | gawk -F, -v OFS=, '
NR == 1 { print "season,date,date_status,home_team,away_team,home_goals,away_goals,result"; next }
{
  if ($2 ~ /^[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9][0-9][0-9]$/) {
    split($2, p, "."); date = p[3] "-" p[2] "-" p[1]; st = "full"
  } else if ($2 ~ /^[0-9][0-9]\.[0-9][0-9]\.$/) {
    split($2, p, "."); m = p[2] + 0
    if (match($1, /([0-9][0-9][0-9][0-9])\/([0-9][0-9][0-9][0-9])$/, y)) yr = (m >= 8) ? y[1] : y[2]
    else if (match($1, /[0-9][0-9][0-9][0-9]$/)) yr = substr($1, RSTART, 4)
    else { print "saison sans annee, ligne " NR > "/dev/stderr"; exit 1 }
    date = yr "-" p[2] "-" p[1]; st = "inferred"
  } else { print "date inattendue ligne " NR ": " $2 > "/dev/stderr"; exit 1 }
  hg = $5 + 0; ag = $6 + 0
  res = (hg > ag) ? "home_win" : ((hg < ag) ? "away_win" : "draw")
  print $1, date, st, $3, $4, $5, $6, res
}' > data/clean/matches_clean.csv

# Test de la regle de travail sur les dates completes des saisons "AAAA/BBBB" (le fichier n'est pas modifie)
tr -d '\r' < data/raw/matches.csv | gawk -F, '
NR > 1 && $1 ~ /[0-9][0-9][0-9][0-9]\/[0-9][0-9][0-9][0-9]$/ && $2 ~ /^[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9][0-9][0-9]$/ {
  match($1, /([0-9][0-9][0-9][0-9])\/([0-9][0-9][0-9][0-9])$/, y); split($2, d, ".")
  pred = (d[2] + 0 >= 8) ? y[1] : y[2]; t++
  if (pred != d[3]) { b++; k = $1 ", mois " d[2] ", annee source " d[3] " (regle : " pred ")"; bad[k]++ }
}
END { print "lignes testees : " t; print "lignes ou la regle donne une autre annee : " b + 0
      for (k in bad) print "  " bad[k] " x " k }' | { read -r l1; read -r l2; echo "$l1"; echo "$l2"; sort; } > results/date_rule_test.txt
cat results/date_rule_test.txt
