#!/usr/bin/env bash
set -euo pipefail

# Sprint 3 (BG): get first bladder cancer diagnosis per patient
# Goal: one row per subject_id (earliest BC-coded admission)
#
# We use awk here because we need to:
# 1) match codes exactly (not partial string matches)
# 2) group by subject_id
# 3) keep the minimum (earliest) admittime
# That kind of “group and compare” logic is hard to do with just sort/uniq.

OUT="out/evidence"
mkdir -p "$OUT"

# ---------------------------------------------------
# Step 1: Build a simple list of BC ICD codes
# ---------------------------------------------------
# bc_icd_codes.csv was generated locally (Sprint 2 logic).
# We just grab the first column (icd_code), skip header, and deduplicate.
cut -d',' -f1 data/bc_icd_codes.csv | tail -n +2 | tr -d '\r' | sort -u > "$OUT/bc_codes.txt"

# ---------------------------------------------------
# Step 2: Filter diagnoses_icd.csv by exact icd_code
# ---------------------------------------------------
# We use awk instead of grep because grep can match partial codes
# (example: code 1881 matching inside 51881).
# awk lets us check column 4 exactly.
awk -F',' '
BEGIN {
  OFS=",";
  # Load code list into an array called "codes"
  # codes["1880"]=1 means that code is valid
  while ((getline c < "'"$OUT/bc_codes.txt"'") > 0) {
    codes[c]=1
  }
  close("'"$OUT/bc_codes.txt"'")
}
NR==1 { print; next }        # keep header
($4 in codes) { print }      # only keep rows where icd_code matches exactly
' data/diagnoses_icd.csv > "$OUT/bc_dx_all.csv"

# ---------------------------------------------------
# Step 3: Build hadm_id -> admittime lookup
# ---------------------------------------------------
# admissions.csv columns start:
# subject_id,hadm_id,admittime,...
# We only need hadm_id and admittime.
awk -F',' 'NR>1 {print $2","$3}' data/admissions.csv > "$OUT/hadm_to_admittime.csv"

# ---------------------------------------------------
# Step 4: Keep earliest BC admission per subject
# ---------------------------------------------------
# This is where awk is really useful.
# We need to:
# - attach admittime to each BC diagnosis
# - group by subject_id
# - keep the smallest (earliest) time
#
# Doing this with sort/uniq alone is not enough because we need to compare times.
awk -F',' '
BEGIN { OFS="," }

# First file: hadm_to_admittime.csv
# Store admittime by hadm_id
NR==FNR {
  t[$1]=$2
  next
}

# Second file: bc_dx_all.csv
NR==1 { next }   # skip header

{
  sid=$1
  hadm=$2
  code=$4
  time=t[hadm]

  if (time=="") next

  # If this subject not seen before, or this time is earlier,
  # update the saved "best" record
  if (!(sid in best_time) || time < best_time[sid]) {
    best_time[sid]=time
    best_row[sid]=sid OFS hadm OFS time OFS code
  }
}

END {
  print "subject_id,hadm_id,admittime,icd_code"
  for (k in best_row) print best_row[k]
}
' "$OUT/hadm_to_admittime.csv" "$OUT/bc_dx_all.csv" \
| sort -t',' -k1,1n > "$OUT/bc_first_diagnosis.csv"

echo "done"
echo "codes: $(wc -l < $OUT/bc_codes.txt)"
echo "bc rows: $(wc -l < $OUT/bc_dx_all.csv)"
echo "unique subjects: $(( $(wc -l < $OUT/bc_first_diagnosis.csv) - 1 ))"
