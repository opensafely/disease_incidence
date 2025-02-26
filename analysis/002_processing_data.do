version 16

/*==============================================================================
DO FILE NAME:			Incidence graphs
PROJECT:				OpenSAFELY Disease Incidence project
DATE: 					23/08/2024
AUTHOR:					J Galloway / M Russell									
DESCRIPTION OF FILE:	Processing of measures data
DATASETS USED:			Measures files
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

*Set filepaths
*global projectdir "C:\Users\Mark\OneDrive\PhD Project\OpenSAFELY Incidence\disease_incidence"
*global projectdir "C:\Users\k1754142\OneDrive\PhD Project\OpenSAFELY Incidence\disease_incidence"
global projectdir `c(pwd)'
di "$projectdir"

capture mkdir "$projectdir/output/data"
capture mkdir "$projectdir/output/tables"
capture mkdir "$projectdir/output/figures"

global logdir "$projectdir/logs"
di "$logdir"

*Open a log file
cap log close
log using "$logdir/processing_data.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

*Import and append measures datasets for diseases
global diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 ckd psoriasis atopic_dermatitis osteoporosis rheumatoid depression coeliac pmr"
*global diseases "rheumatoid pmr"

set type double

local years "2016 2017 2018 2019 2020 2021 2022 2023 2024"
local first_disease: word 1 of $diseases
di "`first_disease'"
local first_year: word 1 of `years'

**Import first file as base dataset
import delimited "$projectdir/output/measures/measures_dataset_`first_disease'_`first_year'.csv", clear
save "$projectdir/output/data/measures_appended.dta", replace

**Loop over diseases and years
foreach disease in $diseases {
	foreach year in `years' {
		if (("`disease'" != "`first_disease'") | ("`year'" != "`first_year'"))  {
		import delimited "$projectdir/output/measures/measures_dataset_`disease'_`year'.csv", clear
		append using "$projectdir/output/data/measures_appended.dta"
		save "$projectdir/output/data/measures_appended.dta", replace 
		}
	}
}

sort measure interval_start sex age
save "$projectdir/output/data/measures_appended.dta", replace 

set scheme plotplainblind

*Descriptive statistics======================================================================*/

use "$projectdir/output/data/measures_appended.dta", clear 

**Format dates
rename interval_start interval_start_s
gen interval_start = date(interval_start_s, "YMD") 
format interval_start %td
drop interval_start_s interval_end

**Month/Year of interval
gen year_diag=year(interval_start)
format year_diag %ty
gen month_diag=month(interval_start)
gen mo_year_diagn=ym(year_diag, month_diag)
format mo_year_diagn %tmMon-CCYY
generate str16 mo_year_diagn_s = strofreal(mo_year_diagn,"%tmCCYY!mNN")
lab var mo_year_diagn "Month/Year of Diagnosis"
lab var mo_year_diagn_s "Month/Year of Diagnosis"

**Check age and sex categories
codebook sex

codebook age

**Code incidence and prevalence
gen measure_inc = 1 if substr(measure,-10,.) == "_incidence"
recode measure_inc .=0
gen measure_prev = 1 if substr(measure,-11,.) == "_prevalence"
recode measure_prev .=0

gen measure_imd = 1 if substr(measure,-4,.) == "_imd"
recode measure_imd .=0
gen measure_ethnicity = 1 if substr(measure,-5,.) == "_ethn"
recode measure_ethnicity .=0

*gen measure_inc_any = 1 if measure_inc ==1
gen measure_inc_any = 1 if measure_inc ==1 | measure_imd==1 | measure_ethnicity==1
recode measure_inc_any .=0

**Drop April/May/June 2016 data - remove this after dataset definition and measures re-run
*drop if measure_inc_any == 1 & (mo_year_diagn_s == "2016m04" | mo_year_diagn_s == "2016m05" | mo_year_diagn_s == "2016m06")

