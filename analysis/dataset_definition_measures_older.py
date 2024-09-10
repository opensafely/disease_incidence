from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date
import codelists_ehrQL as codelists
# from dataset_definition import make_dataset_incidence

# Arguments (from project.yaml)
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--start-date", type=str)
parser.add_argument("--intervals", type=int)

args = parser.parse_args()

start_date = args.start_date
intervals = args.intervals

index_date = INTERVAL.start_date
end_date = INTERVAL.end_date

# Prevalent diagnostic code in primary care record (SNOMED)
def prev_code_in_period_snomed(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(index_date)
    )

# Incident diagnostic code in primary care record (SNOMED) (assuming before study end date)
def first_code_in_period_snomed(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).first_for_patient()

# Prevalent diagnostic code in primary care record (CTV3)
def prev_code_in_period_ctv3(dx_codelist):
    return clinical_events.where(
        clinical_events.ctv3_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(index_date)
    )

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
    for code in dx_codelist:
        code_string = ICD10Code(code.replace(".", ""))._to_primitive_type()
        code_strings.add(code_string)
        conditions = [apcs.all_diagnoses.contains(code_str) 
        for code_str in code_strings]
    return apcs.where(any_of(conditions)
)

# Prevalent diagnostic code in primary care record (ICD10 all diagnoses)
def prev_code_in_period_icd(dx_codelist):
    return (
        admission_diagnosis_matches(dx_codelist)
    ).where(
        apcs.admission_date.is_on_or_before(index_date)
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

# Define patient sex and date of death
sex = patients.sex

age = patients.age_on(index_date)
age_band = case(  
    when((age >= 0) & (age < 4)).then("age_0_4"),
    when((age >= 5) & (age < 9)).then("age_5_9"),
    when((age >= 10) & (age < 14)).then("age_10_14"),
    when((age >= 15) & (age < 19)).then("age_15_19"),
    when((age >= 20) & (age < 24)).then("age_20_24"),
    when((age >= 25) & (age < 29)).then("age_25_29"),
    when((age >= 30) & (age < 34)).then("age_30_34"),
    when((age >= 35) & (age < 39)).then("age_35_39"),
    when((age >= 40) & (age < 44)).then("age_40_44"),
    when((age >= 45) & (age < 49)).then("age_45_49"),
    when((age >= 50) & (age < 54)).then("age_50_54"),
    when((age >= 55) & (age < 59)).then("age_55_59"),
    when((age >= 60) & (age < 64)).then("age_60_64"),
    when((age >= 65) & (age < 69)).then("age_65_69"),
    when((age >= 70) & (age < 74)).then("age_70_74"),
    when((age >= 75) & (age < 79)).then("age_75_79"),
    when((age >= 80) & (age < 84)).then("age_80_84"),
    when((age >= 85) & (age < 89)).then("age_85_89"),
    when((age >= 90)).then("age_greater_equal_90"),
    otherwise="Missing",
)

# diseases = ["rheumatoid_arthritis_snomed", "diabetes_mellitus_ctv", "multiple_sclerosis_ctv", "multiple_sclerosis_icd"]
diseases = ["multiple_sclerosis"]
codelist_types = ["snomed", "ctv", "icd"]

dataset = create_dataset()

measures = create_measures()
measures.configure_dummy_data(population_size=1000)
measures.configure_disclosure_control(enabled=False)
measures.define_defaults(intervals=months(intervals).starting_on(start_date))

prev_numerators = {}  # Dictionary to store the numerators
prev_denominators = {}
incidence_numerators = {}
incidence_denominators = {}

for disease in diseases:

    for codelist_type in codelist_types:

        if (f"{codelist_type}" == "snomed"):
            if hasattr(codelists, f"{disease}_snomed"):
                disease_codelist = getattr(codelists, f"{disease}_snomed")
                dataset.add_column(f"{disease}_snomed_prev", prev_code_in_period_snomed(disease_codelist).exists_for_patient())
                dataset.add_column(f"{disease}_snomed_inc_date", first_code_in_period_snomed(disease_codelist).date)
            else:
                dataset.add_column(f"{disease}_snomed_prev", prev_code_in_period_snomed([]).exists_for_patient())
                dataset.add_column(f"{disease}_snomed_inc_date", first_code_in_period_snomed([]).date)
        elif (f"{codelist_type}" == "ctv"):
            if hasattr(codelists, f"{disease}_ctv"):
                disease_codelist = getattr(codelists, f"{disease}_ctv")
                dataset.add_column(f"{disease}_ctv_prev", prev_code_in_period_ctv3(disease_codelist).exists_for_patient())
                dataset.add_column(f"{disease}_ctv_inc_date", first_code_in_period_ctv3(disease_codelist).date)
            else:
                dataset.add_column(f"{disease}_ctv_prev", prev_code_in_period_snomed([]).exists_for_patient())
                dataset.add_column(f"{disease}_ctv_inc_date", first_code_in_period_snomed([]).date)
        elif (f"{codelist_type}" == "icd"):
            if hasattr(codelists, f"{disease}_icd"):
                disease_codelist = getattr(codelists, f"{disease}_icd")    
                dataset.add_column(f"{disease}_icd_prev", prev_code_in_period_icd(disease_codelist).exists_for_patient())
                dataset.add_column(f"{disease}_icd_inc_date", first_code_in_period_icd(disease_codelist).admission_date)
            else:
                dataset.add_column(f"{disease}_icd_prev", prev_code_in_period_snomed([]).exists_for_patient())
                dataset.add_column(f"{disease}_icd_inc_date", first_code_in_period_snomed([]).date)                
        else:
            dataset.add_column(f"{disease}_{codelist_type}_prev", False)
            dataset.add_column(f"{disease}_{codelist_type}_inc_date", None)

    inc_dates = [date for date in [(getattr(dataset, f"{disease}_snomed_inc_date", None)), (getattr(dataset, f"{disease}_ctv_inc_date", None)), (getattr(dataset, f"{disease}_icd_inc_date", None))] if date is not None]

    dataset.add_column(f"{disease}_inc_date",
        minimum_of(*inc_dates),
    )

    dataset.add_column(f"{disease}_prev", 
        (getattr(dataset, f"{disease}_snomed_prev") | getattr(dataset, f"{disease}_ctv_prev") | getattr(dataset, f"{disease}_icd_prev")),
    )

    ## Prevalence numerator - people currently registered on index date who have an Dx code on or before index date
    prev_numerators[f"{disease}_prev_num"] = (
            (patients.age_on(index_date) >= 0)
            & (patients.age_on(index_date) < 110)
            & ((patients.sex == "male") | (patients.sex == "female"))
            & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
            & (practice_registrations.for_patient_on(index_date).exists_for_patient())
            & (getattr(dataset, f"{disease}_prev") == True)
        )

    ## Prevalence denominator - people currently registered on index date
    prev_denominators[f"{disease}_prev_denom"] = (
            (patients.age_on(index_date) >= 0)
            & (patients.age_on(index_date) < 110)
            & ((patients.sex == "male") | (patients.sex == "female"))
            & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
            & (practice_registrations.for_patient_on(index_date).exists_for_patient())
        )

    ## Incidence numerator - people with new diagnostic codes in the 1 month after index date who have 12m+ prior registration
    incidence_numerators[f"{disease}_inc_num"] = (
            (patients.age_on(index_date) >= 0)
            & (patients.age_on(index_date) < 110)
            & ((patients.sex == "male") | (patients.sex == "female"))
            & (patients.date_of_death.is_after(getattr(dataset, f"{disease}_inc_date")) | patients.date_of_death.is_null())
            & (preceding_registration(getattr(dataset, f"{disease}_inc_date")).exists_for_patient())
            & (((getattr(dataset, f"{disease}_inc_date")) >= index_date) & ((getattr(dataset, f"{disease}_inc_date")) < (index_date + months(1))))
        )

    ## Incidence denominator - people with 12m+ registration prior to index date who do not have a Dx code on or before index date
    incidence_denominators[f"{disease}_inc_denom"] = (
            (patients.age_on(index_date) >= 0)
            & (patients.age_on(index_date) < 110)
            & ((patients.sex == "male") | (patients.sex == "female"))
            & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
            & (preceding_registration(index_date).exists_for_patient())
            & (getattr(dataset, f"{disease}_prev") == False)
        )

    # Prevalence
    measures.define_measure(
        name=disease + "_prevalence",
        numerator=prev_numerators[f"{disease}_prev_num"],
        denominator=prev_denominators[f"{disease}_prev_denom"],
        )

    # Incidence
    measures.define_measure(
        name=disease + "_incidence",
        numerator=incidence_numerators[f"{disease}_inc_num"],
        denominator=incidence_denominators[f"{disease}_inc_denom"],
        group_by={
            "sex": sex,
            "age": age_band,  
        },
        )