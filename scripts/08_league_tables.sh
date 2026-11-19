#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results/tables
M=data/clean/matches_clean.csv
# une ligne par (saison, equipe) : saison,equipe,joues,bp,bc,diff,points
agg=$(tail -n +2 "$M" | awk -F, -v OFS=, '
  { s = $1; h = $4; a = $5; hg = $6 + 0; ag = $7 + 0
    kh = s SUBSEP h; ka = s SUBSEP a; seen[kh]; seen[ka]
    p[kh]++; p[ka]++; gf[kh] += hg; ga[kh] += ag; gf[ka] += ag; ga[ka] += hg
    if (hg > ag) pts[kh] += 3; else if (hg < ag) pts[ka] += 3; else { pts[kh]++; pts[ka]++ } }
  END { for (k in seen) { split(k, z, SUBSEP); print z[1], z[2], p[k], gf[k], ga[k], gf[k] - ga[k], pts[k] + 0 } }')
rm -f results/tables/*.csv
printf '%s\n' "$agg" | cut -d, -f1 | sort -u | while IFS= read -r s; do
  f="results/tables/$(printf '%s' "$s" | tr ' /' '__').csv"
  { echo 'team,played,goals_for,goals_against,diff,points'
    printf '%s\n' "$agg" | awk -F, -v OFS=, -v s="$s" '$1 == s {print $2, $3, $4, $5, $6, $7}' |
      sort -t, -k6,6nr -k5,5nr -k3,3nr -k1,1
  } > "$f"
done
{ echo 'season,teams,matches,expected_matches,complete'
  tail -n +2 "$M" | awk -F, -v OFS=, '
    { m[$1]++; t[$1 SUBSEP $4]; t[$1 SUBSEP $5] }
    END { for (k in t) { split(k, z, SUBSEP); nt[z[1]]++ }
          for (s in m) { e = nt[s] * (nt[s] - 1); print s, nt[s], m[s], e, (m[s] == e) ? "yes" : "no" } }' | sort -t, -k1,1
} > results/season_summary.csv
{ echo 'result,matches'
  tail -n +2 "$M" | cut -d, -f8 | sort | uniq -c | sort -k1,1nr -k2 | awk '{print $2 "," $1}'
} > results/result_distribution.csv
cat results/season_summary.csv results/result_distribution.csv; ls results/tables
