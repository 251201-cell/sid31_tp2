#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results
W=data/clean/web_clean.csv
{
  awk -F, 'NR>1 {
      n++; os[$4]++; if ($2 == "") nc++
      if ($4 == "iOS") ios++; if ($4 == "Android") and_++; if ($4 != "") known++ }
    END {
      d = 0; for (k in os) d++
      printf "records: %d\n", n
      printf "distinct_os_name (empty value counted): %d\n", d
      printf "records_without_city_name: %d\n", nc
      printf "pct_without_city_name (denominator %d records): %.2f\n", n, 100 * nc / n
      printf "pct_ios_all (denominator %d records): %.2f\n", n, 100 * ios / n
      printf "pct_android_all (denominator %d records): %.2f\n", n, 100 * and_ / n
      printf "pct_mobile_all (denominator %d records): %.2f\n", n, 100 * (ios + and_) / n
      printf "records_with_known_os: %d\n", known
      printf "pct_ios_known_os (denominator %d records with OS): %.2f\n", known, 100 * ios / known
      printf "pct_android_known_os (denominator %d records with OS): %.2f\n", known, 100 * and_ / known
      printf "pct_mobile_known_os (denominator %d records with OS): %.2f\n", known, 100 * (ios + and_) / known }' "$W"
  tail -n +2 "$W" | cut -d, -f5 | sort | uniq -c | sort -k1,1nr -k2 | awk 'NR<=5' |
    awk '{c = $1; sub(/^ *[0-9]+ /, ""); printf "top_web_client_%d: %s (%d records)\n", NR, $0, c}'
} > results/web_profile.txt

{ echo 'date,os_name,count'
  tail -n +2 "$W" | awk -F, '{c[$1 "," $4]++} END {for (k in c) print k "," c[k]}' | sort -t, -k3,3nr -k1,1 -k2,2
} > results/daily_os_counts.csv
cat results/web_profile.txt; head -n 4 results/daily_os_counts.csv
