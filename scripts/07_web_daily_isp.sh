#!/usr/bin/env bash
set -euo pipefail
: "${S:?export S=<your student number> first}"
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results
gawk -F, -v OFS=, '
BEGIN { split("CHINGUITEL MATTEL MAURITEL RIMATEL", isps, " ") }
NR > 1 {
  k = $3 SUBSEP $1; rec[k]++
  if ($4 == "iOS" || $4 == "Android") mob[k]++
  if ($6 == "bot") bot[k]++
}
END {
  print "isp,date,records,mobile,bot,busy_flag"
  for (i = 1; i <= 4; i++) {
    isp = isps[i]; delete tmp
    for (d = 1; d <= 31; d++) { k = isp SUBSEP sprintf("2025-10-%02d", d); tmp[d] = rec[k] + 0 }
    n = asort(tmp, srt)                       # ordre croissant des 31 comptes
    x = 0.9 * n; r = (x == int(x)) ? x : int(x) + 1   # rang = plafond de 0,9 n (plus proche rang)
    thr = srt[r]
    for (d = 1; d <= 31; d++) {
      date = sprintf("2025-10-%02d", d); k = isp SUBSEP date
      printf "%s,%s,%d,%d,%d,%d\n", isp, date, rec[k] + 0, mob[k] + 0, bot[k] + 0, (rec[k] + 0 >= thr) ? 1 : 0
    }
    print isp " seuil rang " r " = " thr > "/dev/stderr"
  }
}' data/clean/web_enriched.csv > "results/web_daily_isp_${S}.csv"
wc -l "results/web_daily_isp_${S}.csv"
