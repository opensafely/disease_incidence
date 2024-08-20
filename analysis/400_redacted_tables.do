version 16

/*==============================================================================
DO FILE NAME:			redacted output tables
PROJECT:				EIA OpenSAFELY project
DATE: 					07/03/2022
AUTHOR:					J Galloway / M Russell
						adapted from C Rentsch										
DESCRIPTION OF FILE:	redacted output table
DATASETS USED:			main data file
DATASETS CREATED: 		redacted output table
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

**Set filepaths
*global projectdir "C:\Users\Mark\OneDrive\PhD Project\OpenSAFELY\Github Practice"
*global projectdir "C:\Users\k1754142\OneDrive\PhD Project\OpenSAFELY\Github Practice"
global projectdir `c(pwd)'
di "$projectdir"

capture mkdir "$projectdir/output/data"
capture mkdir "$projectdir/output/tables"
capture mkdir "$projectdir/output/figures"

global logdir "$projectdir/logs"
di "$logdir"

**Open a log file
cap log close
log using "$logdir/redacted_tables.log", replace

**Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

set scheme plotplainblind

**Set index dates ===========================================================*/
global year_preceding = "01/04/2018"
global start_date = "01/04/2019"
global end_date = "01/10/2023"

*Descriptive statistics======================================================================*/

**Baseline table for all EIA patients
clear *
save "$projectdir/output/data/table_1_rounded_all.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

