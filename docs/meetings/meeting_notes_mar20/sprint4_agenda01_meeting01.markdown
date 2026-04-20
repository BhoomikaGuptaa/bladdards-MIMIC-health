Sprint 4 – Meeting 1 Agenda (+ Additional Notes)
Date: March 20, 2023 13:00
Attendees:
Ara Anandkumar (PM)
Bhoomika Gupta (Engineer)
Kristy Chan (Engineer)
Aaditya Deshmukh (Engineer)
Sharon Mathys (Storyteller)


# Sprint 3 Feeback + Improving Symptom List
- Professor G flagged that our symptom list lacks clear relevance to progression of bladder cancer
- Need to clarify why each symptom was included and *why* they were included within the symptoms list 
    Explicitly cite sources used:
        - CDC website, papers, physicians, etc.
- Aaditya will need to add a short explanation of how we constructed the symptom list (method + filtering decisions)

*Acknowledge limitation:*
We do not have access to doctors’ notes, so symptom inclusion is based on external sources, not clinical narratives
These symptoms/diagnoses chosen were those that overlapped with common localized bladder cancer symptoms.
As we are looking for potential delayed diagnoses, those that may be mistaken instead of bladder cancer are considered relevant.


## Other Feedback
- Comments are key. Engineers should be able to explain their code. 
- While AI can be used to help problem-solve, make sure you can explain code before implementing


# ICD Nuances 
ICD codes are:
  - Writen primarily by trained medical coders based on medical documentation (usually not a physician)
  - Used primarily for billing and insurance. Due to Changeover in 2015 (ICD-9 vs ICD-10 overlap) some things may have both versions of the codes
Working assumption:
  - Patients may have both ICD-9 and ICD-10 codes tied to the same encounter
Need to validate whether:
  - Multiple ICD codes = same visit vs multiple visits

# Temporal Structuring of Patient Visits
Use `awk` to:
  - Extract dates + patient identifiers
  - Deconvolute visits --> determine visit-level vs patient-level records
Define:
  - Anchoring year per patient (earliest recorded admission)
Current assumption:
  - Earliest admission year represents the baseline where both ICD-9 and ICD-10 may appear

# Building Distribution Profile 
  - Identify patients with admissions prior to formal bladder cancer diagnosis
  - Build tabular summary with min, max, mean, mode, and standard deviation 

**Goal: Identify surface potential early signals / misdiagnosis patterns**

# Pipeline and Script Requirements 
Entry script: run_pa4.sh must:
    - Accept input path to MIMIC-IV (`hosp/` folder)
    - Prompt user if not provided
  
- The script must check for directories; mkdir -p out 
- The script should be in strict mode; which needs `set -euo pipefail` 
- Clean error messages; continue with logging -> as done with `script3.log`
- Specify that TA/Grader should have access to the MIMIC-IV Database in order to have access to previous `out/` folders + future scripts pertaining to our project 
    - The script MUST be flexibile, given that we do not know where the MIMIC-IV/hosp/ folder lives within the TA/Grader's local machine 

# Additional Notes and Reminders 
We covered the following: 
  - SED --> cleaning + normalization
  - AWK --> filtering, summaries, ratios
  - Temporal or structural analysis (we are choosing temporal)
  - Signal discovery (numeric distributions + outliers)
Outputs:
  - .tsv, reproducible, sorted
**REMEMBER: No outputs committed to repo**

###############################################################################

# ACTION ITEMS FOR DATA ENGINEERS 

- Data Engineer #1 (Kristy Chan) 
  **DE #1 will be in charge of completing deliverable #1, as specified in the project guidelines**

    - Implement `sed -E` pipeline to convert current CSV files into TSV format:
      - Trim leading/trailing whitespace 
      - Collapse internal whitespace --> consistent delimiter (`-d$'\t'`)
      - Normalize punctuation (remove brackets and fix quotes)
      - Handle missing values (NA, empty values --> replaced with standardized tokens)
      - Remove thousands separators (`,`)
  
    - MAKE SURE: 
      - Every row has consistent number of columns 
      - Headers are clean and correctly aligned 
  
    - Generate before/after cleaning samples 
      - Extract first 5 rows saved from CSV file as the *BEFORE*
      - Extrac first 5 rows from the converted TSV file as the *AFTER*
        - Redirect *before/after* results into `out/cleaned_sample.tsv`
    - The final output should be the cleaned full dataset stream (*piped forward, not manually saved*)

