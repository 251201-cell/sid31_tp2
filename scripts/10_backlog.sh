#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results
# base, puis completed, puis les 4 contributions (chaque fichier est lu separement : FNR > 1 saute son en-tete)
gawk -F'\t' -v OFS='\t' '
FILENAME ~ /hass_base/      { if (FNR > 1) inbase[$1]; next }
FILENAME ~ /hass_completed/ { if (FNR > 1 && !($1 in car)) { car[$1] = $2; cen[$1] = $3 }; next }
BEGIN { print "english", "hassaniya_ar", "hassaniya_en", "status" }
FNR == 1 { next }
{
  if ($1 in inbase)                { st = "in_base"; ar = $2; en = $3 }
  else if ($1 in car)              { st = "filled";  ar = car[$1]; en = cen[$1] }
  else if ($2 != "" && $3 != "")   { st = "prefilled"; ar = $2; en = $3 }
  else                             { st = "todo"; ar = $2; en = $3 }
  print $1, ar, en, st
}' data/clean/hass_base.tsv data/clean/hass_completed.tsv \
   data/clean/contrib_d2.tsv data/clean/contrib_d3.tsv data/clean/contrib_d4.tsv data/clean/contrib_d5.tsv > data/clean/hass_backlog.tsv
{ echo 'status,rows'
  for s in filled in_base prefilled todo; do
    printf '%s,%s\n' "$s" "$(tail -n +2 data/clean/hass_backlog.tsv | awk -F'\t' -v s="$s" '$4 == s' | wc -l)"
  done
} > results/backlog_status.csv
cat results/backlog_status.csv
