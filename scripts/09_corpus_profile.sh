#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results
EN=$(mktemp); HA=$(mktemp); trap 'rm -f "$EN" "$HA"' EXIT
# deux passes : (1) comptes et listes, (2) classements (ties : ordre alphabetique)
gawk -F'\t' -v en_out="$EN" -v ha_out="$HA" '
BEGIN { n = split("a an the to of is i you he she it and in my", sw, " "); for (i = 1; i <= n; i++) stop[sw[i]] }
NR == 1 { next }
{
  pairs++; sent[$1]++
  nw = patsplit(tolower($1), w, /[a-z]+/); words += nw
  for (i = 1; i <= nw; i++) if (!(w[i] in stop)) en[w[i]]++
  nt = patsplit(tolower($3), t, /[a-z0-9]+/)
  for (i = 1; i <= nt; i++) { ha[t[i]]++; if (t[i] ~ /[0-9]/) dig++ }
}
END {
  for (s in sent) { d++; if (sent[s] > 1) { rep++; extra += sent[s] - 1 } }
  printf "sentence_pairs: %d\n", pairs
  printf "distinct_english_sentences: %d\n", d
  printf "english_sentences_appearing_more_than_once: %d\n", rep
  printf "extra_rows (rows beyond the first of each repeated sentence): %d\n", extra
  printf "avg_words_per_english_sentence (denominator %d pairs): %.2f\n", pairs, words / pairs
  printf "hassaniya_en_tokens_with_a_digit (occurrences): %d\n", dig
  for (k in en) print "EN\t" k "\t" en[k] > en_out
  for (k in ha) print "HA\t" k "\t" ha[k] > ha_out
}' data/clean/hass_base.tsv > results/hass_profile.txt
{ printf 'top10_english_words (stoplist removed): '
  sort -t$'\t' -k3,3nr -k2,2 "$EN" | awk 'NR<=10' | awk -F'\t' '{printf "%s%s=%s", (NR>1?"; ":""), $2, $3}'; echo
  printf 'top10_hassaniya_en_tokens: '
  sort -t$'\t' -k3,3nr -k2,2 "$HA" | awk 'NR<=10' | awk -F'\t' '{printf "%s%s=%s", (NR>1?"; ":""), $2, $3}'; echo
} >> results/hass_profile.txt
cat results/hass_profile.txt
