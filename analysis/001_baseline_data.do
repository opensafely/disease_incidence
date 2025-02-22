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

*Set disease list
global diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 ckd psoriasis atopic_dermatitis osteoporosis rheumatoid depression coeliac pmr"
*global diseases "rheumatoid pmr"

global start_date = "01/04/2016"
global end_date = "31/12/2024"

*Import dataset
import delimited "$projectdir/output/dataset_definition.csv", clear

set scheme plotplainblind

*Create and label variables ===========================================================*/

**Age
codebook age_reg

**Sex
codebook sex
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

**Format dates
foreach date_var in date_of_death registration_start {
	rename `date_var' `date_var'_s
	gen `date_var' = date(`date_var'_s, "YMD") 
	format `date_var' %td
	drop `date_var'_s 
}
codebook registration_start

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
	lab var `disease'_age "Age at diagnosis"
	*gen `disease'_inc_date = date(`disease'_inc_date_s, "YMD") 
	*format `disease'_inc_date %td
	*drop `disease'_inc_date_s
	codebook `disease'_age
}

**Gen incident disease cohorts during study period, and shorten variable names - too long for Stata
foreach disease in $diseases {
	gen `disease' = 1 if (((`disease'_inc_date >= date("$start_date", "DMY")) & (`disease'_inc_date <= date("$end_date", "DMY"))) & (`disease'_age >=0 & `disease'_age!=.) & `disease'_pre_reg=="T" & `disease'_alive_inc=="T")
	recode `disease' .=0
}

**Format dates
foreach disease in $diseases {
    gen `disease'_year = year(`disease'_inc_date)
	format `disease'_year %ty
	gen `disease'_mon = month(`disease'_inc_date)
	gen `disease'_moyear = ym(`disease'_year, `disease'_mon)
	format `disease'_moyear %tmMon-CCYY
	generate str16 `disease'_moyear_s = strofreal(`disease'_moyear,"%tmCCYY!mNN")
	lab var `disease'_moyear "Month/Year of Diagnosis"
	lab var `disease'_moyear_s "Month/Year of Diagnosis"
}

save "$projectdir/output/data/baseline_data_processed.dta", replace

/*Tables================================================================*/

use "$projectdir/output/data/baseline_data_processed.dta", clear

**Baseline table for reference population
preserve
table1_mc, total(before) onecol nospacelowpercent missing iqrmiddle(",")  ///
	vars(gender cat %5.1f \ ///
		 ethnicity cat %5.1f \ ///
		 imd cat %5.1f \ ///
		 )
restore

**Baseline table by disease
foreach disease in $diseases {
	preserve
	keep if `disease'==1
	table1_mc, total(before) onecol nospacelowpercent missing iqrmiddle(",")  ///
		vars(pmr_age contn %5.1f \ ///
			 gender cat %5.1f \ ///
			 ethnicity cat %5.1f \ ///
			 imd cat %5.1f \ ///
			 )
	restore
}

**Rounded and redacted baseline table for full population
clear *
save "$projectdir/output/data/baseline_table_rounded.dta", replace emptyok
use "$projectdir/output/data/baseline_data_processed.dta", clear

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
	append using "$projectdir/output/data/baseline_table_rounded.dta"
	save "$projectdir/output/data/baseline_table_rounded.dta", replace
	restore
}
use "$projectdir/output/data/baseline_table_rounded.dta", clear
export excel "$projectdir/output/tables/baseline_table_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Baseline table for individual diagnoses - tagged to above excel
use "$projectdir/output/data/baseline_data_processed.dta", clear

local index=1
foreach disease in $diseases {
	clear *
	save "$projectdir/output/data/baseline_table_rounded_`disease'.dta", replace emptyok
	di `index'
	local index = `index' + 16
	di `index'

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
	gen cohort = "`disease'"
	order cohort, first
	list cohort variable categories count percent total
	keep cohort variable categories count percent total
	append using "$projectdir/output/data/baseline_table_rounded_`disease'.dta"
	save "$projectdir/output/data/baseline_table_rounded_`disease'.dta", replace
	restore
}
display `index'
display "`col'"
use "$projectdir/output/data/baseline_table_rounded_`disease'", clear
export excel "$projectdir/output/tables/baseline_table_rounded.xls", sheet("Overall", modify) cell("A`index'") keepcellfmt firstrow(variables)
}
		 
**Table of mean age at diagnosis, by disease
clear *
save "$projectdir/output/data/table_mean_age_rounded.dta", replace emptyok
use "$projectdir/output/data/baseline_data_processed.dta", clear

foreach disease in $diseases {
	preserve
	keep if `disease'==1
	collapse (count) count=`disease' (mean) mean_age=`disease'_age (sd) stdev_age=`disease'_age
	gen cohort ="`disease'"
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
	order cohort, first
	list cohort count mean_age stdev_age
	keep cohort count mean_age stdev_age
	append using "$projectdir/output/data/table_mean_age_rounded.dta"
	save "$projectdir/output/data/table_mean_age_rounded.dta", replace	
	restore
}	

use "$projectdir/output/data/table_mean_age_rounded.dta", clear
export excel "$projectdir/output/tables/table_mean_age_rounded.xls", replace keepcellfmt firstrow(variables)

***Output tables as CSVs		 
import excel "$projectdir/output/tables/baseline_table_rounded.xls", clear
export delimited using "$projectdir/output/tables/baseline_table_rounded.csv", novarnames  replace

import excel "$projectdir/output/tables/table_mean_age_rounded.xls", clear
export delimited using "$projectdir/output/tables/table_mean_age_rounded.csv", novarnames  replace	

/*Graphs================================================================*/

use "$projectdir/output/data/baseline_data_processed.dta", clear

*Graph of (count) diagnoses by month, by disease

foreach disease in $diseases {
	preserve
	keep if `disease'==1 //would need to remove this if calculating incidence
	collapse (count) total_diag=`disease', by(`disease'_moyear) 
	
	**Round to nearest 5
	*foreach var of varlist *_diag {
		*gen `var'_round=round(`var', 5)
		*drop `var'
		
	outsheet * using "$projectdir/output/tables/incidence_count_`disease'.csv" , comma replace
		
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

log close	
