from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date, datetime
import codelists_ehrQL as codelists

dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)

index_date = "2016-04-01"
end_date = "2024-09-30"

# Incident diagnostic code in primary care record (SNOMED) (assuming before study end date)
def first_code_in_period_snomed(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).first_for_patient()

# Incident diagnostic code in secondary care record (ICD10 all diagnoses) (assuming before study end date)
def first_code_in_period_icd(dx_codelist):
    return apcs.where(
        apcs.all_diagnoses.contains_any_of(dx_codelist)
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

# Incident diagnostic code in secondary care record (ICD10 all diagnoses) (assuming before study end date)
def last_code_in_period_icd(dx_codelist):
    return apcs.where(
        apcs.all_diagnoses.contains_any_of(dx_codelist)
    ).where(
        apcs.admission_date.is_on_or_before(end_date)
    ).sort_by(
        apcs.admission_date
    ).last_for_patient()

# Registration (If registered with multiple practices, sort by most recent then longest duration then practice ID)
def preceding_registration(dx_date):
    return practice_registrations.where(
            practice_registrations.start_date <= (dx_date - months(12))
        ).except_where(
            practice_registrations.end_date < dx_date
        ).sort_by(
            practice_registrations.start_date,
            practice_registrations.end_date,
            practice_registrations.practice_pseudo_id,
        ).last_for_patient()

# Define sex, date of death (only need to capture once) 
dataset.sex = patients.sex
dataset.date_of_death = patients.date_of_death

# # Define patient ethnicity
# latest_ethnicity_code = (
#     clinical_events.where(clinical_events.ctv3_code.is_in(codelists.ethnicity_codes))
#     .where(clinical_events.date.is_on_or_before(end_date))
#     .sort_by(clinical_events.date)
#     .last_for_patient()
#     .ctv3_code
# )

# latest_ethnicity = latest_ethnicity_code.to_category(codelists.ethnicity_codes)

# dataset.ethnicity = case(
#     when(latest_ethnicity == "1").then("White"),
#     when(latest_ethnicity == "2").then("Mixed"),
#     when(latest_ethnicity == "3").then("Asian or Asian British"),
#     when(latest_ethnicity == "4").then("Black or Black British"),
#     when(latest_ethnicity == "5").then("Other"),
#     otherwise="missing",
# )

# # Define patient IMD, using latest data for each patient
# latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
# imd_rounded = latest_address_per_patient.imd_rounded
# dataset.imd_quintile = case(
#     when((imd_rounded >= 0) & (imd_rounded < int(32844 * 1 / 5))).then("1"),
#     when(imd_rounded < int(32844 * 2 / 5)).then("2"),
#     when(imd_rounded < int(32844 * 3 / 5)).then("3"),
#     when(imd_rounded < int(32844 * 4 / 5)).then("4"),
#     when(imd_rounded < int(32844 * 5 / 5)).then("5"),
#     otherwise="Missing",
# )

# Any practice registration before study end date
any_registration = practice_registrations.where(
            practice_registrations.start_date <= end_date
        ).except_where(
            practice_registrations.end_date < index_date    
        ).exists_for_patient()

# Define population as any registered patient after index date - then apply further restrictions later
dataset.define_population(
    (any_registration == True)
    & ((dataset.sex == "male") | (dataset.sex == "female"))
)  

# List of diseases and codelists to cycle through
diseases = ["asthma", "copd", "chd", "stroke", "heart_failure"]
# diseases = ["asthma", "copd", "chd", "stroke", "heart_failure", "dementia", "multiple_sclerosis", "epilepsy", "crohns_disease", "ulcerative_colitis", "dm_type2", "dm_type1", "ckd", "psoriasis", "atopic_dermatitis", "osteoporosis", "hiv", "depression", "coeliac", "pmr"]
codelist_types = ["snomed", "icd", "resolved"]

for disease in diseases:

    snomed_inc_date = {}  # Dictionary to store dates
    snomed_last_date = {}
    icd_inc_date = {}
    icd_last_date = {}
    last_date = {}  # Dictionary to store dates

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
    dataset.add_column(f"{disease}_preceding_reg_inc", 
        preceding_registration(getattr(dataset, f"{disease}_inc_date")
        ).exists_for_patient()
    )

    # Alive at incident diagnosis date
    dataset.add_column(f"{disease}_alive_inc",
        case(                     
            when((dataset.date_of_death.is_after(getattr(dataset, f"{disease}_inc_date"))) | (dataset.date_of_death.is_null())).then(True),
            otherwise=False,
        )
    )

    # Last diagnosis date for each disease
    last_date[f"{disease}_last_date"] = (
        maximum_of(*[date for date in [
            (snomed_last_date[f"{disease}_snomed_last_date"]),
            (icd_last_date[f"{disease}_icd_last_date"])
            ] if date is not None])
    )

    # Did the patient have resolved diagnosis code after the last appearance of a diagnostic code for that disease
    dataset.add_column(f"{disease}_resolved", 
        case(
            when(
                (getattr(dataset, f"{disease}_resolved_date", None)) > (last_date[f"{disease}_last_date"])
                ).then(True),
            otherwise=False,
        )
    )