**Label diseases
gen diseases_ = substr(measure, 1, strlen(measure) - 10) if measure_inc==1
replace diseases_ = substr(measure, 1, strlen(measure) - 11) if measure_prev==1
replace diseases_ = substr(measure, 1, strlen(measure) - 8) if measure_imd==1
replace diseases_ = substr(measure, 1, strlen(measure) - 9) if measure_ethnicity==1
gen disease = strproper(subinstr(diseases_, "_", " ",.)) 

gen dis_full = disease
replace dis_full = "Rheumatoid Arthritis" if dis_full == "Rheumatoid"
replace dis_full = "COPD" if dis_full == "Copd"
replace dis_full = "Crohn's Disease" if dis_full == "Crohns Disease"
replace dis_full = "Type 2 Diabetes Mellitus" if dis_full == "Dm Type2"
replace dis_full = "Coronary Heart Disease" if dis_full == "Chd"
replace dis_full = "Chronic Kidney Disease" if dis_full == "Ckd"
replace dis_full = "Coeliac Disease" if dis_full == "Coeliac"
replace dis_full = "Polymyalgia Rheumatica" if dis_full == "Pmr"

gen dis_title = disease
replace dis_title = "Rheumatoid_Arthritis" if dis_title == "Rheumatoid"
replace dis_title = "COPD" if dis_title == "Copd"
replace dis_title = "Crohn's_Disease" if dis_title == "Crohns Disease"
replace dis_title = "Type_2_Diabetes_Mellitus" if dis_title == "Dm Type2"
replace dis_title = "Coronary_Heart_Disease" if dis_title == "Chd"
replace dis_title = "Chronic_Kidney_Disease" if dis_title == "Ckd"
replace dis_title = "Coeliac_Disease" if dis_title == "Coeliac"
replace dis_title = "Polymyalgia_Rheumatica" if dis_title == "Pmr"

*Generate incidence and prevalence by months across ages, sexes, IMD and ethnicity
sort disease mo_year_diagn measure
bys disease mo_year_diagn measure: egen numerator_all = sum(numerator)
bys disease mo_year_diagn measure: egen denominator_all = sum(denominator)

*Redact and round
replace numerator_all =. if numerator_all<=7 | denominator_all<=7
replace denominator_all =. if numerator_all<=7 | numerator_all==. | denominator_all<=7
replace numerator_all = round(numerator_all, 5)
replace denominator_all = round(denominator_all, 5)

gen ratio_all = (numerator_all/denominator_all) if (numerator_all!=. & denominator_all!=.)
replace ratio_all =. if (numerator_all==. | denominator_all==.)
gen ratio_all_100000 = ratio_all*100000

*For males
bys disease mo_year_diagn measure: egen numerator_male = sum(numerator) if sex=="male"
bys disease mo_year_diagn measure: egen denominator_male = sum(denominator) if sex=="male"

*Redact and round
replace numerator_male =. if numerator_male<=7 | denominator_male<=7
replace denominator_male =. if numerator_male<=7 | numerator_male==. | denominator_male<=7
replace numerator_male = round(numerator_male, 5)
replace denominator_male = round(denominator_male, 5)

gen ratio_male = (numerator_male/denominator_male) if (numerator_male!=. & denominator_male!=.)
replace ratio_male =. if (numerator_male==. | denominator_male==.)
gen ratio_male_100000 = ratio_male*100000

sort disease mo_year_diagn measure_prev measure_inc_any ratio_male_100000 
by disease mo_year_diagn measure_prev measure_inc_any (ratio_male_100000): replace ratio_male_100000 = ratio_male_100000[_n-1] if missing(ratio_male_100000)
sort disease mo_year_diagn measure_prev measure_inc_any numerator_male 
by disease mo_year_diagn measure_prev measure_inc_any (numerator_male): replace numerator_male = numerator_male[_n-1] if missing(numerator_male)
sort disease mo_year_diagn measure_prev measure_inc_any denominator_male 
by disease mo_year_diagn measure_prev measure_inc_any (denominator_male): replace denominator_male = denominator_male[_n-1] if missing(denominator_male)

