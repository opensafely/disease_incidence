from ehrql import create_dataset, days, months, years, case, when, create_measures, INTERVAL, minimum_of, maximum_of
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, apcs, addresses, ons_deaths, appointments
from datetime import date, datetime
import codelists_ehrQL as codelists
from analysis.dataset_definition import dataset, diseases
import sys

# Arguments (from project.yaml)
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--start-date", type=str)
parser.add_argument("--intervals", type=int)
args = parser.parse_args()

start_date = args.start_date
intervals = args.intervals
intervals_years = int(intervals/12)

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
dataset.preceding_reg_index = preceding_registration(index_date).exists_for_patient()

# Currently registered at interval start
dataset.currently_registered = practice_registrations.for_patient_on(index_date).exists_for_patient()

# Age at interval start
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
)

dataset.age_band2 = case(  
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

measures = create_measures()
measures.configure_dummy_data(population_size=1000)
measures.configure_disclosure_control(enabled=False) #Consider changing this in final output
measures.define_defaults(intervals=months(intervals).starting_on(start_date))

prev_numerators = {}  # Dictionary to store the numerators
prev_denominators = {}
incidence_numerators = {}
incidence_denominators = {}

for disease in diseases:
    
    # Prevalent diagnosis (at interval start)
    dataset.add_column(f"{disease}_prev", 
        case(
            when(getattr(dataset, f"{disease}_inc_date") < index_date).then(True),
            otherwise=False,
        )
    )
    
    ## Prevalence numerator - people currently registered on index date who have an Dx code on or before index date
    prev_numerators[f"{disease}_prev_num"] = (
            (getattr(dataset, f"{disease}_prev") == True)
            & ((dataset.age >= 0) & (dataset.age < 110))
            & (dataset.age_band.is_not_null())
            & (dataset.date_of_death.is_after(index_date) | dataset.date_of_death.is_null())
            & (dataset.currently_registered == True)
            & (dataset.sex.is_in(["male","female"]))
        )

    ## Prevalence denominator - people currently registered on index date
    prev_denominators[f"{disease}_prev_denom"] = (
            ((dataset.age >= 0) & (dataset.age < 110))
            & (dataset.age_band.is_not_null())
            & (dataset.date_of_death.is_after(index_date) | dataset.date_of_death.is_null())
            & (dataset.currently_registered == True)
            & (dataset.sex.is_in(["male","female"]))
        )

    # Incident case (i.e. incident date within interval window)
    dataset.add_column(f"{disease}_inc_case", 
        case(
            when(((getattr(dataset, f"{disease}_inc_date")) >= index_date) & ((getattr(dataset, f"{disease}_inc_date")) <= end_date)).then(True),
            otherwise=False,
        )
    )

    # Preceding registration and alive at incident diagnosis date
    dataset.add_column(f"{disease}_inc_case_12m_alive", 
        case(
            when(((getattr(dataset, f"{disease}_inc_case")) == True)
                & ((getattr(dataset, f"{disease}_preceding_reg_inc") == True))
                & ((getattr(dataset, f"{disease}_alive_inc") == True))                
                ).then(True),
            otherwise=False,
        )
    )
    
    ## Incidence numerator - people with new diagnostic codes in the 1 month after index date who have 12m+ prior registration and alive 
    incidence_numerators[f"{disease}_inc_num"] = (
            (getattr(dataset, f"{disease}_inc_case_12m_alive") == True)
            & ((dataset.age >= 0) & (dataset.age < 110))
            & (dataset.age_band.is_not_null())
            & (dataset.sex.is_in(["male","female"]))
        )

    ## Incidence denominator - people with 12m+ registration prior to index date who do not have a Dx code on or before index date
    incidence_denominators[f"{disease}_inc_denom"] = (
            (getattr(dataset, f"{disease}_prev") == False)
            & (dataset.date_of_death.is_after(index_date) | dataset.date_of_death.is_null())
            & (dataset.preceding_reg_index == True)
            & ((dataset.age >= 0) & (dataset.age < 110))
            & (dataset.age_band.is_not_null())
            & (dataset.sex.is_in(["male","female"]))
        )

    # Prevalence
    measures.define_measure(
        name=disease + "_prevalence",
        numerator=prev_numerators[f"{disease}_prev_num"],
        denominator=prev_denominators[f"{disease}_prev_denom"],
        intervals=years(intervals_years).starting_on(start_date),
        group_by={
            "sex": dataset.sex,
            "age": dataset.age_band2,  
        },
        )
    
    # Incidence by age and sex
    measures.define_measure(
        name=disease + "_incidence",
        numerator=incidence_numerators[f"{disease}_inc_num"],
        denominator=incidence_denominators[f"{disease}_inc_denom"],
        group_by={
            "sex": dataset.sex,
            "age": dataset.age_band2,  
        },
        )  
        
    # # Incidence by ethnicity (Nb. not age and sex)
    # measures.define_measure(
    #     name=disease + "_incidence_ethnicity",
    #     numerator=incidence_numerators[f"{disease}_inc_num"],
    #     denominator=incidence_denominators[f"{disease}_inc_denom"],
    #     group_by={
    #         "ethnicity": dataset.ethnicity,
    #     },
    #     )

    # # Incidence by IMD quintile (Nb. not age and sex)
    # measures.define_measure(
    #     name=disease + "_incidence_imd",
    #     numerator=incidence_numerators[f"{disease}_inc_num"],
    #     denominator=incidence_denominators[f"{disease}_inc_denom"],
    #     group_by={
    #         "imd": dataset.imd_quintile,
    #     },
    #     )    