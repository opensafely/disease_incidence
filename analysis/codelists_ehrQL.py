# ehrQL codelists
from ehrql import codelist_from_csv

# DEMOGRAPHIC CODELIST
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="snomedcode",
    category_column="Grouping_6",
)

# SMOKING CODELIST
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    column="CTV3Code",
    category_column="Category",
)

# CLINICAL CONDITIONS CODELISTS
asthma_snomed = codelist_from_csv(
    "codelists/opensafely-asthma-diagnosis-codes.csv", column="code",
)

copd_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-copd_cod.csv", column="code",
)

copd_icd = codelist_from_csv(
    "codelists/opensafely-copd-secondary-care.csv", column="code",
)

chd_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-chd_cod.csv", column="code",
)

stroke_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-strk_cod.csv", column="code",
)

stroke_icd = codelist_from_csv(
    "codelists/opensafely-stroke-secondary-care.csv", column="icd",
)

heart_failure_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-hf_cod.csv", column="code",
)

dementia_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dem_cod.csv", column="code",
)

multiple_sclerosis_ctv = codelist_from_csv(
    "codelists/opensafely-multiple-sclerosis-v2.csv", column="code",
)

multiple_sclerosis_icd = codelist_from_csv(
    "codelists/bristol-multiple-sclerosis-icd10-v13.csv", column="code",
)

epilepsy_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-epil_cod.csv", column="code",
)

crohns_disease_ctv = codelist_from_csv(
    "codelists/opensafely-crohns-disease.csv", column="code",
)

ulcerative_colitis_ctv = codelist_from_csv(
    "codelists/opensafely-ulcerative-colitis.csv", column="code",
)

dm_type2_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dmtype2_cod.csv", column="code",
)

dm_type1_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dmtype1_cod.csv", column="code",
)

ckd_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-ckd_cod.csv", column="code",
)

psoriasis_ctv = codelist_from_csv(
    "codelists/opensafely-psoriasis.csv", column="code",
)

atopic_dermatitis_ctv = codelist_from_csv(
    "codelists/opensafely-atopic-dermatitis.csv", column="code",
)

osteoporosis_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-osteo_cod.csv", column="code",
)

hiv_snomed = codelist_from_csv(
    "codelists/opensafely-hiv-aids.csv", column="code",
)

depression_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-depr_cod.csv", column="code",
)