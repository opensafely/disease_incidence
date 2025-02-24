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

set type double

global start_date = "01/04/2016"

*Import dataset
import delimited "$projectdir/output/dataset_definition_2016.csv", clear

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

save "$projectdir/output/data/reference_data_processed.dta", replace

/*Tables================================================================*/

use "$projectdir/output/data/reference_data_processed.dta", clear

**Baseline table for reference population
preserve
table1_mc, total(before) onecol nospacelowpercent missing iqrmiddle(",")  ///
	vars(age contn %5.1f \ ///
		 age_band cat %5.1f \ ///
		 gender cat %5.1f \ ///
		 ethnicity cat %5.1f \ ///
		 imd cat %5.1f \ ///
		 )
restore

**Rounded and redacted baseline table for ref population
clear *
save "$projectdir/output/data/reference_table_rounded.dta", replace emptyok
use "$projectdir/output/data/reference_data_processed.dta", clear

foreach var of varlist imd ethnicity gender age_band  {
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
	gen cohort = "All"
	order cohort, first
	format percent %14.4f
	format count total %14.0f
	list cohort variable categories count total percent
	keep cohort variable categories count total percent
	append using "$projectdir/output/data/reference_table_rounded.dta"
	save "$projectdir/output/data/reference_table_rounded.dta", replace
	restore
}
use "$projectdir/output/data/reference_table_rounded.dta", clear
export excel "$projectdir/output/tables/reference_table_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

/*
**Baseline table for individual diagnoses - tagged to above excel
use "$projectdir/output/data/reference_data_processed.dta", clear

local index=1
foreach disease in $diseases {
	clear *
	save "$projectdir/output/data/baseline_table_rounded_`disease'.dta", replace emptyok
	local index = `index' + 16

use "$projectdir/output/data/baseline_data_processed.dta", clear

foreach var of varlist imd ethnicity gender {
	preserve
	keep if `disease'==1
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
	gen cohort = "`disease'"
	order cohort, first
	format percent %14.4f
	format count total %14.0f
	list cohort variable categories count total percent
	keep cohort variable categories count total percent
	append using "$projectdir/output/data/baseline_table_rounded_`disease'.dta"
	save "$projectdir/output/data/baseline_table_rounded_`disease'.dta", replace
	restore
}

use "$projectdir/output/data/baseline_table_rounded_`disease'", clear
export excel "$projectdir/output/tables/baseline_table_rounded.xls", sheet("Overall", modify) cell("A`index'") keepcellfmt firstrow(variables)
}
*/

*Table of mean age for reference population
clear *
save "$projectdir/output/data/reference_mean_age_rounded.dta", replace emptyok
use "$projectdir/output/data/reference_data_processed.dta", clear

foreach var of varlist age  {
	preserve
	collapse (count) count=patient_id (mean) mean_age=age (sd) stdev_age=age
	gen cohort = "All"
	rename *count freq
	gen count = round(freq, 5)
	replace stdev_age = . if count<=7
	replace mean_age = . if count<=7
	replace count = . if count<=7
	order count, first
	order cohort, first
	format mean_age stdev_age %14.4f
	format count %14.0f
	list cohort count mean_age stdev_age
	keep cohort count mean_age stdev_age
	append using "$projectdir/output/data/reference_mean_age_rounded.dta"
	save "$projectdir/output/data/reference_mean_age_rounded.dta", replace
	restore
}
use "$projectdir/output/data/reference_mean_age_rounded.dta", clear
export excel "$projectdir/output/tables/reference_mean_age_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

/*		 
**Table of mean age at diagnosis, by disease - tagged to the above
use "$projectdir/output/data/baseline_data_processed.dta", clear

foreach disease in $diseases {
	preserve
	keep if `disease'==1
	collapse (count) count=`disease' (mean) mean_age=`disease'_age (sd) stdev_age=`disease'_age
	gen cohort ="`disease'"
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace stdev_age = . if count<=7
	replace mean_age = . if count<=7
	replace count = . if count<=7
	order count, first
	order cohort, first
	format mean_age stdev_age %14.4f
	format count %14.0f
	list cohort count mean_age stdev_age
	keep cohort count mean_age stdev_age
	append using "$projectdir/output/data/table_mean_age_rounded.dta"
	save "$projectdir/output/data/table_mean_age_rounded.dta", replace	
	restore
}	

use "$projectdir/output/data/table_mean_age_rounded.dta", clear
export excel "$projectdir/output/tables/table_mean_age_rounded.xls", replace keepcellfmt firstrow(variables)
*/

***Output tables as CSVs		 
import excel "$projectdir/output/tables/reference_table_rounded.xls", clear
export delimited using "$projectdir/output/tables/reference_table_rounded.csv", novarnames  replace

import excel "$projectdir/output/tables/reference_mean_age_rounded.xls", clear
export delimited using "$projectdir/output/tables/reference_mean_age_rounded.csv", novarnames  replace	
/*
/*Graphs================================================================*/

use "$projectdir/output/data/baseline_data_processed.dta", clear

*Graph of (count) diagnoses by month, by disease
foreach disease in $diseases {
	preserve
	keep if `disease'==1 //would need to remove this if calculating incidence
	collapse (count) total_diag_un=`disease', by(`disease'_moyear) 
	gen total_diag = round(total_diag_un, 5)
	drop total_diag_un
	
	outsheet * using "$projectdir/output/tables/incidence_count_`disease'.csv" , comma replace
	export delimited using "$projectdir/output/tables/incidence_count_`disease'.csv", datafmt replace
	
	**Label diseases
	local dis_full = strproper(subinstr("`disease'", "_", " ",.)) 
	if "`dis_full'" == "Rheumatoid" local dis_full "Rheumatoid Arthritis"
	if "`dis_full'" == "Copd" local dis_full "COPD"
	if "`dis_full'" == "Crohns Disease" local dis_full "Crohn's Disease"
	if "`dis_full'" == "Dm Type2" local dis_full "Type 2 Diabetes Mellitus"
	if "`dis_full'" == "Chd" local dis_full "Coronary Heart Disease"
	if "`dis_full'" == "Ckd" local dis_full "Chronic Kidney Disease"
	if "`dis_full'" == "Coeliac" local dis_full "Coeliac Disease"
	if "`dis_full'" == "Pmr" local dis_full "Polymyalgia Rheumatica"
	
	twoway connected total_diag `disease'_moyear, ytitle("Monthly count of diagnoses", size(med)) color(gold%35) msymbol(circle) lstyle(solid) lcolor(gold) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small)) xline(722) title("`dis_full'", size(medium) margin(b=2)) name(`disease'_count, replace) saving("$projectdir/output/figures/count_inc_`disease'.gph", replace)
		graph export "$projectdir/output/figures/count_inc_`disease'.svg", replace
	
	restore
}
*/
log close	
