# This is to live in the projects (cs131-bladdards-MIMIC-health ) in Gcloud
# Access is restricted to members of the project.
#Import statements
import argparse
from pyspark.sql import SparkSession
import pandas as pd
import itertools
from pyspark.sql.window import Window
import pyspark.sql.functions as F
from pyspark.sql.functions import (
    col,
    count,
    count_distinct,
    broadcast,
    min as spark_min,
    max as spark_max,
    mean,
    when,
    datediff
)
import matplotlib.pyplot as plt
from google.cloud import storage
import gcsfs

def save_figure(plot,bucket,path,name, fs):
    with fs.open(f"{path}/{name}", 'wb') as f:
        plot.savefig(f, format='png')

    #
    # plot.savefig('/tmp/plot.png')
    # client = storage.Client()
    # bucket = client.get_bucket(bucket)
    # full_path = f"{path}/{name}"
    # blob = bucket.blob(full_path)
    # blob.upload_from_filename('/tmp/plot.png')

    print("Saved figure")


# defined output directory as in the project folder
def build_parser():
    parser = argparse.ArgumentParser(description="bladdards cloud Pyspark Batch job")
    parser.add_argument("--visits", default= 'gs://cs131-bladdards-bucket/data/visits', help="visit parquet location")
    parser.add_argument("--diagnoses", default='gs://cs131-bladdards-bucket/data/diagnoses', help="diagnoses parquet location")
    parser.add_argument("--icd_codes", default='gs://cs131-bladdards-bucket/data/icd_codes', help="icd_codes parquet location")
    parser.add_argument("--output", default="gs://cs131-bladdards-bucket/output", help="Base output directory")
    parser.add_argument("--bucket", default="cs131-bladdards-bucket", help="GCS bucket location")
    return parser

# allows for the parsing later. Allowing for defaults in the main project

def main():