*For females
bys disease mo_year_diagn measure: egen numerator_female = sum(numerator) if sex=="female"
bys disease mo_year_diagn measure: egen denominator_female = sum(denominator) if sex=="female"

*Redact and round
replace numerator_female =. if numerator_female<=7 | denominator_female<=7
replace denominator_female =. if numerator_female<=7 | numerator_female==. | denominator_female<=7
replace numerator_female = round(numerator_female, 5)
replace denominator_female = round(denominator_female, 5)

gen ratio_female = (numerator_female/denominator_female) if (numerator_female!=. & denominator_female!=.)
replace ratio_female =. if (numerator_female==. | denominator_female==.)
gen ratio_female_100000 = ratio_female*100000

sort disease mo_year_diagn measure_prev measure_inc_any ratio_female_100000 
by disease mo_year_diagn measure_prev measure_inc_any (ratio_female_100000): replace ratio_female_100000 = ratio_female_100000[_n-1] if missing(ratio_female_100000)
sort disease mo_year_diagn measure_prev measure_inc_any numerator_female 
by disease mo_year_diagn measure_prev measure_inc_any (numerator_female): replace numerator_female = numerator_female[_n-1] if missing(numerator_female)
sort disease mo_year_diagn measure_prev measure_inc_any denominator_female 
by disease mo_year_diagn measure_prev measure_inc_any (denominator_female): replace denominator_female = denominator_female[_n-1] if missing(denominator_female)

*For age groups
foreach var in 0_9 10_19 20_29 30_39 40_49 50_59 60_69 70_79 {
bys disease mo_year_diagn measure: egen numerator_`var' = sum(numerator) if age=="age_`var'"
bys disease mo_year_diagn measure: egen denominator_`var' = sum(denominator) if age=="age_`var'"

*Redact and round
replace numerator_`var' =. if numerator_`var'<=7 | denominator_`var'<=7
replace denominator_`var' =. if numerator_`var'<=7 | numerator_`var'==. | denominator_`var'<=7
replace numerator_`var' = round(numerator_`var', 5)
replace denominator_`var' = round(denominator_`var', 5)

gen ratio_`var' = (numerator_`var'/denominator_`var') if (numerator_`var'!=. & denominator_`var'!=.)
replace ratio_`var' =. if (numerator_`var'==. | denominator_`var'==.)
gen ratio_`var'_100000 = ratio_`var'*100000

sort disease mo_year_diagn measure_prev measure_inc_any ratio_`var'_100000 
by disease mo_year_diagn measure_prev measure_inc_any (ratio_`var'_100000): replace ratio_`var'_100000 = ratio_`var'_100000[_n-1] if missing(ratio_`var'_100000)
sort disease mo_year_diagn measure_prev measure_inc_any numerator_`var'
by disease mo_year_diagn measure_prev measure_inc_any (numerator_`var'): replace numerator_`var' = numerator_`var'[_n-1] if missing(numerator_`var')
sort disease mo_year_diagn measure_prev measure_inc_any denominator_`var' 
by disease mo_year_diagn measure_prev measure_inc_any (denominator_`var'): replace denominator_`var' = denominator_`var'[_n-1] if missing(denominator_`var')
}

*For 80+ age group
bys disease mo_year_diagn measure: egen numerator_80 = sum(numerator) if age=="age_greater_equal_80"
bys disease mo_year_diagn measure: egen denominator_80 = sum(denominator) if age=="age_greater_equal_80"

*Redact and round
replace numerator_80 =. if numerator_80<=7 | denominator_80<=7
replace denominator_80 =. if numerator_80<=7 | numerator_80==. | denominator_80<=7
replace numerator_80 = round(numerator_80, 5)
replace denominator_80 = round(denominator_80, 5)

