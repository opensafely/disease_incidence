version 16

/*==============================================================================
DO FILE NAME:			Incidence graphs
PROJECT:				OpenSAFELY Disease Incidence project
DATE: 					23/08/2024
AUTHOR:					J Galloway / M Russell									
DESCRIPTION OF FILE:	Produces incidence graphs 
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
log using "$logdir/descriptive_tables.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

*Import and append measures datasets for diseases
*local diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 ckd psoriasis atopic_dermatitis osteoporosis rheumatoid depression coeliac pmr"
local diseases "pmr"
local years "2016 2017 2018 2019 2020 2021 2022 2023 2024"
local first_disease: word 1 of `diseases'
local first_year: word 1 of `years'

**Import first file as base dataset
import delimited "$projectdir/output/measures/measures_dataset_`first_disease'_`first_year'.csv", clear
save "$projectdir/output/data/measures_appended.dta", replace

**Loop over diseases and years
foreach disease in `diseases' {
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
keep if sex == "female" | sex == "male" //should already be accounted for in dataset definition

codebook age
keep if age != "" //should already be accounted for in dataset definition

**Code incidence and prevalence
gen measure_inc = 1 if substr(measure,-10,.) == "_incidence"
recode measure_inc .=0
gen measure_prev = 1 if substr(measure,-11,.) == "_prevalence"
recode measure_prev .=0

/*
gen measure_imd = 1 if substr(measure,-4,.) == "_imd"
recode measure_imd .=0
gen measure_ethnicity = 1 if substr(measure,-10,.) == "_ethnicity"
recode measure_ethnicity .=0
*/

gen measure_inc_any = 1 if measure_inc ==1
*gen measure_inc_any = 1 if measure_inc ==1 | measure_imd==1 | measure_ethnicity==1
recode measure_inc_any .=0

**Drop April/May/June 2016 data - remove this after dataset definition and measures re-run
drop if measure_inc_any == 1 & (mo_year_diagn_s == "2016m04" | mo_year_diagn_s == "2016m05" | mo_year_diagn_s == "2016m06")

**Label diseases
gen diseases_ = substr(measure, 1, strlen(measure) - 10) if measure_inc==1
replace diseases_ = substr(measure, 1, strlen(measure) - 11) if measure_prev==1
*replace diseases_ = substr(measure, 1, strlen(measure) - 14) if measure_imd==1
*replace diseases_ = substr(measure, 1, strlen(measure) - 20) if measure_ethnicity==1
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

**DO the same for IMD and ethnicity, then add moving average

save "$projectdir/output/data/processed_nonstandardised.dta", replace

*Export a CSV for import into ARIMA R file - unadjusted incidence ratios
keep if measure_inc==1
sort disease mo_year_diagn age sex
bys measure interval_start: gen n=_n
keep if n==1
drop n

rename year_diag year
rename ratio_all_100000 incidence //(rounded and redacted)
replace sex = "All"
keep disease sex mo_year_diagn year numerator_all denominator_all incidence
rename numerator_all numerator //(rounded and redacted)
rename denominator_all denominator //(rounded and redacted)

save "$projectdir/output/tables/arima_nonstandardised.dta", replace
outsheet * using "$projectdir/output/tables/arima_nonstandardised.csv" , comma replace

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

*Redact and round, then recalculate ratio - can I do this later?
replace numerator =. if numerator<=7 | denominator<=7
replace denominator =. if numerator<=7 | numerator==. | denominator<=7
replace numerator = round(numerator, 5)
replace denominator = round(denominator, 5)

replace ratio = (numerator/denominator) if (numerator!=. & denominator!=.)
replace ratio =. if (numerator==. | denominator==.)
gen ratio_100000 = ratio*100000

*Generate standardised incidence and prevalence, overall and by sex
gen new_value = prop*ratio_100000
bys disease mo_year_diagn measure: egen sum_new_value_male=sum(new_value) if sex=="male" 
gen asr_male = sum_new_value_male/100000
sort disease mo_year_diagn measure asr_male 
by disease mo_year_diagn measure (asr_male): replace asr_male = asr_male[_n-1] if missing(asr_male)
bys disease mo_year_diagn measure: egen sum_new_value_female=sum(new_value) if sex=="female" 
gen asr_female = sum_new_value_female/100000
sort disease mo_year_diagn measure asr_female 
by disease mo_year_diagn measure (asr_female): replace asr_female = asr_female[_n-1] if missing(asr_female)
bys disease mo_year_diagn measure: egen sum_new_value_all=sum(new_value)
gen asr_all = sum_new_value_all/200000

*Generate standardised incidence and prevalence, by age group
bys disease mo_year_diagn measure: egen sum_new_value_0_9=sum(new_value) if age=="age_0_9"
gen asr_0_9 = sum_new_value_0_9/21000
sort disease mo_year_diagn measure asr_0_9 
by disease mo_year_diagn measure (asr_0_9): replace asr_0_9 = asr_0_9[_n-1] if missing(asr_0_9)