# Start the parsing and spark
    args = build_parser().parse_args()
    spark = (
        SparkSession.builder
        .appName("bladdards-final-cloudjob")
        .getOrCreate()
    )
    fs = gcsfs.GCSFileSystem(project='cs131-bladdards-mimic-health')

    # loading the parquet files for use later

    visits = spark.read.parquet(args.visits)
    diagnoses = spark.read.parquet(args.diagnoses)
    icd_codes = spark.read.parquet(args.icd_codes)


    # First we wanted to see what the cohorts looked like, such as visit frequency prior to diagnosis
    bc_dx_dates = (
        visits
        .filter(col("visit_type") == "BC_FIRST_DX")
        .groupBy("subject_id")
        .agg(spark_min("admit_day").alias("dx_date"))
    )

    # Join symptom visits to their patient's dx date, compute days_before_dx
    visits_with_days = (
        visits
        .filter(col("visit_type") == "SYMPTOM")
        .join(broadcast(bc_dx_dates), on="subject_id", how="inner")
        .withColumn("days_before_dx", datediff(col("dx_date"), col("admit_day")))
        .filter(col("days_before_dx") >= 0)
    )

    # Bucket into time groups
    visits_bucketed = (
        visits_with_days
        .withColumn(
            "time_bucket",
            when(col("days_before_dx") <= 30,  "0-30 days")
            .when(col("days_before_dx") <= 90,  "30-90 days")
            .when(col("days_before_dx") <= 180, "90-180 days")
            .otherwise("180+ days")
        )
    )

    # Aggregate ﷿﷿﷿ chronological order
    bucket_order = (
        when(col("time_bucket") == "180+ days",   0)
        .when(col("time_bucket") == "90-180 days", 1)
        .when(col("time_bucket") == "30-90 days",  2)
        .otherwise(3)
    )

    visit_frequency_relative_dx = (
        visits_bucketed
        .groupBy("time_bucket")
        .agg(
            count("hadm_id").alias("visit_count"),
            count_distinct("subject_id").alias("distinct_patients"),
            (count("hadm_id") / count_distinct("subject_id")).alias("avg_visits_per_patient")
        )
        .orderBy(bucket_order)
    )

    print("=== visit_frequency_relative_dx ===")
    visit_frequency_relative_dx.show(truncate=False)

    # Bar chart
    # matplotlib cannot read Spark dataframes directly without converting to pandas
    pdf = visit_frequency_relative_dx.toPandas()
    pdf.to_csv(f"{args.output}/tables/visit_frequency_relative_dx.tsv", index=False, header=True, sep='\t')

    fig_visit_frequency_relative_dx, ax = plt.subplots()
    ax.bar(pdf["time_bucket"], pdf["avg_visits_per_patient"])
    ax.set_xlabel("Time Bucket (Days Before Diagnosis)")
    ax.set_ylabel("Avg Visits per Patient")
    ax.set_title("Hospital Visit Frequency Relative to BC Diagnosis")
    plt.show()
    #plt.savefig(f"{args.output}/figs/visit_frequency_relative_dx.png")
    save_figure(plt,args.bucket,args.output,"visit_frequency_relative_dx.png", fs)

    # Cohort Comparison

    # Count symptom visits per patient ﷿﷿﷿ pre_dx_visits
    pre_dx_counts = (
        visits
        .filter(col("visit_type") == "SYMPTOM")
        .groupBy("subject_id")
        .agg(count("hadm_id").alias("pre_dx_visits"))
    )

    # Get BC diagnosis date per patient
    bc_dx_dates = (
        visits
        .filter(col("visit_type") == "BC_FIRST_DX")
        .select(col("subject_id"), col("admit_day").alias("dx_date"))
    )

    # Get last symptom date per patient ﷿﷿﷿ used to compute days until dx
    last_symptom = (
        visits
        .filter(col("visit_type") == "SYMPTOM")
        .groupBy("subject_id")
        .agg(spark_max("admit_day").alias("last_symptom_date"))
    )

    # Join everything and compute days between last symptom and diagnosis
    patient_stats = (
        pre_dx_counts
        .join(bc_dx_dates, on="subject_id", how="inner")
        .join(last_symptom, on="subject_id", how="inner")
        .withColumn("days_before_dx", datediff(col("dx_date"), col("last_symptom_date")))
        .filter(col("days_before_dx") >= 0)
    )

    # Bucket patients by pre_dx_visits (matches sprint 4 shell script buckets)
    patient_bucketed = (
        patient_stats
        .withColumn(
            "bucket",
            when(col("pre_dx_visits") == 1, "LOW")
            .when(col("pre_dx_visits") == 2, "MID")
            .otherwise("HIGH")
        )
    )

    # Group by bucket, compute distinct patients and averages
    cohort_summary = (
        patient_bucketed
        .groupBy("bucket")
        .agg(
            count_distinct("subject_id").alias("distinct_patients"),
            mean("pre_dx_visits").alias("avg_pre_dx_visits"),
            mean("days_before_dx").alias("avg_days_before_dx")
        )
        .orderBy(
            when(col("bucket") == "LOW",  0)
            .when(col("bucket") == "MID",  1)
            .otherwise(2)
        )
    )

    print("=== cohort_summary ===")
    cohort_summary.show(truncate=False)

    # Bar chart ﷿﷿﷿ x: bucket, y: avg days before diagnosis
    pdf = cohort_summary.toPandas()
    pdf.to_csv(f"{args.output}/tables/cohort_summary.tsv", index=False, header=True, sep='\t')

    fig_cohort_summary, ax = plt.subplots()
    ax.bar(pdf["bucket"], pdf["avg_days_before_dx"])
    ax.set_xlabel("Bucket (Pre-Diagnosis Visit Count)")
    ax.set_ylabel("Avg Days Before Diagnosis")
    ax.set_title("Patient Cohorts by Pre-Diagnosis Visit Frequency")
    plt.show()
    #plt.savefig(f"{args.output}/figs/cohort_summary.png")
    save_figure(plt,args.bucket,args.output,"cohort_summary.png", fs)

    # || Ara's Deliverable ||

    # >> Dataframe + Stacked Bar chart to conduct further analysis on whether diagnoses differ by gender across age groups <<
    #creating a df that has only the last symptom visit date saved but counts number of visits per subject prior
    last_symptoms = (
        visits
        .filter(col("visit_type") == "SYMPTOM")
        .groupBy("subject_id")
        .agg(
            count("*").alias("num_of_symptoms"),
            spark_max("admit_day").alias("last_symptom_time"))
    )
    # df that has only the diagnosis visit and saves column as distinct name for later
    first_bc = (
        visits
        .select("subject_id",col("admit_day").alias("bc_time"))
        .filter(col("visit_type") == "BC_FIRST_DX")
    )
    # combines the two so it has for each subject, how many prior visits, last symptom visit time, first bc visit time
    time_difference = (
        last_symptoms
        .join(first_bc,
              on="subject_id", how="inner")
        .withColumn(
            "days_before_dx",
            F.datediff(col("bc_time"), col("last_symptom_time"))
        )
    )

    # Creating buckets for corresponding ages
    demographics_age_gender = (
        visits
        .filter(col("visit_type") == "BC_FIRST_DX")
        .withColumn( "age_bucket",
        F.when(F.col("age") < 30, "<30")
        .when((F.col("age") >= 30) & (F.col("age") <= 40), "30-40")
        .when((F.col("age") >= 41) & (F.col("age") <= 55), "41-55")
        .when((F.col("age") >= 56) & (F.col("age") <= 70), "56-70")
        .when((F.col("age") >= 71) & (F.col("age") <= 85), "71-85")
        .otherwise("85+")
        )
        .join(time_difference.select("subject_id","days_before_dx"),
              on="subject_id", how="left")
        .groupBy("age_bucket","gender")
        .agg(
            F.countDistinct("subject_id").alias("distinct_patients"),
            F.avg("days_before_dx").alias("avg_days_before_dx")
        )
        .withColumn(
            "age_bucket_order",
            F.when(F.col("age_bucket") == "<30", 1)
            .when(F.col("age_bucket") == "30-40", 2)
            .when(F.col("age_bucket") == "41-55", 3)
            .when(F.col("age_bucket") == "56-70", 4)
            .when(F.col("age_bucket") == "71-85", 5)
            .when(F.col("age_bucket") == "85+", 6)
            .otherwise(7)
        )
        .orderBy("age_bucket_order", "gender")
        .drop("age_bucket_order")
    )

    demographics_age_gender.show(truncate=False)
    #Only doing this because it is small!
    pandas_demographics = demographics_age_gender.toPandas()
    pandas_demographics.to_csv(f"{args.output}/tables/demographics_age_gender.tsv", index=False, header=True, sep='\t')

    # || STACKED BAR CHART: fig_demographics_age_gender ||

    # Note: Implementing the use of the pandas library to show the bar chart seamlessly
    dag_df = demographics_age_gender.toPandas() # dag -> demographics_age_gender

    age_order = ["<30", "30-40", "41-55", "56-70", "71-85", "85+"]
    dag_df["age_bucket"] = pd.Categorical(dag_df["age_bucket"], categories = age_order, ordered = True)
    dag_df = dag_df.sort_values(["age_bucket", "gender"])

    stacked_bar_chart_df = (dag_df.pivot(index = "age_bucket", columns = "gender", values = "distinct_patients")
                           .fillna(0)
                          )
    fig_demographics_age_gender = stacked_bar_chart_df.plot(
        kind="bar",
        stacked=True,
        figsize= (10, 6)
    )

    plt.xlabel("Age_Bucket")
    plt.ylabel("Distinct_Patients")
    plt.title("Diagnoses by Gender Across Different Age Groups")
    plt.legend(title="Gender")
    plt.tight_layout()
    plt.show()
    #plt.savefig(f"{args.output}/figs/demographics_age_gender.png")
    save_figure(plt,args.bucket, args.output,"fig_demographics_age_gender.png", fs)

    #SRM


    trigonitis = ["N3030", "N3031"]
    hematuria = ["5997",
                 "59970", "59971", "59972", "N02", "N020",
                 "N021", "N022", "N023", "N024", "N025", "N026",
                 "N027", "N028", "N029", "N02A", "R31", "R310",
                 "R311", "R312", "R3121", "R3129", "R319"]
    dysuria = ["30653", "7881", "R300"]
    cystitis = ["N3000", "N3001",
                "N3010", "N3011", "N3020", "N3021", "N3040", "N3041",
                "N3080", "N3081"]
    calculus = ["57400", "57401", "57410",
                "57411", "57420", "57421", "57430", "57431",
                "57440", "57441", "57450", "57451", "57460",
                "57461", "57470", "57471", "57480", "57481",
                "57490", "57491", "5920", "5921", "5929",
                "5940", "5941", "5942", "5948", "5949", "6020",
                "K800", "K8000", "K8001", "K801", "K8010", "K8011",
                "K8012", "K8013", "K8018", "K8019", "K802", "K8020",
                "K8021", "K803", "K8030", "K8031", "K8032", "K8033",
                "K8034", "K8035", "K8036", "K8037", "K804", "K8040",
                "K8041", "K8042", "K8043", "K8044", "K8045", "K8046",
                "K8047", "K805", "K8050", "K8051", "K806", "K8060",
                "K8061", "K8062", "K8063", "K8064", "K8065", "K8066",
                "K8067", "K807", "K8070", "K8071", "N20", "N200",
                "N201", "N202", "N209", "N21", "N210", "N211",
                "N218", "N219", "N22", "N420"]
    uti = ["78820", "78829", "R33", "R330", "R338", "R339", "5990", "77182", "N390", "O0338", "O0388", "O0488", "O0738",
           "O0883", "O862", "O8620", "O8629", "P393"]
    abdominal_pain = ["78900", "78901", "78902", "78903", "78904", "78905", "78906", "78907", "78909", "R1010", "R102",
                      "R1030", "R1031", "R1032", "R108", "R1084", "R109", "R141"]

    other = ["N329"]
    symptoms = itertools.chain(abdominal_pain,uti,calculus,dysuria,cystitis,trigonitis,hematuria,other)