gen ratio_80 = (numerator_80/denominator_80) if (numerator_80!=. & denominator_80!=.)
replace ratio_80 =. if (numerator_80==. | denominator_80==.)
gen ratio_80_100000 = ratio_80*100000

sort disease mo_year_diagn measure_prev measure_inc_any ratio_80_100000 
by disease mo_year_diagn measure_prev measure_inc_any (ratio_80_100000): replace ratio_80_100000 = ratio_80_100000[_n-1] if missing(ratio_80_100000)
sort disease mo_year_diagn measure_prev measure_inc_any numerator_80 
by disease mo_year_diagn measure_prev measure_inc_any (numerator_80): replace numerator_80 = numerator_80[_n-1] if missing(numerator_80)
sort disease mo_year_diagn measure_prev measure_inc_any denominator_80 
by disease mo_year_diagn measure_prev measure_inc_any (denominator_80): replace denominator_80 = denominator_80[_n-1] if missing(denominator_80)

*For ethnicity
bys disease mo_year_diagn measure: egen numerator_white = sum(numerator) if ethnicity=="White"
bys disease mo_year_diagn measure: egen denominator_white = sum(denominator) if ethnicity=="White"

bys disease mo_year_diagn measure: egen numerator_mixed = sum(numerator) if ethnicity=="Mixed"
bys disease mo_year_diagn measure: egen denominator_mixed = sum(denominator) if ethnicity=="Mixed"

bys disease mo_year_diagn measure: egen numerator_black = sum(numerator) if ethnicity=="Black or Black British"
bys disease mo_year_diagn measure: egen denominator_black = sum(denominator) if ethnicity=="Black or Black British"

bys disease mo_year_diagn measure: egen numerator_asian = sum(numerator) if ethnicity=="Asian or Asian British"
bys disease mo_year_diagn measure: egen denominator_asian = sum(denominator) if ethnicity=="Asian or Asian British"

bys disease mo_year_diagn measure: egen numerator_other = sum(numerator) if ethnicity=="Chinese or Other Ethnic Groups"
bys disease mo_year_diagn measure: egen denominator_other = sum(denominator) if ethnicity=="Chinese or Other Ethnic Groups"

bys disease mo_year_diagn measure: egen numerator_ethunk = sum(numerator) if ethnicity=="Unknown"
bys disease mo_year_diagn measure: egen denominator_ethunk = sum(denominator) if ethnicity=="Unknown"

*Redact and round
foreach var in white mixed black asian other ethunk {
replace numerator_`var' =. if numerator_`var'<=7 | denominator_`var'<=7
replace denominator_`var' =. if numerator_`var'<=7 | numerator_`var'==. | denominator_`var'<=7
replace numerator_`var' = round(numerator_`var', 5)
replace denominator_`var' = round(denominator_`var', 5)

gen ratio_`var' = (numerator_`var'/denominator_`var') if (numerator_`var'!=. & denominator_`var'!=.)
replace ratio_`var' =. if (numerator_`var'==. | denominator_`var'==.)
gen ratio_`var'_100000 = ratio_`var'*100000

sort disease mo_year_diagn measure_prev measure_inc_any ratio_`var'_100000 
by disease mo_year_diagn measure_prev measure_inc_any (ratio_`var'_100000): replace ratio_`var'_100000 = ratio_`var'_100000[_n-1] if missing(ratio_`var'_100000)
sort disease mo_year_diagn measure_prev measure_inc_any numerator_`var'
by disease mo_year_diagn measure_prev measure_inc_any (numerator_`var'): replace numerator_`var' = numerator_`var'[_n-1] if missing(numerator_`var')
sort disease mo_year_diagn measure_prev measure_inc_any denominator_`var' 
by disease mo_year_diagn measure_prev measure_inc_any (denominator_`var'): replace denominator_`var' = denominator_`var'[_n-1] if missing(denominator_`var')
}

*For IMD
bys disease mo_year_diagn measure: egen numerator_imd1 = sum(numerator) if imd=="1 (most deprived)"
bys disease mo_year_diagn measure: egen denominator_imd1 = sum(denominator) if imd=="1 (most deprived)"

