#!/bin/bash
# run_pa4.sh
#
# Sprint 4 main script. Builds off sprint 3 outputs.
#
set -euo pipefail

OUT=out/evidence
DATA=data

mkdir -p out/evidence
mkdir -p out/logs

# Clean bc_first_diagnosis.csv -> bc_first_diagnosis.tsv
# source cols: subject_id,hadm_id,admittime,icd_code
# strip quotes, remove brackets, remove thousands separators,
# convert comma delimiter to tab, trim leading/trailing whitespace,
# then fill empty fields with NA.
# after converting commas to tabs, an empty field looks like \t\t (two tabs in a row).
# s/\t\t/\tNA\t/ replaces it with NA in the middle.
# s/^\t/NA\t/ handles an empty first field (line starts with a tab).
# s/\t$/\tNA/ handles an empty last field (line ends with a tab).
sed -E \
  -e 's/"([^"]*)"/\1/g' \
  -e 's/\[//g' \
  -e 's/\]//g' \
  -e 's/([0-9]),([0-9]{3})/\1\2/g' \
  -e 's/[[:space:]]*,[[:space:]]*/\t/g' \
  -e 's/^[[:space:]]+//; s/[[:space:]]+$//' \
  "${OUT}/bc_first_diagnosis.csv" \
| sed -E \
  -e 's/\t\t/\tNA\t/g' \
  -e 's/^\t/NA\t/' \
  -e 's/\t$/\tNA/' \
> "${OUT}/bc_first_diagnosis.tsv"

# Clean pre_bc_symptom_timeline.csv -> pre_bc_symptom_timeline.tsv
# source cols: subject_id,row_type,hadm_id,admittime,seq_num,icd_code
# strip quotes, remove brackets, remove thousands separators,
# convert comma delimiter to tab, trim leading/trailing whitespace,
# then fill empty fields with NA
sed -E \
  -e 's/"([^"]*)"/\1/g' \
  -e 's/\[//g' \
  -e 's/\]//g' \
  -e 's/([0-9]),([0-9]{3})/\1\2/g' \
  -e 's/[[:space:]]*,[[:space:]]*/\t/g' \
  -e 's/^[[:space:]]+//; s/[[:space:]]+$//' \
  "${OUT}/pre_bc_symptom_timeline.csv" \
| sed -E \
  -e 's/\t\t/\tNA\t/g' \
  -e 's/^\t/NA\t/' \
  -e 's/\t$/\tNA/' \
> "${OUT}/pre_bc_symptom_timeline.tsv"

# BEFORE/AFTER sample file
# Writes head -n 5 of each CSV (before) and TSV (after) into one file for review
{
  echo "BEFORE: bc_first_diagnosis.csv (head -n 5)"
  head -n 5 "${OUT}/bc_first_diagnosis.csv"
  echo ""
  echo "AFTER:  bc_first_diagnosis.tsv (head -n 5)"
  head -n 5 "${OUT}/bc_first_diagnosis.tsv"
  echo ""
  echo "BEFORE: pre_bc_symptom_timeline.csv (head -n 5)"
  head -n 5 "${OUT}/pre_bc_symptom_timeline.csv"
  echo ""
  echo "AFTER:  pre_bc_symptom_timeline.tsv (head -n 5)"
  head -n 5 "${OUT}/pre_bc_symptom_timeline.tsv"
} > out/cleaned_sample.tsv

echo "sample written to out/cleaned_sample.tsv"

# Sanity checks
echo "bc_first_diagnosis row count:"
wc -l "${OUT}/bc_first_diagnosis.csv" "${OUT}/bc_first_diagnosis.tsv"

echo "pre_bc_symptom_timeline row count:"
wc -l "${OUT}/pre_bc_symptom_timeline.csv" "${OUT}/pre_bc_symptom_timeline.tsv"


# =============================================================================
# BHOOMIKA'S SECTION
# =============================================================================