#Getting the top relevant symptoms that were observed by searching relevant visits
    top_symptoms = (
        diagnoses
        .filter( col("visit_type")=="SYMPTOM")
        .join(
            broadcast(icd_codes.filter(col("status") == "RELEVANT")), #broadcast join on filtered dataset
            on=["icd_code","icd_version"],
            how="inner"
        )
        .where(col("ranking") <= 10)
        .withColumn("symptom_group",
                    when(F.col("icd_code").isin(abdominal_pain), "Abdominal Pain")
                    .when(F.col("icd_code").isin(uti), "Urinary Tract Infection")
                    .when(F.col("icd_code").isin(calculus), "Calculus")
                    .when(F.col("icd_code").isin(dysuria), "Dysuria")
                    .when(F.col("icd_code").isin(trigonitis), "Trigonitis")
                    .when(F.col("icd_code").isin(cystitis), "Cystitis")
                    .when(F.col("icd_code").isin(hematuria), "Hematuria")
                    .when(F.col("icd_code") == "N329", "Other Bladder Disorders")
                    .otherwise("Not in List"))
        .groupBy("symptom_group") # decided to just go for top 10, will figure out
        .agg(
            count("*").alias("total_count"),
            count_distinct("subject_id").alias("distinct_patients")
    )
        .drop("icd_code","icd_version","status")
        .sort("total_count", ascending=False)
    )

    top_symptoms.show(10, truncate=False)


    pdf = top_symptoms.toPandas()
    pdf.to_csv(f"{args.output}/tables/top_symptoms.tsv", index=False, header=True, sep='\t')
    fig_top_symptoms, ax = plt.subplots()
    ax.bar(pdf["symptom_group"], pdf["total_count"])
    ax.set_xlabel("Symptom Group")
    ax.set_ylabel("Number of Occurrences")
    ax.set_title("Relevant Symptoms Prior to Diagnosis")
    plt.grid(None)
    plt.xticks(rotation=45, ha="right")
    plt.show()
    #plt.savefig(f"{args.output}/figs/top_symptoms.png")
    save_figure(plt,args.bucket, args.output,"fig_top_symptoms.png", fs)
    # Now to try to get accumulations based on date

    #Need a window that gets the highest rank symptom and assigns it to a group
    #Another window that takes those and numbers based on row in window

    ranking_group = Window.partitionBy('hadm_id').orderBy(F.desc('ranking'))
    ranking_visits = Window.partitionBy('subject_id').orderBy('admit_day')

    symptom_pattern_sequences = (
        diagnoses
        .select("subject_id","hadm_id","icd_code","ranking")
        .filter((col("visit_type") == "SYMPTOM" ))
        .withColumn("symptom_group",
                    when(F.col("icd_code").isin(abdominal_pain), "Abdominal Pain")
                    .when(F.col("icd_code").isin(uti), "Urinary Tract Infection")
                    .when(F.col("icd_code").isin(calculus), "Calculus")
                    .when(F.col("icd_code").isin(dysuria), "Dysuria")
                    .when(F.col("icd_code").isin(trigonitis), "Trigonitis")
                    .when(F.col("icd_code").isin(cystitis), "Cystitis")
                    .when(F.col("icd_code").isin(hematuria), "Hematuria")
                    .when(F.col("icd_code")=="N329", "Other Bladder Disorders")
                    .otherwise("Not in List")) #should not hit this
        .filter(col("symptom_group") != "Not in List")
        .withColumn("row_number", F.row_number().over(ranking_group))
        .filter(col("row_number") == 1)
        .join(visits.select("hadm_id","admit_day"), on=["hadm_id"], how="inner")
        .withColumn("repeat", when(F.lag("symptom_group").over(ranking_visits) == col("symptom_group"), "True" ).otherwise("False"))
        .filter( col("repeat")!= "True")
        .withColumn("sequence_order", F.row_number().over(ranking_visits))
        .drop(*["repeat","ranking","hadm_id","icd_code","row_number"]) # The * is needed. Has to do somehow with making it positional?
        .orderBy("subject_id")
    )





    symptom_pattern_sequences.show(10,truncate=False)

    symptom_transitions = symptom_pattern_sequences.groupBy("sequence_order","symptom_group").count().toPandas()
    symptom_transitions.sort_values(by=["count","sequence_order"], ascending=[False,False], inplace=True)


    stacked_bar_chart_df = (symptom_transitions.pivot(index = "sequence_order", columns = "symptom_group", values = "count")
                           .fillna(0)
                          )
    fig = stacked_bar_chart_df.plot(
        kind="bar",
        stacked=True,
    )

    plt.xlabel("Transition Timeline")
    plt.ylabel("Number of Subjects")
    plt.title("Symptom Transitions Prior to Diagnosis")
    plt.legend(title="Symptom Groups")
    plt.grid(None)
    plt.xticks(rotation=0, ha="right")
    plt.tight_layout()
    plt.show()
    #plt.savefig(f"{args.output}/figs/symptom_transitions.png")
    save_figure(plt,args.bucket,args.output,"symptom_transitions.png", fs)

    spark.stop()

if __name__ == "__main__":
    main()