bys disease mo_year_diagn measure: egen numerator_imd2 = sum(numerator) if imd=="2"
bys disease mo_year_diagn measure: egen denominator_imd2 = sum(denominator) if imd=="2"

bys disease mo_year_diagn measure: egen numerator_imd3 = sum(numerator) if imd=="3"
bys disease mo_year_diagn measure: egen denominator_imd3 = sum(denominator) if imd=="3"

bys disease mo_year_diagn measure: egen numerator_imd4 = sum(numerator) if imd=="4"
bys disease mo_year_diagn measure: egen denominator_imd4 = sum(denominator) if imd=="4"

bys disease mo_year_diagn measure: egen numerator_imd5 = sum(numerator) if imd=="5 (least deprived)"
bys disease mo_year_diagn measure: egen denominator_imd5 = sum(denominator) if imd=="5 (least deprived)"

bys disease mo_year_diagn measure: egen numerator_imdunk = sum(numerator) if imd=="Unknown"
bys disease mo_year_diagn measure: egen denominator_imdunk = sum(denominator) if imd=="Unknown"

*Redact and round
foreach var in imd1 imd2 imd3 imd4 imd5 imdunk {
replace numerator_`var' =. if numerator_`var'<=7 | denominator_`var'<=7
replace denominator_`var' =. if numerator_`var'<=7 | numerator_`var'==. | denominator_`var'<=7
replace numerator_`var' = round(numerator_`var', 5)
replace denominator_`var' = round(denominator_`var', 5)

gen ratio_`var' = (numerator_`var'/denominator_`var') if (numerator_`var'!=. & denominator_`var'!=.)
replace ratio_`var' =. if (numerator_`var'==. | denominator_`var'==.)
gen ratio_`var'_100000 = ratio_`var'*100000

sort disease mo_year_diagn measure_prev measure_inc_any ratio_`var'_100000 
by disease mo_year_diagn measure_prev measure_inc_any (ratio_`var'_100000): replace ratio_`var'_100000 = ratio_`var'_100000[_n-1] if missing(ratio_`var'_100000)
sort disease mo_year_diagn measure_prev measure_inc_any numerator_`var'
by disease mo_year_diagn measure_prev measure_inc_any (numerator_`var'): replace numerator_`var' = numerator_`var'[_n-1] if missing(numerator_`var')
sort disease mo_year_diagn measure_prev measure_inc_any denominator_`var' 
by disease mo_year_diagn measure_prev measure_inc_any (denominator_`var'): replace denominator_`var' = denominator_`var'[_n-1] if missing(denominator_`var')
}

save "$projectdir/output/data/processed_nonstandardised.dta", replace

*Calculate the age-standardized incidence rate (ASIR): use age specific incidence data - European Standard Population 2013
use "$projectdir/output/data/processed_nonstandardised.dta", clear

*Append includes the European Standard Population 2013
gen prop=10500 if age=="age_0_9"
replace prop=11000 if age=="age_10_19"
replace prop=12000 if age=="age_20_29"
replace prop=13500 if age=="age_30_39"
replace prop=14000 if age=="age_40_49"
replace prop=13500 if age=="age_50_59"
replace prop=11500 if age=="age_60_69"
replace prop=9000 if age=="age_70_79"
replace prop=5000 if age=="age_greater_equal_80"

*Apply the Standard Population Weights: multiply crude age-specific incidence rates by corresponding standard population weights
gen ratio_100000 = ratio*100000

