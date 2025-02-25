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
log using "$logdir/baseline_data_reference.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

clear *
save "$projectdir/output/data/reference_table_rounded.dta", replace emptyok

set type double

global years "2024 2023 2022 2021 2020 2019 2018 2017 2016"
*global years "2017 2016"

foreach year in $years {

*Import dataset
import delimited "$projectdir/output/dataset_definition_`year'.csv", clear

set scheme plotplainblind

*Create and label variables ===========================================================*/

**Age
lab var age "Age"
rename age_band age_band_old
encode age_band_old, gen(age_band)
drop age_band_old
lab var age_band "Age band, years"

label define age_band		1 "0 to 9"  ///
							2 "10 to 19" ///
							3 "20 to 29" ///
							4 "30 to 39" ///
							5 "40 to 49" ///
							6 "50 to 59" ///
							7 "60 to 69" ///
							8 "70 to 79" ///
							9 "80 or above", modify
lab val age_band age_band

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

save "$projectdir/output/data/reference_data_processed_`year'.dta", replace

/*Tables================================================================*/

**Baseline table
use "$projectdir/output/data/reference_data_processed_`year'.dta", clear
	preserve
	table1_mc, total(before) onecol nospacelowpercent missing iqrmiddle(",")  ///
		vars(age contn %5.1f \ ///
			 age_band cat %5.1f \ ///
			 gender cat %5.1f \ ///
			 ethnicity cat %5.1f \ ///
			 imd cat %5.1f \ ///
			 )
	restore

*Table of mean age and demographics for reference population, with counts rounded and redacted

use "$projectdir/output/data/reference_data_processed_`year'.dta", clear

	foreach var of varlist imd ethnicity gender age_band {
		preserve
		contract `var'
		local v : variable label `var' 
		gen variable = `"`v'"'
		decode `var', gen(categories)
		gen count = round(_freq, 5)
		egen total = total(count)
		gen percent = round((count/total)*100, 0.1)
		order total, before(percent)
		replace percent = . if count<=7
		replace total = . if count<=7
		replace count = . if count<=7
		gen cohort = "Reference population"
		order cohort, first
		gen year = "`year'"
		order year, after(cohort)
		format percent %14.4f
		format count total %14.0f
		list cohort year variable categories count total percent
		keep cohort year variable categories count total percent
		append using "$projectdir/output/data/reference_table_rounded.dta"
		save "$projectdir/output/data/reference_table_rounded.dta", replace
		restore
	}
	
	use "$projectdir/output/data/reference_data_processed_`year'.dta", clear

	foreach var of varlist age {
		preserve
		collapse (count) count=patient_id (mean) mean_age=age (sd) stdev_age=age
		rename *count freq
		gen count = round(freq, 5)
		replace stdev_age = . if count<=7
		replace mean_age = . if count<=7
		replace count = . if count<=7
		gen cohort = "Reference population"
		order cohort, first
		gen year = "`year'"
		order year, after(cohort)
		gen variable = "Age"
		order variable, after(year)
		gen categories = "Not applicable"
		order categories, after(variable)
		order count, after(stdev_age)
		gen total = count
		order total, after(count)
		format mean_age stdev_age %14.4f
		format count %14.0f
		list cohort year variable categories mean_age stdev_age count total
		keep cohort year variable categories mean_age stdev_age count total
		append using "$projectdir/output/data/reference_table_rounded.dta"
		save "$projectdir/output/data/reference_table_rounded.dta", replace
		restore
	}
}

use "$projectdir/output/data/reference_table_rounded.dta", clear
export delimited using "$projectdir/output/tables/reference_table_rounded.csv", datafmt replace

log close	