foreach var of varlist has_12m_post_appt has_6m_post_appt last_gp_prerheum_to21 last_gp_prerheum_to6m rheum_appt_to21 rheum_appt_to6m rheum_appt ckd chronic_liver_disease chronic_resp_disease cancer stroke chronic_cardiac_disease diabcatm hypertension smoke bmicat imd ethnicity male agegroup {
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

**Table of mean outputs - full study period
clear *
save "$projectdir/output/data/table_mean_bydiag_rounded.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

foreach var of varlist rheum_appt_count age {
	preserve
	collapse (count) "`var'_count"=`var' (mean) mean=`var' (sd) stdev=`var', by(eia_diagnosis)
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
    decode eia_diagnosis, gen(diagnosis)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring mean, gen(meanstr) force format(%9.1f)
	replace meanstr = "-" if count =="<8"
	order meanstr, after(mean)
	drop mean
	rename meanstr mean
	tostring stdev, gen(stdevstr) force format(%9.1f)
	replace stdevstr = "-" if count =="<8"
	order stdevstr, after(stdev)
	drop stdev
	rename stdevstr stdev
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count mean stdev
	keep variable diagnosis count mean stdev
	append using "$projectdir/output/data/table_mean_bydiag_rounded.dta"
	save "$projectdir/output/data/table_mean_bydiag_rounded.dta", replace
	restore
	preserve
	collapse (count) "`var'_count"=`var' (mean) mean=`var' (sd) stdev=`var'
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring mean, gen(meanstr) force format(%9.1f)
	replace meanstr = "-" if count =="<8"
	order meanstr, after(mean)
	drop mean
	rename meanstr mean
	tostring stdev, gen(stdevstr) force format(%9.1f)
	replace stdevstr = "-" if count =="<8"
	order stdevstr, after(stdev)
	drop stdev
	rename stdevstr stdev
	gen diagnosis = "Total"
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count mean stdev
	keep variable diagnosis count mean stdev
	append using "$projectdir/output/data/table_mean_bydiag_rounded.dta"
	save "$projectdir/output/data/table_mean_bydiag_rounded.dta", replace
	restore
} 

use "$projectdir/output/data/table_mean_bydiag_rounded.dta", clear
export excel "$projectdir/output/tables/table_mean_bydiag_rounded.xls", replace keepcellfmt firstrow(variables)

**Table of median/IQR outputs - full study period
clear *
save "$projectdir/output/data/table_median_bydiag_rounded.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

foreach var of varlist time_gp_rheum_appt time_rheum_eia_code {
	preserve
	collapse (count) "`var'_count"=`var' (p50) p50_un=`var' (p25) p25_un=`var' (p75) p75_un=`var', by(eia_diagnosis)
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	gen p25 = round(p25_un, 1)
	gen p75 = round(p75_un, 1)
    decode eia_diagnosis, gen(diagnosis)
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count p50 p25 p75
	keep variable diagnosis count p50 p25 p75
	append using "$projectdir/output/data/table_median_bydiag_rounded.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded.dta", replace
	restore
	preserve
	collapse (count) "`var'_count"=`var' (p50) p50_un=`var' (p25) p25_un=`var' (p75) p75_un=`var'
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	gen p25 = round(p25_un, 1)
	gen p75 = round(p75_un, 1)
	gen diagnosis = "Total"
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count p50 p25 p75
	keep variable diagnosis count p50 p25 p75
	append using "$projectdir/output/data/table_median_bydiag_rounded.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded.dta", replace
	restore
} 

use "$projectdir/output/data/table_median_bydiag_rounded.dta", clear
export excel "$projectdir/output/tables/table_median_bydiag_rounded.xls", replace keepcellfmt firstrow(variables)

**All below analyses are for those with rheum appt + GP appt + 6m+ of follow-up (changed from 12m requirement, for purposes of OpenSAFELY report)

**Table of median/IQR outputs - limited to those with 6m follow-up and rheum/GP appt
clear *
save "$projectdir/output/data/table_median_bydiag_rounded_to21.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

foreach var of varlist time_to_csdmard time_gp_rheum_appt time_rheum_eia_code {
	preserve
	collapse (count) "`var'_count"=`var' (p50) p50_un=`var' (p25) p25_un=`var' (p75) p75_un=`var', by(eia_diagnosis)
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	gen p25 = round(p25_un, 1)
	gen p75 = round(p75_un, 1)
    decode eia_diagnosis, gen(diagnosis)
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count p50 p25 p75
	keep variable diagnosis count p50 p25 p75
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21.dta", replace
	restore
	preserve
	collapse (count) "`var'_count"=`var' (p50) p50_un=`var' (p25) p25_un=`var' (p75) p75_un=`var'
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	gen p25 = round(p25_un, 1)
	gen p75 = round(p75_un, 1)
	gen diagnosis = "Total"
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count p50 p25 p75
	keep variable diagnosis count p50 p25 p75
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21.dta", replace
	restore
} 

use "$projectdir/output/data/table_median_bydiag_rounded_to21.dta", clear
export excel "$projectdir/output/tables/table_median_bydiag_rounded_to21.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Table of median/IQR outputs by appt year - limited to those with 6m follow-up and rheum/GP appt - tagged to above excel

use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

recode appt_year 1=2019
recode appt_year 2=2020
recode appt_year 3=2021
recode appt_year 4=2022
recode appt_year 5=2023

local index=0
levelsof appt_year, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_`i'.dta", replace emptyok
di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+7)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+5)
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

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

recode appt_year 1=2019
recode appt_year 2=2020
recode appt_year 3=2021
recode appt_year 4=2022
recode appt_year 5=2023

keep if appt_year==`i'

foreach var of varlist time_to_csdmard time_gp_rheum_appt time_rheum_eia_code {
	preserve
	collapse (count) freq=`var' (p50) p50_un=`var' (p25) p25_un=`var' (p75) p75_un=`var', by(eia_diagnosis)
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	gen p25 = round(p25_un, 1)
	gen p75 = round(p75_un, 1)
	drop p50_un p25_un p75_un
	rename count count_`i'
	rename p50 p50_`i'
	rename p25 p25_`i'
	rename p75 p75_`i'
   	order count, first
	list count p50 p25 p75
	keep count p50 p25 p75
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21_`i'.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_`i'.dta", replace
	restore
		preserve
	collapse (count) freq=`var' (p50) p50_un=`var' (p25) p25_un=`var' (p75) p75_un=`var'
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	gen p25 = round(p25_un, 1)
	gen p75 = round(p75_un, 1)
	drop p50_un p25_un p75_un
	rename count count_`i'
	rename p50 p50_`i'
	rename p25 p25_`i'
	rename p75 p75_`i'
   	order count, first
	list count p50 p25 p75
	keep count p50 p25 p75
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21_`i'.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_`i'.dta", replace
	restore
} 

display `index'
display "`col'"
use "$projectdir/output/data/table_median_bydiag_rounded_to21_`i'.dta", clear
export excel "$projectdir/output/tables/table_median_bydiag_rounded_to21.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

**Table of median/IQR outputs - for OpenSAFELY Report (3 monthly periods) - limited to those with 6m follow-up and rheum/GP appt
clear *
save "$projectdir/output/data/table_median_bydiag_rounded_to21_report.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

foreach var of varlist time_gp_rheum_appt {
	preserve
	collapse (count) "`var'_count"=`var' (p50) p50_un=`var', by(eia_diagnosis)
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count_all = round(freq, 5)
	gen p50_all = round(p50_un, 1)
    decode eia_diagnosis, gen(diagnosis)
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count_all p50_all
	keep variable diagnosis count_all p50_all
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21_report.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_report.dta", replace
	restore
	preserve
	collapse (count) "`var'_count"=`var' (p50) p50_un=`var'
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count_all = round(freq, 5)
	gen p50_all = round(p50_un, 1)
	gen diagnosis = "Total"
	order count, first
	order diagnosis, first
	order variable, first
	list variable diagnosis count_all p50_all
	keep variable diagnosis count_all p50_all
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21_report.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_report.dta", replace
	restore
} 

use "$projectdir/output/data/table_median_bydiag_rounded_to21_report.dta", clear
export excel "$projectdir/output/tables/table_median_bydiag_rounded_to21_report.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Table of median/IQR outputs by appt year - for OpenSAFELY Report - limited to those with 6m follow-up and rheum/GP appt - tagged to above excel

use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023 

local index=0
levelsof appt_3m, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_report_`i'.dta", replace emptyok
di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+5)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+3)
	}
	else if `index'==22 {
	    local col = "Y"
	}
	else if `index'==24 {
	    local col = "AA"
	}
	else if `index'==26 {
	    local col = "AC"
	}	
	else if `index'==28 {
	    local col = "AE"
	}	
	else if `index'==30 {
	    local col = "AG"
	}	
	else if `index'==32 {
	    local col = "AI"
	}	
	di "`col'"
	if `index'==0 {
		local `index++'
		local `index++'
		local `index++'
		local `index++'
	}
	else {
	    local `index++'
		local `index++'
	}
	di `index'

