#!/bin/bash

#Variables: Please make sure to modify for your own paths
HOSP_PATH=data/MIMIC-IV/hosp
DATA_PATH=data
OUT_PATH=out

# using bc as a shorthand for bladder cancer

#creating required directories if not available
mkdir -p out
mkdir -p data
mkdir -p data/samples

# Making an error file with headers to help with debugging script
# Note that zcat does not work for .gz files on MacOS/Unix systems


# Pulling out the ICD codes of interest along with version and description
# codes are pulled from hosp/d_icd_diagnoses.csv.gz
# saving the codes to file: bc_icd_codes.csv
# this file contains icd_code, icd_version, long_title
# presorting for ease of joins later
# Fulfills case-insensitive and inverse grep matching requirements in Part C

echo "Errors in making bc_icd_codes.csv" > sprint2_error.log

(zcat ${HOSP_PATH}/d_icd_diagnoses.csv.gz| head -n1 && zgrep -wi 'bladder' ${HOSP_PATH}/d_icd_diagnoses.csv.gz| zgrep -wi 'neoplasm' | zgrep -wiv 'history'| sort -n -k1,1 -t $',') > ${DATA_PATH}/bc_icd_codes.csv 2>>sprint2_error.log


# Using the ICD codes saved to scan diagnoses for related subjects
# pulling subjects from hosp/diagnoses_icd.csv.gz
# saving the values in a file bc_diagnoses.csv with header
# containing subject_id, hadm_id, seq_num, icd_code, icd_version, long_title

echo "Errors in making bc_diagnoses.csv" >> sprint2_error.log

(echo 'subject_id,hadm_id,seq_num,icd_code,icd_version,long_title' && join -1 1 -2 4 -o 2.1,2.2,2.3,1.1,1.2,1.3 -t $',' <(tail -n +2 $(DATA_PATH}/bc_icd_codes.csv) <(zcat ${HOSP_PATH}/diagnoses_icd.csv.gz| tail -n +2 | sort -t ',' -k4,4)) > ${DATA_PATH}/bc_diagnoses.csv 2>> sprint2_error.log

# Creating subject_id file
# cutting the first column, removing header (to add later), then using sort and uniq to remove dupes
# saving output as bc_subjects.csv
# Is technically a skinny table

echo 'Errors in bc_subjects.csv' >> sprint2_error.log

(echo 'subject_id' && cut -f1 -d',' ${DATA_PATH}/bc_diagnoses.csv| tail -n +2| sort | uniq| sort -n) > ${DATA_PATH}/bc_subjects.csv 2>> sprint2_error.log

# Use the subject file to pull out more patient information to save
# pulling patient file from hosp/patients.csv.gz
# use join and save in data using bc_patients.csv
# contains subject_id, gender, anchor age, anchor year, anchor year group, date of death
echo "Error in pulling out bc_patients.csv" >> sprint2_error.log

(echo 'subject_id,gender,anchor_age,anchor_year,anchor_year_group,dod' && join -t $',' <(tail -n +2 ${DATA_PATH}/bc_subjects.csv) <(zcat ${HOSP_PATH}/patients.csv.gz| tail -n +2 | sort -t $',' -k1,1 -n)) > ${DATA_PATH}/bc_patients.csv 2>> sprint2_error.log

# Get all diagnoses from subjects of concern
# combines bc_subjects and diagnoses_icd tables
# saving output as bc_subjects_diagnoses
# joins subject to diagnosis table
# contains subject_id, hadm_id, seq_num, icd_code, icd_version
# cannot at this time link to long version due to the lack of sanitation (comma’s present in the long_title field messing with the join)
echo "Error in pulling out bc_subjects_diagnoses.csv" >> sprint2_error.log

(echo 'subject_id,hadm_id,seq_num,icd_code,icd_version' && join -1 1 -2 1 -t',' <(tail -n +2 ${DATA_PATH}/bc_subjects.csv ) <(zcat ${HOSP_PATH}/diagnoses_icd.csv.gz| tail -n +2 | sort -t',' -k1,1 -n))> ${DATA_PATH}/bc_subjects_diagnoses.csv 2>> sprint2_error.log


# Get all visits from subjects and combine with patient information)
# Pull people from hosp/admissions.csv and join with the bc_patients table
# use join and save as bc_admissions_patients.csv
# contains all headers from admissions and patients tables
# Fulfills part of section C optional join
echo "Error in pulling all admissions of patients with their information" >> sprint2_error.log

(echo 'subject_id,hadm_id,admittime,dischtime,deathtime,admission_type,admit_provider_id,admission_location,discharge_location,insurance,language,marital_status,race,edregtime,edoutttime,hospital_expire_flag,gender,anchor_age,anchor_year,anchor_year_group,dod' && join -1 1 -2 1 -t',' <(zcat ${HOSP_PATH}/admissions.csv.gz |tail -n +2| sort -t',' -k1,1) <(tail -n +2 ${DATA_PATH}/bc_patients.csv| sort -t',' -k1,1))> ${DATA_PATH}/bc_admissions_patients.csv 2>>script2_error.log




# Get a sample from the bc_admissions_patients.csv
# requires shuf, may require homebrew for MacOS/Unix download first
# Fulfills Part of Section B
echo "Errors in getting a shuffled subset of bc_admissions_patients.csv" >> script2_error.log

(head -n1 ${DATA_PATH}/bc_admissions_patients.csv && tail -n +2 ${DATA_PATH}/bc_admissions_patients.csv| shuf -n 1000) > ${DATA_PATH}/sample/subset_bc_admissions_patients.csv 2>>script2_error.log

# Get histograms
# sex/gender : using bc_patients.csv
tail -n +2 ${DATA_PATH}/bc_patients.csv| cut -d',' -f2| sort | uniq -c |sort -nr > ${OUT_PATH}/freq_gender.txt

# race : using bc_admissions_patients.csv
#ideally no duplicates. So extract out subject_id and race, sort, uniq, cut subject_id, sort, uniq c, sort -nr.
tail -n +2 ${DATA_PATH}/bc_admissions_patients.csv| cut -d',' -f1,13| sort | uniq| cut -d',' -f2| sort | uniq -c| sort -nr > ${OUT_PATH}/freq_race.txt

# Deriving Skinny Tables 
# subject_id/race : using bc_admissions_patients.csv
tail -n +2 ${DATA_PATH}/bc_admissions_patients.csv | cut -d',' -f1,13 | sort -u > ${OUT_PATH}/bc_skinny_subjectID_race.csv 

# subject_id/gender : using bc_patients.csv
tail -n +2 ${DATA_PATH}/bc_patients.csv | cut -d',' -f1,2 | sort -u > ${OUT_PATH}/bc_skinny_subjectID_gender.csv


# language: using bc_admissions.patients.csv
# as before, extract out subject_id and language, sort, uniq, cut subject_id, sort, uniq c, sort -nr
tail -n +2 ${DATA_PATH}/bc_admissions_patients.csv| cut -d',' -f1,11| sort | uniq| cut -d',' -f2| sort | uniq -c| sort -nr > ${OUT_PATH}/freq_language.txt


# top 10 subjects by number of admissions
tail -n +2 ${DATA_PATH}/bc_admissions_patients.csv  | cut -d',' -f1  | sort -n  | uniq -c  | sort -nr  | head > ${OUT_PATH}/top_admissions_by_subject.txt

 