bys disease mo_year_diagn measure: egen sum_new_value_10_19=sum(new_value) if age=="age_10_19"
gen asr_10_19 = sum_new_value_10_19/22000
sort disease mo_year_diagn measure asr_10_19 
by disease mo_year_diagn measure (asr_10_19): replace asr_10_19 = asr_10_19[_n-1] if missing(asr_10_19)

bys disease mo_year_diagn measure: egen sum_new_value_20_29=sum(new_value) if age=="age_20_29"
gen asr_20_29 = sum_new_value_20_29/24000
sort disease mo_year_diagn measure asr_20_29 
by disease mo_year_diagn measure (asr_20_29): replace asr_20_29 = asr_20_29[_n-1] if missing(asr_20_29)

bys disease mo_year_diagn measure: egen sum_new_value_30_39=sum(new_value) if age=="age_30_39"
gen asr_30_39 = sum_new_value_30_39/27000
sort disease mo_year_diagn measure asr_30_39 
by disease mo_year_diagn measure (asr_30_39): replace asr_30_39 = asr_30_39[_n-1] if missing(asr_30_39)

bys disease mo_year_diagn measure: egen sum_new_value_40_49=sum(new_value) if age=="age_40_49"
gen asr_40_49 = sum_new_value_40_49/28000
sort disease mo_year_diagn measure asr_40_49 
by disease mo_year_diagn measure (asr_40_49): replace asr_40_49 = asr_40_49[_n-1] if missing(asr_40_49)

bys disease mo_year_diagn measure: egen sum_new_value_50_59=sum(new_value) if age=="age_50_59"
gen asr_50_59 = sum_new_value_50_59/27000
sort disease mo_year_diagn measure asr_50_59 
by disease mo_year_diagn measure (asr_50_59): replace asr_50_59 = asr_50_59[_n-1] if missing(asr_50_59)

bys disease mo_year_diagn measure: egen sum_new_value_60_69=sum(new_value) if age=="age_60_69"
gen asr_60_69 = sum_new_value_60_69/23000
sort disease mo_year_diagn measure asr_60_69 
by disease mo_year_diagn measure (asr_60_69): replace asr_60_69 = asr_60_69[_n-1] if missing(asr_60_69)

bys disease mo_year_diagn measure: egen sum_new_value_70_79=sum(new_value) if age=="age_70_79"
gen asr_70_79 = sum_new_value_70_79/18000
sort disease mo_year_diagn measure asr_70_79 
by disease mo_year_diagn measure (asr_70_79): replace asr_70_79 = asr_70_79[_n-1] if missing(asr_70_79)

bys disease mo_year_diagn measure: egen sum_new_value_80=sum(new_value) if age=="age_greater_equal_80"
gen asr_80 = sum_new_value_80/10000
sort disease mo_year_diagn measure asr_80 
by disease mo_year_diagn measure (asr_80): replace asr_80 = asr_80[_n-1] if missing(asr_80)

sort disease mo_year_diagn measure age sex
bys measure interval_start: gen n=_n
keep if n==1
drop n

*Generate 3-monthly moving averages
bysort measure (interval_start): gen asr_all_ma =(asr_all[_n-1]+asr_all[_n]+asr_all[_n+1])/3
bysort measure (interval_start): gen asr_male_ma =(asr_male[_n-1]+asr_male[_n]+asr_male[_n+1])/3
bysort measure (interval_start): gen asr_female_ma =(asr_female[_n-1]+asr_female[_n]+asr_female[_n+1])/3
bysort measure (interval_start): gen asr_0_9_ma =(asr_0_9[_n-1]+asr_0_9[_n]+asr_0_9[_n+1])/3
bysort measure (interval_start): gen asr_10_19_ma =(asr_10_19[_n-1]+asr_10_19[_n]+asr_10_19[_n+1])/3
bysort measure (interval_start): gen asr_20_29_ma =(asr_20_29[_n-1]+asr_20_29[_n]+asr_20_29[_n+1])/3
bysort measure (interval_start): gen asr_30_39_ma =(asr_30_39[_n-1]+asr_30_39[_n]+asr_30_39[_n+1])/3
bysort measure (interval_start): gen asr_40_49_ma =(asr_40_49[_n-1]+asr_40_49[_n]+asr_40_49[_n+1])/3
bysort measure (interval_start): gen asr_50_59_ma =(asr_50_59[_n-1]+asr_50_59[_n]+asr_50_59[_n+1])/3
bysort measure (interval_start): gen asr_60_69_ma =(asr_60_69[_n-1]+asr_60_69[_n]+asr_60_69[_n+1])/3
bysort measure (interval_start): gen asr_70_79_ma =(asr_70_79[_n-1]+asr_70_79[_n]+asr_70_79[_n+1])/3
bysort measure (interval_start): gen asr_80_ma =(asr_80[_n-1]+asr_80[_n]+asr_80[_n+1])/3

