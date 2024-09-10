from ehrql import create_dataset, days, months, years, case, when
from ehrql.tables.tpp import patients, medications, practice_registrations, clinical_events, addresses, ons_deaths, appointments
from datetime import date
import codelists_ehrQL as codelists

def make_dataset_incidence(disease_codelist, index_date, end_date):

    dataset = create_dataset()
    dataset.configure_dummy_data(population_size=10000)

    # Prevalent diagnostic code in primary care record
    def prev_code_in_period(dx_codelist):
        return clinical_events.where(
            clinical_events.snomedct_code.is_in(dx_codelist)
        ).where(
            clinical_events.date.is_on_or_before(index_date)
        )

    dataset.prev_case = prev_code_in_period(disease_codelist).exists_for_patient()

    # Incident diagnostic code in primary care record (assuming before study end date)
    def first_code_in_period(dx_codelist):
        return clinical_events.where(
            clinical_events.snomedct_code.is_in(dx_codelist)
        ).where(
            clinical_events.date.is_on_or_before(end_date)
        ).sort_by(
            clinical_events.date
        ).first_for_patient()

    dataset.incident_case_date = first_code_in_period(disease_codelist).date

    return dataset

    # ## Practice region
    # dataset.region = ordered_regs.practice_nuts1_region_name
    # dataset.stp = ordered_regs.practice_stp

    # # Death
    # dataset.died_date=patients.date_of_death
    # dataset.died_date_ons = ons_deaths.date

    # # Demographics    
    # dataset.age = patients.age_on(dataset.ra_date)

    # dataset.sex = patients.sex

    # dataset.ethnicity = clinical_events.where(
    #     clinical_events.ctv3_code.is_in(codelists.ethnicity_codes)
    #     ).where(
    #         clinical_events.date.is_on_or_before(end_date)
    #     ).sort_by(
    #         clinical_events.date
    #     ).last_for_patient(
    #     ).ctv3_code.to_category(codelists.ethnicity_codes)

    # imd_rank = addresses.for_patient_on(dataset.ra_date).imd_rounded
    # dataset.imd = case(
    #     when((imd_rank >=0) & (imd_rank < int(32844 * 1 / 5))).then("1"),
    #     when(imd_rank < int(32844 * 2 / 5)).then("2"),
    #     when(imd_rank < int(32844 * 3 / 5)).then("3"),
    #     when(imd_rank < int(32844 * 4 / 5)).then("4"),
    #     when(imd_rank < int(32844 * 5 / 5)).then("5"),
    #     otherwise=".u"
    # )

    # # Relevant blood tests (last match before EIA code)
    # def last_test_in_period(dx_codelist):
    #     return clinical_events.where(
    #         clinical_events.ctv3_code.is_in(dx_codelist)
    #     ).where(
    #         clinical_events.date <= dataset.ra_date
    #     ).sort_by(
    #         clinical_events.date
    #     ).last_for_patient()

    # dataset.hba1c_mmol_per_mol=last_test_in_period(codelists.hba1c_new_codes).numeric_value
    # dataset.hba1c_mmol_per_mol_date=last_test_in_period(codelists.hba1c_new_codes).date

    # dataset.hba1c_percentage=last_test_in_period(codelists.hba1c_old_codes).numeric_value
    # dataset.hba1c_percentage_date=last_test_in_period(codelists.hba1c_old_codes).date

    # dataset.creatinine=last_test_in_period(codelists.creatinine_codes).numeric_value
    # dataset.creatinine_date=last_test_in_period(codelists.creatinine_codes).date

    # # BMI
    # bmi_record = clinical_events.where(
    #         clinical_events.snomedct_code.is_in(codelists.bmi_codes)
    #     ).where(
    #         clinical_events.date >= (patients.date_of_birth + years(16))
    #     ).where(
    #         (clinical_events.date >= (dataset.ra_date - years(10))) & (clinical_events.date <= dataset.ra_date)
    #     ).sort_by(
    #         clinical_events.date
    #     ).last_for_patient()

    # dataset.bmi = bmi_record.numeric_value
    # dataset.bmi_date = bmi_record.date

    # ## Smoking status
    # dataset.most_recent_smoking_code=clinical_events.where(
    #         clinical_events.ctv3_code.is_in(codelists.clear_smoking_codes)
    #     ).where(
    #         clinical_events.date <= dataset.ra_date
    #     ).sort_by(
    #         clinical_events.date
    #     ).last_for_patient().ctv3_code.to_category(codelists.clear_smoking_codes)

    # def filter_codes_by_category(codelist, include):
    #     return {k:v for k,v in codelist.items() if v in include}

    # dataset.ever_smoked=clinical_events.where(
    #         clinical_events.ctv3_code.is_in(filter_codes_by_category(codelists.clear_smoking_codes, include=["S", "E"]))
    #     ).where(
    #         clinical_events.date <= dataset.ra_date
    #     ).exists_for_patient()

    # dataset.smoking_status=case(
    #     when(dataset.most_recent_smoking_code == "S").then("S"),
    #     when((dataset.most_recent_smoking_code == "E") | ((dataset.most_recent_smoking_code == "N") & (dataset.ever_smoked == True))).then("E"),
    #     when((dataset.most_recent_smoking_code == "N") & (dataset.ever_smoked == False)).then("N"),
    #     otherwise="M"
    # )
