version 16

/*==============================================================================
DO FILE NAME:			Incidence graphs
PROJECT:				OpenSAFELY Disease Incidence project
DATE: 					23/08/2024
AUTHOR:					J Galloway / M Russell									
DESCRIPTION OF FILE:	Produces data availability table 
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
log using "$logdir/data_avail_tables.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

set type double

*Import datasets for diseases
import delimited "$projectdir/output/dataset_definition_data_avail.csv", clear

*local diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 dm_type1 ckd psoriasis atopic_dermatitis osteoporosis hiv depression coeliac pmr"
local diseases "rheumatoid copd stroke heart_failure"
local variables "icd_inc_d sno_inc_d inc_d icd_last_d sno_last_d last_d res_d"

foreach disease in `diseases' {
	foreach var in `variables' {
		rename `disease'_`var' `disease'_`var'_s
		gen `disease'_`var' = .
		capture confirm numeric variable `disease'_`var'_s
		if _rc == 0 {
        	replace `disease'_`var' = date(string(`disease'_`var'_s), "YMD") if `disease'_`var'_s !=.
		}
		else {
			replace `disease'_`var' = date(`disease'_`var'_s, "YMD") if `disease'_`var'_s != ""	
		}
		format `disease'_`var' %td
		drop `disease'_`var'_s	
	}
	gen gp1_`disease' =1 if `disease'_sno_inc_d==`disease'_inc_d & `disease'_sno_inc_d!=.
	recode gp1_`disease' .=0
	gen ho1_`disease' =1 if `disease'_icd_inc_d==`disease'_inc_d & `disease'_icd_inc_d!=.
    recode ho1_`disease' .=0
	
	preserve
	gen hosp_`disease' = !missing(`disease'_icd_inc_d)
	gen gp_`disease' = !missing(`disease'_sno_inc_d)
	gen all_`disease' = !missing(`disease'_inc_d)

	gen year_diag=year(`disease'_inc_d)
	format year_diag %ty
	gen month_diag=month(`disease'_inc_d)
	gen mo_year_diagn=ym(year_diag, month_diag)
	format mo_year_diagn %tmMon-CCYY
	generate str16 mo_year_diagn_s = strofreal(mo_year_diagn,"%tmCCYY!mNN")
	lab var mo_year_diagn "Month/Year of Diagnosis"
	lab var mo_year_diagn_s "Month/Year of Diagnosis"
	collapse (sum) all_`disease'=all_`disease' ho1_`disease'=ho1_`disease' gp1_`disease'=gp1_`disease' hosp_`disease'=hosp_`disease' gp_`disease'=gp_`disease', by(mo_year_diagn)
	export delimited using "$projectdir/output/tables/data_check_`disease'.csv", datafmt replace
	restore
}

log off