use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
keep if appt_3m==`i'

foreach var of varlist time_gp_rheum_appt {
	preserve
	collapse (count) freq=`var' (p50) p50_un=`var', by(eia_diagnosis)
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	drop p50_un
	rename count count_period`i'
	rename p50 p50_period`i'
   	order count, first
	list count p50
	keep count p50
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21_report_`i'.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_report_`i'.dta", replace
	restore
		preserve
	collapse (count) freq=`var' (p50) p50_un=`var'
	gen count = round(freq, 5)
	gen p50 = round(p50_un, 1)
	drop p50_un
	rename count count_period`i'
	rename p50 p50_period`i'
   	order count, first
	list count p50
	keep count p50
	append using "$projectdir/output/data/table_median_bydiag_rounded_to21_report_`i'.dta"
	save "$projectdir/output/data/table_median_bydiag_rounded_to21_report_`i'.dta", replace
	restore
} 

display `index'
display "`col'"
use "$projectdir/output/data/table_median_bydiag_rounded_to21_report_`i'.dta", clear
export excel "$projectdir/output/tables/table_median_bydiag_rounded_to21_report.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

**ITSA outputs for appt delays - 6m+ only
clear *
save "$projectdir/output/data/ITSA_tables_rounded.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

recode gp_appt_3w 2=0
lab var gp_appt_3w "Rheum appt within 3 weeks"
lab def gp_appt_3w 0 "No" 1 "Yes", modify
lab val gp_appt_3w gp_appt_3w

