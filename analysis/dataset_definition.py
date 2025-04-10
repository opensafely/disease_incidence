from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date, datetime
import codelists_ehrQL as codelists

# # Arguments (from project.yaml)
# from argparse import ArgumentParser

# parser = ArgumentParser()
# parser.add_argument("--diseases", type=str)
# args = parser.parse_args()
# diseases = args.diseases.split(", ")

diseases = ["asthma", "copd", "chd", "stroke", "heart_failure", "dementia", "multiple_sclerosis", "epilepsy", "crohns_disease", "ulcerative_colitis", "dm_type2", "ckd", "psoriasis", "atopic_dermatitis", "osteoporosis", "rheumatoid", "depression", "coeliac", "pmr"]
#diseases = ["depression_broad"]
codelist_types = ["snomed", "icd", "resolved"]

dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)

index_date = "2016-04-01"
end_date = "2024-11-30"

# Incident diagnostic code in primary care record (SNOMED) (assuming before study end date)
def first_code_in_period_snomed(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).first_for_patient()

# Incident diagnostic code in secondary care record (ICD10 primary diagnoses) (assuming before study end date)
def first_code_in_period_icd(dx_codelist):
    return apcs.where(
        apcs.primary_diagnosis.is_in(dx_codelist)
    ).where(
        apcs.admission_date.is_on_or_before(end_date)
    ).sort_by(
        apcs.admission_date
    ).first_for_patient()

# Last diagnostic code in primary care record (SNOMED) (assuming before study end date)
def last_code_in_period_snomed(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).last_for_patient()

# Last diagnostic code in secondary care record (ICD10 primary diagnoses) (assuming before study end date)
def last_code_in_period_icd(dx_codelist):
    return apcs.where(
        apcs.primary_diagnosis.is_in(dx_codelist)
    ).where(
        apcs.admission_date.is_on_or_before(end_date)
    ).sort_by(
        apcs.admission_date
    ).last_for_patient()

# Registration for 12 months prior to incident diagnosis date
def preceding_registration(dx_date):
    return practice_registrations.where(
        practice_registrations.start_date.is_on_or_before(dx_date - months(12))
    ).except_where(
        practice_registrations.end_date.is_on_or_before(dx_date)
    )

# Define sex, date of death (only need to capture once) 
dataset.sex = patients.sex
dataset.date_of_death = patients.date_of_death

# Any practice registration before study end date
any_registration = practice_registrations.where(
            practice_registrations.start_date <= end_date
        ).except_where(
            practice_registrations.end_date < index_date    
        ).exists_for_patient()

# Registration start date (for purposes of calculating age)
dataset.registration_start = practice_registrations.where(
            practice_registrations.start_date <= end_date
        ).except_where(
            practice_registrations.end_date < index_date   
        ).sort_by(
            practice_registrations.start_date
        ).last_for_patient().start_date

# Define age at practice registration start date
dataset.age_reg = patients.age_on(dataset.registration_start)

# Define patient ethnicity
latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(codelists.ethnicity_codes))
    .where(clinical_events.date.is_on_or_before(end_date))
    .sort_by(clinical_events.date)
    .last_for_patient().snomedct_code.to_category(codelists.ethnicity_codes)
)

dataset.ethnicity = case(
    when(latest_ethnicity_code == "1").then("White"),
    when(latest_ethnicity_code == "2").then("Mixed"),
    when(latest_ethnicity_code == "3").then("Asian or Asian British"),
    when(latest_ethnicity_code == "4").then("Black or Black British"),
    when(latest_ethnicity_code == "5").then("Chinese or Other Ethnic Groups"),
    otherwise="Unknown",
)