*Generate standardised incidence and prevalence, overall and by sex
gen new_value = prop*ratio_100000
bys disease mo_year_diagn measure: egen sum_new_value_male=sum(new_value) if sex=="male"
gen asr_male = sum_new_value_male/100000
replace asr_male =. if ratio_male_100000 ==.
sort disease mo_year_diagn measure asr_male 
by disease mo_year_diagn measure (asr_male): replace asr_male = asr_male[_n-1] if missing(asr_male)
bys disease mo_year_diagn measure: egen sum_new_value_female=sum(new_value) if sex=="female" 
gen asr_female = sum_new_value_female/100000
replace asr_female =. if ratio_female_100000 ==. 
sort disease mo_year_diagn measure asr_female 
by disease mo_year_diagn measure (asr_female): replace asr_female = asr_female[_n-1] if missing(asr_female)
bys disease mo_year_diagn measure: egen sum_new_value_all=sum(new_value)
gen asr_all = sum_new_value_all/200000
replace asr_all =. if ratio_all_100000 ==. 

*Generate standardised incidence and prevalence, by age group
bys disease mo_year_diagn measure: egen sum_new_value_0_9=sum(new_value) if age=="age_0_9"
gen asr_0_9 = sum_new_value_0_9/21000
replace asr_0_9 =. if ratio_0_9_100000 ==.
sort disease mo_year_diagn measure asr_0_9 
by disease mo_year_diagn measure (asr_0_9): replace asr_0_9 = asr_0_9[_n-1] if missing(asr_0_9)

bys disease mo_year_diagn measure: egen sum_new_value_10_19=sum(new_value) if age=="age_10_19"
gen asr_10_19 = sum_new_value_10_19/22000
replace asr_10_19 =. if ratio_10_19_100000 ==.
sort disease mo_year_diagn measure asr_10_19 
by disease mo_year_diagn measure (asr_10_19): replace asr_10_19 = asr_10_19[_n-1] if missing(asr_10_19)

bys disease mo_year_diagn measure: egen sum_new_value_20_29=sum(new_value) if age=="age_20_29"
gen asr_20_29 = sum_new_value_20_29/24000
replace asr_20_29 =. if ratio_20_29_100000 ==.
sort disease mo_year_diagn measure asr_20_29 
by disease mo_year_diagn measure (asr_20_29): replace asr_20_29 = asr_20_29[_n-1] if missing(asr_20_29)

bys disease mo_year_diagn measure: egen sum_new_value_30_39=sum(new_value) if age=="age_30_39"
gen asr_30_39 = sum_new_value_30_39/27000
replace asr_30_39 =. if ratio_30_39_100000 ==.
sort disease mo_year_diagn measure asr_30_39 
by disease mo_year_diagn measure (asr_30_39): replace asr_30_39 = asr_30_39[_n-1] if missing(asr_30_39)

bys disease mo_year_diagn measure: egen sum_new_value_40_49=sum(new_value) if age=="age_40_49"
gen asr_40_49 = sum_new_value_40_49/28000
replace asr_40_49 =. if ratio_40_49_100000 ==.
sort disease mo_year_diagn measure asr_40_49 
by disease mo_year_diagn measure (asr_40_49): replace asr_40_49 = asr_40_49[_n-1] if missing(asr_40_49)

bys disease mo_year_diagn measure: egen sum_new_value_50_59=sum(new_value) if age=="age_50_59"
gen asr_50_59 = sum_new_value_50_59/27000
replace asr_50_59 =. if ratio_50_59_100000 ==.
sort disease mo_year_diagn measure asr_50_59 
by disease mo_year_diagn measure (asr_50_59): replace asr_50_59 = asr_50_59[_n-1] if missing(asr_50_59)

bys disease mo_year_diagn measure: egen sum_new_value_60_69=sum(new_value) if age=="age_60_69"
gen asr_60_69 = sum_new_value_60_69/23000
replace asr_60_69 =. if ratio_60_69_100000 ==.
sort disease mo_year_diagn measure asr_60_69 
by disease mo_year_diagn measure (asr_60_69): replace asr_60_69 = asr_60_69[_n-1] if missing(asr_60_69)