foreach var of varlist gp_appt_3w {
	preserve
	collapse (count) "`var'_count"=`var' (mean) mean=`var', by(mo_year_appt_s)
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring mean, gen(meanstr) force format(%9.3f)
	replace meanstr = "-" if count =="<8"
	order meanstr, after(mean)
	drop mean
	rename meanstr mean_proportion
	order count, first
	order mo_year_appt_s, first
	order variable, first
	list variable mo_year_appt_s count mean_proportion 
	keep variable mo_year_appt_s count mean_proportion 
	append using "$projectdir/output/data/ITSA_tables_rounded.dta"
	save "$projectdir/output/data/ITSA_tables_rounded.dta", replace
	restore
	preserve
	collapse (count) "`var'_count"=`var' (mean) mean=`var'
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring mean, gen(meanstr) force format(%9.3f)
	replace meanstr = "-" if count =="<8"
	order meanstr, after(mean)
	drop mean
	rename meanstr mean_proportion
	gen mo_year_appt_s = "Overall"
	order count, first
	order mo_year_appt_s, first
	order variable, first
	list variable mo_year_appt_s count mean_proportion 
	keep variable mo_year_appt_s count mean_proportion 
	append using "$projectdir/output/data/ITSA_tables_rounded.dta"
	save "$projectdir/output/data/ITSA_tables_rounded.dta", replace
	restore
} 

use "$projectdir/output/data/ITSA_tables_rounded.dta", clear
export excel "$projectdir/output/tables/ITSA_tables_appt_delay_rounded.xls", replace sheet ("GP to Appt") keepcellfmt firstrow(variables)

**ITSA outputs for csDMARDs - 6m+ only
clear *
save "$projectdir/output/data/ITSA_tables_rounded.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist csdmard_6m {
	preserve
	collapse (count) "`var'_count"=`var' (mean) mean=`var', by(mo_year_appt_s)
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring mean, gen(meanstr) force format(%9.3f)
	replace meanstr = "-" if count =="<8"
	order meanstr, after(mean)
	drop mean
	rename meanstr mean_proportion
	order count, first
	order mo_year_appt_s, first
	order variable, first
	list variable mo_year_appt_s count mean_proportion 
	keep variable mo_year_appt_s count mean_proportion 
	append using "$projectdir/output/data/ITSA_tables_rounded.dta"
	save "$projectdir/output/data/ITSA_tables_rounded.dta", replace
	restore
	preserve
	collapse (count) "`var'_count"=`var' (mean) mean=`var'
	gen varn = "`var'_count"
	gen variable = substr(varn, 1, strpos(varn, "_count") - 1)
	drop varn
	rename *count freq
	gen count = round(freq, 5)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count
	tostring mean, gen(meanstr) force format(%9.3f)
	replace meanstr = "-" if count =="<8"
	order meanstr, after(mean)
	drop mean
	rename meanstr mean_proportion
	gen mo_year_appt_s = "Overall"
	order count, first
	order mo_year_appt_s, first
	order variable, first
	list variable mo_year_appt_s count mean_proportion 
	keep variable mo_year_appt_s count mean_proportion 
	append using "$projectdir/output/data/ITSA_tables_rounded.dta"
	save "$projectdir/output/data/ITSA_tables_rounded.dta", replace
	restore
} 

use "$projectdir/output/data/ITSA_tables_rounded.dta", clear
export excel "$projectdir/output/tables/ITSA_tables_csdmard_delay_rounded.xls", replace sheet("csDMARD delays") keepcellfmt firstrow(variables)

