from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from datetime import date, datetime
import codelists_ehrQL as codelists
from analysis.dataset_definition import dataset
import sys

# Arguments (from project.yaml)
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--start-date", type=str)
parser.add_argument("--intervals", type=int)
parser.add_argument("--disease", type=str)
args = parser.parse_args()

start_date = args.start_date
intervals = args.intervals
intervals_years = int(intervals/12)
disease = args.disease

index_date = INTERVAL.start_date
end_date = INTERVAL.end_date

print((f"{end_date}"), file=sys.stderr)

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

# 12m preceding registration exist at interval start
preceding_reg_index = preceding_registration(index_date).exists_for_patient()

# Age at interval start
age = patients.age_on(index_date)

age_band = case(  
    when((age >= 0) & (age < 9)).then("age_0_9"),
    when((age >= 10) & (age < 19)).then("age_10_19"),
    when((age >= 20) & (age < 29)).then("age_20_29"),
    when((age >= 30) & (age < 39)).then("age_30_39"),
    when((age >= 40) & (age < 49)).then("age_40_49"),
    when((age >= 50) & (age < 59)).then("age_50_59"),
    when((age >= 60) & (age < 69)).then("age_60_69"),
    when((age >= 70) & (age < 79)).then("age_70_79"),
    when((age >= 80)).then("age_greater_equal_80"),
)

measures = create_measures()
measures.configure_dummy_data(population_size=1000, legacy=True)
measures.configure_disclosure_control(enabled=False)
measures.define_defaults(intervals=months(intervals).starting_on(start_date))

## Prevalence denominator - people registered for more than one year on index date (Nb. sex already selected for in dataset definition)
prev_denominator = (
        (age_band.is_not_null())
        & ((dataset.sex == "male") | (dataset.sex == "female"))
        & (dataset.date_of_death.is_after(index_date) | dataset.date_of_death.is_null())
        & (preceding_reg_index == True)
        )

# Dictionaries to store the values
prev = {}
prev_numerators = {} 
inc_case = {}
inc_case_12m_alive = {} 
incidence_numerators = {}
incidence_denominators = {}

# Prevalent diagnosis (at interval start)
# prev[disease + "_prev"] = ( 
#     case(
#         when(
#             (getattr(dataset, disease + "_inc_date", None) < index_date)
#             & ((getattr(dataset, disease + "_resolved") != True) | ((getattr(dataset, disease + "_resolved") == True) & (getattr(dataset, disease + "_resolved_date", None) > index_date)))
#             ).then(True),
#         otherwise=False,
#     )
# )

# Prevalent diagnosis (at interval start)
prev[disease + "_prev"] = ( 
    (getattr(dataset, disease + "_inc_date") < index_date)
    & ((getattr(dataset, disease + "_resolved") != True) | ((getattr(dataset, disease + "_resolved")) & (getattr(dataset, disease + "_resolved_date") > index_date))
    ).when_null_then(False)
)

## Prevalence numerator - people registered for more than one year on index date who have an Dx code on or before index date
prev_numerators[disease + "_prev_num"] = (
        ((prev[disease + "_prev"]) == True)
        & (prev_denominator == True)
)

# # Incident case (i.e. incident date within interval window)
# inc_case[disease + "_inc_case"] = ( 
#     case(
#         when(((getattr(dataset, disease + "_inc_date", None)) >= index_date) & ((getattr(dataset, disease + "_inc_date", None)) <= end_date)).then(True),
#         otherwise=False,
#     )
# )

# Incident case (i.e. incident date within interval window)
inc_case[disease + "_inc_case"] = ( 
    (((getattr(dataset, disease + "_inc_date")) >= index_date) & ((getattr(dataset, disease + "_inc_date")) <= end_date)
    ).when_null_then(False)
)

# Preceding registration and alive at incident diagnosis date
inc_case_12m_alive[disease + "_inc_case_12m_alive"] = ( 
    (((inc_case[disease + "_inc_case"]) == True)
    & ((getattr(dataset, disease + "_preceding_reg_inc") == True))
    & ((getattr(dataset, disease + "_alive_inc") == True)) 
    ).when_null_then(False)               
)

# # Preceding registration and alive at incident diagnosis date
# inc_case_12m_alive[disease + "_inc_case_12m_alive"] = ( 
#     case(
#         when(((inc_case[disease + "_inc_case"]) == True)
#             & ((getattr(dataset, disease + "_preceding_reg_inc") == True))
#             & ((getattr(dataset, disease + "_alive_inc") == True))                
#             ).then(True),
#         otherwise=False,
#     )
# )

## Incidence numerator - people with new diagnostic codes in the 1 month after index date who have 12m+ prior registration and alive 
incidence_numerators[disease + "_inc_num"] = (
        ((inc_case_12m_alive[disease + "_inc_case_12m_alive"]) == True)
        & (age_band.is_not_null())
        & ((dataset.sex == "male") | (dataset.sex == "female"))
    )

## Incidence denominator - people with 12m+ registration prior to index date who do not have a Dx code on or before index date
incidence_denominators[disease + "_inc_denom"] = (
        ((prev[disease + "_prev"]) != True)
        & (prev_denominator == True)
    )

# Prevalence by age and sex - change start date to July
measures.define_measure(
    name=disease + "_prevalence",
    numerator=prev_numerators[disease + "_prev_num"],
    denominator=prev_denominator,
    intervals=years(intervals_years).starting_on(start_date),
    group_by={
        "sex": dataset.sex,
        "age": age_band,  
    },
    )

# Incidence by age and sex
measures.define_measure(
    name=disease + "_incidence",
    numerator=incidence_numerators[disease + "_inc_num"],
    denominator=incidence_denominators[disease + "_inc_denom"],
    group_by={
        "sex": dataset.sex,
        "age": age_band,  
    },
    )