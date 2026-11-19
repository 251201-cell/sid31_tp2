# Bibliotheque gawk : lecture d'un CSV avec champs entre guillemets (virgules internes).
BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }
# enleve les guillemets englobants, "" -> ", retire espaces/tabulations aux deux bouts,
# et remplace une tabulation interne par une espace (le TSV garde ainsi 3 champs)
function clean(v) {
  if (length(v) >= 2 && v ~ /^".*"$/) { v = substr(v, 2, length(v) - 2); gsub(/""/, "\"", v) }
  gsub(/^[ \t]+|[ \t]+$/, "", v)
  gsub(/\t/, " ", v)
  return v
}
