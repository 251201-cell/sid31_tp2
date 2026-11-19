#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results
awk -F, -v OFS=, '
  NR == FNR { if (FNR > 1) cls[$1] = $2; next }
  FNR == 1  { print $0, "client_class"; next }
  { print $0, (($5 in cls) ? cls[$5] : "unmapped") }' \
  data/ref/client_class.csv data/clean/web_clean.csv > data/clean/web_enriched.csv

{ echo 'isp,client_class,records'
  tail -n +2 data/clean/web_enriched.csv | awk -F, -v OFS=, '{c[$3 "," $6]++} END {for (k in c) print k "," c[k]}' | sort -t, -k1,1 -k2,2
} > results/isp_client_class.csv

# clients absents de la table de reference (utile pour le README)
{ echo 'web_client,records'
  tail -n +2 data/clean/web_enriched.csv | awk -F, '$6 == "unmapped" {c[$5]++} END {for (k in c) print k "," c[k]}' | sort -t, -k2,2nr -k1,1
} > results/unmapped_clients.csv
echo "web_enriched : $(( $(wc -l < data/clean/web_enriched.csv) - 1 )) lignes"
cat results/unmapped_clients.csv
