# Sprint 5: Meeting 1 Agenda
Date: April 15, 2026

## Members and roles:
PM : Sharon Mathys
Engineers: Kristy Chan, Bhoomika Gupta, Ara Anandkumar
Storyteller: Aaditya Deshmukh


## Overview: High View goal for the Sprint

Goal for the Sprint is to set up for the Final Project result. 

Issue: We do not have enough subjects to create training for models.
Solution: We create a compelling exploratory analysis wrap up to inform further research

Issue: We have not fully Explored all Data available to us
Solution: This sprint focuses on obtaining all relevant data, using PySpark and previous scripts with initial processing

Issue: We have lots of data everywhere and not streamlined
Solution: Using the original files and select data, create streamlined dataframes that can be manipulated to answer all questions of interest


## Data Available:

Information on the Data is available at : https://mimic.mit.edu/docs/iv/modules/hosp/
We do have more data available than used. Make sure everyone has the following files from the MIMIC-IV hosp data

### Previously used (all .csv.gz)
- admissions
- d_icd_diagnoses
- diagnoses_icd
- patients

### New for Further Investigation
*will be further added*
d_labitems
d_icd_procedures
procedures_icd



### Additional Module to see if there are missed participants 

Also obtain the following Database to make sure we did not miss any Participants
ED - can be obtained using current access for MIMIC-IV from the same source


## General Assumptions on Code pushed for review/accepted:

1. Anything presented for review has passed the following tests:
	- Successful execution on the code level (no errors, produces an output)
	- Output matches expected parameters (if visually inspected, no clear issues. File not abnormally short, etc)
	- Has documentation/comments which explain what is being done (brief ok)
	- Engineers can explain reasoning behind all of their code if asked
	

2. Reviewer before approving code has:
	- Run the code of interest locally
	- Checked code logic
	- Double checked output

## Tasks for Discussion

1. How to work on the document: Locally with git pushes and merges or through google colab?
 Note: Will check with professor tomorrow on how to accomplish Colab vs .ipynb on git

2. New Exploring Data
	- Do we have access to lab information for tumors for staging (primary and secondary neoplasms)
	- Can certain lab results
	- Have we missed participants in the ER only dataset that we can add?


2. Creation of pySpark Dataframe that contains overview of all visits of interest
	Contains information from admissions, patients
	- Raw columns
		subject_id
		hadm_id
		race
		gender
		
	- Calculated/Derived columns
		Pre/Post Diagnosis (Symptoms/ PreBC diagnosis) (come from other sources)
		Age (approximated) (using patient table/ anchor age/anchor year etc)
		Admit_time (with year conversion) (patient table, and admit from admissions)
		discharge_time (with year conversion) (patient table and discharge from admissions)
	
Example for Ages
subject: anchor age 35, anchor year 2116, age range (2008-2010), approx date: 2008
hadm: 1/4/2110, -> 2110 - 2116 = -6, 35 + -6 = 29 age
				-> 2110 - 2116 = 2008 + -6 = 2002
		 	
		
	
Questions that can be

3. Creation of pySpark Dataframe that contains all diagnoses from all visits of interest

4. Potential Spark stuff that aggregates/outputs


5. logic internal to the frames to output queries such as frequencies/ top 10/ times, etc.

6. Storyteller requires graphs/top10 etc, and will make sure to add in the document the dataframe logic and explain why


