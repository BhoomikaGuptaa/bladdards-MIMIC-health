#!/usr/bin/env bash
set -euo pipefail

OUT="out/evidence"
DATA="data"
FULL_DX_GZ="$HOME/physionet.org/files/mimiciv/3.1/hosp/diagnoses_icd.csv.gz"
DICT="$HOME/physionet.org/files/mimiciv/3.1/hosp/d_icd_diagnoses.csv.gz"

mkdir -p "$OUT"

# Inputs
test -f "$DATA/bc_admissions_patients.csv"
test -f "$OUT/bc_first_diagnosis.csv"
test -f "$FULL_DX_GZ"

# Step 0: build symptom ICD list

KEYWORDS="hematuria|dysuria|urinary tract infection|uti|abdominal pain|gas pain|bladder disorder|calculus|retention of urine|suprapubic|pelvic and perineal pain|lower quadrant pain"

# Step 0: build symptom ICD list
{
  echo "icd_code,icd_version,long_title"

  zcat "$DICT" \
  | awk -F',' 'NR>1 {print $1","$2","$3}' \
  | grep -Ei "$KEYWORDS"

} \
| sort -t',' -k1,1 -k2,2 \
| uniq \
| cut -d',' -f1,2 \
> "$DATA/symptom_icd_list.txt"
# Step 1: build hadm_id -> admittime lookup
(
  echo "hadm_id,admittime"
  cut -d',' -f2,3 "$DATA/bc_admissions_patients.csv" | tail -n +2
) \
| sort -t',' -k1,1n -u \
> "$OUT/hadm_to_admittime.csv"

# Step 2: extract all symptom diagnosis rows from FULL diagnoses file
(
  echo "subject_id,hadm_id,seq_num,icd_code,icd_version"
  awk -F',' '
  NR==FNR {
    keep[$1 "|" $2] = 1
    next
  }
  FNR==1 { next }
  {
    key = $4 "|" $5
    if (key in keep) {
      print $1 "," $2 "," $3 "," $4 "," $5
    }
  }
  ' "$DATA/symptom_icd_list.txt" <(zcat "$FULL_DX_GZ")
) \
> "$OUT/symptom_dx_all.csv"

# Step 3: attach admittime to symptom rows
awk -F',' '
BEGIN { OFS="," }

NR==FNR {
  if (FNR==1) next
  t[$1] = $2
  next
}

FNR==1 {
  print "subject_id","hadm_id","admittime","seq_num","icd_code","icd_version"
  next
}

{
  hadm = $2
  if (hadm in t) {
    print $1,$2,t[hadm],$3,$4,$5
  }
}
' "$OUT/hadm_to_admittime.csv" "$OUT/symptom_dx_all.csv" \
> "$OUT/symptom_dx_with_time.csv"

# Step 4: keep only symptom rows before first BC diagnosis
awk -F',' '
BEGIN { OFS="," }

NR==FNR {
  if (FNR==1) next
  bc_hadm[$1] = $2
  bc_time[$1] = $3
  bc_code[$1] = $4
  next
}

FNR==1 { next }

{
  sid = $1
  sym_hadm = $2
  sym_time = $3

  if ((sid in bc_time) && sym_time < bc_time[sid]) {
    print sid,"SYMPTOM",sym_hadm,sym_time,$4,$5
  }
}
' "$OUT/bc_first_diagnosis.csv" "$OUT/symptom_dx_with_time.csv" \
| sort -t',' -k1,1n -k4,4 \
> "$OUT/pre_bc_symptoms_only.csv"

# Step 5: make one BC row per subject
awk -F',' '
BEGIN { OFS="," }

FNR==1 { next }

{
  print $1,"BC_FIRST_DX",$2,$3,$4,$5
}
' "$OUT/bc_first_diagnosis.csv" \
> "$OUT/bc_first_dx_rows.csv"

# Step 6: combine symptom rows + BC row into patient timeline
(
  echo "subject_id,row_type,hadm_id,admittime,seq_num,icd_code"
  cat "$OUT/pre_bc_symptoms_only.csv"
  cat "$OUT/bc_first_dx_rows.csv"
) \
| sort -t',' -k1,1n -k4,4 -k2,2 \
> "$OUT/pre_bc_symptom_timeline.csv"

# Step 7: checks
echo "Created: $OUT/pre_bc_symptom_timeline.csv"
echo "timeline rows: $(( $(wc -l < "$OUT/pre_bc_symptom_timeline.csv") - 1 ))"
echo "subjects in timeline: $(tail -n +2 "$OUT/pre_bc_symptom_timeline.csv" | cut -d',' -f1 | sort -u | wc -l)"
echo "symptom rows: $(awk -F',' 'NR>1 && $2=="SYMPTOM"{c++} END{print c+0}' "$OUT/pre_bc_symptom_timeline.csv")"
echo "BC rows: $(awk -F',' 'NR>1 && $2=="BC_FIRST_DX"{c++} END{print c+0}' "$OUT/pre_bc_symptom_timeline.csv")"
