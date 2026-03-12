# Meeting 2: Decision Review and Finalize Brief
Team: Bladdard Bards (Bladdards)
Date/Time: <2026-03-06 14:00>
Duration: 45 to 60 minutes
Facilitator (PM): Kristy Chan
Notetaker: Ara Anandkumar

Goal of the meeting: check in on 
Review evidence artifacts, agree on a recommendation, and finalize the Decision Brief and Action Plan.

1) Status check (5 min)
- What artifacts are complete?
    - in progress 
    - preliminary admission counts, ICD frequency, and outlier files generated
  
- What is blocked?
    - can't run scripts yet - path issues
        - resolved 

2) Evidence walkthrough (20 to 25 min)
For each artifact:
- What does it show (one sentence)?
    1. showing patients with first bladder cancer related symptoms by subject_id
- Why does it matter to the decision?
    - finds all hospital visits where patients showed urinary/relevant symptoms before their first bladder cancer diagnosis, to answer whether patients were repeatedly seen for concerning issues before finally being diagnosed with bladder cancer.
- Any caveats?
    - the time (year) is inconsistent

Artifacts:
- A1: out/evidence/bc_first_diagnosis.txt (first bladder cancer diagnosis per patient)
- A2: out/evidence/symptom_icd_list.txt (list of symptom-related ICD codes)
- A3: out/evidence/pre_bc_symptom_admissions.txt (admissions with symptom codes before BC diagnosis)
- A4: out/evidence/pre_bc_symptom_admissions_joined.txt (joined view of pre-BC symptom admissions)
- A5: out/evidence/admissions_counts_pre_bc.txt (counts of prior admissions before first bladder cancer diagnosis)
- A6: out/evidence/admissions_outliers.txt (patients with unusually high admission counts)
- A7: out/evidence/freq_admissions_counts.txt (frequency distribution of admission counts)
- Trust check: out/evidence/trust_check.txt (check for extreme values and missing data)
- Assumption test: deliverables/assumption_filter_check.csv

3) Recommendation drafting (10 to 15 min)
Draft 1 to 3 recommendation bullets and verify they are supported by evidence.
- Refer to the pre-diagnosis symptom timeline dataset to determine the proportion of BC* patients with more than 1 symptom-coded admission before first formal BC* diagnosis. 
- Prioritize pre-BC symptoms (e.g. hematuria, UTI, dysuria, pelvic and perineal pain) that emerge repeatedly in readmission of high-risk patients inevitably diagnosed with BC; flag such symptoms for pathway review and integrate into diagnostic escalation protocols. 
- Refer to the `bc_first_dx` dataset to correctly map the progression from initial high-risk symptom onset to formal cancer detection, thereby aiding in TTD (time-to-diagnosis) analysis to accurately identify systemic delays in BC diagnostics. 


4) Action plan finalization (10 min)
Confirm owners, due dates, and definitions of done for remaining deliverables.

5) Wrap (2 min)
Confirm the plan finalize the Decision Brief and the remaining tasks.