bysort measure (interval_start): gen ratio_0_9_ma =(ratio_0_9_100000[_n-1]+ratio_0_9_100000[_n]+ratio_0_9_100000[_n+1])/3
bysort measure (interval_start): gen ratio_10_19_ma =(ratio_10_19_100000[_n-1]+ratio_10_19_100000[_n]+ratio_10_19_100000[_n+1])/3
bysort measure (interval_start): gen ratio_20_29_ma =(ratio_20_29_100000[_n-1]+ratio_20_29_100000[_n]+ratio_20_29_100000[_n+1])/3
bysort measure (interval_start): gen ratio_30_39_ma =(ratio_30_39_100000[_n-1]+ratio_30_39_100000[_n]+ratio_30_39_100000[_n+1])/3
bysort measure (interval_start): gen ratio_40_49_ma =(ratio_40_49_100000[_n-1]+ratio_40_49_100000[_n]+ratio_40_49_100000[_n+1])/3
bysort measure (interval_start): gen ratio_50_59_ma =(ratio_50_59_100000[_n-1]+ratio_50_59_100000[_n]+ratio_50_59_100000[_n+1])/3
bysort measure (interval_start): gen ratio_60_69_ma =(ratio_60_69_100000[_n-1]+ratio_60_69_100000[_n]+ratio_60_69_100000[_n+1])/3
bysort measure (interval_start): gen ratio_70_79_ma =(ratio_70_79_100000[_n-1]+ratio_70_79_100000[_n]+ratio_70_79_100000[_n+1])/3
bysort measure (interval_start): gen ratio_80_ma =(ratio_80_100000[_n-1]+ratio_80_100000[_n]+ratio_80_100000[_n+1])/3

/*gen asr_lci = asr-1.96*(asr/sqrt(denominator_all))
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
*/

save "$projectdir/output/data/processed_standardised.dta", replace

*Export a CSV for import into ARIMA R file - adjusted incidence rates
use "$projectdir/output/data/processed_standardised.dta", clear

keep if measure_inc==1

rename year_diag year
rename asr_all incidence //use age and sex-standardised IR (rounded and redacted)
replace sex = "All"
keep disease sex mo_year_diagn year numerator_all denominator_all incidence //incidence is adjusted
rename numerator_all numerator //unadjusted counts (rounded and redacted)
rename denominator_all denominator //unadjusted counts (rounded and redacted)
order disease, before(sex)

save "$projectdir/output/tables/arima_standardised.dta", replace
outsheet * using "$projectdir/output/tables/arima_standardised.csv" , comma replace

*Output string version of table to stop conversion for big numbers
use "$projectdir/output/data/processed_standardised.dta", clear

rename asr_all rate_n //use age and sex-standardised IR (rounded and redacted)
replace sex = "All"
rename numerator numerator_n //unadjusted counts (rounded and redacted)
rename denominator denominator_n //unadjusted counts (rounded and redacted)
gen numerator = string(numerator_all)
gen denominator = string(denominator_all)
gen rate = string(rate_n)

keep dis_full measure sex mo_year_diagn numerator denominator rate
order dis_full, before(measure)

save "$projectdir/output/tables/arima_standardised_s.dta", replace
outsheet * using "$projectdir/output/tables/arima_standardised_s.csv" , comma replace

**Produce graphs
use "$projectdir/output/data/processed_standardised.dta", clear

levelsof dis_title, local(levels)
foreach disease_ of local levels {
	
	di "`disease_'"
	local disease_title = strproper(subinstr("`disease_'", "_", " ",.)) 

/*	*Unadjusted incidence overall/male/female
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"
	
	twoway connected ratio_all_100000 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(gold) msymbol(circle) lstyle(solid) lcolor(gold) || connected ratio_male_100000 mo_year_diagn, color(ebblue) msymbol(circle) lstyle(solid) lcolor(ebblue) || connected ratio_female_100000 mo_year_diagn, color(red) lcolor(red) msymbol(circle) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(incidence, replace) saving("$projectdir/output/figures/`disease_'_incidence.gph", replace)
		graph export "$projectdir/output/figures/incidence_`disease_'.svg", replace
	restore		
	
	*Unadjusted prevalence overall/male/female
	preserve
	keep if measure_prev==1 
	keep if dis_title == "`disease_'"

	twoway connected ratio_all_100000 year, ytitle("Prevalence per 100,000 population", size(med)) color(gold) msymbol(circle) lstyle(solid) lcolor(gold)  || connected ratio_male_100000 year, color(ebblue) msymbol(circle) lstyle(solid) lcolor(ebblue)  || connected ratio_female_100000 year, color(red) lcolor(red) msymbol(circle) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Year beginning", size(medium) margin(medsmall)) xlabel(2016(1)2023, nogrid)  title("`disease_title'", size(medium)) xline(2020) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(prevalence, replace) saving("$projectdir/output/figures/`disease_'_prevalence.gph", replace)
		graph export "$projectdir/output/figures/prevalence_`disease_'.svg", replace
	restore	
*/	
	*Adjusted incidence comparison
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway connected ratio_all_100000 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(gold) msymbol(circle) lstyle(solid) lcolor(gold)  || connected asr_all mo_year_diagn, color(green) msymbol(circle) lstyle(solid) lcolor(green) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) legend(region(fcolor(white%0)) order(1 "Crude" 2 "Adjusted")) name(inc_comp, replace) saving("$projectdir/output/figures/`disease_'_inc_comp.gph", replace)
		graph export "$projectdir/output/figures/inc_comp_`disease_'.svg", replace
	restore		
			
	*Adjusted prevalence comparison
	preserve
	keep if measure_prev==1
	keep if dis_title == "`disease_'"

	twoway connected ratio_all_100000 year, ytitle("Prevalence per 100,000 population", size(med)) color(gold) msymbol(circle) lstyle(solid) lcolor(gold) || connected asr_all year, color(green) msymbol(circle) lstyle(solid) lcolor(green) ylabel(, nogrid labsize(small)) xtitle("Year beginning", size(medium) margin(medsmall)) xlabel(2016(1)2023, nogrid)  title("`disease_title'", size(medium)) legend(region(fcolor(white%0)) order(1 "Crude" 2 "Adjusted")) name(prev_comp, replace) saving("$projectdir/output/figures/`disease_'_prev_comp.gph", replace)
		graph export "$projectdir/output/figures/prev_comp_`disease_'.svg", replace
	restore		
	
