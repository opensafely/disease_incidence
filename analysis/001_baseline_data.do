version 16

/*==============================================================================
DO FILE NAME:			Incidence graphs
PROJECT:				OpenSAFELY Disease Incidence project
DATE: 					23/08/2024
AUTHOR:					J Galloway / M Russell									
DESCRIPTION OF FILE:	Baseline data for full cohort
DATASETS USED:			Dataset definition
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
log using "$logdir/baseline_data.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

*Set disease list and index dates
*global diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 ckd psoriasis atopic_dermatitis osteoporosis rheumatoid depression coeliac pmr"
global diseases "rheumatoid pmr"

global start_date = "01/04/2016"
global end_date = "31/12/2024"

*Import dataset
import delimited "$projectdir/output/dataset_definition.csv", clear

set scheme plotplainblind

*Create and label variables ===========================================================*/

**Sex
gen gender = 1 if sex == "female"
replace gender = 2 if sex == "male"
lab var gender "Gender"
lab define gender 1 "Female" 2 "Male", modify
lab val gender gender
tab gender, missing
drop sex

**Ethnicity
gen ethnicity_n = 1 if ethnicity == "White"
replace ethnicity_n = 2 if ethnicity == "Asian or Asian British" /* mixed to 6 */
replace ethnicity_n = 3 if ethnicity == "Black or Black British"
replace ethnicity_n = 4 if ethnicity == "Mixed"
replace ethnicity_n = 5 if ethnicity == "Chinese or Other Ethnic Groups"

label define ethnicity_n	1 "White"  						///
							2 "Asian or Asian British"		///
							3 "Black or Black British"  	///
							4 "Mixed"						///
							5 "Chinese or Other Ethnic Groups"
							
label values ethnicity_n ethnicity_n
lab var ethnicity_n "Ethnicity"
tab ethnicity_n, missing
drop ethnicity
rename ethnicity_n ethnicity

**IMD
gen imd = 1 if imd_quintile == "1 (most deprived)"
replace imd = 2 if imd_quintile == "2"
replace imd = 3 if imd_quintile == "3"
replace imd = 4 if imd_quintile == "4"
replace imd = 5 if imd_quintile == "5 (least deprived)"

label define imd 1 "1 (most deprived)" 2 "2" 3 "3" 4 "4" 5 "5 (least deprived)"
label values imd imd 
lab var imd "Index of multiple deprivation"
tab imd, missing
drop imd_quintile

**Format dates
foreach date_var in date_of_death registration_start {
	rename `date_var' `date_var'_s
	gen `date_var' = date(`date_var'_s, "YMD") 
	format `date_var' %td
	drop `date_var'_s 
}

foreach disease in $diseases {
	rename `disease'_inc_date `disease'_inc_date_s
	gen `disease'_inc_date = date(`disease'_inc_date_s, "YMD") 
	format `disease'_inc_date %td
	drop `disease'_inc_date_s
}

**Work out age at diagnosis
foreach disease in $diseases {
	gen `disease'_int = `disease'_inc_date - registration_start if `disease'_inc_date!=. & registration_start!=.
	replace `disease'_int = `disease'_int/365.25
	gen `disease'_age = age_reg + `disease'_int
	lab var `disease'_age "Age at disease onset"
	*gen `disease'_inc_date = date(`disease'_inc_date_s, "YMD") 
	*format `disease'_inc_date %td
	*drop `disease'_inc_date_s
}

**Gen incident disease cohorts during study period
foreach disease in $diseases {
	gen `disease' = 1 if (((`disease'_inc_date >= date("$start_date", "DMY")) & (`disease'_inc_date <= date("$end_date", "DMY"))) & `disease'_inc_date!=. & gender!=. & `disease'_age!=. & `disease'_preceding_reg_inc=="T" & `disease'_alive_inc=="T")
	recode `disease' .=0
}

