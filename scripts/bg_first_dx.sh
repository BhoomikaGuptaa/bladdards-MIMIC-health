#!/usr/bin/env bash
set -euo pipefail

# BG Sprint 3 tasks:
# 1.1 Create BC group with first diagnosis (one row per subject_id)
# 1.2 Remove later BC diagnoses per patient (keep earliest)
#
# Inputs (local, not committed):
#   data/admissions.csv
#   data/diagnoses_icd.csv
#
# Outputs (ignored by git):
#   out/evidence/bc_dx_all.csv
#   out/evidence/hadm_to_admittime.csv
#   out/evidence/bc_first_diagnosis.csv

mkdir -p out/evidence

# All ICD-10 bladder cancer diagnoses (C67*)
awk -F, 'NR==1 || ($5==10 && $4 ~ /^C67/)' data/diagnoses_icd.csv > out/evidence/bc_dx_all.csv

# hadm_id -> admittime lookup
awk -F, 'NR>1 {print $2","$3}' data/admissions.csv > out/evidence/hadm_to_admittime.csv

# Join + keep earliest BC diagnosis per subject_id
awk -F, '
BEGIN { OFS="," }
NR==FNR { t[$1]=$2; next }
NR==1 { next }
{
  sid=$1; hadm=$2; code=$4;
  time=t[hadm];
  if (time=="") next;

  if (!(sid in best_time) || time < best_time[sid]) {
    best_time[sid]=time;
    best_row[sid]=sid OFS hadm OFS time OFS code;
  }
}
END {
  print "subject_id,hadm_id,admittime,icd_code";
  for (k in best_row) print best_row[k];
}
' out/evidence/hadm_to_admittime.csv out/evidence/bc_dx_all.csv \
| sort -t, -k1,1n \
> out/evidence/bc_first_diagnosis.csv

echo "Wrote out/evidence/bc_first_diagnosis.csv"
echo "Total BC dx rows: $(($(wc -l < out/evidence/bc_dx_all.csv) - 1))"
echo "Unique subjects (first dx): $(($(wc -l < out/evidence/bc_first_diagnosis.csv) - 1))"
