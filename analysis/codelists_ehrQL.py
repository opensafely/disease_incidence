# ehrQL codelists
from ehrql import codelist_from_csv

# DEMOGRAPHIC CODELIST
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    column="Code",
    category_column="Grouping_6",
)

# SMOKING CODELIST
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    column="CTV3Code",
    category_column="Category",
)

# CLINICAL CONDITIONS CODELISTS
axial_spondyloarthritis = codelist_from_csv(
    "codelists/user-markdrussell-axial-spondyloarthritis.csv", column="code",
)

psoriatic_arthritis_codes = codelist_from_csv(
    "codelists/user-markdrussell-psoriatic-arthritis.csv", column="code",
)

rheumatoid_arthritis = codelist_from_csv(
    "codelists/user-markdrussell-new-rheumatoid-arthritis.csv", column="code",
)

undifferentiated_arthritis_codes = codelist_from_csv(
    "codelists/user-markdrussell-undiff-eia.csv", column="code",
)

chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", column="CTV3ID",
)

diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", column="CTV3ID",
)

hba1c_new_codes = ["XaPbt", "Xaeze", "Xaezd"]
hba1c_old_codes = ["X772q", "XaERo", "XaERp"]

hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv", column="CTV3ID",
)

chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv",
    column="CTV3ID",
)

copd_codes = codelist_from_csv(
    "codelists/opensafely-current-copd.csv", column="CTV3ID",
)

chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", column="CTV3ID",
)

stroke_codes = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", column="CTV3ID",
)

lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", column="CTV3ID",
)

haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", column="CTV3ID",
)

other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    column="CTV3ID",
)

creatinine_codes = ["XE2q5"]

ckd_codes = codelist_from_csv(
    "codelists/opensafely-chronic-kidney-disease.csv", column="CTV3ID",
)

bmi_codes = ["60621009", "846931000000101"]

referral_rheumatology = codelist_from_csv(
    "codelists/user-markdrussell-referral-rheumatology.csv", column = "code"
)
