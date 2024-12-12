from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date, datetime
import codelists_ehrQL as codelists

dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)

index_date = "2015-03-01"
end_date = "2023-02-28"

# Incident diagnostic code in primary care record (SNOMED) (assuming before study end date)
def first_code_in_period_snomed(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).first_for_patient()

# Incident diagnostic code in primary care record (CTV3) (assuming before study end date)
def first_code_in_period_ctv3(dx_codelist):
    return clinical_events.where(
        clinical_events.ctv3_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).first_for_patient()

# https://github.com/opensafely/comparative-booster-spring2023/blob/e714dcca0ddeed12853b272e374027efd237a17c/analysis/dataset_definition.py#L219
import operator
from functools import reduce
def any_of(conditions):
    return reduce(operator.or_, conditions)

def admission_diagnosis_matches(dx_codelist):  
    code_strings = set()
    if dx_codelist:
        for code in dx_codelist:
            code_string = ICD10Code(code.replace(".", ""))._to_primitive_type()
            code_strings.add(code_string)
            conditions = [apcs.all_diagnoses.contains(code_str) 
            for code_str in code_strings]
        return apcs.where(any_of(conditions))
    else:
        return apcs.where(apcs.primary_diagnosis.is_in([])
)

# Incident diagnostic code in secondary care record (ICD10 all diagnoses) (assuming before study end date)
def first_code_in_period_icd(dx_codelist):
    return (
        admission_diagnosis_matches(dx_codelist)
    ).where(
        apcs.admission_date.is_on_or_before(end_date)
    ).sort_by(
        apcs.admission_date
    ).first_for_patient()

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

# Define patient ethnicity
latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(codelists.ethnicity_codes))
    .where(clinical_events.date.is_on_or_before(end_date))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

latest_ethnicity = latest_ethnicity_code.to_category(codelists.ethnicity_codes)

dataset.ethnicity = case(
    when(latest_ethnicity == "1").then("White"),
    when(latest_ethnicity == "2").then("Mixed"),
    when(latest_ethnicity == "3").then("Asian or Asian British"),
    when(latest_ethnicity == "4").then("Black or Black British"),
    when(latest_ethnicity == "5").then("Chinese or Other Ethnic Groups"),
    otherwise="missing",
)

# Define patient IMD, using latest data for each patient
latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
imd_rounded = latest_address_per_patient.imd_rounded
dataset.imd_quintile = case(
    when((imd_rounded >= 0) & (imd_rounded < int(32844 * 1 / 5))).then("1"),
    when(imd_rounded < int(32844 * 2 / 5)).then("2"),
    when(imd_rounded < int(32844 * 3 / 5)).then("3"),
    when(imd_rounded < int(32844 * 4 / 5)).then("4"),
    when(imd_rounded < int(32844 * 5 / 5)).then("5"),
    otherwise="Missing",
)

# Any practice registration before study end date
# If registered with multiple practices, sort by most recent then longest duration then practice ID
dataset.any_registration = practice_registrations.where(
            practice_registrations.start_date <= end_date
        ).except_where(
            practice_registrations.end_date < index_date    
        ).exists_for_patient()

# Define population as any registered patient after index date - then apply further restrictions later
dataset.define_population(
    (dataset.any_registration == True)
    & ((dataset.sex == "male") | (dataset.sex == "female"))
)  

# List of diseases and codelists to cycle through
diseases = ["multiple_sclerosis", "heart_failure", "ulcerative_colitis"]
# diseases = ["asthma", "copd", "chd", "stroke", "heart_failure", "dementia", "multiple_sclerosis", "epilepsy", "crohns_disease", "ulcerative_colitis", "dm_type2", "dm_type1", "ckd", "psoriasis", "atopic_dermatitis", "osteoporosis", "hiv", "depression"]
codelist_types = ["snomed", "ctv", "icd"]

for disease in diseases:

    for codelist_type in codelist_types:

        if (f"{codelist_type}" == "snomed"):
            if hasattr(codelists, f"{disease}_snomed"):
                disease_codelist = getattr(codelists, f"{disease}_snomed")
                dataset.add_column(f"{disease}_snomed_inc_date", first_code_in_period_snomed(disease_codelist).date)
            else:
                dataset.add_column(f"{disease}_snomed_inc_date", first_code_in_period_snomed([]).date)
        elif (f"{codelist_type}" == "ctv"):
            if hasattr(codelists, f"{disease}_ctv"):
                disease_codelist = getattr(codelists, f"{disease}_ctv")
                dataset.add_column(f"{disease}_ctv_inc_date", first_code_in_period_ctv3(disease_codelist).date)
            else:
                dataset.add_column(f"{disease}_ctv_inc_date", first_code_in_period_ctv3([]).date)
        elif (f"{codelist_type}" == "icd"):
            if hasattr(codelists, f"{disease}_icd"):
                disease_codelist = getattr(codelists, f"{disease}_icd")    
                dataset.add_column(f"{disease}_icd_inc_date", first_code_in_period_icd(disease_codelist).admission_date)
            else:
                dataset.add_column(f"{disease}_icd_inc_date", first_code_in_period_icd([]).admission_date)                
        else:
            dataset.add_column(f"{disease}_{codelist_type}_inc_date", None)

    # Incident date for each disease
    dataset.add_column(f"{disease}_inc_date",
        minimum_of(*[date for date in [
            (getattr(dataset, f"{disease}_snomed_inc_date", None)),
            (getattr(dataset, f"{disease}_ctv_inc_date", None)),
            (getattr(dataset, f"{disease}_icd_inc_date", None))
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