/*	*Adjusted incidence overall/male/female
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway connected asr_all mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(gold) msymbol(circle) lstyle(solid) lcolor(gold) || connected asr_male mo_year_diagn, color(ebblue) msymbol(circle) lstyle(solid) lcolor(ebblue) || connected asr_female mo_year_diagn, color(red) msymbol(circle) lstyle(solid) lcolor(red)  ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(inc_adj, replace) saving("$projectdir/output/figures/`disease_'_inc_adj.gph", replace)
		graph export "$projectdir/output/figures/inc_adj_`disease_'.svg", replace
	restore	

	*Adjusted incidence moving average overall/male/female
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway line asr_all_ma mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) lcolor(gold) lstyle(solid) || scatter asr_all mo_year_diagn, color(gold) msymbol(circle) || line asr_male_ma mo_year_diagn, lcolor(ebblue) lstyle(solid) || scatter asr_male mo_year_diagn, color(ebblue) msymbol(circle) || line asr_female_ma mo_year_diagn, lcolor(red) lstyle(solid) || scatter asr_female mo_year_diagn, color(red) msymbol(circle) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(2 "All" 4 "Male" 6 "Female")) name(inc_ma_sex, replace) saving("$projectdir/output/figures/`disease_'_inc_ma_sex.gph", replace)
		graph export "$projectdir/output/figures/inc_ma_sex_`disease_'.svg", replace
	restore		
*/			
	*Adjusted prevalence overall/male/female
	preserve
	keep if measure_prev==1
	keep if dis_title == "`disease_'"

	twoway connected asr_all year, ytitle("Prevalence per 100,000 population", size(med)) color(green) msymbol(circle) lcolor(green) lstyle(solid) || connected asr_male year, color(midblue) msymbol(circle) lcolor(midblue) lstyle(solid) || connected asr_female year, color(red) msymbol(circle) lcolor(red) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Year beginning", size(medium) margin(medsmall)) xlabel(2016(1)2023, nogrid) title("`disease_title'", size(medium)) xline(2020) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(prev_adj, replace) saving("$projectdir/output/figures/`disease_'_prev_adj.gph", replace)
		graph export "$projectdir/output/figures/prev_adj_`disease_'.svg", replace
	restore	
/*	

	*Adjusted incidence overall with moving average (connected)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway connected asr_all mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue) lcolor(bluishgray) msymbol(circle) || line asr_all_ma mo_year_diagn, lcolor(midblue) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(off) name(inc_adj_ma, replace) saving("$projectdir/output/figures/`disease_'_inc_adj_ma.gph", replace)
		graph export "$projectdir/output/figures/inc_adj_ma_`disease_'.svg", replace
	restore	
*/	
	*Adjusted incidence overall with moving average (scatter)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway scatter asr_all mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue%35) msymbol(circle) || line asr_all_ma mo_year_diagn, lcolor(midblue) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(off) name(inc_adj_ma2, replace) saving("$projectdir/output/figures/`disease_'_inc_adj_ma2.gph", replace)
		graph export "$projectdir/output/figures/inc_adj_ma2_`disease_'.svg", replace
	restore	
	
