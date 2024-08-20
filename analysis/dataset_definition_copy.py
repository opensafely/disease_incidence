from ehrql import create_dataset, days, months, years, case, when, Measures, INTERVAL
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, addresses, ons_deaths, appointments
from datetime import date
import codelists_ehrQL as codelists
from dataset_definition import make_dataset_incidence

# Arguments (from project.yaml)
# from argparse import ArgumentParser

# parser = ArgumentParser()
# parser.add_argument("--start-date", type=str)
# parser.add_argument("--intervals", type=int)

# args = parser.parse_args()

# start_date = args.start_date
# intervals = args.intervals

index_date = "2019-04-01"
end_date="2020-04-01"

dataset = create_dataset()
dataset.configure_dummy_data(population_size=10000)

dataset.age = patients.age_on(index_date)

# Prevalent diagnostic code in primary care record
def prev_code_in_period(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
    ).where(
        clinical_events.date.is_on_or_before(index_date)
    )

# Incident diagnostic code in primary care record (assuming before study end date)
def first_code_in_period(dx_codelist):
    return clinical_events.where(
        clinical_events.snomedct_code.is_in(dx_codelist)
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

# disease_codelists = {
#     "rheumatoid_arthritis": rheumatoid_arthritis,
#     "axial_spondyloarthritis": axial_spondyloarthritis,
# }

diseases = ["rheumatoid_arthritis", "axial_spondyloarthritis"]

numerators = {}  # Dictionary to store the numerators

for disease in diseases:

    disease_codelist = getattr(codelists, disease)

    # dataset.add_column = make_dataset_incidence(disease_codelist, index_date, end_date)
    # dataset.configure_dummy_data(population_size=10000)

    dataset.add_column(f"{disease}", prev_code_in_period(disease_codelist).exists_for_patient())
    dataset.add_column(f"{disease}_inc_date", first_code_in_period(disease_codelist).date)

    #for measures_name, code_counts in pharmacy_first_code_counts.items():

    # Prevalence numerator - people currently registered on index date who have an Dx code on or before index date 
    numerators[f"{disease}_numerator"] = (
            (patients.age_on(index_date) >= 0) 
            & (patients.age_on(index_date) < 110)
            & (getattr(dataset, f"{disease}") == True)
        )

# Define population
dataset.define_population(
    ((dataset.age >= 18) & (dataset.age <= 110))
)