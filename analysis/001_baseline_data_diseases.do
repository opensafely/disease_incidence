version 16

/*==============================================================================
DO FILE NAME:			Baseline data disease
PROJECT:				OpenSAFELY Disease Incidence project
AUTHOR:					M Russell / J Galloway									
DESCRIPTION OF FILE:	Baseline data by disease
DATASETS USED:			Dataset definition
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

*Set filepaths
global projectdir `c(pwd)'
di "$projectdir"

capture mkdir "$projectdir/output/data"
capture mkdir "$projectdir/output/tables"
capture mkdir "$projectdir/output/figures"

global logdir "$projectdir/logs"
di "$logdir"

*Open a log file
cap log close
log using "$logdir/baseline_data_diseases.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

*Set disease list
*global diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 ckd psoriasis atopic_dermatitis osteoporosis rheumatoid depression coeliac pmr"
global diseases "depression"

set type double

*Import dataset
import delimited "$projectdir/output/dataset_definition_demographics_disease.csv", clear

set scheme plotplainblind

*Create and label variables ===========================================================*/

**Age at index date
lab var age "Age at index date"
codebook age

**Sex
gen gender = 1 if sex == "female"
replace gender = 2 if sex == "male"
lab var gender "Gender"
lab define gender 1 "Female" 2 "Male", modify
lab val gender gender
tab gender, missing
keep if gender == 1 | gender == 2
drop sex

**Ethnicity
gen ethnicity_n = 1 if ethnicity == "White"
replace ethnicity_n = 2 if ethnicity == "Asian or Asian British"
replace ethnicity_n = 3 if ethnicity == "Black or Black British"
replace ethnicity_n = 4 if ethnicity == "Mixed"
replace ethnicity_n = 5 if ethnicity == "Chinese or Other Ethnic Groups"
replace ethnicity_n = 6 if ethnicity == "Unknown"


label define ethnicity_n	1 "White"  						///
							2 "Asian or Asian British"		///
							3 "Black or Black British"  	///
							4 "Mixed"						///
							5 "Chinese or Other Ethnic Groups" ///
							6 "Unknown", modify
							
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
replace imd = 6 if imd_quintile == "Unknown"

label define imd 1 "1 (most deprived)" 2 "2" 3 "3" 4 "4" 5 "5 (least deprived)" 6 "Unknown", modify
label values imd imd 
lab var imd "Index of multiple deprivation"
tab imd, missing
drop imd_quintile

**Age at diagnosis
foreach disease in $diseases {
	lab var `disease'_age "Age at diagnosis"
	codebook `disease'_age
	gen `disease'_age_band = 1 if ((`disease'_age >= 0) & (`disease'_age < 10)) 
	replace `disease'_age_band = 2 if ((`disease'_age >= 10) & (`disease'_age < 20)) 
	replace `disease'_age_band = 3 if ((`disease'_age >= 20) & (`disease'_age < 30))
	replace `disease'_age_band = 4 if ((`disease'_age >= 30) & (`disease'_age < 40))
	replace `disease'_age_band = 5 if ((`disease'_age >= 40) & (`disease'_age < 50))
	replace `disease'_age_band = 6 if ((`disease'_age >= 50) & (`disease'_age < 60))
	replace `disease'_age_band = 7 if ((`disease'_age >= 60) & (`disease'_age < 70))
	replace `disease'_age_band = 8 if ((`disease'_age >= 70) & (`disease'_age < 80))
	replace `disease'_age_band = 9 if ((`disease'_age >= 80) & (`disease'_age !=.))
	lab var `disease'_age_band "Age band, years"

	label define `disease'_age_band		1 "0 to 9"  ///
										2 "10 to 19" ///
										3 "20 to 29" ///
										4 "30 to 39" ///
										5 "40 to 49" ///
										6 "50 to 59" ///
										7 "60 to 69" ///
										8 "70 to 79" ///
										9 "80 or above", modify
	lab val `disease'_age_band `disease'_age_band
}

**Gen incident disease cohorts during study period
foreach disease in $diseases {
	gen `disease' = 1 if `disease'_inc_case=="T" & (`disease'_age >=0 & `disease'_age!=.) & `disease'_pre_reg=="T" & `disease'_alive_inc=="T"
	recode `disease' .=0
}

save "$projectdir/output/data/baseline_data_process.dta", replace

/*Tables================================================================*/

use "$projectdir/output/data/baseline_data_process.dta", clear

**Rounded and redacted baseline tables for each disease
clear *
save "$projectdir/output/data/baseline_table_rounded.dta", replace emptyok

foreach disease in $diseases {
	use "$projectdir/output/data/baseline_data_process.dta", clear
	keep if `disease'==1
	foreach var of varlist imd ethnicity gender `disease'_age_band {
		preserve
		contract `var'
		local v : variable label `var' 
		gen variable = `"`v'"'
		decode `var', gen(categories)
		gen count = round(_freq, 5)
		egen total = total(count)
		gen percent = round((count/total)*100, 0001)
		order total, before(percent)
		replace percent = . if count<=7
		replace total = . if count<=7
		replace count = . if count<=7
		gen cohort = "`disease'"
		order cohort, first
		format percent %14.4f
		format count total %14.0f
		list cohort variable categories count total percent
		keep cohort variable categories count total percent
		append using "$projectdir/output/data/baseline_table_rounded.dta"
		save "$projectdir/output/data/baseline_table_rounded.dta", replace
		restore
	}

	preserve
	collapse (count) count=`disease' (mean) mean_age=`disease'_age (sd) stdev_age=`disease'_age
	gen cohort ="`disease'"
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace stdev_age = . if count<=7
	replace mean_age = . if count<=7
	replace count = . if count<=7
	order cohort, first
	gen variable = "Age"
	order variable, after(cohort)
	gen categories = "Not applicable"
	order categories, after(variable)
	order count, after(stdev_age)
	gen total = count
	order total, after(count)
	format mean_age %14.4f
	format stdev_age %14.4f
	format count %14.0f
	list cohort variable categories mean_age stdev_age count total
	keep cohort variable categories mean_age stdev_age count total
	append using "$projectdir/output/data/baseline_table_rounded.dta"
	save "$projectdir/output/data/baseline_table_rounded.dta", replace	
	restore
}	
use "$projectdir/output/data/baseline_table_rounded.dta", clear
export delimited using "$projectdir/output/tables/baseline_table_rounded.csv", datafmt replace

log close	
