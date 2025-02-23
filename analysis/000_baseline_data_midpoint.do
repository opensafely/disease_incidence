version 16

/*==============================================================================
DO FILE NAME:			Incidence graphs
PROJECT:				OpenSAFELY Disease Incidence project
DATE: 					23/08/2024
AUTHOR:					J Galloway / M Russell									
DESCRIPTION OF FILE:	Baseline data for reference population
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
log using "$logdir/baseline_data_midpoint.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

*Import dataset
import delimited "$projectdir/output/dataset_definition_midpoint.csv", clear

set scheme plotplainblind

*Create and label variables ===========================================================*/

**Age
lab var age "Age"
codebook age
keep if age !=.
codebook age_band

**Sex
gen gender = 1 if sex == "female"
replace gender = 2 if sex == "male"
lab var gender "Gender"
lab define gender 1 "Female" 2 "Male", modify
lab val gender gender
tab gender, missing
keep if gender !=.
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

save "$projectdir/output/data/reference_data_processed.dta", replace

/*Tables================================================================*/

use "$projectdir/output/data/reference_data_processed.dta", clear

**Baseline table for reference population
preserve
table1_mc, total(before) onecol nospacelowpercent missing iqrmiddle(",")  ///
	vars(age contn %5.1f \ ///
		 gender cat %5.1f \ ///
		 ethnicity cat %5.1f \ ///
		 imd cat %5.1f \ ///
		 )
restore

**Rounded and redacted baseline table for full population
clear *
save "$projectdir/output/data/reference_table_rounded.dta", replace emptyok
use "$projectdir/output/data/reference_data_processed.dta", clear

set type double

foreach var of varlist imd ethnicity gender  {
	preserve
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	gen count = round(_freq, 5)
	egen total = total(count)
	gen percent = round((count/total)*100, 0.1)
	order total, after(percent)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring percent, gen(percentstr) force format(%9.1f)
	replace percentstr = "-" if count =="<8"
	order percentstr, after(percent)
	drop percent
	rename percentstr percent
	gen totalstr = string(total)
	replace totalstr = "-" if count =="<8"
	order totalstr, after(count)
	drop total
	rename totalstr total
	gen cohort = "All"
	order cohort, first
	list cohort variable categories count percent total
	keep cohort variable categories count percent total
	append using "$projectdir/output/data/reference_table_rounded.dta"
	save "$projectdir/output/data/reference_table_rounded.dta", replace
	restore
}
use "$projectdir/output/data/reference_table_rounded.dta", clear
export excel "$projectdir/output/tables/reference_table_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Table of mean age
clear *
save "$projectdir/output/data/reference_mean_age_rounded.dta", replace emptyok
use "$projectdir/output/data/reference_data_processed.dta", clear

	preserve
	collapse (count) count=age (mean) mean_age=age (sd) stdev_age=age
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring mean_age, gen(meanstr) force format(%9.1f)
	replace meanstr = "-" if count =="<8"
	drop mean_age
	rename meanstr mean_age
	tostring stdev_age, gen(stdevstr) force format(%9.1f)
	replace stdevstr = "-" if count =="<8"
	order stdevstr, after(stdev_age)
	drop stdev_age
	rename stdevstr stdev_age
	order count, first
	list count mean_age stdev_age
	keep count mean_age stdev_age
	append using "$projectdir/output/data/reference_mean_age_rounded.dta"
	save "$projectdir/output/data/reference_mean_age_rounded.dta", replace	
	restore

use "$projectdir/output/data/reference_mean_age_rounded.dta", clear
export excel "$projectdir/output/tables/reference_mean_age_rounded.xls", replace keepcellfmt firstrow(variables)

***Output tables as CSVs		 
import excel "$projectdir/output/tables/reference_table_rounded.xls", clear
export delimited using "$projectdir/output/tables/reference_table_rounded.csv", novarnames  replace

import excel "$projectdir/output/tables/reference_mean_age_rounded.xls", clear
export delimited using "$projectdir/output/tables/reference_mean_age_rounded.csv", novarnames  replace	

log close	
