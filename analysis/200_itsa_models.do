version 16

/*==============================================================================
DO FILE NAME:			ITSA models
PROJECT:				EIA OpenSAFELY project
DATE: 					07/03/2022
AUTHOR:					J Galloway / M Russell
						adapted from C Rentsch										
DESCRIPTION OF FILE:	ITSA models
DATASETS USED:			main data file
DATASETS CREATED: 		ITSA figures and outputs
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

**Set filepaths#
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
log using "$logdir/itsa_models.log", replace

**Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

**Use cleaned data from previous step
use "$projectdir/output/data/file_eia_all_ehrQL.dta", clear

set scheme plotplainblind

/*ITSA models for appt and referral times===========================================================================*/

*Restrict all analyses below to patients with rheum appt, GP appt and 6m follow-up and registration (changed from 12m requirement, for purposes of OpenSAFELY report)
keep if has_6m_post_appt==1

**Time from rheum referral to rheum appt (all diagnoses) - low rheumatology referral capture currently, therefore last GP appointment proxy being used currently (see below)
preserve
recode ref_appt_3w 2=0
lab var ref_appt_3w "Rheumatology assessment within 3 weeks of referral"
lab def ref_appt_3w 0 "No" 1 "Yes", modify
lab val ref_appt_3w ref_appt_3w
tab mo_year_appt ref_appt_3w, row  //proportion of patients with rheum assessment within 3 weeks of referral
collapse (mean) mean_ref_appt_delay=ref_appt_3w, by(mo_year_appt)

tsset mo_year_appt

**Newey Standard Errors with 5 lags
itsa mean_ref_appt_delay if inrange(mo_year_appt, tm(2019m4), tm(2023m03)), single trperiod(2020m4; 2021m4; 2022m4) lag(5) replace figure(title("", size(small)) subtitle("", size(medsmall)) ytitle("Mean proportion assessed within 3 weeks of referral", size(medsmall) margin(small)) ylabel(, nogrid) xtitle("Date of diagnosis", size(medsmall) margin(medsmall)) xlabel(711 "Apr 2019" 717 "Oct 2019" 723 "Apr 2020" 729 "Oct 2020" 735 "Apr 2021" 741 "Oct 2021" 747 "Apr 2022" 753 "Oct 2022" 759 "Apr 2023", nogrid) note("", size(v.small)) legend(off)) posttrend 
	graph export "$projectdir/output/figures/ITSA_diagnostic_delay_newey.svg", as(svg) replace
actest, lag(18)	

**Prais-Winsten	
itsa mean_ref_appt_delay if inrange(mo_year_appt, tm(2019m4), tm(2023m03)), single trperiod(2020m4; 2021m4; 2022m4) replace prais rhotype(tscorr) vce(robust) figure(title("", size(small)) subtitle("", size(medsmall)) ytitle("Mean proportion assessed within 3 weeks of referral", size(medsmall) margin(small)) ylabel(, nogrid) xtitle("Date of diagnosis", size(medsmall) margin(medsmall)) xlabel(711 "Apr 2019" 717 "Oct 2019" 723 "Apr 2020" 729 "Oct 2020" 735 "Apr 2021" 741 "Oct 2021" 747 "Apr 2022" 753 "Oct 2022" 759 "Apr 2023", nogrid) note("", size(v.small)) legend(off)) posttrend 
	graph export "$projectdir/output/figures/ITSA_diagnostic_delay_prais.svg", as(svg) replace	
restore

**Time from last GP (pre-rheum appt) to rheum appt (all diagnoses)
preserve
recode gp_appt_3w 2=0
lab var gp_appt_3w "Rheumatology assessment within 3 weeks of referral"
lab def gp_appt_3w 0 "No" 1 "Yes", modify
lab val gp_appt_3w gp_appt_3w
tab mo_year_appt gp_appt_3w, row  //proportion of patients with rheum appointment within 3 weeks of last GP appointment
eststo X: estpost tabstat gp_appt_3w, stat(n mean) by(mo_year_appt_s)
esttab X using "$projectdir/output/tables/gp_to_appt_ITSA_table.csv", cells("count mean") collabels("Count" "Mean proportion") replace plain nomtitle noobs
collapse (mean) mean_gp_appt_delay=gp_appt_3w, by(mo_year_appt)

**for table with rounded values - see ITSA_tables_rounded

tsset mo_year_appt

**Newey Standard Errors with 5 lags
itsa mean_gp_appt_delay if inrange(mo_year_appt, tm(2019m4), tm(2023m03)), single trperiod(2020m4; 2021m4; 2022m4) lag(5) replace figure(title("", size(small)) subtitle("", size(medsmall)) ytitle("Mean proportion assessed within 3 weeks of referral", size(small) margin(small)) yscale(range(0.2(0.1)0.8)) ylabel(0.2(0.1)0.8, format(%03.1f) nogrid labsize(vsmall)) xtitle("Date of first rheumatology appointment", size(small) margin(medsmall)) xlabel(711 "Apr 2019" 717 "Oct 2019" 723 "Apr 2020" 729 "Oct 2020" 735 "Apr 2021" 741 "Oct 2021" 747 "Apr 2022" 753 "Oct 2022" 759 "Apr 2023", nogrid labsize(vsmall)) note("", size(v.small)) legend(off)) posttrend 
	graph export "$projectdir/output/figures/ITSA_diagnostic_delay_GP_newey.svg", width(12in) as(svg) replace
actest, lag(18)	

**Prais-Winsten	
itsa mean_gp_appt_delay if inrange(mo_year_appt, tm(2019m4), tm(2023m03)), single trperiod(2020m4; 2021m4; 2022m4) replace prais rhotype(tscorr) vce(robust) figure(title("", size(small)) subtitle("", size(medsmall)) ytitle("Mean proportion assessed within 3 weeks of referral", size(small) margin(small)) yscale(range(0.2(0.1)0.8)) ylabel(0.2(0.1)0.8, format(%03.1f) nogrid) xtitle("Date of first rheumatology appointment", size(small) margin(medsmall)) xlabel(711 "Apr 2019" 717 "Oct 2019" 723 "Apr 2020" 729 "Oct 2020" 735 "Apr 2021" 741 "Oct 2021" 747 "Apr 2022" 753 "Oct 2022" 759 "Apr 2023", nogrid) note("", size(v.small)) legend(off)) posttrend 
	graph export "$projectdir/output/figures/ITSA_diagnostic_delay_GP_prais.svg", as(svg) replace	
restore

log close