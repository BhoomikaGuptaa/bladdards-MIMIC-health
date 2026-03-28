#!/bin/bash
#
# Sprint 4 main script. Builds off sprint 3 outputs.
#
set -euo pipefail

mkdir -p out/evidence logs

# Prompt for the path to the sprint 3 output CSVs.
# The MIMIC-IV dataset location varies per machine, so this allows the
# TA/grader to point the script at wherever their sprint 3 outputs live.
# Press Enter to accept the default (out/evidence).
echo "Enter path to sprint 3 output CSVs [default: out/evidence]:"
read INPUT_PATH
# If the user pressed Enter without typing a path, fall back to the default
if [ -z "$INPUT_PATH" ]; then
  INPUT_PATH=out/evidence
fi

# OUT is used as the base directory for both input CSVs and output TSVs
OUT="$INPUT_PATH"

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

# 
# BEFORE/AFTER sample file
# 
# Writes head -n 5 of each CSV and TSV into one file 
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