- Data Engineer #2 (Bhoomika Gupta) 
**DE #2 will be in charge of completing deliverables #2 and #4, as specified in the project guidelines**

# Below is the action items for #2 
- Implement quality filtering using `AWK`:
  - Keep:
    - Non-empty patient IDs
    - Valid ICD codes
    - Realistic admission dates

  - Drop:
    - Null / malformed rows
    - Test or invalid entries
  
  - Maintain headers using:
    - `NR==1 || (predicate)`

REMEMBER!: Redirect results to separate out files, but do not push the out/ to Github 
- Output:
`out/filtered_sample.tsv` 


# Below is the action items for #4 
- Implement temporal structuring of patient visits (core logic):
  - Extract:
    - subject_id (`subj_id`)
    - admission ids (`hadm_id`)

  - Deconvolute visits:
    - Determine if multiple ICD codes correspond to the same visit or multiple visits

  - Derive:
    - Anchoring year (earliest admission per patient)

REMEMBER!: Redirect results to separate out files, but do not push the out/ to Github 
Output:
- `out/patient_visits.tsv`
- `out/anchoring_years.tsv`


- Data Engineer #3 (Aaditya Deshmukh)
**DE #3 will be in charge of completing deliverables #3 and #5, as specified in the project guidelines**

# Below is the action items for #3 
- Implement ratios + bucketization (AWK):
  - Compute at least one ratio:
        e.g., pre-diagnosis visits / total visits
  - Guard against division by zero
  - Bucket patients into:
        **HIGH / MID / LOW / ZERO**

REMEMBER!: Redirect results to separate out files, but do not push the out/ to Github 
Output:
- `out/buckets.tsv`


# Below is the action items for #5 

- Implement per-entity summaries:
  - For each patient:
    - Total visit count
    - Average pre-diagnosis visits
    - Min / Max values

- Use `printf` formatting (required, as stated in Project Requirements)

REMEMBER!: Redirect results to separate out files, but do not push the out/ to Github 
Output:
- `out/patient_summary.tsv`

- Implement signal discovery (numeric focus):
  - Compare patterns across patients (early vs. late diagnoses trends)
  - Identify outliers (z-score OR threshold-based)
  - Compute distribution profile (`mean, std, min, max`) based on findings 

REMEMBER!: Redirect results to separate out files, but do not push the out/ to Github 
Output:
- `out/signals.tsv (ranked insights table)`

-------------------------------------------------------------------------------

# ACTION ITEMS FOR PM 

Oversee completion and implementation of:
  - run_pa4.sh <INPUT> (single entry point)
Ensure script includes:
  - `set -euo pipefail` (strict mode)
  - `mkdir -p out logs`
  - input validation (prompt or fail if path to hosp/ is missing)
  - logging 
  
Define and manage tickets + Definition of Done (DoD):
  Each task must include: 
    - Input
    - Output file
    - Expected format
  - Acceptance criteria
Enforce Git workflow:
  - Minimum 3 PRs
  - No direct commits to main
  - Require at least one review per PR

Ensure reproducibility:
  - One-command execution
  - NO manual steps

Outputs:
`.tsv` file 

# ACTION ITEMS FOR DATA STORYTELLER 
- Write up an executive summay of Sprint #4 
- Include 1–3 tables from:
  - `patient_summary.tsv`
  - `signals.tsv`
  - `buckets.tsv`

Clearly explain:
  - Patterns observed in pre-diagnosis visits
  - How ICD coding inconsistencies may contribute to misdiagnosis

Include caveats, limitations, and documentation:
  - No access to doctors’ notes
  - ICD codes written by non-specialists
  - Dataset limitations
  - Consulted with an ER doc for the compilation of pre_bc symptom list 

End with one concrete next PM question:
  *e.g., Do certain ICD coding patterns correlate with delayed diagnosis?*