from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from ehrql.codes import ICD10Code
from datetime import date, datetime
import codelists_ehrQL as codelists

dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)

index_date = "2020-08-01"

# Demographics
dataset.age = patients.age_on(index_date)
dataset.sex = patients.sex

# Currently registered at mid-point
any_registration = practice_registrations.for_patient_on(index_date).exists_for_patient()

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

# Define population as any registered patient after index date - then apply further restrictions later
dataset.define_population(
    any_registration
    & dataset.sex.is_in(["male", "female"]) 
)  