*Age variables
*Create categorised age
drop if age<0 & age !=.
drop if age>109 & age !=.
drop if age==.
lab var age "Age"

recode age 18/39.9999 = 1 /// 
           40/49.9999 = 2 ///
		   50/59.9999 = 3 ///
	       60/69.9999 = 4 ///
		   70/79.9999 = 5 ///
		   80/max = 6, gen(agegroup) 

label define agegroup 	1 "18-39" ///
						2 "40-49" ///
						3 "50-59" ///
						4 "60-69" ///
						5 "70-79" ///
						6 "80+"
						
label values agegroup agegroup
lab var agegroup "Age group"
tab agegroup, missing

save "$projectdir/output/data/baseline_data_processed.dta", replace

/*Tables=====================================================================================*/

use "$projectdir/output/data/baseline_data_processed.dta", clear

**Baseline table for reference population
preserve
keep if pmr==1
table1_mc, total(before) onecol nospacelowpercent missing iqrmiddle(",")  ///
	vars(pmr_age contn %5.1f \ ///
		 gender cat %5.1f \ ///
		 ethnicity cat %5.1f \ ///
		 imd cat %5.1f \ ///
		 ) saving("$projectdir/output/tables/baseline_table.xls", replace)
restore

**Round and redacted baseline table by disease
clear *
save "$projectdir/output/data/baseline_table_rounded.dta", replace emptyok
use "$projectdir/output/data/baseline_data_processed.dta", clear

set type double

foreach var of varlist gender  {
	preserve
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	gen count = round(_freq, 5)
	egen total = total(count)
	egen non_missing=sum(count) if categories!="Not known"
	drop if categories=="Not known"
	gen percent = round((count/non_missing)*100, 0.1)
	gen missing=(total-non_missing)
	order total, after(percent)
	order missing, after(total)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count_all
	tostring percent, gen(percentstr) force format(%9.1f)
	replace percentstr = "-" if count =="<8"
	order percentstr, after(percent)
	drop percent
	rename percentstr percent_all
	gen totalstr = string(total)
	replace totalstr = "-" if count =="<8"
	order totalstr, after(total)
	drop total
	rename totalstr total_all
	gen missingstr = string(missing)
	replace missingstr = "-" if count =="<8"
	order missingstr, after(missing)
	drop missing
	rename missingstr missing
	list variable categories count percent total missing
	keep variable categories count percent total missing
	append using "$projectdir/output/data/table_1_rounded_all.dta"
	save "$projectdir/output/data/table_1_rounded_all.dta", replace
	restore
}
use "$projectdir/output/data/table_1_rounded_all.dta", clear
export excel "$projectdir/output/tables/table_1_rounded_bydiag.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Baseline table for EIA subdiagnoses - tagged to above excel
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