# Define patient IMD
latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
imd_rounded = latest_address_per_patient.imd_rounded
dataset.imd_quintile = case(
    when((imd_rounded >= 0) & (imd_rounded < int(32844 * 1 / 5))).then("1 (most deprived)"),
    when(imd_rounded < int(32844 * 2 / 5)).then("2"),
    when(imd_rounded < int(32844 * 3 / 5)).then("3"),
    when(imd_rounded < int(32844 * 4 / 5)).then("4"),
    when(imd_rounded < int(32844 * 5 / 5)).then("5 (least deprived)"),
    otherwise="Unknown",
)

# Define population as any registered patient after index date - then apply further restrictions later
dataset.define_population(
    any_registration & dataset.sex.is_in(["male", "female"])
)  

for disease in diseases:

    snomed_inc_date = {}  # Dictionary to store dates
    snomed_last_date = {}
    icd_inc_date = {}
    icd_last_date = {}
    last_date = {}

    for codelist_type in codelist_types:

        if (f"{codelist_type}" == "snomed"):
            if hasattr(codelists, f"{disease}_snomed"):
                disease_codelist = getattr(codelists, f"{disease}_snomed")
                snomed_inc_date[f"{disease}_snomed_inc_date"] = (first_code_in_period_snomed(disease_codelist).date)
                snomed_last_date[f"{disease}_snomed_last_date"] = (last_code_in_period_snomed(disease_codelist).date)
            else:
                snomed_inc_date[f"{disease}_snomed_inc_date"] = (first_code_in_period_snomed([]).date)
                snomed_last_date[f"{disease}_snomed_last_date"] = (last_code_in_period_snomed([]).date)
        elif (f"{codelist_type}" == "icd"):
            if hasattr(codelists, f"{disease}_icd"):
                disease_codelist = getattr(codelists, f"{disease}_icd")    
                icd_inc_date[f"{disease}_icd_inc_date"] = (first_code_in_period_icd(disease_codelist).admission_date)
                icd_last_date[f"{disease}_icd_last_date"] = (last_code_in_period_icd(disease_codelist).admission_date)
            else:
                icd_inc_date[f"{disease}_icd_inc_date"] = (first_code_in_period_icd([]).admission_date)
                icd_last_date[f"{disease}_icd_last_date"] = (last_code_in_period_icd([]).admission_date)
        elif (f"{codelist_type}" == "resolved"):
            if hasattr(codelists, f"{disease}_resolved"):
                disease_codelist = getattr(codelists, f"{disease}_resolved")    
                dataset.add_column(f"{disease}_resolved_date", last_code_in_period_snomed(disease_codelist).date)
            else:
                dataset.add_column(f"{disease}_resolved_date", last_code_in_period_snomed([]).date)  
        else:
            dataset.add_column(f"{disease}_{codelist_type}_inc_date", None)

    # Incident date for each disease
    dataset.add_column(f"{disease}_inc_date",
        minimum_of(*[date for date in [
            (snomed_inc_date[f"{disease}_snomed_inc_date"]),
            (icd_inc_date[f"{disease}_icd_inc_date"])
            ] if date is not None]),
    )

    # 12 months registration preceding incident diagnosis date
    dataset.add_column(f"{disease}_pre_reg", 
        preceding_registration(getattr(dataset, f"{disease}_inc_date")
        ).exists_for_patient()
    )

    # Alive at incident diagnosis date
    dataset.add_column(f"{disease}_alive_inc",
        (
            (dataset.date_of_death.is_after(getattr(dataset, f"{disease}_inc_date"))) |
            dataset.date_of_death.is_null()
        ).when_null_then(False)
    )
    
    # Last diagnosis date for each disease
    last_date[f"{disease}_last_date"] = maximum_of(
        snomed_last_date[f"{disease}_snomed_last_date"],
        icd_last_date[f"{disease}_icd_last_date"]
    )

    # Did the patient have resolved diagnosis code after the last appearance of a diagnostic code for that disease
    dataset.add_column(f"{disease}_resolved", 
        (getattr(dataset, f"{disease}_resolved_date") > (last_date[f"{disease}_last_date"])
        ).when_null_then(False)
    )