# =========================================================
# PART 2: AWK Quality Filtering
#
# Goal:
# Keep only valid rows from the dataset.
#
# Keep rows where:
#   - subject_id is non-empty and not 0
#   - hadm_id is non-empty
#   - admittime starts with a valid year (YYYY)
#   - icd_code is non-empty
#
# Drop malformed or null rows
#
# Important:
#   - Input is CSV → delimiter = ","
#   - Output is TSV → delimiter = "\t"
#   - NR==1 preserves header
# =========================================================

echo "=== PART 2: AWK Quality Filtering ==="

awk -F',' '
BEGIN { OFS="\t" }

# Preserve header (convert commas → tabs)
NR == 1 {
  print $1, $2, $3, $4, $5, $6
  next
}

# Filter conditions
($1 == "" || $1 == "0" || $1 == "NA") { next }
($3 == "" || $3 == "NA") { next }

# match() checks if admittime starts with YYYY
(match($4, /^[0-9]{4}/) == 0) { next }

($6 == "" || $6 == "NA") { next }

# Print valid rows (CSV → TSV conversion)
{ print $1, $2, $3, $4, $5, $6 }
' "${OUT}/pre_bc_symptom_timeline.csv" \
| sort -t$'\t' -k1,1n -k4,4 \
> "${OUT}/filtered_sample.tsv"

echo "Created: ${OUT}/filtered_sample.tsv"
wc -l "${OUT}/filtered_sample.tsv"
head -n 5 "${OUT}/filtered_sample.tsv"


# =========================================================
# PART 4A: Patient Visits (Temporal Structuring)
#
# Goal:
# Group rows by (subject_id + hadm_id)
# → each pair = one hospital visit
#
# Count distinct ICD codes per visit
#
# Important concepts:
#   - SUBSEP allows multi-key indexing in awk
#   - seen_code[] ensures unique counting
# =========================================================

echo "=== PART 4A: Patient Visits ==="

awk -F'\t' '
BEGIN { OFS="\t" }

# Skip header
NR == 1 { next }

{
  sid  = $1
  hadm = $3
  time = $4
  code = $6

  # Create a unique key for each visit
  visit_key = sid SUBSEP hadm

  # Store admission time for that visit
  admit_time[visit_key] = time

  # Create a unique key for each ICD code per visit
  code_key = sid SUBSEP hadm SUBSEP code

  # Only count each ICD code once per visit
  if (!(code_key in seen_code)) {
    seen_code[code_key] = 1
    code_count[visit_key]++
  }
}

END {
  print "subject_id","hadm_id","admittime","icd_code_count"

  for (k in admit_time) {
    split(k, parts, SUBSEP)
    sid  = parts[1]
    hadm = parts[2]

    print sid, hadm, admit_time[k], code_count[k] + 0
  }
}
' "${OUT}/filtered_sample.tsv" \
| sort -t$'\t' -k1,1n -k3,3 \
> "${OUT}/patient_visits.tsv"

echo "Created: ${OUT}/patient_visits.tsv"
wc -l "${OUT}/patient_visits.tsv"
head -n 5 "${OUT}/patient_visits.tsv"


# =========================================================
# PART 4B: Anchoring Years
#
# Goal:
# Extract earliest year from anchor_year_group
#
# Example:
#   "2008 - 2016" → "2008"
#
# Important functions:
#   - sub() removes text after "-"
#   - gsub() removes spaces
# =========================================================

echo "=== PART 4B: Anchoring Years ==="

awk -F',' '
BEGIN { OFS="\t" }

NR == 1 { next }

{
  sid = $1
  year_group = $5

  # Keep only the first year
  sub(/ - .*/, "", year_group)

  # Remove spaces
  gsub(/[[:space:]]/, "", year_group)

  print sid, year_group
}
' "${DATA}/bc_patients.csv" \
| sort -t$'\t' -k1,1n \
> "${OUT}/anchoring_years.tsv"

echo "Created: ${OUT}/anchoring_years.tsv"
wc -l "${OUT}/anchoring_years.tsv"
head -n 5 "${OUT}/anchoring_years.tsv"

echo "=== (Part 2 + Part 4) complete ==="
