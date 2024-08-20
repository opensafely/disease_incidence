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
global projectdir `c(pwd)'
di "$projectdir"

capture mkdir "$projectdir/output/data"
capture mkdir "$projectdir/output/tables"
capture mkdir "$projectdir/output/figures"

global logdir "$projectdir/logs"
di "$logdir"

**Open a log file
cap log close
log using "$logdir/redacted_tables_allpts.log", replace

**Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

set scheme plotplainblind

**Set index dates ===========================================================*/
global year_preceding = "01/04/2018"
global start_date = "01/04/2019"
global appt_date = "01/04/2021"
global end_date = "01/04/2023"

*Descriptive statistics======================================================================*/

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

log close