**csDMARD table for all EIA patients
clear *
save "$projectdir/output/data/drug_byyearanddisease_all.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist csdmard_time_22 csdmard_time_21 csdmard_time_20 csdmard_time_19 hcq_time ssz_time mtx_time csdmard_time {
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
	list variable categories count percent total
	keep variable categories count percent total
	append using "$projectdir/output/data/drug_byyearanddisease_all.dta"
	save "$projectdir/output/data/drug_byyearanddisease_all.dta", replace
	restore
}
use "$projectdir/output/data/drug_byyearanddisease_all.dta", clear
export excel "$projectdir/output/tables/drug_byyearanddisease_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Baseline table for EIA subdiagnoses - tagged to above excel
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
keep if ra_code==1 | psa_code==1 | undiff_code==1

local index=0
levelsof eia_diag, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/drug_byyearanddisease_`i'.dta", replace emptyok
	di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+6)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+4)
	}
	di "`col'"
	if `index'==0 {
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
	}
	di `index'
	
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist csdmard_time_22 csdmard_time_21 csdmard_time_20 csdmard_time_19 hcq_time ssz_time mtx_time csdmard_time {
	preserve
	keep if eia_diag=="`i'"
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
	list count percent total
	keep count percent total
	append using "$projectdir/output/data/drug_byyearanddisease_`i'.dta"
	save "$projectdir/output/data/drug_byyearanddisease_`i'.dta", replace
	restore
}
use "$projectdir/output/data/drug_byyearanddisease_`i'.dta", clear
export excel "$projectdir/output/tables/drug_byyearanddisease_rounded.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

**First csDMARD table for all EIA patients (removed leflunomide for OpenSAFELY report due to small counts with more granular time periods)
clear *
save "$projectdir/output/data/first_csdmard.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if first_csDMARD==""
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist first_csDMARD {
	preserve
	contract `var'
	gen count = round(_freq, 5)
	egen total = total(count)
	gen percent = round((count/total)*100, 0.1)
	order total, after(percent)
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
	list first_csDMARD count percent total
	keep first_csDMARD count percent total
	append using "$projectdir/output/data/first_csdmard.dta"
	save "$projectdir/output/data/first_csdmard.dta", replace
	restore
}
use "$projectdir/output/data/first_csdmard.dta", clear
export excel "$projectdir/output/tables/first_csdmard_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**First csDMARD table for EIA subdiagnoses - tagged to above excel
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if first_csDMARD==""
keep if ra_code==1 | psa_code==1 | undiff_code==1

recode appt_year 1=2019
recode appt_year 2=2020
recode appt_year 3=2021
recode appt_year 4=2022
recode appt_year 5=2023

local index=0
levelsof appt_year, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/first_csdmard_`i'.dta", replace emptyok
di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+5)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+4)
	}
	di "`col'"
	if `index'==0 {
		local `index++'
		local `index++'
		local `index++'
		local `index++'
	}
	else {
	    local `index++'
		local `index++'
		local `index++'
	}
	di `index'
	
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if first_csDMARD==""
keep if ra_code==1 | psa_code==1 | undiff_code==1

recode appt_year 1=2019
recode appt_year 2=2020
recode appt_year 3=2021
recode appt_year 4=2022
recode appt_year 5=2023

foreach var of varlist first_csDMARD {
	preserve
	keep if appt_year==`i'
	contract `var'
	gen count = round(_freq, 5)
	egen total = total(count)
	gen percent = round((count/total)*100, 0.1)
	order total, after(percent)
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
	list count percent total
	keep count percent total
	append using "$projectdir/output/data/first_csdmard_`i'.dta"
	save "$projectdir/output/data/first_csdmard_`i'.dta", replace
	restore
}

display `index'
display "`col'"
use "$projectdir/output/data/first_csdmard_`i'.dta", clear
export excel "$projectdir/output/tables/first_csdmard_rounded.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

