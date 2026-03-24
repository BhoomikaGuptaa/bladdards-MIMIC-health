#!/bin/bash

# clean_csvs.sh
#
# Converts sprint output CSVs to normalized TSV files using a sed -E pipeline.
# Called from run_sprint3.sh
#
# Outputs:
#   out/evidence/*.tsv          — cleaned TSV versions of key CSVs
#   out/cleaned_sample.tsv      — BEFORE/AFTER head -n 5 samples

OUT="${OUT:-out/evidence}"

# ---------------------------------------------------
# Clean bc_first_diagnosis.csv -> bc_first_diagnosis.tsv
# ---------------------------------------------------
# source cols: subject_id,hadm_id,admittime,icd_code
sed -E \
  -e 's/\r//' \
  -e 's/"([^"]*)"/\1/g' \
  -e 's/\[//g' \
  -e 's/\]//g' \
  -e 's/([0-9]),([0-9]{3})/\1\2/g' \
  -e 's/[[:space:]]*,[[:space:]]*/\t/g' \
  -e 's/^[[:space:]]+//; s/[[:space:]]+$//' \
  "${OUT}/bc_first_diagnosis.csv" \
| sed -E \
  -e 's/\t\t/\tNA\t/g' \
  -e 's/\t\t/\tNA\t/g' \
  -e 's/^\t/NA\t/' \
  -e 's/\t$/\tNA/' \
> "${OUT}/bc_first_diagnosis.tsv"

# ---------------------------------------------------
# Clean pre_bc_symptom_timeline.csv -> pre_bc_symptom_timeline.tsv
# ---------------------------------------------------
# source cols: subject_id,row_type,hadm_id,admittime,seq_num,icd_code
sed -E \
  -e 's/\r//' \
  -e 's/"([^"]*)"/\1/g' \
  -e 's/\[//g' \
  -e 's/\]//g' \
  -e 's/([0-9]),([0-9]{3})/\1\2/g' \
  -e 's/[[:space:]]*,[[:space:]]*/\t/g' \
  -e 's/^[[:space:]]+//; s/[[:space:]]+$//' \
  "${OUT}/pre_bc_symptom_timeline.csv" \
| sed -E \
  -e 's/\t\t/\tNA\t/g' \
  -e 's/\t\t/\tNA\t/g' \
  -e 's/^\t/NA\t/' \
  -e 's/\t$/\tNA/' \
> "${OUT}/pre_bc_symptom_timeline.tsv"

# ---------------------------------------------------
# BEFORE/AFTER sample file
# ---------------------------------------------------
{
  echo "=== BEFORE: bc_first_diagnosis.csv (head -n 5) ==="
  head -n 5 "${OUT}/bc_first_diagnosis.csv"
  echo ""
  echo "=== AFTER:  bc_first_diagnosis.tsv (head -n 5) ==="
  head -n 5 "${OUT}/bc_first_diagnosis.tsv"

  echo ""
  echo "=== BEFORE: pre_bc_symptom_timeline.csv (head -n 5) ==="
  head -n 5 "${OUT}/pre_bc_symptom_timeline.csv"
  echo ""
  echo "=== AFTER:  pre_bc_symptom_timeline.tsv (head -n 5) ==="
  head -n 5 "${OUT}/pre_bc_symptom_timeline.tsv"
} > out/cleaned_sample.tsv

echo "sample written to out/cleaned_sample.tsv"
