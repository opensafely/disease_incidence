version 16

/*==============================================================================
DO FILE NAME:			Incidence graphs
PROJECT:				OpenSAFELY Disease Incidence project
DATE: 					23/08/2024
AUTHOR:					J Galloway / M Russell									
DESCRIPTION OF FILE:	Produces incidence graphs 
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
log using "$logdir/descriptive_tables.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

*Import redacted data for each disease
*global diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 ckd psoriasis atopic_dermatitis osteoporosis rheumatoid depression coeliac pmr"
global diseases "rheumatoid pmr"
local first_disease: word 1 of $diseases
di "`first_disease'"

**Import first file as base dataset
import delimited "$projectdir/output/tables/redacted_counts_`first_disease'.csv", clear
save "$projectdir/output/data/redacted_standardised.dta", replace

**Loop over diseases and years
foreach disease in $diseases {
	if "`disease'" != "`first_disease'"  {
		import delimited "$projectdir/output/tables/redacted_counts_`disease'.csv", clear
		append using "$projectdir/output/data/redacted_standardised.dta"
		save "$projectdir/output/data/redacted_standardised.dta", replace 
		}
}

set scheme plotplainblind

*Produce graphs======================================================================*/

use "$projectdir/output/data/redacted_standardised.dta", clear

gen mo_year_diagn_s = monthly(mo_year_diagn, "MY") 
format mo_year_diagn_s %tmMon-CCYY
drop mo_year_diagn
rename mo_year_diagn_s mo_year_diagn
order mo_year_diagn, after(measure)
gen year=yofd(dofm(mo_year_diagn))
order year, after(mo_year_diagn)