**First csDMARD table for all EIA patients - version used for report (removed leflunomide due to small counts with more granular time periods)
clear *
save "$projectdir/output/data/first_csdmard_report.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if first_csDMARD==""
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist first_csDMARD {
	preserve
	contract `var'
	gen count = round(_freq, 5)
	egen total = total(count)
	gen percent = round((count/total)*100, 0.1)
	order total, after(percent)
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
	list first_csDMARD count percent
	keep first_csDMARD count percent
	append using "$projectdir/output/data/first_csdmard_report.dta"
	save "$projectdir/output/data/first_csdmard_report.dta", replace
	restore
}
use "$projectdir/output/data/first_csdmard_report.dta", clear
export excel "$projectdir/output/tables/first_csdmard_rounded_report.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**First csDMARD table for EIA subdiagnoses - tagged to above excel
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if first_csDMARD==""
keep if ra_code==1 | psa_code==1 | undiff_code==1

local index=0
levelsof appt_3m, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/first_csdmard_`i'_report.dta", replace emptyok
di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+4)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+3)
	}
	else if `index'==23 {
	    local col = "Z"
	}
	else if `index'==25 {
	    local col = "AB"
	}
	else if `index'==27 {
	    local col = "AD"
	}
	else if `index'==29 {
	    local col = "AF"
	}
	else if `index'==31 {
	    local col = "AH"
	}	
	di "`col'"
	if `index'==0 {
		local `index++'
		local `index++'
		local `index++'
	}
	else {
	    local `index++'
		local `index++'
	}
	di `index'

use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if first_csDMARD==""
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist first_csDMARD {
	preserve
	keep if appt_3m==`i'
	contract `var'
	gen count = round(_freq, 5)
	egen total = total(count)
	gen percent = round((count/total)*100, 0.1)
	order total, after(percent)
	gen countstr = string(count)
	replace countstr = "<8" if count<=7
	order countstr, after(count)
	drop count
	rename countstr count_period`i'
	tostring percent, gen(percentstr) force format(%9.1f)
	replace percentstr = "-" if count =="<8"
	order percentstr, after(percent)
	drop percent
	rename percentstr percent_period`i'
	gen totalstr = string(total)
	replace totalstr = "-" if count =="<8"
	order totalstr, after(total)
	drop total
	rename totalstr total_period`i'
	list count percent
	keep count percent
	append using "$projectdir/output/data/first_csdmard_`i'_report.dta"
	save "$projectdir/output/data/first_csdmard_`i'_report.dta", replace
	restore
}

display `index'
display "`col'"
use "$projectdir/output/data/first_csdmard_`i'_report.dta", clear
export excel "$projectdir/output/tables/first_csdmard_rounded_report.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

**Boxplot outputs - csDMARD standards, all regions
clear *
save "$projectdir/output/data/drug_byyearandregion_rounded_all.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if region_nospace=="Not known"
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist csdmard_time_22 csdmard_time_21 csdmard_time_20 csdmard_time_19 csdmard_time {
	preserve
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	gen count = round(_freq, 5)
	egen total = total(count)
	egen non_missing=sum(count) if categories!=""
	drop if categories==""
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
	rename missingstr missing_all
	list variable categories count percent total missing
	keep variable categories count percent total missing
	append using "$projectdir/output/data/drug_byyearandregion_rounded_all.dta"
	save "$projectdir/output/data/drug_byyearandregion_rounded_all.dta", replace
	restore
}
use "$projectdir/output/data/drug_byyearandregion_rounded_all.dta", clear
export excel "$projectdir/output/tables/drug_byyearandregion_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Boxplot outputs - csDMARD outputs by region
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if region_nospace=="Not known"
keep if ra_code==1 | psa_code==1 | undiff_code==1

local index=0
levelsof region_nospace, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/drug_byyearandregion_rounded_`i'.dta", replace emptyok
	di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+7)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+5)
	}
	else if `index'==22 {
	    local col = "AA"
	}
	else if `index'==26 {
	    local col = "AE"
	}	
	else if `index'==30 {
	    local col = "AI"	
	}	
	else if `index'==34 {
	    local col = "AM"
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

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if region_nospace=="Not known"
keep if ra_code==1 | psa_code==1 | undiff_code==1

foreach var of varlist csdmard_time_22 csdmard_time_21 csdmard_time_20 csdmard_time_19 csdmard_time {
	preserve
	keep if region_nospace=="`i'"
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	gen count = round(_freq, 5)
	egen total = total(count)
	egen non_missing=sum(count) if categories!=""
	drop if categories==""
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
	append using "$projectdir/output/data/drug_byyearandregion_rounded_`i'.dta"
	save "$projectdir/output/data/drug_byyearandregion_rounded_`i'.dta", replace
	restore
}
display `index'
display "`col'"
use "$projectdir/output/data/drug_byyearandregion_rounded_`i'.dta", clear
export excel "$projectdir/output/tables/drug_byyearandregion_rounded.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

