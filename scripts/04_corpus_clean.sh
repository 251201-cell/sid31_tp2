#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean
# conv <entree> <sortie> : CSV (champs cites) -> TSV a 3 champs, ligne par ligne, sans CR
conv() {
  gawk -f scripts/lib_csv.awk -e '
  { sub(/\r$/, "") }
  NF < 3 || NF > 4 { print FILENAME ": ligne " NR " : " NF " champs" > "/dev/stderr"; exit 1 }
  { print clean($1) "\t" clean($2) "\t" clean($3) }' "$1" > "$2"
}
conv data/raw/dah_d1.csv        data/clean/hass_base.tsv
conv data/raw/dah_completed.csv data/clean/hass_completed.tsv
for n in 2 3 4 5; do conv "data/raw/dah_d$n.csv" "data/clean/contrib_d$n.tsv"; done

# Verification : nombre de champs par ligne, decoupage simple vs methode FPAT
for f in dah_d1 dah_d3; do
  printf '%s, decoupage simple sur les virgules : ' "$f"
  tr -d '\r' < "data/raw/$f.csv" | awk -F, '{print NF}' | sort -n | uniq -c | tr '\n' ' '; echo
  printf '%s, methode FPAT                      : ' "$f"
  tr -d '\r' < "data/raw/$f.csv" | gawk -f scripts/lib_csv.awk -e '{print NF}' | sort -n | uniq -c | tr '\n' ' '; echo
done
printf 'dah_completed.csv : lignes dont la 4e colonne (ecartee) n est pas vide : '
tr -d '\r' < data/raw/dah_completed.csv | gawk -f scripts/lib_csv.awk -e 'NR > 1 && $4 != ""' | wc -l
for f in hass_base hass_completed contrib_d2 contrib_d3 contrib_d4 contrib_d5; do
  printf '%s.tsv : %s lignes, champs par ligne : ' "$f" "$(wc -l < "data/clean/$f.tsv")"
  awk -F'\t' '{print NF}' "data/clean/$f.tsv" | sort -u | tr '\n' ' '; echo
done
