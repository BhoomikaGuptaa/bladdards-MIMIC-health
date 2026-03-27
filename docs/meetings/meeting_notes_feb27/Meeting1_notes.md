# Meeting 1 Notes: Stakeholder Alignment
Date/Time: 02-27-2026
Facilitator: Kristy Chan and Ara Anandkumar 
Attendees: Ara Anandkumar, Bhoomika Gupta, Aaditya Deshmukh, Kristy Chan 

Decisions made:

- Stakeholder persona: Head of the Genitourinary Oncology Department 
- Decision question: 
Are there people readmitted with relevant concerns prior to diagnosis of bladder cancer?

Success criteria: 

-  Finding people with 2 or more hospital admissions for urological-related conditions before Bladder Cancer diagnosis. 
- Differentiating Bladder cancer diagnoses to irrelevant concerns of admissions, like adbdomen or menstrual cramps. 
- Looking for potential patterns in demographic data that can help with prevention of Bladder Cancer diagnoses. 

Scope exclusions: 

- Timeline between visits/hospital admissions because the dataset does not support such variables.  
- Integrating external datasets
- Data cleaning 

Open questions:
- Q1: How do we effectively plan out action items for Data Engineers without tasks bleeding into one another? 
- Q2: What specific pre-diagnoses symptoms are strongly associated with Bladder Cancer diagnoses in the dataset population?

Evidence plan (draft):

- Decision-driving artifacts:
- Trust check: (PM must clarify definition of Trust Check w/ CEO) 
- Assumption test: (PM must clarify definition of Assumption Test w/ CEO) 

Action items (summary):

- <PM>: <Double check the Trust Check & Assumption Test w/ CEO> (Due: March 3rd)
- <Data Engineers> Count of people with relevant admissions prior to bladder cancer diagnosis: (Break down) (Due: March 5th) 
- <Data Engineers> Find the subjects who have multiple hospitalizations <Due: March 5th> 
- <Data Engineers> Find the diagnoses of bladder cancer per subject and see where it places in time <Due March 5th> 
- <Data Storyteller> Schedule a meeting w/ CEO <Due: March 5th> 

Detailed Action Items:  

[Format: Engineer <1>.Task<1>]
[Engineer 1: Bhoomika, Engineer 2: Aaditya, Engineer 3: Sharon]

Task 1.1 BC group w/ first diagnosis
 - one row per subject ID
 - first BC diagnosis from time 


Task 1.2 remove the later ones per patient
- subject_id, hadm_id, admittime etc

Task 2.1 Create lower abdomen symptom list

Task 2.2 Extract them

Task 2.3 Join this to admissions

Task 3.1 Compute count of admissions based

Task 3.2 Artifact count, count frequency of admissions before 

Task 3.3 Top ICD codes before BC diagnosis

Task 3.4 Distibution + outlier check