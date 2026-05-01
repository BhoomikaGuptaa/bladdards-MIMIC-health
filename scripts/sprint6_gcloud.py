# This is to live in the projects (cs131-bladdards-MIMIC-health ) in Gcloud
# Access is restricted to members of the project.
#Import statements
import argparse
from pyspark.sql import SparkSession
import pyspark.sql
from google.colab import auth
from google.cloud import bigquery

# defined output directory as in the project folder
def build_parser():
    parser = argparse.ArgumentParser(description="bladdards-final-cloudjob")
    parser.add_argument("--output", default="", help="Base output directory")
    return parser

# allows for the parsing later

def main():



# Creating the initial dictionaries/maps used for pyspark
    bc_icd = {"C67":"Bladder Cancer","C791":"Bladder Cancer","C7911":"Bladder Cancer","Z126":"Bladder Cancer",
           "1880":"Bladder Cancer","1881":"Bladder Cancer","1882":"Bladder Cancer","1883":"Bladder Cancer","1884":"Bladder Cancer",
           "1885":"Bladder Cancer","1888":"Bladder Cancer","1889":"Bladder Cancer","2233":"Bladder Cancer","2367":"Bladder Cancer",
           "2394":"Bladder Cancer","C670":"Bladder Cancer","C671":"Bladder Cancer","C672":"Bladder Cancer","C673":"Bladder Cancer",
           "C674":"Bladder Cancer","C675":"Bladder Cancer","C678":"Bladder Cancer","C679":"Bladder Cancer","D303":"Bladder Cancer",
           "D414":"Bladder Cancer","D494":"Bladder Cancer"}



    relevant_icd ={"78900":"Abdominal pain","78901":"Abdominal pain","78902":"Abdominal pain","78903":"Abdominal pain",
               "78904":"Abdominal pain","78905":"Abdominal pain","78906":"Abdominal pain","78907":"Abdominal pain",
               "78909":"Abdominal pain","R1010":"Abdominal pain","R102":"Abdominal pain","R1030":"Abdominal pain",
               "R1031":"Abdominal pain","R1032":"Abdominal pain","R108":"Abdominal pain","R1084":"Abdominal pain",
               "R109":"Abdominal pain","R141":"Abdominal pain","57400":"Calculus","57401":"Calculus","57410":"Calculus",
               "57411":"Calculus","57420":"Calculus","57421":"Calculus","57430":"Calculus","57431":"Calculus",
               "57440":"Calculus","57441":"Calculus","57450":"Calculus","57451":"Calculus","57460":"Calculus",
               "57461":"Calculus","57470":"Calculus","57471":"Calculus","57480":"Calculus","57481":"Calculus",
               "57490":"Calculus","57491":"Calculus","5920":"Calculus","5921":"Calculus","5929":"Calculus",
               "5940":"Calculus","5941":"Calculus","5942":"Calculus","5948":"Calculus","5949":"Calculus","6020":"Calculus",
               "K800":"Calculus","K8000":"Calculus","K8001":"Calculus","K801":"Calculus","K8010":"Calculus","K8011":"Calculus",
               "K8012":"Calculus","K8013":"Calculus","K8018":"Calculus","K8019":"Calculus","K802":"Calculus","K8020":"Calculus",
               "K8021":"Calculus","K803":"Calculus","K8030":"Calculus","K8031":"Calculus","K8032":"Calculus","K8033":"Calculus",
               "K8034":"Calculus","K8035":"Calculus","K8036":"Calculus","K8037":"Calculus","K804":"Calculus","K8040":"Calculus",
               "K8041":"Calculus","K8042":"Calculus","K8043":"Calculus","K8044":"Calculus","K8045":"Calculus","K8046":"Calculus",
               "K8047":"Calculus","K805":"Calculus","K8050":"Calculus","K8051":"Calculus","K806":"Calculus","K8060":"Calculus",
               "K8061":"Calculus","K8062":"Calculus","K8063":"Calculus","K8064":"Calculus","K8065":"Calculus","K8066":"Calculus",
               "K8067":"Calculus","K807":"Calculus","K8070":"Calculus","K8071":"Calculus","N20":"Calculus","N200":"Calculus",
               "N201":"Calculus","N202":"Calculus","N209":"Calculus","N21":"Calculus","N210":"Calculus","N211":"Calculus",
               "N218":"Calculus","N219":"Calculus","N22":"Calculus","N420":"Calculus","N3000":"Cystitis","N3001":"Cystitis",
               "N3010":"Cystitis","N3011":"Cystitis","N3020":"Cystitis","N3021":"Cystitis","N3040":"Cystitis","N3041":"Cystitis",
               "N3080":"Cystitis","N3081":"Cystitis","30653":"Dysuria","7881":"Dysuria","R300":"Dysuria","5997":"Hematuria",
               "59970":"Hematuria","59971":"Hematuria","59972":"Hematuria","N02":"Hematuria","N020":"Hematuria",
               "N021":"Hematuria","N022":"Hematuria","N023":"Hematuria","N024":"Hematuria","N025":"Hematuria","N026":"Hematuria",
               "N027":"Hematuria","N028":"Hematuria","N029":"Hematuria","N02A":"Hematuria","R31":"Hematuria","R310":"Hematuria",
               "R311":"Hematuria","R312":"Hematuria","R3121":"Hematuria","R3129":"Hematuria","R319":"Hematuria",
               "N329":"Other Bladder Disorders","N3030":"Trigonitis","N3031":"Trigonitis","78820":"Urinary Retention",
               "78829":"Urinary Retention","R33":"Urinary Retention","R330":"Urinary Retention","R338":"Urinary Retention",
               "R339":"Urinary Retention","5990":"Urinary Tract Infection","77182":"Urinary Tract Infection","N390":"Urinary Tract Infection",
               "O0338":"Urinary Tract Infection","O0388":"Urinary Tract Infection","O0488":"Urinary Tract Infection",
               "O0738":"Urinary Tract Infection","O0883":"Urinary Tract Infection","O862":"Urinary Tract Infection",
               "O8620":"Urinary Tract Infection","O8629":"Urinary Tract Infection","P393":"Urinary Tract Infection"}

    bc_icd_list = list(bc_icd.keys())
    relevant_icd_list = list(relevant_icd.keys())

    sql_icd =("SELECT * "
              "FROM 'physionet"
              "WHERE icd_code IN UNNEST(@bc) OR icd_code IN UNNEST(@symptoms)")
    icd_job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ArrayQueryParameter("bc","STRING", bc_icd_list),
            bigquery.ArrayQueryParameter("symptoms","STRING", relevant_icd_list)]
    )

# Will add things later. Using this to filter from dataframe. First need to get this into a dataframe
    icd_bq_pd= client.query(sql_icd, job_config = icd_job_config).to_dataframe()
# for icd big query dataframe. Will make a pandas dataframe to pull as parquet file from this after adding type
# will add symptom groups and maneuver appropriately
    icd_bq_df = spark.createDataFrame(icd_bq_pd)














