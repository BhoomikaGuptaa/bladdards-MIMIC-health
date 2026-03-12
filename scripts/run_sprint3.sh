#!/bin/bash

#  sprint3_script.sh
#  
# Created by Bhoomika, Aaditya and Sharon
# Combined by Sharon M.
#
set -euo pipefail

LOG=out/run_sprint3.log
ERROR=out/errors.log
OUT=out/evidence
DATA=data
MIMIC=data/MIMIC-IV/hosp
FULL_DX_GZ="data/MIMIC-IV/hosp/diagnoses_icd.csv.gz"
#where the diagnoses file lives
DICT="data/MIMIC-IV/hosp/d_icd_diagnoses.csv.gz"
# where the icd codes lives

# Sprint 3 (BG): get first bladder cancer diagnosis per patient
# Goal: one row per subject_id (earliest BC-coded admission)
#
# We use awk here because we need to:
# 1) match codes exactly (not partial string matches)
# 2) group by subject_id
# 3) keep the minimum (earliest) admittime
# That kind of “group and compare” logic is hard to do with just sort/uniq.

mkdir -p "$OUT"
: > "${LOG}"
: > "${ERROR}"
exec > >(tee -a "${LOG}") 2> >(tee -a "${ERROR}" >&2)
# for logging
# ---------------------------------------------------
# Step 1: Build a simple list of BC ICD codes
# ---------------------------------------------------
# bc_icd_codes.csv was generated locally (Sprint 2 logic).
# We just grab the first column (icd_code), skip header, and deduplicate.
cut -d',' -f1 ${DATA}/bc_icd_codes.csv | tail -n +2 | tr -d '\r' | sort -u > "${OUT}/bc_codes.txt"

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
  while ((getline c < "'"${OUT}/bc_codes.txt"'") > 0) {
    codes[c]=1
  }
  close("'"${OUT}/bc_codes.txt"'")
}
NR==1 { print; next }        # keep header
($4 in codes) { print }      # only keep rows where icd_code matches exactly
' <(gzcat ${MIMIC}/diagnoses_icd.csv.gz) > "${OUT}/bc_dx_all.csv"

## Use join. In fact, we have this table -> bc_diagnoses.csv

# ---------------------------------------------------
# Step 3: Build hadm_id -> admittime lookup
# ---------------------------------------------------
# admissions.csv columns start:
# subject_id,hadm_id,admittime,...
# We only need hadm_id and admittime.
awk -F',' 'NR>1 {print $2","$3}' <(gzcat ${MIMIC}/admissions.csv.gz) > "${OUT}/hadm_to_admittime.csv"

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

# Second file: bc_diagnoses.csv
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
' "${OUT}/hadm_to_admittime.csv" "${OUT}/bc_dx_all.csv" \
| sort -t',' -k1,1n > "${OUT}/bc_first_diagnosis.csv"

echo "done"
echo "codes: $(wc -l < ${OUT}/bc_codes.txt)"
echo "bc rows: $(wc -l < ${OUT}/bc_dx_all.csv)"
echo "unique subjects: $(( $(wc -l < ${OUT}/bc_first_diagnosis.csv) - 1 ))"





# Inputs
test -f "${DATA}/bc_admissions_patients.csv"
test -f "${OUT}/bc_first_diagnosis.csv"
test -f "${FULL_DX_GZ}"

# Step 0: build symptom ICD list

KEYWORDS="hematuria|dysuria|urinary tract infection|uti|abdominal pain|gas pain|bladder disorder|calculus|retention of urine|suprapubic|pelvic and perineal pain|lower quadrant pain"

# Step 0: build symptom ICD list
{
  echo "icd_code,icd_version,long_title"

  gzcat "$DICT" \
  | awk -F',' 'NR>1 {print $1","$2","$3}' \
  | grep -Eiw "${KEYWORDS}"

} \
| sort -t',' -k1,1 -k2,2 \
| uniq \
| cut -d',' -f1,2 \
> "${DATA}/symptom_icd_list.txt"
# Step 1: build hadm_id -> admittime lookup
(
  echo "hadm_id,admittime"
  cut -d',' -f2,3 "${DATA}/bc_admissions_patients.csv" | tail -n +2
) \
| sort -t',' -k1,1n -u \
> "${OUT}/hadm_to_admittime.csv"

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
  ' "${DATA}/symptom_icd_list.txt" <(gzcat "${FULL_DX_GZ}")
) \
> "${OUT}/symptom_dx_all.csv"

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
' "${OUT}/hadm_to_admittime.csv" "${OUT}/symptom_dx_all.csv" \
> "${OUT}/symptom_dx_with_time.csv"

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
' "${OUT}/bc_first_diagnosis.csv" "${OUT}/symptom_dx_with_time.csv" \
| sort -t',' -k1,1n -k4,4 \
> "${OUT}/pre_bc_symptoms_only.csv"

# Step 5: make one BC row per subject
awk -F',' '
BEGIN { OFS="," }

FNR==1 { next }