**Boxplot outputs - referral standards, all regions
clear *
save "$projectdir/output/data/referral_byregion_rounded_all.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if region_nospace=="Not known"

foreach var of varlist gp_appt_cat_22 gp_appt_cat_21 gp_appt_cat_20 gp_appt_cat_19 gp_appt_cat {
	preserve
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	gen count = round(_freq, 5)
	egen total = total(count)
	egen non_missing=sum(count) if categories!=""
	drop if categories==""
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
	rename missingstr missing_all
	list variable categories count percent total missing
	keep variable categories count percent total missing
	append using "$projectdir/output/data/referral_byregion_rounded_all.dta"
	save "$projectdir/output/data/referral_byregion_rounded_all.dta", replace
	restore
}
use "$projectdir/output/data/referral_byregion_rounded_all.dta", clear
export excel "$projectdir/output/tables/referral_byregion_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Boxplot outputs - referral standards, by regions - tagged to above excel
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if region_nospace=="Not known"

local index=0
levelsof region_nospace, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/referral_byregion_rounded_`i'.dta", replace emptyok
	di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+7)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+5)
	}
	else if `index'==22 {
	    local col = "AA"
	}
	else if `index'==26 {
	    local col = "AE"
	}	
	else if `index'==30 {
	    local col = "AI"	
	}	
	else if `index'==34 {
	    local col = "AM"
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

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023
drop if region_nospace=="Not known"

foreach var of varlist gp_appt_cat_22 gp_appt_cat_21 gp_appt_cat_20 gp_appt_cat_19 gp_appt_cat {
	preserve
	keep if region_nospace=="`i'"
	contract `var'
	local v : variable label `var' 
	gen variable = `"`v'"'
    decode `var', gen(categories)
	gen count = round(_freq, 5)
	egen total = total(count)
	egen non_missing=sum(count) if categories!=""
	drop if categories==""
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
	append using "$projectdir/output/data/referral_byregion_rounded_`i'.dta"
	save "$projectdir/output/data/referral_byregion_rounded_`i'.dta", replace
	restore
}
display `index'
display "`col'"
use "$projectdir/output/data/referral_byregion_rounded_`i'.dta", clear
export excel "$projectdir/output/tables/referral_byregion_rounded.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

**Rheumatology appointment consultation medium for all years
clear *
save "$projectdir/output/data/consultation_medium.dta", replace emptyok
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

