#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean
# On coupe sur "," entre guillemets ; la 6e colonne (hash) n'est jamais ecrite.
awk -F'","' -v OFS=, '
NR == 1 { print "date,city_name,isp_name,os_name,web_client"; next }
NF != 6 { print "ligne " NR " : " NF " champs au lieu de 6" > "/dev/stderr"; exit 1 }
{ d = $1; sub(/^"/, "", d); print d, $2, $3, $4, $5 }' data/raw/web_2025-10.csv > data/clean/web_clean.csv
echo "web_clean.csv : $(wc -l < data/clean/web_clean.csv) lignes"