bys disease mo_year_diagn measure: egen sum_new_value_70_79=sum(new_value) if age=="age_70_79"
gen asr_70_79 = sum_new_value_70_79/18000
replace asr_70_79 =. if ratio_70_79_100000 ==.
sort disease mo_year_diagn measure asr_70_79 
by disease mo_year_diagn measure (asr_70_79): replace asr_70_79 = asr_70_79[_n-1] if missing(asr_70_79)

bys disease mo_year_diagn measure: egen sum_new_value_80=sum(new_value) if age=="age_greater_equal_80"
gen asr_80 = sum_new_value_80/10000
replace asr_80 =. if ratio_80_100000 ==.
sort disease mo_year_diagn measure asr_80 
by disease mo_year_diagn measure (asr_80): replace asr_80 = asr_80[_n-1] if missing(asr_80)

sort disease mo_year_diagn measure age sex
bys measure interval_start: gen n=_n
keep if n==1
drop n

save "$projectdir/output/data/processed_standardised.dta", replace

/*
gen asr_lci = asr-1.96*(asr/sqrt(denominator_all))
gen asr_uci = asr+1.96*(asr/sqrt(denominator_all))
gen asr_esp = Prop*calc_pyr_
bys year: egen sum_asr_esp=sum(asr_esp)
gen asir = sum_asr_esp/sum_prop
gen total_pyr = pyr_ if Age=="all_"
bys year_cal: ereplace total_pyr = max(total_pyr)
gen ci_95 = (calc_pyr_*Prop*Prop*100000/pyr_)
gen sum_ci_95 = sum(ci_95)/(sum_prop*sum_prop)
gen standerror = sqrt(sum_ci_95)
gen asir_lci = asir-1.96*standerror
gen asir_uci = asir+1.96*standerror

*Export a CSV for import into ARIMA R file - adjusted incidence rates
use "$projectdir/output/data/processed_standardised.dta", clear

keep if measure_inc==1

rename year_diag year
rename asr_all incidence //age and sex-standardised IR
replace sex = "All"
keep disease sex mo_year_diagn year numerator_all denominator_all incidence //incidence is adjusted
rename numerator_all numerator //unadjusted counts (rounded and redacted)
rename denominator_all denominator //unadjusted counts (rounded and redacted)
order disease, before(sex)

save "$projectdir/output/tables/arima_standardised2.dta", replace
outsheet * using "$projectdir/output/tables/arima_standardised2.csv" , comma replace
*/

*Output string version of incidence and prevalence (to stop conversion for big numbers)
use "$projectdir/output/data/processed_standardised.dta", clear

keep if measure_inc==1 | measure_prev==1

foreach var in all male female {
	rename ratio_`var'_100000 rate_`var' //unadjusted IR 
	rename asr_`var' s_rate_`var' //age and sex-standardised IR
	order s_rate_`var', after(rate_`var')
	format s_rate_`var' %14.4f
	format rate_`var' %14.4f
	format numerator_`var' %14.0f
	format denominator_`var' %14.0f
}

foreach var in 0_9 10_19 20_29 30_39 40_49 50_59 60_69 70_79 80 white mixed black asian other ethunk imd1 imd2 imd3 imd4 imd5 imdunk {
	rename ratio_`var'_100000 rate_`var'
	format rate_`var' %14.4f
	order rate_`var', after(denominator_`var')
	format numerator_`var' %14.0f
	format denominator_`var' %14.0f
}

keep diseases_ dis_title measure mo_year_diagn numerator_* denominator_* rate_* s_rate_*
order dis_title, before(measure)
replace measure = "Incidence" if substr(measure,-9,.) == "incidence"
replace measure = "Prevalence" if substr(measure,-10,.) == "prevalence"

foreach dis in $diseases {
	preserve
	keep if diseases_ == "`dis'"
	rename diseases_ disease
	rename dis_title disease_full
	order disease, before(disease_full)
	save "$projectdir/output/tables/redacted_counts_`dis'.dta", replace
	export delimited using "$projectdir/output/tables/redacted_counts_`dis'.csv", datafmt replace
	restore
}

log close	