/*	*Adjusted incidence overall with moving average, by sex (connected)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway connected asr_male mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue%35) mlcolor(eltblue%35) lstyle(solid) lcolor(bluishgray) msymbol(circle) || line asr_male_ma mo_year_diagn, lcolor(midblue) lstyle(solid) || connected asr_female mo_year_diagn, color(orange%35) mlcolor(orange%35) lstyle(solid) lcolor(orange%35) msymbol(circle)  || line asr_female_ma mo_year_diagn, lcolor(red) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "Male" 3 "Female")) name(adj_ma_sex, replace) saving("$projectdir/output/figures/`disease_'_adj_ma_sex.gph", replace)
		graph export "$projectdir/output/figures/adj_ma_sex_`disease_'.svg", replace
	restore		
*/	
	*Adjusted incidence overall with moving average, by sex (scatter)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway scatter asr_male mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue%35) mlcolor(eltblue%35) msymbol(circle) || line asr_male_ma mo_year_diagn, lcolor(midblue) lstyle(solid) || scatter asr_female mo_year_diagn, color(orange%35) mlcolor(orange%35) msymbol(circle)  || line asr_female_ma mo_year_diagn, lcolor(red) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "Male" 3 "Female")) name(adj_ma_sex2, replace) saving("$projectdir/output/figures/`disease_'_adj_ma_sex2.gph", replace)
		graph export "$projectdir/output/figures/adj_ma_sex2_`disease_'.svg", replace
	restore		
	
/*	*Adjusted incidence overall with moving average, by age group (scatter)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway scatter asr_0_9 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(gold%35) mlcolor(gold%35) msymbol(circle) || line asr_0_9_ma mo_year_diagn, lcolor(gold) lstyle(solid) || scatter asr_10_19 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(orange%35) mlcolor(orange%35) msymbol(circle) || line asr_10_19_ma mo_year_diagn, lcolor(orange) lstyle(solid) || scatter asr_20_29 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(red%35) mlcolor(red%35) msymbol(circle) || line asr_20_29_ma mo_year_diagn, lcolor(red) lstyle(solid) || scatter asr_30_39 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(ltblue%35) mlcolor(ltblue%35) msymbol(circle) || line asr_30_39_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) || scatter asr_40_49 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue%35) mlcolor(eltblue%35) msymbol(circle) || line asr_40_49_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || scatter asr_50_59 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(blue%35) mlcolor(blue%35) msymbol(circle) || line asr_50_59_ma mo_year_diagn, lcolor(blue) lstyle(solid) || scatter asr_60_69 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(purple%35) mlcolor(purple%35) msymbol(circle) || line asr_60_69_ma mo_year_diagn, lcolor(purple) lstyle(solid) || scatter asr_70_79 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(brown%35) mlcolor(brown%35) msymbol(circle) || line asr_70_79_ma mo_year_diagn, lcolor(brown) lstyle(solid) || scatter asr_80 mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(black%35) mlcolor(black%35) msymbol(circle) || line asr_80_ma mo_year_diagn, lcolor(black) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "0-9" 3 "10-19" 5 "20-29" 7 "30-39" 9 "40-49" 11 "50-59" 13 "60-69" 15 "70-79" 17 "80+")) name(adj_ma_age, replace) saving("$projectdir/output/figures/`disease_'_adj_ma_age.gph", replace)
		graph export "$projectdir/output/figures/adj_ma_age_`disease_'.svg", replace
	restore	
*/	

*Adjusted incidence overall with moving average, by age group (lines only)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway line asr_0_9_ma mo_year_diagn, lcolor(gold) lstyle(solid) ytitle("Monthly incidence per 100,000 population", size(med)) || line asr_10_19_ma mo_year_diagn, lcolor(orange) lstyle(solid) || line asr_20_29_ma mo_year_diagn, lcolor(red) lstyle(solid) || line asr_30_39_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) || line asr_40_49_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line asr_50_59_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line asr_60_69_ma mo_year_diagn, lcolor(purple) lstyle(solid) || line asr_70_79_ma mo_year_diagn, lcolor(brown) lstyle(solid) || line asr_80_ma mo_year_diagn, lcolor(black) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "0-9" 2 "10-19" 3 "20-29" 4 "30-39" 5 "40-49" 6 "50-59" 7 "60-69" 8 "70-79" 9 "80+")) name(adj_ma_age2, replace) saving("$projectdir/output/figures/`disease_'_adj_ma_age2.gph", replace)
		graph export "$projectdir/output/figures/adj_ma_age2_`disease_'.svg", replace
	restore	
	
