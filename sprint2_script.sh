#!/bin/bash

# Starting from scratch
# using bc as a shorthand for bladder cancer

# requirement B random 1k sample
mkdir -p data/samples
(zcat data/MIMIC-IV/hosp/admissions.csv.gz | head -n 1 && zcat data/MIMIC-IV/hosp/admissions.csv.gz | tail -n +2 | shuf -n 1000) > data/samples/admissions_sample_1k.csv

#general out directory
mkdir -p out

# Pulling out the ICD codes of interest along with version and description
# codes are pulled from hosp/d_icd_diagnoses.csv.gz
# saving the codes to file: bc_icd_codes.csv
# this file contains icd_code, icd_version, long_title
# presorting for ease of joins later
(zcat data/MIMIC-IV/hosp/d_icd_diagnoses.csv.gz| head -n1 && zgrep -wi 'bladder' data/MIMIC-IV/hosp/d_icd_diagnoses.csv.gz| zgrep -wi 'neoplasm' | zgrep -wiv 'history'| sort -n -k1,1 -t $',') > data/bc_icd_codes.csv    

#example grep specific usage
zcat data/MIMIC-IV/hosp/d_icd_diagnoses.csv.gz | grep -i bladder | grep -v history | head > out/grep_screen_example.txt

# Using the ICD codes saved to scan diagnoses for related subjects
# pulling subjects from hosp/diagnoses_icd.csv.gz
# saving the values in a file bc_diagnoses.csv with header
# containing subject_id, hadm_id, seq_num, icd_code, icd_version, long_title
(echo 'subject_id,hadm_id,seq_num,icd_code,icd_version,long_title' && join -1 1 -2 4 -o 2.1,2.2,2.3,1.1,1.2,1.3 -t $',' <(tail -n +2 data/bc_icd_codes.csv) <(zcat data/MIMIC-IV/hosp/diagnoses_icd.csv.gz| tail -n +2 | sort -t ',' -k4,4)) > data/bc_diagnoses.csv 2> error.log

# Creating subject_id file
# cutting the first column, removing header (to add later), then using sort and uniq to remove dupes
# saving output as bc_subjects.csv
# total number of subjects = 720 patients
(echo 'subject_id' && cut -f1 -d',' data/bc_diagnoses.csv| tail -n +2| sort | uniq| sort -n) > data/bc_subjects.csv

# Use the subject file to pull out more patient information to save
# pulling patient file from hosp/patients.csv.gz
# use join and save in data using bc_patients.csv
# contains subject_id, gender, anchor age, anchor year, anchor year group, date of death
(echo 'subject_id,gender,anchor_age,anchor_year,anchor_year_group,dod' && join -t $',' <(tail -n +2 data/bc_subjects.csv) <(zcat data/MIMIC-IV/hosp/patients.csv.gz| tail -n +2 | sort -t $',' -k1,1 -n)) > data/bc_patients.csv 2> error.log


# Get all diagnoses from subjects of concern
# combines bc_subjects and diagnoses_icd tables
# saving output as bc_subjects_diagnoses
# joins subject to diagnosis table
# contains subject_id, hadm_id, seq_num, icd_code, icd_version
# cannot at this time link to long version due to the lack of sanitation (comma’s present in the long_title field messing with the join)

(echo 'subject_id,hadm_id,seq_num,icd_code,icd_version' && join -1 1 -2 1 -t',' <(tail -n +2 data/bc_subjects.csv ) <(zcat data/MIMIC-IV/hosp/diagnoses_icd.csv.gz| tail -n +2 | sort -t',' -k1,1 -n))> data/bc_subjects_diagnoses.csv 2> error.log


# Get all visits from subjects and combine with patient information)
# Pull people from hosp/admissions.csv and join with the bc_patients table
# use join and save as bc_admissions_patients.csv
# contains all headers from admissions and patients tables
(echo 'subject_id,hadm_id,admittime,dischtime,deathtime,admission_type,admit_provider_id,admission_location,discharge_location,insurance,language,marital_status,race,edregtime,edoutttime,hospital_expire_flag,gender,anchor_age,anchor_year,anchor_year_group,dod' && join -1 1 -2 1 -t',' <(zcat data/MIMIC-IV/hosp/admissions.csv.gz |tail -n +2| sort -t',' -k1,1) <(tail -n +2 data/bc_patients.csv| sort -t',' -k1,1))> data/bc_admissions_patients.csv 2>error.log


# Get histograms
# sex/gender : using bc_patients.csv
tail -n +2 data/bc_patients.csv| cut -d',' -f2| sort | uniq -c |sort -nr > out/freq_gender.txt

# race : using bc_admissions_patients.csv
#ideally no duplicates. So extract out subject_id and race, sort, uniq, cut subject_id, sort, uniq c, sort -nr.
tail -n +2 data/bc_admissions_patients.csv| cut -d',' -f1,13| sort | uniq| cut -d',' -f2| sort | uniq -c| sort -nr > out/freq_race.txt  

# language: using bc_admissions.patients.csv
# as before, extract out subject_id and language, sort, uniq, cut subject_id, sort, uniq c, sort -nr
tail -n +2 data/bc_admissions_patients.csv| cut -d',' -f1,11| sort | uniq| cut -d',' -f2| sort | uniq -c| sort -nr > out/freq_language.txt


# top 10 subjects by number of admissions
tail -n +2 data/bc_admissions_patients.csv  | cut -d',' -f1  | sort  | uniq -c  | sort -nr  | head -n 10 > out/top_admissions_by_subject.txt

# skinny tables
(zcat data/MIMIC-IV/hosp/admissions.csv.gz | head -n 1 | cut -d',' -f1,13 && zcat data/MIMIC-IV/hosp/admissions.csv.gz | tail -n +2 | cut -d',' -f1,13 | sort -u) > out/skinny_subjectID_race.txt

(zcat data/MIMIC-IV/hosp/patients.csv.gz | head -n 1 | cut -d',' -f1,2 && zcat data/MIMIC-IV/hosp/patients.csv.gz | tail -n +2 | cut -d',' -f1,2 | sort -u) > out/skinny_subjectID_gender.txt

#requirement D using tee out for top diagnoses
tail -n +2 data/bc_subjects_diagnoses.csv | cut -d',' -f4,5 | sort -n | uniq -c | sort -nr | head | tee out/top_diagnoses.txt
