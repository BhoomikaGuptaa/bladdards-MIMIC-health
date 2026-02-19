# MIMIC-IV Dataset Information

Location and Information at: https://physionet.org/content/mimiciv/3.1/

Medical Information Mart for Intensive Care (MIMIC) -IV is a deidentified dataset of patients admitted to the Emergency Department (ED)or Intensive Care Unit (ICU) at Beth Israel Deaconess Medical Center in Boston MA between 2008 - 2022. It contains data for over 65,000 patients admitted to the ICU and over 200,000 patients admitted to the ED.

This dataset requires training and credentialing for access.

## Download Instructions

1. Must make an account with physionet.org
2. Complete CITI Training for Conflicts of Interest and Human Research: Data or Specimens Only Research through Massachusetts Institute of Technology Affiliates
   https://physionet.org/about/citi-course/
3. Apply for Credentialing and Upload CITI training reports
4. Once approved, access to database is granted under Files. Only Credentialed users are allowed to access.

## Dataset Information

Dataset is installed initially as a .zip file. Once taken out, there are two modules provided: hosp and icu (and optionally ed).

Each module contains csv tables (comma delimited) with headers that are compressed with gz compression. Size of the complete unzipped database with compressed files is ~ 10 GB. 

hosp module contains the data for all the patients seen in the hospital during the time period for this dataset. Patient information and Subject_id is used to link throughout and also with the icu and ed modules. Module size (with compressed tables) is ~ 6.3 GB

icu module contains the data for icu visits for patients through this timeperiod at this hospital. Links to the hosp module (Currently not used). Module size (with compressed tables) is ~ 4.36 GB. 

ed module (if used) contains the data for all the patients seen in the er. Links to the hosp module. Module size (with compressed tables) is 122 MB


Note on encoding: All date and date/time stamps are encoded to help de-identify the dataset. Each year is related to the subject according to the 

### Tables used in hosp

admissions
- Size 19M with 70699 lines

d_icd_diagnoses
- Size 856K with 3319 lines

diagnoses_icd
- Size 32M with 118929





## More Information

Comprehensive information on the modules and tables used in the database are available at: https://mimic.mit.edu/docs/iv/

## Citations for use

Johnson, A., Bulgarelli, L., Pollard, T., Gow, B., Moody, B., Horng, S., Celi, L. A., & Mark, R. (2024). MIMIC-IV (version 3.1). _PhysioNet_. RRID:SCR_007345. [https://doi.org/10.13026/kpb9-mt58](https://doi.org/10.13026/kpb9-mt58)

[Johnson, A.E.W., Bulgarelli, L., Shen, L. et al. MIMIC-IV, a freely accessible electronic health record dataset. Sci Data 10, 1 (2023). https://doi.org/10.1038/s41597-022-01899-x](https://doi.org/10.1038/s41597-022-01899-x)

Goldberger, A., Amaral, L., Glass, L., Hausdorff, J., Ivanov, P. C., Mark, R., ... & Stanley, H. E. (2000). PhysioBank, PhysioToolkit, and PhysioNet: Components of a new research resource for complex physiologic signals. Circulation [Online]. 101 (23), pp. e215–e220. RRID:SCR_007345.