/**Unadjusted incidence, by age group (lines only)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway line ratio_0_9_100000 mo_year_diagn, lcolor(gold) lstyle(solid) ytitle("Monthly incidence per 100,000 population", size(med)) || line ratio_10_19_100000 mo_year_diagn, lcolor(orange) lstyle(solid) || line ratio_20_29_100000 mo_year_diagn, lcolor(red) lstyle(solid) || line ratio_30_39_100000 mo_year_diagn, lcolor(ltblue) lstyle(solid) || line ratio_40_49_100000 mo_year_diagn, lcolor(eltblue) lstyle(solid) || line ratio_50_59_100000 mo_year_diagn, lcolor(blue) lstyle(solid) || line ratio_60_69_100000 mo_year_diagn, lcolor(purple) lstyle(solid) || line ratio_70_79_100000 mo_year_diagn, lcolor(brown) lstyle(solid) || line ratio_80_100000 mo_year_diagn, lcolor(black) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "0-9" 2 "10-19" 3 "20-29" 4 "30-39" 5 "40-49" 6 "50-59" 7 "60-69" 8 "70-79" 9 "80+")) name(un_age2, replace) saving("$projectdir/output/figures/`disease_'_un_age2.gph", replace)
		graph export "$projectdir/output/figures/un_age2_`disease_'.svg", replace
	restore		
	
*Unadjusted incidence moving average, by age group (lines only)
	preserve
	keep if measure_inc==1
	keep if dis_title == "`disease_'"

	twoway line ratio_0_9_ma mo_year_diagn, lcolor(gold) lstyle(solid) ytitle("Monthly incidence per 100,000 population", size(med)) || line ratio_10_19_ma mo_year_diagn, lcolor(orange) lstyle(solid) || line ratio_20_29_ma mo_year_diagn, lcolor(red) lstyle(solid) || line ratio_30_39_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) || line ratio_40_49_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line ratio_50_59_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line ratio_60_69_ma mo_year_diagn, lcolor(purple) lstyle(solid) || line ratio_70_79_ma mo_year_diagn, lcolor(brown) lstyle(solid) || line ratio_80_ma mo_year_diagn, lcolor(black) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "0-9" 2 "10-19" 3 "20-29" 4 "30-39" 5 "40-49" 6 "50-59" 7 "60-69" 8 "70-79" 9 "80+")) name(un_age2_ma, replace) saving("$projectdir/output/figures/`disease_'_un_age2_ma.gph", replace)
		graph export "$projectdir/output/figures/un_age2_ma_`disease_'.svg", replace
	restore
*/
}

log close	

*******Also need by IMD quintile +/- ethnicity**************	
		
