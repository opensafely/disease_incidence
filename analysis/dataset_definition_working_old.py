from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date, datetime
import codelists_ehrQL as codelists
import sys
from argparse import ArgumentParser

dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)

# Arguments (from project.yaml)
parser = ArgumentParser()
parser.add_argument("--start-date", type=str)
parser.add_argument("--intervals", type=int)

args = parser.parse_args()

start_date = args.start_date
intervals = args.intervals

# index_date = INTERVAL.start_date
# end_date = INTERVAL.end_date

index_date = "2023-04-01"
end_date = "2023-04-30"

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

# Define demographics, date of death, practice registration
dataset.sex = patients.sex

dataset.age = patients.age_on(index_date)
dataset.age_band = case(  
    when((dataset.age >= 0) & (dataset.age < 4)).then("age_0_4"),
    when((dataset.age >= 5) & (dataset.age < 9)).then("age_5_9"),
    when((dataset.age >= 10) & (dataset.age < 14)).then("age_10_14"),
    when((dataset.age >= 15) & (dataset.age < 19)).then("age_15_19"),
    when((dataset.age >= 20) & (dataset.age < 24)).then("age_20_24"),
    when((dataset.age >= 25) & (dataset.age < 29)).then("age_25_29"),
    when((dataset.age >= 30) & (dataset.age < 34)).then("age_30_34"),
    when((dataset.age >= 35) & (dataset.age < 39)).then("age_35_39"),
    when((dataset.age >= 40) & (dataset.age < 44)).then("age_40_44"),
    when((dataset.age >= 45) & (dataset.age < 49)).then("age_45_49"),
    when((dataset.age >= 50) & (dataset.age < 54)).then("age_50_54"),
    when((dataset.age >= 55) & (dataset.age < 59)).then("age_55_59"),
    when((dataset.age >= 60) & (dataset.age < 64)).then("age_60_64"),
    when((dataset.age >= 65) & (dataset.age < 69)).then("age_65_69"),
    when((dataset.age >= 70) & (dataset.age < 74)).then("age_70_74"),
    when((dataset.age >= 75) & (dataset.age < 79)).then("age_75_79"),
    when((dataset.age >= 80) & (dataset.age < 84)).then("age_80_84"),
    when((dataset.age >= 85) & (dataset.age < 89)).then("age_85_89"),
    when((dataset.age >= 90)).then("age_greater_equal_90"),
    otherwise="Missing",
)

dataset.date_of_death = patients.date_of_death

dataset.currently_registered = practice_registrations.for_patient_on(index_date).exists_for_patient()
dataset.preceding_reg_index = preceding_registration(index_date).exists_for_patient()

# Define population
dataset.define_population(
    ((dataset.age >= 0) & (dataset.age < 110))
    & ((dataset.sex == "male") | (dataset.sex == "female"))
    & (dataset.date_of_death.is_after(index_date) | dataset.date_of_death.is_null())
    & (dataset.currently_registered)
)  

# List of diseases and codelists to cycle through
diseases = ["rheumatoid_arthritis", "diabetes_mellitus", "multiple_sclerosis"]
# diseases = ["multiple_sclerosis"]
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

    # print((getattr(dataset, f"{disease}_snomed_inc_date", None)), file=sys.stderr)
    # print((getattr(dataset, f"{disease}_ctv_inc_date", None)), file=sys.stderr)
    # print((getattr(dataset, f"{disease}_icd_inc_date", None)), file=sys.stderr)

    # Incident date for each disease
    dataset.add_column(f"{disease}_inc_date",
        minimum_of(*[date for date in [
            (getattr(dataset, f"{disease}_snomed_inc_date", None)),
            (getattr(dataset, f"{disease}_ctv_inc_date", None)),
            (getattr(dataset, f"{disease}_icd_inc_date", None))
            ] if date is not None]),
    )

    # Prevalent diagnosis
    dataset.add_column(f"{disease}_prev", 
        case(
            when(getattr(dataset, f"{disease}_inc_date") < index_date).then(True),
            otherwise=False,
        )
    )
    
    # Incident diagnosis (i.e. incident date within interval window)
    dataset.add_column(f"{disease}_inc_case", 
        case(
            when(((getattr(dataset, f"{disease}_inc_date")) >= index_date) & ((getattr(dataset, f"{disease}_inc_date")) <= end_date)).then(True),
            otherwise=False,
        )
    )

    # 12 months registration preceding incident diagnosis date
    dataset.add_column(f"{disease}_preceding_reg_inc", 
        preceding_registration(getattr(dataset, f"{disease}_inc_date")
        ).exists_for_patient()
    )

    # Death after incident date or not died
    dataset.add_column(f"{disease}_alive_inc",
        case(                     
            when((dataset.date_of_death.is_after(getattr(dataset, f"{disease}_inc_date"))) | (dataset.date_of_death.is_null())).then(True),
            otherwise=False,
        )
    )

    # Incident case and preceding registration and alive
    dataset.add_column(f"{disease}_inc_case_12m_alive", 
        case(
            when(((getattr(dataset, f"{disease}_inc_case")) == True)
                & ((getattr(dataset, f"{disease}_preceding_reg_inc") == True))
                & ((getattr(dataset, f"{disease}_alive_inc") == True))                
                ).then(True),
            otherwise=False,
        )
    )

