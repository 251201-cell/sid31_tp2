#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results
{
  printf 'file\trecords\tfields_header\tlines_other_fields\tcrlf_lines\tfinal_newline\n'
  for f in data/raw/*.csv; do
    rec=$(awk 'END{print NR-1}' "$f")                       # ok meme sans \n final
    fh=$(awk -F, 'NR==1{print NF; exit}' "$f")
    oth=$(awk -F, -v h="$fh" 'NF!=h' "$f" | wc -l)           # simple decoupage sur les virgules
    crlf=$(grep -c $'\r' "$f" || true)
    if [ -z "$(tail -c 1 "$f")" ]; then fn=yes; else fn=no; fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(basename "$f")" "$rec" "$fh" "$oth" "$crlf" "$fn"
  done
} > results/inventory.tsv
cat results/inventory.tsv
