from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, addresses, ons_deaths, appointments
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
end_date=INTERVAL.end_date

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
dod = patients.date_of_death

age = patients.age_on(index_date)
age_band = case(  
    when((age >= 0) & (age < 18)).then("age_18_49"),
    when((age >= 18) & (age < 50)).then("age_18_49"),
    when((age >= 50) & (age < 65)).then("age_50_64"),
    when((age >= 65) & (age < 75)).then("age_65_74"),
    when((age >= 75) & (age < 85)).then("age_75_84"),
    when((age >= 85)).then("age_greater_equal_85"),
    otherwise="Missing",
)

diseases = ["rheumatoid_arthritis", "axial_spondyloarthritis"]

dataset = create_dataset()

measures = create_measures()
measures.configure_dummy_data(population_size=1000)
measures.define_defaults(intervals=months(intervals).starting_on(start_date))

prev_numerators = {}  # Dictionary to store the numerators
prev_denominators = {}
incidence_numerators = {}
incidence_denominators = {}

for disease in diseases:

    disease_codelist = getattr(codelists, disease)
    column_name = disease_codelist[1]

    if column_name == "code":
        dataset.add_column(f"{disease}_prev", prev_code_in_period_snomed(disease_codelist).exists_for_patient())
        dataset.add_column(f"{disease}_inc_date", first_code_in_period_snomed(disease_codelist).date)
    else:
        dataset.add_column(f"{disease}_prev", prev_code_in_period_ctv3(disease_codelist).exists_for_patient())
        dataset.add_column(f"{disease}_inc_date", first_code_in_period_ctv3(disease_codelist).date)        

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
        group_by={
            "sex": sex,
        },
        )

    # Incidence
    measures.define_measure(
        name=disease + "_incidence",
        numerator=incidence_numerators[f"{disease}_inc_num"],
        denominator=incidence_denominators[f"{disease}_inc_denom"],
        group_by={
            "sex": sex,
        },
        )