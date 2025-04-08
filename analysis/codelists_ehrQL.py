# ehrQL codelists
from ehrql import codelist_from_csv

# DEMOGRAPHIC CODELIST
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="code",
    category_column="Grouping_6",
)

# CLINICAL CONDITIONS CODELISTS
asthma_diag = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-ast_cod.csv", column="code",
)

asthma_emerg = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-astadmsn_cod.csv", column="code",
)

asthma_snomed = (
    asthma_diag
    + asthma_emerg
)

asthma_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-astres_cod.csv", column="code",
)

asthma_icd = codelist_from_csv(
    "codelists/user-markdrussell-asthma-secondary-care.csv", column="code",
)

copd_diag = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-copd_cod.csv", column="code",
)

copd_emerg = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-copdadmsn_cod.csv", column="code",
)

copd_snomed = (
    copd_diag
    + copd_emerg
)

copd_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-copdres_cod.csv", column="code",
)

copd_icd = codelist_from_csv(
    "codelists/user-markdrussell-COPD_admission.csv", column="code",
)

chd_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-chd_cod.csv", column="code",
)

chd_icd = codelist_from_csv(
    "codelists/user-markdrussell-coronary-heart-disease-secondary-care.csv", column="code",
)

stroke_diag = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-strk_cod.csv", column="code",
)

tia_diag = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-tia_cod.csv", column="code",
)

stroke_snomed = (
    stroke_diag
    + tia_diag
)

stroke_icd = codelist_from_csv(
    "codelists/user-markdrussell-stroke-and-tia-secondary-care.csv", column="code",
)

heart_failure_diag = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-hf_cod.csv", column="code",
)

heart_failure_lv_diag = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-hflvsd_cod.csv", column="code",
)

heart_failure_snomed = (
    heart_failure_diag
    + heart_failure_lv_diag
)

heart_failure_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-hfres_cod.csv", column="code",
)

heart_failure_icd = codelist_from_csv(
    "codelists/user-markdrussell-heart-failure-secondary-care.csv", column="code",
)

dementia_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dem_cod.csv", column="code",
)

dementia_icd = codelist_from_csv(
    "codelists/user-markdrussell-dementia-secondary-care.csv", column="code",
)

multiple_sclerosis_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-multiple-sclerosis-codes.csv", column="code",
)

multiple_sclerosis_icd = codelist_from_csv(
    "codelists/user-markdrussell-multiple-sclerosis-secondary-care.csv", column="code",
)

epilepsy_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-epil_cod.csv", column="code",
)

epilepsy_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-epilres_cod.csv", column="code",
)

epilepsy_icd = codelist_from_csv(
    "codelists/user-markdrussell-epilepsy-secondary-care.csv", column="code",
)

crohns_disease_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-crohns-disease-codes.csv", column="code",
)

crohns_disease_icd = codelist_from_csv(
    "codelists/user-markdrussell-crohns-disease-secondary-care.csv", column="code",
)

ulcerative_colitis_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-ulcerative-colitis-uc-codes.csv", column="code",
)

ulcerative_colitis_icd = codelist_from_csv(
    "codelists/user-markdrussell-ulcerative-colitis-secondary-care.csv", column="code",
)

dm_type2_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dmtype2audit_cod.csv", column="code",
)

dm_type2_icd = codelist_from_csv(
    "codelists/user-markdrussell-type-2-diabetes-secondary-care.csv", column="code",
)

dm_type2_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dmres_cod.csv", column="code",
)

dm_type1_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dmtype1audit_cod.csv", column="code",
)

dm_type1_icd = codelist_from_csv(
    "codelists/user-markdrussell-type-1-diabetes-secondary-care.csv", column="code",
)

## The following NHSD ref set includes ESRF, dialysis and transplant codes
ckd_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-ckdatrisk2_cod.csv", column="code",
)

ckd_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-ckdres_cod.csv", column="code",
)

ckd_icd = codelist_from_csv(
    "codelists/user-markdrussell-chronic-kidney-disease-secondary-care.csv", column="code",
)

psoriasis_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-adult-and-child-psoriasis-codes.csv", column="code",
)

psoriasis_icd = codelist_from_csv(
    "codelists/user-markdrussell-psoriasis-secondary-care.csv", column="code",
)

atopic_dermatitis_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-atopic-dermatitis-codes.csv", column="code",
)

atopic_dermatitis_icd = codelist_from_csv(
    "codelists/user-markdrussell-atopic-dermatitis-secondary-care.csv", column="code",
)

osteoporosis_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-osteo_cod.csv", column="code",
)

osteoporosis_icd = codelist_from_csv(
    "codelists/user-markdrussell-osteoporosis-secondary-care.csv", column="code",
)

osteoporosis_resolved = codelist_from_csv(
    "codelists/user-markdrussell-osteoporosis-resolved.csv", column="code",
)

hiv_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-human-immunodeficiency-virus-hiv-codes.csv", column="code",
)

hiv_icd = codelist_from_csv(
    "codelists/user-markdrussell-hiv-secondary-care.csv", column="code",
)

depression_diag = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-depr_cod.csv", column="code",
)

depression_management = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-depsupp_cod.csv", column="code",
)

depression_snomed = (
    depression_diag
    + depression_management
)

depression_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-depres_cod.csv", column="code",
)

depression_icd = codelist_from_csv(
    "codelists/user-markdrussell-depression-secondary-care.csv", column="code",
)

depression_broad_snomed = codelist_from_csv(
    "codelists/user-markdrussell-depression_broad.csv", column="code",
)

depression_broad_icd = codelist_from_csv(
    "codelists/user-markdrussell-depression-secondary-care.csv", column="code",
)

depression_broad_resolved = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-depres_cod.csv", column="code",
)

coeliac_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-coeliac-disease-codes.csv", column="code",
)

coeliac_icd = codelist_from_csv(
    "codelists/user-markdrussell-coeliac-secondary-care.csv", column="code",
)

pmr_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-polymyalgia-rheumatica-pmr-codes.csv", column="code",
)

pmr_icd = codelist_from_csv(
    "codelists/user-markdrussell-polymyalgia-rheumatica-pmr-secondary-care.csv", column="code",
)

rheumatoid_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-rheumatoid-arthritis-disorders.csv", column="code",
)

rheumatoid_icd = codelist_from_csv(
    "codelists/user-markdrussell-rheumatoid-arthritis-secondary-care.csv", column="code",
)