foreach var of varlist rheum_appt_medium {
	preserve
	contract `var'
	gen count = round(_freq, 5)
	egen total = total(count)
	gen percent = round((count/total)*100, 0.1)
	order total, after(percent)
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
	list rheum_appt_medium count percent total
	keep rheum_appt_medium count percent total
	append using "$projectdir/output/data/consultation_medium.dta"
	save "$projectdir/output/data/consultation_medium.dta", replace
	restore
}
use "$projectdir/output/data/consultation_medium.dta", clear
export excel "$projectdir/output/tables/consultation_medium_rounded.xls", replace sheet("Overall") keepcellfmt firstrow(variables)

**Rheumatology appointment consultation medium table by year
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

recode appt_year 1=2019
recode appt_year 2=2020
recode appt_year 3=2021
recode appt_year 4=2022
recode appt_year 5=2023

local index=0
levelsof appt_year, local(levels)
foreach i of local levels {
	clear *
	save "$projectdir/output/data/consultation_medium_`i'.dta", replace emptyok
di `index'
	if `index'==0 {
		local col = word("`c(ALPHA)'", `index'+5)
	}
	else if `index'>0 & `index'<=21 {
	    local col = word("`c(ALPHA)'", `index'+4)
	}
	di "`col'"
	if `index'==0 {
		local `index++'
		local `index++'
		local `index++'
		local `index++'
	}
	else {
	    local `index++'
		local `index++'
		local `index++'
	}
	di `index'
	
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

keep if has_6m_post_appt==1
drop if appt_3m>16 | appt_3m==. //up to March 2023

recode appt_year 1=2019
recode appt_year 2=2020
recode appt_year 3=2021
recode appt_year 4=2022
recode appt_year 5=2023

foreach var of varlist rheum_appt_medium {
	preserve
	keep if appt_year==`i'
	contract `var'
	gen count = round(_freq, 5)
	egen total = total(count)
	gen percent = round((count/total)*100, 0.1)
	order total, after(percent)
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
	list count percent total
	keep count percent total
	append using "$projectdir/output/data/consultation_medium_`i'.dta"
	save "$projectdir/output/data/consultation_medium_`i'.dta", replace
	restore
}

display `index'
display "`col'"
use "$projectdir/output/data/consultation_medium_`i'.dta", clear
export excel "$projectdir/output/tables/consultation_medium_rounded.xls", sheet("Overall", modify) cell("`col'1") keepcellfmt firstrow(variables)
}

*Output tables as CSVs		 
import excel "$projectdir/output/tables/table_1_rounded_bydiag.xls", clear
export delimited using "$projectdir/output/tables/table_1_rounded_bydiag.csv" , novarnames  replace		

import excel "$projectdir/output/tables/table_mean_bydiag_rounded.xls", clear
export delimited using "$projectdir/output/tables/table_mean_bydiag_rounded.csv" , novarnames  replace		

import excel "$projectdir/output/tables/table_median_bydiag_rounded.xls", clear
export delimited using "$projectdir/output/tables/table_median_bydiag_rounded.csv" , novarnames  replace		

import excel "$projectdir/output/tables/table_median_bydiag_rounded_to21.xls", clear
export delimited using "$projectdir/output/tables/table_median_bydiag_rounded_to21.csv" , novarnames  replace

import excel "$projectdir/output/tables/table_median_bydiag_rounded_to21_report.xls", clear
export delimited using "$projectdir/output/tables/table_median_bydiag_rounded_to21_report.csv" , novarnames  replace		

import excel "$projectdir/output/tables/ITSA_tables_appt_delay_rounded.xls", clear
export delimited using "$projectdir/output/tables/ITSA_tables_appt_delay_rounded.csv" , novarnames  replace		

import excel "$projectdir/output/tables/ITSA_tables_csdmard_delay_rounded.xls", clear
export delimited using "$projectdir/output/tables/ITSA_tables_csdmard_delay_rounded.csv" , novarnames  replace	

import excel "$projectdir/output/tables/drug_byyearanddisease_rounded.xls", clear
export delimited using "$projectdir/output/tables/drug_byyearanddisease_rounded.csv" , novarnames  replace		

import excel "$projectdir/output/tables/first_csdmard_rounded.xls", clear
export delimited using "$projectdir/output/tables/first_csdmard_rounded.csv" , novarnames  replace	

import excel "$projectdir/output/tables/first_csdmard_rounded_report.xls", clear
export delimited using "$projectdir/output/tables/first_csdmard_rounded_report.csv" , novarnames  replace	

import excel "$projectdir/output/tables/drug_byyearandregion_rounded.xls", clear
export delimited using "$projectdir/output/tables/drug_byyearandregion_rounded.csv" , novarnames  replace	

import excel "$projectdir/output/tables/referral_byregion_rounded.xls", clear
export delimited using "$projectdir/output/tables/referral_byregion_rounded.csv" , novarnames  replace		

import excel "$projectdir/output/tables/consultation_medium_rounded.xls", clear
export delimited using "$projectdir/output/tables/consultation_medium_rounded.csv" , novarnames  replace		

log close