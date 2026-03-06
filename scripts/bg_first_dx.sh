#!/usr/bin/env bash
set -euo pipefail

# Sprint 3 (BG): get first bladder cancer diagnosis per patient
# Goal: one row per subject_id (earliest BC-coded admission)
#
#NOTE: This assumes Sprint 2 cohort files exist locally (not committed):
#   data/bc_diagnoses.csv
#   data/bc_admissions_patients.csv

# We use awk here because we need to:
# 1) match codes exactly (not partial string matches)
# 2) group by subject_id
# 3) keep the minimum (earliest) admittime
# That kind of “group and compare” logic is hard to do with just sort/uniq.

OUT="out/evidence"
DATA="data"
mkdir -p "$OUT"

# # Step 1: Build hadm_id -> admittime lookup from bc_admissions_patients.csv
# (hadm_id is col 2, admittime is col 3)
# Both bc_diagnoses and bc_admissions_patients share hadm_id.
# We pull just those two columns so Step 2 can look up dates.
cut -d',' -f2,3 "$DATA/bc_admissions_patients.csv" | tail -n +2 > "$OUT/hadm_to_admittime.csv"

# Step 2: Find the earliest BC admission per patient
#
# bc_diagnoses.csv has multiple rows per patient (one per BC-coded visit).
# We need to compare admittimes across rows for the same subject_id
# and keep only the earliest one. sort/uniq can't do this because the
# rows are all different lines - we need to track the minimum date per
# subject across rows, which is what awk's array does here.
awk -F',' '
BEGIN { OFS="," }

# FILE 1: load hadm_id -> admittime into array t
NR==FNR {
  t[$1] = $2
  next
}

# FILE 2: bc_diagnoses.csv - find earliest admittime per subject
NR==1 { next }  # skip header

{
  sid  = $1
  hadm = $2
  code = $4
  time = t[hadm]

  if (time == "") next

  if (!(sid in best_time) || time < best_time[sid]) {
    best_time[sid] = time
    best_row[sid]  = sid OFS hadm OFS time OFS code
  }
}

END {
  print "subject_id,hadm_id,admittime,icd_code"
  for (k in best_row) print best_row[k]
}
' "$OUT/hadm_to_admittime.csv" "$DATA/bc_diagnoses.csv" \
| sort -t',' -k1,1n > "$OUT/bc_first_diagnosis.csv"

# DoD check: verify no duplicate subject_ids
TOTAL=$(( $(wc -l < $OUT/bc_first_diagnosis.txt) - 1 ))
UNIQUE=$(tail -n +2 $OUT/bc_first_diagnosis.txt | cut -d',' -f1 | sort -u | wc -l)

echo "total rows: $TOTAL"
echo "unique subject_ids: $UNIQUE"

if [[ "$TOTAL" -eq "$UNIQUE" ]]; then
  echo "CHECK PASSED: no duplicate subject_ids"
else
  echo "WARNING: duplicates found" >&2
fi



