from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date, datetime
import codelists_ehrQL as codelists

# Arguments (from project.yaml)
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--start-date", type=str)
args = parser.parse_args()

start_date = args.start_date

# Define start date as midpoint for that year of study
index_date = start_date + months(6)

dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)

# Define sex
dataset.sex = patients.sex

# Date of death
dataset.date_of_death = patients.date_of_death

# Currently registered
curr_registered = practice_registrations.for_patient_on(index_date).exists_for_patient()

# Age at index date
dataset.age = patients.age_on(index_date)

dataset.age_band = case(  
    when((dataset.age >= 0) & (dataset.age < 9)).then("age_0_9"),
    when((dataset.age >= 10) & (dataset.age < 19)).then("age_10_19"),
    when((dataset.age >= 20) & (dataset.age < 29)).then("age_20_29"),
    when((dataset.age >= 30) & (dataset.age < 39)).then("age_30_39"),
    when((dataset.age >= 40) & (dataset.age < 49)).then("age_40_49"),
    when((dataset.age >= 50) & (dataset.age < 59)).then("age_50_59"),
    when((dataset.age >= 60) & (dataset.age < 69)).then("age_60_69"),
    when((dataset.age >= 70) & (dataset.age < 79)).then("age_70_79"),
    when((dataset.age >= 80)).then("age_greater_equal_80"),
)

# Define patient ethnicity
latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(codelists.ethnicity_codes))
    .where(clinical_events.date.is_on_or_before(index_date))
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
imd = addresses.for_patient_on(index_date).imd_rounded

dataset.imd_quintile = case(
    when((imd >= 0) & (imd < int(32844 * 1 / 5))).then("1 (most deprived)"),
    when(imd < int(32844 * 2 / 5)).then("2"),
    when(imd < int(32844 * 3 / 5)).then("3"),
    when(imd < int(32844 * 4 / 5)).then("4"),
    when(imd < int(32844 * 5 / 5)).then("5 (least deprived)"),
    otherwise="Unknown",
)

# Define population
dataset.define_population(
    dataset.age_band.is_not_null()
    & dataset.sex.is_in(["male", "female"])
    & (dataset.date_of_death.is_after(index_date) | dataset.date_of_death.is_null())
    & curr_registered
)