**Generate 3-monthly moving averages
bysort disease measure (mo_year_diagn): gen s_rate_all_ma =(s_rate_all[_n-1]+s_rate_all[_n]+s_rate_all[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_male_ma =(s_rate_male[_n-1]+s_rate_male[_n]+s_rate_male[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_female_ma =(s_rate_female[_n-1]+s_rate_female[_n]+s_rate_female[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_0_9_ma =(s_rate_0_9[_n-1]+s_rate_0_9[_n]+s_rate_0_9[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_10_19_ma =(s_rate_10_19[_n-1]+s_rate_10_19[_n]+s_rate_10_19[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_20_29_ma =(s_rate_20_29[_n-1]+s_rate_20_29[_n]+s_rate_20_29[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_30_39_ma =(s_rate_30_39[_n-1]+s_rate_30_39[_n]+s_rate_30_39[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_40_49_ma =(s_rate_40_49[_n-1]+s_rate_40_49[_n]+s_rate_40_49[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_50_59_ma =(s_rate_50_59[_n-1]+s_rate_50_59[_n]+s_rate_50_59[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_60_69_ma =(s_rate_60_69[_n-1]+s_rate_60_69[_n]+s_rate_60_69[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_70_79_ma =(s_rate_70_79[_n-1]+s_rate_70_79[_n]+s_rate_70_79[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_80_ma =(s_rate_80[_n-1]+s_rate_80[_n]+s_rate_80[_n+1])/3

bysort disease measure (mo_year_diagn): gen rate_0_9_ma =(rate_0_9[_n-1]+rate_0_9[_n]+rate_0_9[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_10_19_ma =(rate_10_19[_n-1]+rate_10_19[_n]+rate_10_19[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_20_29_ma =(rate_20_29[_n-1]+rate_20_29[_n]+rate_20_29[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_30_39_ma =(rate_30_39[_n-1]+rate_30_39[_n]+rate_30_39[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_40_49_ma =(rate_40_49[_n-1]+rate_40_49[_n]+rate_40_49[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_50_59_ma =(rate_50_59[_n-1]+rate_50_59[_n]+rate_50_59[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_60_69_ma =(rate_60_69[_n-1]+rate_60_69[_n]+rate_60_69[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_70_79_ma =(rate_70_79[_n-1]+rate_70_79[_n]+rate_70_79[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_80_ma =(rate_80[_n-1]+rate_80[_n]+rate_80[_n+1])/3

bysort disease measure (mo_year_diagn): gen rate_white_ma =(rate_white[_n-1]+rate_white[_n]+rate_white[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_mixed_ma =(rate_mixed[_n-1]+rate_mixed[_n]+rate_mixed[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_black_ma =(rate_black[_n-1]+rate_black[_n]+rate_black[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_asian_ma =(rate_asian[_n-1]+rate_asian[_n]+rate_asian[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_other_ma =(rate_other[_n-1]+rate_other[_n]+rate_other[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_ethunk_ma =(rate_ethunk[_n-1]+rate_ethunk[_n]+rate_ethunk[_n+1])/3

bysort disease measure (mo_year_diagn): gen rate_imd1_ma =(rate_imd1[_n-1]+rate_imd1[_n]+rate_imd1[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_imd2_ma =(rate_imd2[_n-1]+rate_imd2[_n]+rate_imd2[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_imd3_ma =(rate_imd3[_n-1]+rate_imd3[_n]+rate_imd3[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_imd4_ma =(rate_imd4[_n-1]+rate_imd4[_n]+rate_imd4[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_imd5_ma =(rate_imd5[_n-1]+rate_imd5[_n]+rate_imd5[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_imdunk_ma =(rate_imdunk[_n-1]+rate_imdunk[_n]+rate_imdunk[_n+1])/3

**Save subset of data for use with ARIMA
preserve
keep if measure=="Incidence"
rename s_rate_all incidence
rename numerator_all numerator
rename denominator_all denominator
rename disease diseases_
gen disease = strproper(subinstr(diseases_, "_", " ",.)) 
order disease, before(diseases_)
keep disease year mo_year_diagn numerator denominator incidence
outsheet * using "$projectdir/output/tables/arima_standardised.csv", comma replace
restore

levelsof disease_full, local(levels)
foreach disease_ of local levels {
	
	di "`disease_'"
	local disease_title = strproper(subinstr("`disease_'", "_", " ",.)) 

	*Adjusted incidence comparison
	preserve
	keep if measure=="Incidence"
	keep if disease_full == "`disease_'"

	twoway connected rate_all mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(gold%35) msymbol(circle) lstyle(solid) lcolor(gold)  || connected s_rate_all mo_year_diagn, color(emerald%35) msymbol(circle) lstyle(solid) lcolor(emerald) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small)) xline(722) title("`disease_title'", size(medium) margin(b=2)) legend(region(fcolor(white%0)) order(1 "Crude" 2 "Adjusted")) name(inc_comp, replace) saving("$projectdir/output/figures/`disease_'_inc_comp.gph", replace)
		graph export "$projectdir/output/figures/inc_comp_`disease_'.svg", replace
	restore		
			
	*Adjusted prevalence comparison
	preserve
	keep if measure=="Prevalence"
	keep if disease_full == "`disease_'"

	twoway connected rate_all year, ytitle("Prevalence per 100,000 population", size(med)) color(gold%35) msymbol(circle) lstyle(solid) lcolor(gold) || connected s_rate_all year, color(emerald%35) msymbol(circle) lstyle(solid) lcolor(emerald) ylabel(, nogrid labsize(small)) xtitle("Year beginning", size(medium) margin(medsmall)) xlabel(2016(1)2023, nogrid) xline(2020) title("`disease_title'", size(medium) margin(b=2)) legend(region(fcolor(white%0)) order(1 "Crude" 2 "Adjusted")) name(prev_comp, replace) saving("$projectdir/output/figures/`disease_'_prev_comp.gph", replace)
		graph export "$projectdir/output/figures/prev_comp_`disease_'.svg", replace
	restore		
	
	*Adjusted prevalence overall/male/female
	preserve
	keep if measure=="Prevalence"
	keep if disease_full == "`disease_'"

	twoway connected s_rate_all year, ytitle("Prevalence per 100,000 population", size(med)) color(emerald%35) msymbol(circle) lcolor(emerald) lstyle(solid) || connected s_rate_male year, color(eltblue%35) msymbol(circle) lcolor(midblue) lstyle(solid) || connected s_rate_female year, color(orange%35) msymbol(circle) lcolor(red) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Year beginning", size(medium) margin(medsmall)) xlabel(2016(1)2023, nogrid) title("`disease_title'", size(medium) margin(b=2)) xline(2020) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(prev_adj, replace) saving("$projectdir/output/figures/`disease_'_prev_adj.gph", replace)
		graph export "$projectdir/output/figures/prev_adj_`disease_'.svg", replace
	restore	

	*Adjusted incidence overall with moving average (scatter)
	preserve
	keep if measure=="Incidence"
	keep if disease_full == "`disease_'"

	twoway scatter s_rate_all mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(emerald%35) msymbol(circle) || line s_rate_all_ma mo_year_diagn, lcolor(emerald) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small)) title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(off) name(inc_adj, replace) saving("$projectdir/output/figures/`disease_'_inc_adj.gph", replace)
		graph export "$projectdir/output/figures/inc_adj_`disease_'.svg", replace
	restore	
	
	*Adjusted incidence overall with moving average, by sex (scatter)
	preserve
	keep if measure=="Incidence"
	keep if disease_full == "`disease_'"

	twoway scatter s_rate_male mo_year_diagn, ytitle("Monthly incidence per 100,000 population", size(med)) color(eltblue%35) mlcolor(eltblue%35) msymbol(circle) || line s_rate_male_ma mo_year_diagn, lcolor(midblue) lstyle(solid) || scatter s_rate_female mo_year_diagn, color(orange%35) mlcolor(orange%35) msymbol(circle)  || line s_rate_female_ma mo_year_diagn, lcolor(red) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(region(fcolor(white%0)) order(1 "Male" 3 "Female")) name(adj_sex, replace) saving("$projectdir/output/figures/`disease_'_adj_sex.gph", replace)
		graph export "$projectdir/output/figures/adj_sex_`disease_'.svg", replace
	restore		
	
*Adjusted incidence overall with moving average, by age group (lines only)
	preserve
	keep if measure=="Incidence"
	keep if disease_full == "`disease_'"

	twoway line s_rate_0_9_ma mo_year_diagn, lcolor(gold) lstyle(solid) ytitle("Monthly incidence per 100,000 population", size(med)) || line s_rate_10_19_ma mo_year_diagn, lcolor(orange) lstyle(solid) || line s_rate_20_29_ma mo_year_diagn, lcolor(red) lstyle(solid) || line s_rate_30_39_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) || line s_rate_40_49_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line s_rate_50_59_ma mo_year_diagn, lcolor(ebblue) lstyle(solid) || line s_rate_60_69_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line s_rate_70_79_ma mo_year_diagn, lcolor(navy) lstyle(solid) || line s_rate_80_ma mo_year_diagn, lcolor(black) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(region(fcolor(white%0)) title("Age group", size(small) margin(b=1)) order(1 "0-9" 2 "10-19" 3 "20-29" 4 "30-39" 5 "40-49" 6 "50-59" 7 "60-69" 8 "70-79" 9 "80+")) name(adj_age, replace) saving("$projectdir/output/figures/`disease_'_adj_age.gph", replace)
		graph export "$projectdir/output/figures/adj_age_`disease_'.svg", replace
	restore	
	
*Unadjusted incidence moving average, by ethnicity (lines only)
	preserve
	keep if measure=="Incidence"
	keep if disease_full == "`disease_'"

	twoway line rate_white_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) ytitle("Monthly incidence per 100,000 population", size(med)) || line rate_mixed_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line rate_black_ma mo_year_diagn, lcolor(ebblue) lstyle(solid) || line rate_asian_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line rate_other_ma mo_year_diagn, lcolor(navy) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(region(fcolor(white%0)) title("Ethnicity", size(small) margin(b=1)) order(1 "White" 2 "Mixed" 3 "Black" 4 "Asian" 5 "Other")) name(unadj_ethn, replace) saving("$projectdir/output/figures/`disease_'_unadj_ethn.gph", replace)
		graph export "$projectdir/output/figures/unadj_ethn_`disease_'.svg", replace
	restore	
	
*Unadjusted incidence moving average, by IMD (lines only)
	preserve
	keep if measure=="Incidence"
	keep if disease_full == "`disease_'"

	twoway line rate_imd1_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) ytitle("Monthly incidence per 100,000 population", size(med)) || line rate_imd2_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line rate_imd3_ma mo_year_diagn, lcolor(ebblue) lstyle(solid) || line rate_imd4_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line rate_imd5_ma mo_year_diagn, lcolor(navy) lstyle(solid) ylabel(, nogrid labsize(small)) xtitle("Date of diagnosis", size(medium) margin(medsmall)) xlabel(671 "2016" 683 "2017" 695 "2018" 707 "2019" 719 "2020" 731 "2021" 743 "2022" 755 "2023" 767 "2024" 779 "2025", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(region(fcolor(white%0)) title("IMD quintile", size(small) margin(b=1)) order(1 "1 Most deprived" 2 "2" 3 "3" 4 "4" 5 "5 Least deprived")) name(unadj_imd, replace) saving("$projectdir/output/figures/`disease_'_unadj_imd.gph", replace)
		graph export "$projectdir/output/figures/unadj_imd_`disease_'.svg", replace
	restore	
}

log close	
