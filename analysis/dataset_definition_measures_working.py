from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date, datetime
import codelists_ehrQL as codelists
from analysis.dataset_definition import dataset

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

# List of diseases and codelists to cycle through
diseases = ["rheumatoid_arthritis", "diabetes_mellitus", "multiple_sclerosis"]
# diseases = ["multiple_sclerosis"]

measures = create_measures()
measures.configure_dummy_data(population_size=1000)
measures.configure_disclosure_control(enabled=False)
measures.define_defaults(intervals=months(intervals).starting_on(start_date))

prev_numerators = {}  # Dictionary to store the numerators
prev_denominators = {}
incidence_numerators = {}
incidence_denominators = {}

for disease in diseases:

    ## Prevalence numerator - people currently registered on index date who have an Dx code on or before index date
    prev_numerators[f"{disease}_prev_num"] = (
            (getattr(dataset, f"{disease}_prev") == True)
        )

    ## Prevalence denominator - people currently registered on index date
    prev_denominators[f"{disease}_prev_denom"] = (
            ((getattr(dataset, f"{disease}_prev") == True) | (getattr(dataset, f"{disease}_prev") == False))
        )
    
    ## Incidence numerator - people with new diagnostic codes in the 1 month after index date who have 12m+ prior registration and alive 
    incidence_numerators[f"{disease}_inc_num"] = (
            (getattr(dataset, f"{disease}_inc_case") == True)
            & ((getattr(dataset, f"{disease}_preceding_reg_inc")) == True)            
            & ((getattr(dataset, f"{disease}_alive_inc")) == True) 
        )

    ## Incidence denominator - people with 12m+ registration prior to index date who do not have a Dx code on or before index date
    incidence_denominators[f"{disease}_inc_denom"] = (
            (getattr(dataset, f"{disease}_prev") == False)
            & (dataset.preceding_reg_index == True)
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
        # group_by={
        #     "sex": dataset.sex,
        #     "age": dataset.age_band,  
        # },
        )       