local index=0
levelsof eia_diag, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/table_1_rounded_`i'.dta", replace emptyok
	di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+6)
	}
	else if `index'>0 & `index'<=22 {
	    local col = word("`c(ALPHA)'", `index'+4)
	}
	di "`col'"
	if `index'==0 {
		local `index++'
		local `index++'
		local `index++'
		local `index++'
		local `index++'
		local `index++'
	}
	else {
	    local `index++'
		local `index++'
		local `index++'
		local `index++'
	}
	di `index'

use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

foreach var of varlist has_12m_post_appt has_6m_post_appt last_gp_prerheum_to21 last_gp_prerheum_to6m rheum_appt_to21 rheum_appt_to6m rheum_appt ckd chronic_liver_disease chronic_resp_disease cancer stroke chronic_cardiac_disease diabcatm hypertension smoke bmicat imd ethnicity male agegroup {
	preserve
	keep if eia_diag=="`i'"
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	gen count = round(_freq, 5)
	egen total = total(count)
	egen non_missing=sum(count) if categories!="Not known"
	drop if categories=="Not known"
	gen percent = round((count/non_missing)*100, 0.1)
	gen missing=(total-non_missing)
	order total, after(percent)
	order missing, after(total)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count_`i'
	tostring percent, gen(percentstr) force format(%9.1f)
	replace percentstr = "-" if count =="<8"
	order percentstr, after(percent)
	drop percent
	rename percentstr percent_`i'
	gen totalstr = string(total)
	replace totalstr = "-" if count =="<8"
	order totalstr, after(total)
	drop total
	rename totalstr total_`i'
	gen missingstr = string(missing)
	replace missingstr = "-" if count =="<8"
	order missingstr, after(missing)
	drop missing
	rename missingstr missing_`i'
	list count percent total missing
	keep count percent total missing
	append using "$projectdir/output/data/table_1_rounded_`i'.dta"
	save "$projectdir/output/data/table_1_rounded_`i'.dta", replace
	restore
}
display `index'
display "`col'"
use "$projectdir/output/data/table_1_rounded_`i'.dta", clear
export excel "$projectdir/output/tables/table_1_rounded_bydiag.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}
		 
***Output tables as CSVs		 
import excel "$projectdir/output/tables/baseline_table.xls", clear
export delimited using "$projectdir/output/tables/baseline_table.csv", novarnames  replace		

**Baseline table for reference population
clear *
save "$projectdir/output/data/table_1_rounded_allpts.dta", replace emptyok
use "$projectdir/output/data/file_eia_allpts.dta", clear

set type double

foreach var of varlist ckd chronic_liver_disease chronic_resp_disease cancer stroke chronic_cardiac_disease diabcatm hypertension smoke bmicat imd ethnicity male agegroup {
	preserve
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	egen total_un = total(_freq)
	egen non_missing_un=sum(_freq) if categories!="Not Known"
	gen missing_un=(total_un-non_missing_un)
	drop if categories=="Not Known"
	gen count = round(_freq, 5)
	gen total = round(total_un, 5)
	gen missing = round(missing_un, 5)
	gen non_missing = round(non_missing_un, 5)
	gen percent = round((count/non_missing)*100, 0.1)
	order variable, first
	order categories, after(variable)
	order count, after(categories)
	order percent, after(count)
	order total, after(percent)
	order missing, after(total)
	list variable categories count percent total missing
	keep variable categories count percent total missing
	append using "$projectdir/output/data/table_1_rounded_allpts.dta"
	save "$projectdir/output/data/table_1_rounded_allpts.dta", replace
	restore
}
use "$projectdir/output/data/table_1_rounded_allpts.dta", clear
export excel "$projectdir/output/tables/table_1_rounded_allpts.xls", replace keepcellfmt firstrow(variables)

*Output tables as CSVs		 
import excel "$projectdir/output/tables/table_1_rounded_allpts.xls", clear
export delimited using "$projectdir/output/tables/table_1_rounded_allpts.csv" , novarnames  replace		

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
*keep if sex == "female" | sex == "male" 

codebook age
*keep if age != ""

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

/* No longer needed - done at the next stage of pipeline 
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

bysort measure (interval_start): gen ratio_white_ma =(ratio_white_100000[_n-1]+ratio_white_100000[_n]+ratio_white_100000[_n+1])/3
bysort measure (interval_start): gen ratio_mixed_ma =(ratio_mixed_100000[_n-1]+ratio_mixed_100000[_n]+ratio_mixed_100000[_n+1])/3
bysort measure (interval_start): gen ratio_black_ma =(ratio_black_100000[_n-1]+ratio_black_100000[_n]+ratio_black_100000[_n+1])/3
bysort measure (interval_start): gen ratio_asian_ma =(ratio_asian_100000[_n-1]+ratio_asian_100000[_n]+ratio_asian_100000[_n+1])/3
bysort measure (interval_start): gen ratio_other_ma =(ratio_other_100000[_n-1]+ratio_other_100000[_n]+ratio_other_100000[_n+1])/3
bysort measure (interval_start): gen ratio_ethunk_ma =(ratio_ethunk_100000[_n-1]+ratio_ethunk_100000[_n]+ratio_ethunk_100000[_n+1])/3

bysort measure (interval_start): gen ratio_imd1_ma =(ratio_imd1_100000[_n-1]+ratio_imd1_100000[_n]+ratio_imd1_100000[_n+1])/3
bysort measure (interval_start): gen ratio_imd2_ma =(ratio_imd2_100000[_n-1]+ratio_imd2_100000[_n]+ratio_imd2_100000[_n+1])/3
bysort measure (interval_start): gen ratio_imd3_ma =(ratio_imd3_100000[_n-1]+ratio_imd3_100000[_n]+ratio_imd3_100000[_n+1])/3
bysort measure (interval_start): gen ratio_imd4_ma =(ratio_imd4_100000[_n-1]+ratio_imd4_100000[_n]+ratio_imd4_100000[_n+1])/3
bysort measure (interval_start): gen ratio_imd5_ma =(ratio_imd5_100000[_n-1]+ratio_imd5_100000[_n]+ratio_imd5_100000[_n+1])/3
bysort measure (interval_start): gen ratio_imdunk_ma =(ratio_imdunk_100000[_n-1]+ratio_imdunk_100000[_n]+ratio_imdunk_100000[_n+1])/3

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
*/
*/
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

set type double

keep if measure_inc==1 | measure_prev==1

foreach var in all male female 0_9 10_19 20_29 30_39 40_49 50_59 60_69 70_79 80 {
	rename numerator_`var' numerator_`var'_n //unadjusted counts (rounded and redacted)
	rename denominator_`var' denominator_`var'_n //unadjusted counts (rounded and redacted)
	rename ratio_`var'_100000 rate_`var'_n // unadjusted IR
	rename asr_`var' s_rate_`var'_n //age and sex-standardised IR 
	gen numerator_`var' = string(numerator_`var'_n)
	replace numerator_`var' = "" if numerator_`var' == "."
	gen denominator_`var' = string(denominator_`var'_n)
	replace denominator_`var' = "" if denominator_`var' == "."
	gen rate_`var' = string(rate_`var'_n)
	replace rate_`var' = "" if rate_`var' == "."
	gen s_rate_`var' = string(s_rate_`var'_n)
	replace s_rate_`var' = "" if s_rate_`var' == "."
	drop numerator_`var'_n denominator_`var'_n s_rate_`var'_n rate_`var'_n 
}

foreach var in white mixed black asian other ethunk imd1 imd2 imd3 imd4 imd5 imdunk {
	rename numerator_`var' numerator_`var'_n //unadjusted counts (rounded and redacted)
	rename denominator_`var' denominator_`var'_n //unadjusted counts (rounded and redacted)
	rename ratio_`var'_100000 rate_`var'_n
	gen numerator_`var' = string(numerator_`var'_n)
	replace numerator_`var' = "" if numerator_`var' == "."
	gen denominator_`var' = string(denominator_`var'_n)
	replace denominator_`var' = "" if denominator_`var' == "."
	gen rate_`var' = string(rate_`var'_n)
	replace rate_`var' = "" if rate_`var' == "."
	drop numerator_`var'_n denominator_`var'_n rate_`var'_n
}

keep diseases_ dis_title measure mo_year_diagn numerator_* denominator_* rate_* s_rate_*
order dis_title, before(measure)
replace measure = "Incidence" if substr(measure,-9,.) == "incidence"
replace measure = "Prevalence" if substr(measure,-10,.) == "prevalence"

foreach dis in $diseases {
	preserve
	keep if diseases_ == "`dis'"
	*drop diseases_
	rename diseases_ disease
	rename dis_title disease_full
	order disease, before(disease_full)
	save "$projectdir/output/tables/redacted_counts_`dis'.dta", replace
	outsheet * using "$projectdir/output/tables/redacted_counts_`dis'.csv" , comma replace
	restore
}

log close	