/*	
	*Adjusted incidence overall, with 95% CI
	preserve
	keep if measure_inc==1
	keep if diseases_ == "`disease_'"

	twoway connected ratio_all_100 mo_year_diagn, ytitle("Monthly incidence per 100 population", size(med)) color(gold) || (connected asr mo_year_diagn, color(green)) (rcap asr_lci asr_uci mo_year_diagn, color(green)) ylabel(,  nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`dis_title'", size(medium)) legend(region(fcolor(white%0)) order(1 "Unadjusted" 2 "Adjusted")) name(`disease_'_incidence_as_95, replace) saving("$projectdir/output/figures/`disease_'_incidence_as_95.gph", replace)
		graph export "$projectdir/output/figures/`disease_'_incidence_as_95.svg", replace
	restore		
			
	*Adjusted prevalence overall, with 95% CI
	preserve
	keep if measure_prev==1
	keep if diseases_ == "`disease_'"

	twoway connected ratio_all_100 year, ytitle("Prevalence (%)", size(med)) color(gold) || connected asr year, color(green) ylabel(, nogrid labsize(small)) xtitle("Year beginning", size(medium) margin(medsmall)) xlabel(, nogrid)  title("`dis_title'", size(medium)) legend(region(fcolor(white%0)) order(1 "Unadjusted" 2 "Adjusted")) name(`disease_'_prevalence_as_95, replace) saving("$projectdir/output/figures/`disease_'_prevalence_as_95.gph", replace)
		graph export "$projectdir/output/figures/`disease_'_prevalence_as_95.svg", replace
	restore	
keep if measure_inc==1
keep if measure == "***"
keep if disease == "***"

*Lowess
twoway scatter asr_all mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(gold) || lowess asr_all mo_year_diagn, ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`dis_title'", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(prev_lowess, replace) saving("$projectdir/output/figures/prev_lowess.gph", replace)

*Test Lowess with data - not good enough
import delimited "$projectdir/output/data/incidence_month_rounded.csv", clear
gen monyear = monthly(mo_year_diagn, "MY", 2000) + 1200
format monyear %tmMon-CCYY
drop  mo_year_diagn
rename monyear mo_year_diagn

keep if sex=="All"

twoway scatter incidence mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(gold) || lowess incidence mo_year_diagn, ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("Disease", size(medium)) xline(722) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(prev_lowess, replace) saving("$projectdir/output/figures/prev_lowess.gph", replace)

*Moving average
use "$projectdir/output/data/processed_standardised.dta", clear

twoway connected asr_all mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue) lcolor(bluishgray)|| line asr_all_ma mo_year_diagn, lcolor(midblue) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("Disease", size(medium)) xline(722) legend(off) name(nc_adj_ma, replace) saving("$projectdir/output/figures/inc_adj_ma.gph", replace)



*ARIMA

use "$projectdir/output/data/processed_standardised.dta", clear

keep if measure == ***

sort mo_year_diagn
keep mo_year_diagn ratio_all_100000 //use crude incidence rate 
rename ratio_all_100000 inc_rate
gen t=_n
tsset t

*Plot raw series - is it stationary?
twoway (tsline inc_rate) //No

*Now plot differenced asr to see if stationarity  
gen inc_rate_diff = D.inc_rate
twoway (tsline inc_rate_diff) //stationary - we will use difference for our model

gen inc_rate_diffr = D.inc_rate/L.inc_rate //% difference
twoway (tsline inc_rate_diffr) //also stationary

*Now check for seasonality
gen inc_rate_seasonal = inc_rate_diff - inc_rate_diff[_n-12]
twoway (tsline inc_rate_seasonal) //Stationary - we will use difference for our model

*Plot ACF of differenced series (noting the extent of autocorrelation between time points)
ac inc_rate 
ac inc_rate_diff //1st lag negative - add MA term (1 term)
ac inc_rate_seasonal

*Plot partial ACF of differenced series
pac inc_rate 
pac inc_rate_diff
pac inc_rate_seasonal

*Autoarima to fit SARIMA model using undifferenced data, it will identify p/q parameters that optimise AIC
arimaauto inc_rate //suggests ARIMA(1,0,0) AIC 1084
predict inc_rate_p
twoway (tsline inc_rate inc_rate_p)

*Switch to bulk estimation from Hyndman-Khandakar algorithm
arimaauto inc_rate, nostepwise //suggests ARIMA(4,0,0) AIC 1057
predict inc_rate_p2
twoway (tsline inc_rate inc_rate_p2)

*Manually define d=1
arima inc_rate, arima(1,0,0)
estat ic

arima inc_rate, arima(1,1,0) //AIC 1040
predict inc_rate_p3
twoway (tsline inc_rate inc_rate_p3)

arima inc_rate, arima(4,1,0) //AIC 1034
estat ic
predict inc_rate_p4
twoway (tsline inc_rate_diff inc_rate_p4)

*How to manually specify d=1 in arimaauto?
arimaauto inc_rate, arima(0,1,0) nostepwise //(1,1,2) AIC 1032
predict inc_rate_p5
twoway (tsline inc_rate_diff inc_rate_p5)

*Run using differenced data 
arimaauto inc_rate_diff // 0,0,1 AIC 1034
estat ic
predict inc_rate_diff_p1
twoway (tsline inc_rate_diff inc_rate_diff_p1) 
arima inc_rate, arima(0,1,1) //AIC 1034
predict inc_rate_p6
twoway (tsline inc_rate_diff_p1 inc_rate_p6) //same as above

*Run nostepwise with differenced data
arimaauto inc_rate_diff, nostepwise //(1,0,2) AIC 1032
predict inc_rate_diff_p2
twoway (tsline inc_rate_diff inc_rate_diff_p2) 

*Forward predict
set obs `=_N+10'
replace t=_n

arimaauto inc_rate, nostepwise 
predict inc_rate_p7, dynamic(60)
twoway (tsline inc_rate inc_rate_p7)

arimaauto inc_rate_diff, nostepwise 
predict inc_rate_diff_p3, dynamic(60)
twoway (tsline inc_rate_diff_p2 inc_rate_diff_p3) 

gen original_series = .
replace original_series = inc_rate[1] in 1
replace original_series = original_series[_n-1] + inc_rate_diff in 2/L

gen predicted_series = .
replace predicted_series = inc_rate[1] in 1
replace predicted_series = predicted_series[_n-1] + inc_rate_diff_p3 in 2/L
twoway (tsline inc_rate predicted_series)

*Try with data
import delimited "$projectdir/output/data/incidence_month_rounded.csv", clear

keep if sex=="All"

*Change date format
numdate monthly mo_year_diagn_clean = mo_year_diagn, pattern(MY) topyear(2050)
format mo_year_diagn_clean %tmMon_CCYY
drop mo_year_diagn
rename mo_year_diagn_clean mo_year_diagn

keep mo_year_diagn incidence year
rename incidence inc_rate
gen t=_n

save "$projectdir/output/data/raw_incidence.dta", replace

keep if year<2020

*format mo_year_diagn %tmMon-CCYY

set obs `=_N+36'
replace t=_n

tsset t

*Plot raw series - is it stationary?
twoway (tsline inc_rate) //No

*Now plot differenced asr to see if stationarity  
gen inc_rate_diff = D.inc_rate
twoway (tsline inc_rate_diff) //stationary - we will use difference for our model

gen inc_rate_diffr = D.inc_rate/L.inc_rate //% difference
twoway (tsline inc_rate_diffr) //also stationary

*Now check for seasonality
gen inc_rate_seasonal = inc_rate_diff - inc_rate_diff[_n-12]
twoway (tsline inc_rate_seasonal)  //Stationary - we will use difference for our model

*Plot ACF of differenced series (noting the extent of autocorrelation between time points)
ac inc_rate 
ac inc_rate_diff //1st lag negative - add MA term (1 term)
ac inc_rate_seasonal

*Plot partial ACF of differenced series
pac inc_rate 
pac inc_rate_diff
pac inc_rate_seasonal

*Autoarima to fit SARIMA model using undifferenced data, it will identify p/q parameters that optimise AIC
arimaauto inc_rate //this runs infinitely
predict inc_rate_p
twoway (tsline inc_rate inc_rate_p)

*Switch to bulk estimation from Hyndman-Khandakar algorithm
arimaauto inc_rate, nostepwise
predict inc_rate_p2
twoway (tsline inc_rate inc_rate_p2)

*Attempt model with best fit from R
arima inc_rate, arima(2,0,1) sarima(1,1,0,12) trace
estat ic
predict inc_rate_pR, dynamic(61) y
twoway (tsline inc_rate inc_rate_pR)
predict fvar, mse
gen inc_rate_pR_lower=inc_rate_pR - 1.96*sqrt(fvar)
gen inc_rate_pR_upper=inc_rate_pR + 1.96*sqrt(fvar)
drop fvar

*Merge with original data
replace inc_rate_pR = inc_rate if t<61
keep t inc_rate_pR
merge 1:1 t using "$projectdir/output/data/raw_incidence.dta", nogen

*Generate 3-monthly moving averages of IR
gen inc_rate_ma =(inc_rate[_n-1]+inc_rate[_n]+inc_rate[_n+1])/3
gen inc_rate_pR_ma =(inc_rate_pR[_n-1]+inc_rate_pR[_n]+inc_rate_pR[_n+1])/3

*Plot graph of observed and predicted
twoway connected inc_rate mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue) lcolor(bluishgray) msymbol(circle) || line inc_rate_ma mo_year_diagn, lcolor(midblue) lstyle(solid) || connected inc_rate_pR mo_year_diagn if t>60, color(orange%50) lstyle(solid) lcolor(orange%50) msymbol(circle) || line inc_rate_pR_ma mo_year_diagn if t>60, lcolor(red) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("Disease", size(medium)) xline(722) legend(off) name(inc_adj_ma, replace) saving("$projectdir/output/figures/inc_adj_ma.gph", replace)
	graph export "$projectdir/output/figures/inc_adj_ma.svg", replace		
	
*Run using differenced data 
arimaauto inc_rate_diff, nostepwise 
predict inc_rate_diff_p1
twoway (tsline inc_rate_diff inc_rate_diff_p1) 
predict  inc_rate_diff_p2, dynamic(61)
twoway (tsline inc_rate_diff inc_rate_diff_p2) 

arimaauto inc_rate, arima(0,1,0) sarima(0,1,0,12) nostepwise trace
predict inc_rate_p4
twoway (tsline inc_rate inc_rate_p4)

arima inc_rate, arima(0,1,0) 
predict inc_rate_p5

set obs `=_N+10'
replace t=_n
arima inc_rate, arima(1,0,0)
predict inc_rate_p6
twoway (tsline inc_rate inc_rate_p6)

estat ic

arima inc_rate, arima(1,1,0) //AIC 1040
predict inc_rate_p3
twoway (tsline inc_rate inc_rate_p3)

arima inc_rate, arima(4,1,0) //AIC 1034
estat ic
predict inc_rate_p4
twoway (tsline inc_rate_diff inc_rate_p4)

*How to manually specify d=1 in arimaauto?
arimaauto inc_rate, arima(0,1,0) nostepwise //(1,1,2) AIC 1032
predict inc_rate_p5
twoway (tsline inc_rate_diff inc_rate_p5)

*Run nostepwise with differenced data
arimaauto inc_rate_diff, nostepwise //(1,0,2) AIC 1032
predict inc_rate_diff_p2
twoway (tsline inc_rate_diff inc_rate_diff_p2) 

arimaauto inc_rate, nostepwise 
predict inc_rate_p7, dynamic(60)
twoway (tsline inc_rate inc_rate_p7)

arimaauto inc_rate_diff, nostepwise 
predict inc_rate_diff_p3, dynamic(60)
twoway (tsline inc_rate_diff_p2 inc_rate_diff_p3) 

gen original_series = .
replace original_series = inc_rate[1] in 1
replace original_series = original_series[_n-1] + inc_rate_diff in 2/L

gen predicted_series = .
replace predicted_series = inc_rate[1] in 1
replace predicted_series = predicted_series[_n-1] + inc_rate_diff_p3 in 2/L
twoway (tsline inc_rate predicted_series)

gen asr_all_ln = ln(asr_all)
tsline asr_all //check trends (for D)
tsline D.asr_all
tsline D.asr_all_ln //D = 1

ac D.asr_all_ln //for Q
ac D.asr_all_ln //Q = 1

pac D.asr_all_ln //for P (try 4)

gen asr_diff = D.asr_all/L.asr_all
tsline asr_diff
arima asr_diff if t<=50, arima(1,1,1) sarima(1,1,1,12) noconstant
predict asr_diff_p, dynamic(50)
tsline asr_diff asr_diff_p

arima asr_all if t<=50, arima(4,1,1) noconstant
predict asr_all_p, dynamic(50)
tsline asr_all asr_all_p


/*

*Output tables as CSVs		 
import excel "$projectdir/output/tables/baseline_bydiagnosis.xls", clear
outsheet * using "$projectdir/output/tables/baseline_bydiagnosis.csv" , comma nonames replace	

*/