# Meeting 2 Notes

```markdown
# Meeting 2 Notes: Decision Review and Finalize Brief
Date/Time: March 6th, 2-2:30pm 
Facilitator: Kristy Chan 
	Attendees: Kristy Chan, Bhoomika Gupta, Sharon Mathys, Ara Anandkumar, Aaditya Deshmukh 
--------------------------------------------------------------------------
**Progress Since Last Meeting:** 
- Bhoomika is utilizing sprint 2 scripts to parse through bcd_diagnoses,  extracting subject_ids *and* corresponding hadm_ids (hospital admission ids) to identify the earliest admission for a condition that is bladder-cancer related. 
- Aaditya is curating a keyword list that identifies conditions bladder-cancer related. 
- Data Engineers are currently validating output integrity

**Issues Encountered:** 
- Bhoomika's `awk` script doesn't seem to be working as intended because of path issues  

--------------------------------------------------------------------------

**Evidence Reviewed 
-** A1: Output sample of extracted `subject_id` and `hadm_id` pairs, along with specified admission times. 
- A2: Initial keyword list for bladder-cancer-related conditions 

- **Trust Check:** 
Data engineers confirmed no `subject_id` entries were duplicated/removed unintentionally 
	- Used a thorough visual check to identify any anomalies within the extracted dataset

- **Assumption Test 
[**Still under progress] 

**Final Risks and Limitations** 
- Keyword-based identification may disregard edge-case diagnoses related to bladder cancer 
- Admission timings are inconsistent in the entirety of the dataset, but are *consistent* by subject_id 

```