{
  print $1,"BC_FIRST_DX",$2,$3,$4,$5
}
' "${OUT}/bc_first_diagnosis.csv" \
> "${OUT}/bc_first_dx_rows.csv"

# Step 6: combine symptom rows + BC row into patient timeline
(
  echo "subject_id,row_type,hadm_id,admittime,seq_num,icd_code"
  cat "${OUT}/pre_bc_symptoms_only.csv"
  cat "${OUT}/bc_first_dx_rows.csv"
) \
| sort -t',' -k1,1n -k4,4 -k2,2 \
> "${OUT}/pre_bc_symptom_timeline.csv"

# Step 7: checks
echo "Created: ${OUT}/pre_bc_symptom_timeline.csv"
echo "timeline rows: $(( $(wc -l < "${OUT}/pre_bc_symptom_timeline.csv") - 1 ))"
echo "subjects in timeline: $(tail -n +2 "${OUT}/pre_bc_symptom_timeline.csv" | cut -d',' -f1 | sort -u | wc -l)"
echo "symptom rows: $(awk -F',' 'NR>1 && $2=="SYMPTOM"{c++} END{print c+0}' "${OUT}/pre_bc_symptom_timeline.csv")"
echo "BC rows: $(awk -F',' 'NR>1 && $2=="BC_FIRST_DX"{c++} END{print c+0}' "${OUT}/pre_bc_symptom_timeline.csv")"


# Now to find out how many people came for related symptoms
# prior to their bladder cancer diagnosis
# using the pre-bc symptoms only (no headers)
(echo -e "subject_id\tcount" && cut -d',' -f1,3 ${OUT}/pre_bc_symptoms_only.csv | sort |uniq|cut -d',' -f1|uniq -c| sort -nr | sed -E 's/^[[:space:]]*([0-9]+)[[:space:]]+(.+)/\2\t\1/')> ${OUT}/admission_counts_pre_bc.txt
#the -e allows the tab to work. Otherwise it cuts the subject line, sorts, uniqs
# and then turns the odd uniq-c spacing into tab delimited and saves

# Create buckets of 1, 2, 3+ admissions prior to diagnoses
# easiest using awk
(echo -e "Admissions\tSubjects" &&
awk -F '\t' \
' BEGIN {bucket1=0; bucket2=0; bucket3=0}\
FNR==1 {next}\
{admissions = $2\
($2>=3 ? bucket3++ : ($2==2 ? bucket2++ : bucket1++))}\
END {print "One""\t"bucket1"\nTwo""\t"bucket2"\nThree+""\t"bucket3}' ${OUT}/admission_counts_pre_bc.txt| sort -t '\t' -k2,2 -nr)>${OUT}/freq_admission_counts.txt


# make a top 20 list of those ICD codes and conditions.
# Since I don't want errors here, I'm going to start transforming things to tab using sed
sed 's/,/\t/g' ${OUT}/pre_bc_symptoms_only.csv| \
#change to a tab delimited
cut -f6 -d $'\t'|\
#just keeping the icd codes
sort | uniq -c| sort -nr |\
# getting the top x ones
head -n20| sed -E 's/^[[:space:]]*([0-9]+)[[:space:]]+(.+)/\1\t\2/'|\
# grabs the head and changes to tab delimited. Now to join with ICD version and long title as tabs
sort -t $'\t' -k2,2| \
#sorting them by icd code
join -1 2 -2 1 -t $'\t' -o 1.1,1.2,2.2,2.3 - <(gzcat ${MIMIC}/d_icd_diagnoses.csv.gz| tail -n +2| sed -e 's/,/\t/1' -e 's/,/\t/1'| sort -t $'\t' -k1,1)|\
sort -t $'\t' -k1,1 -nr > ${OUT}/top_icd_pre_bc.txt



# Sanity check. Does the admisison counts totals match that of the initial pre_bc_symptoms_file?
# Are there the same or moore counts in the freq_admissions as the admission_counts
echo "Sanity Check on Admissions" > ${OUT}/admission_outliers.txt
(echo "Number of unique admissions" && cut -d',' -f3 ${OUT}/pre_bc_symptoms_only.csv|sort|uniq|wc -l )>> ${OUT}/admission_outliers.txt
(echo "Number per admission counts" && \
awk -F'\t' \
'BEGIN {admin_count=0} FNR==1{next}\
{counts = $2 ; admin_count+=counts}\
END {print admin_count}' ${OUT}/admission_counts_pre_bc.txt)\
>>${OUT}/admission_outliers.txt

(echo "Approximation based on frequency" && \
awk -F'\t' \
'BEGIN {admin_count=0}\
FNR==1 {next}\
{admin_type = $1 ; subjects = $2; \
($1=="One" ? (admin_count += subjects) : ($1=="Two" ? (admin_count+= subjects*2): (admin_count += subjects*3)))}\
END {print admin_count }' \
${OUT}/freq_admission_counts.txt)>>${OUT}/admission_outliers.txt

