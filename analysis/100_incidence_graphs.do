version 16

/*==============================================================================
DO FILE NAME:			Incidence graphs
PROJECT:				OpenSAFELY Disease Incidence project
AUTHOR:					M Russell / J Galloway								
DESCRIPTION OF FILE:	Produces incidence graphs 
DATASETS USED:			Redacted counts
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
log using "$logdir/descriptive_tables.log", replace

*Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

global diseases "asthma copd chd stroke heart_failure dementia multiple_sclerosis epilepsy crohns_disease ulcerative_colitis dm_type2 ckd psoriasis atopic_dermatitis osteoporosis rheumatoid depression depression_broad coeliac pmr"

set type double

*Import rounded and redacted data for each disease
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

***Collapse age bands
bys disease mo_year_diagn measure: egen numerator_0_19 = sum(numerator_0_9 + numerator_10_19)
bys disease mo_year_diagn measure: egen numerator_20_39 = sum(numerator_20_29 + numerator_30_39)
bys disease mo_year_diagn measure: egen numerator_40_59 = sum(numerator_40_49 + numerator_50_59)
bys disease mo_year_diagn measure: egen numerator_60_79 = sum(numerator_60_69 + numerator_70_79)

bys disease mo_year_diagn measure: egen denominator_0_19 = sum(denominator_0_9 + denominator_10_19)
bys disease mo_year_diagn measure: egen denominator_20_39 = sum(denominator_20_29 + denominator_30_39)
bys disease mo_year_diagn measure: egen denominator_40_59 = sum(denominator_40_49 + denominator_50_59)
bys disease mo_year_diagn measure: egen denominator_60_79 = sum(denominator_60_69 + denominator_70_79)

gen rate_0_19 = (numerator_0_19/denominator_0_19)*100000
gen rate_20_39 = (numerator_20_39/denominator_20_39)*100000
gen rate_40_59 = (numerator_40_59/denominator_40_59)*100000
gen rate_60_79 = (numerator_60_79/denominator_60_79)*100000

**For age rate bands with >70% missing data, convert all in that age rate to missing
foreach disease in $diseases {
	di "`disease'"
	foreach var in rate_0_19 rate_20_39 rate_40_59 rate_60_79 rate_80 rate_0_9 rate_10_19 rate_20_29 rate_30_39 rate_40_49 rate_50_59 rate_60_69 rate_70_79 {
		di "`var'"
		quietly count if missing(`var') & disease == "`disease'" & measure == "Incidence"
		local num_missing = r(N)
		di `num_missing'
		
		quietly count if disease == "`disease'" & measure == "Incidence"  
		local total = r(N)
		di `total'
		
		local pct_missing = (`num_missing' / `total') * 100
		di `pct_missing'
		
		replace `var' = . if (`pct_missing' > 70) & disease == "`disease'" & measure == "Incidence"  
	} 
} 

**Convert missing age rates to zero
foreach var in rate_0_19 rate_20_39 rate_40_59 rate_60_79 rate_80 rate_0_9 rate_10_19 rate_20_29 rate_30_39 rate_40_49 rate_50_59 rate_60_69 rate_70_79 {
	recode `var' .=0 if `var' ==.
}

**Generate 3-monthly moving averages
bysort disease measure (mo_year_diagn): gen s_rate_all_ma =(s_rate_all[_n-1]+s_rate_all[_n]+s_rate_all[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_male_ma =(s_rate_male[_n-1]+s_rate_male[_n]+s_rate_male[_n+1])/3
bysort disease measure (mo_year_diagn): gen s_rate_female_ma =(s_rate_female[_n-1]+s_rate_female[_n]+s_rate_female[_n+1])/3

bysort disease measure (mo_year_diagn): gen rate_all_ma =(rate_all[_n-1]+rate_all[_n]+rate_all[_n+1])/3

bysort disease measure (mo_year_diagn): gen rate_0_9_ma =(rate_0_9[_n-1]+rate_0_9[_n]+rate_0_9[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_10_19_ma =(rate_10_19[_n-1]+rate_10_19[_n]+rate_10_19[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_20_29_ma =(rate_20_29[_n-1]+rate_20_29[_n]+rate_20_29[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_30_39_ma =(rate_30_39[_n-1]+rate_30_39[_n]+rate_30_39[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_40_49_ma =(rate_40_49[_n-1]+rate_40_49[_n]+rate_40_49[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_50_59_ma =(rate_50_59[_n-1]+rate_50_59[_n]+rate_50_59[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_60_69_ma =(rate_60_69[_n-1]+rate_60_69[_n]+rate_60_69[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_70_79_ma =(rate_70_79[_n-1]+rate_70_79[_n]+rate_70_79[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_80_ma =(rate_80[_n-1]+rate_80[_n]+rate_80[_n+1])/3

bysort disease measure (mo_year_diagn): gen rate_0_19_ma =(rate_0_19[_n-1]+rate_0_19[_n]+rate_0_19[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_20_39_ma =(rate_20_39[_n-1]+rate_20_39[_n]+rate_20_39[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_40_59_ma =(rate_40_59[_n-1]+rate_40_59[_n]+rate_40_59[_n+1])/3
bysort disease measure (mo_year_diagn): gen rate_60_79_ma =(rate_60_79[_n-1]+rate_60_79[_n]+rate_60_79[_n+1])/3

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

save "$projectdir/output/data/redacted_standardised.dta", replace

**Save subset of data for use with ARIMA
preserve
keep if measure=="Incidence"
rename s_rate_all incidence
rename numerator_all numerator
rename denominator_all denominator
keep disease year mo_year_diagn numerator denominator incidence
outsheet * using "$projectdir/output/tables/arima_standardised.csv", comma replace
export delimited using "$projectdir/output/tables/arima_standardised.csv", datafmt replace
restore

use "$projectdir/output/data/redacted_standardised.dta", clear

local index=1

levelsof disease, local(levels)
foreach disease_ of local levels {
	
	***Label diseases
	di "`disease_'"
	
    if "`disease_'" == "rheumatoid" {
		local disease_title "Rheumatoid Arthritis"
    }
	else if "`disease_'" == "copd" {
		local disease_title "COPD"
	}
	else if "`disease_'" == "crohns_disease" {
		local disease_title "Crohn's Disease"
	}
	else if "`disease_'" == "dm_type2" {
		local disease_title "Diabetes Mellitus Type 2"
	}
	else if "`disease_'" == "chd" {
		local disease_title "Coronary Heart Disease"
	}
	else if "`disease_'" == "ckd" {
		local disease_title "Chronic Kidney Disease"
	}
	else if "`disease_'" == "coeliac" {
		local disease_title "Coeliac Disease"
	}
	else if "`disease_'" == "pmr" {
		local disease_title "Polymyalgia Rheumatica"
	}
	else if "`disease_'" == "depression_broad" {
		local disease_title "Depression and depressive symptoms"
	}
	else if "`disease_'" == "stroke" {
		local disease_title "Stroke and TIA"
	}
	else {
		local disease_title = strproper(subinstr("`disease_'", "_", " ",.))
	}

	*Label y-axis (for combined graph)
	if `index' == 1 | `index' == 6 | `index' == 11 | `index' == 16 {
		local ytitle "Monthly incidence rate per 100,000"
		local ytitleprev "Annual prevalence per 100,000"
	}
	else {
		local ytitle ""
		local ytitleprev ""
	}

	*Label x-axis (for combined graph)
	if `index' == 16 | `index' == 17 | `index' == 18 | `index' == 19 {
		*local xtitle "Year"
		local xtitle ""
	}
	else {
		local xtitle ""
	}	
			
	*Incidence graphs
	preserve
	keep if measure=="Incidence"
	keep if disease == "`disease_'"
	
	***Set y-axis format
	egen s_rate_all_min = min(s_rate_all)
	if s_rate_all_min < 1 {
		local format = "format(%03.1f)"
	}
	else if s_rate_all_min >= 1 & s_rate_all_min < 10 {
		local format = "format(%9.2g)"
	}
	else {
		local format = "format(%9.0f)"
	}
	di "`format'"
	
	*Adjusted incidence overall with moving average (scatter)
	twoway scatter s_rate_all mo_year_diagn, ytitle("`ytitle'", size(medsmall)) color(emerald%20) msymbol(circle) || line s_rate_all_ma mo_year_diagn, lcolor(emerald) lstyle(solid) ylabel(, `format' nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(671 "2016" 695 "2018" 719 "2020" 743 "2022" 767 "2024" 779 " ", nogrid labsize(small)) title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(off) name("inc_adj_`index'", replace) saving("$projectdir/output/figures/inc_adj_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/inc_adj_`disease_'.png", replace
		graph export "$projectdir/output/figures/inc_adj_`disease_'.svg", replace
		
	*Adjusted incidence overall with moving average, by sex (scatter)
	twoway scatter s_rate_male mo_year_diagn, ytitle("`ytitle'", size(medsmall)) color(eltblue%20) mlcolor(eltblue%20) msymbol(circle) || line s_rate_male_ma mo_year_diagn, lcolor(midblue) lstyle(solid) || scatter s_rate_female mo_year_diagn, color(orange%20) mlcolor(orange%20) msymbol(circle)  || line s_rate_female_ma mo_year_diagn, lcolor(red) lstyle(solid) ylabel(, `format' nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(671 "2016" 695 "2018" 719 "2020" 743 "2022" 767 "2024" 779 " ", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(off) name(adj_sex_`index', replace) saving("$projectdir/output/figures/adj_sex_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/adj_sex_`disease_'.png", replace
		graph export "$projectdir/output/figures/adj_sex_`disease_'.svg", replace
		*legend(region(fcolor(white%0)) order(2 "Male" 4 "Female")) 

	*Adjusted incidence comparison
	twoway line rate_all_ma mo_year_diagn, ytitle("`ytitle'", size(medsmall)) lstyle(solid) lcolor(gold)  || line s_rate_all_ma mo_year_diagn, lstyle(solid) lcolor(emerald) ylabel(, `format' nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(671 "2016" 695 "2018" 719 "2020" 743 "2022" 767 "2024" 779 " ", nogrid labsize(small)) xline(722) title("`disease_title'", size(medium) margin(b=2)) legend(off) name(inc_comp_`index', replace) saving("$projectdir/output/figures/inc_comp_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/inc_comp_`disease_'.png", replace
		graph export "$projectdir/output/figures/inc_comp_`disease_'.svg", replace
		*legend(region(fcolor(white%0)) order(1 "Crude" 2 "Adjusted")) 
	
	*Unadjusted incidence overall with moving average, by 20-year age groups (lines only)
	twoway line rate_0_19_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) ytitle("`ytitle'", size(medsmall)) || line rate_20_39_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line rate_40_59_ma mo_year_diagn, lcolor(ebblue) lstyle(solid) || line rate_60_79_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line rate_80_ma mo_year_diagn, lcolor(navy) lstyle(solid) ylabel(, `format' nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(671 "2016" 695 "2018" 719 "2020" 743 "2022" 767 "2024" 779 " ", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(off) name(unadj_age_`index', replace) saving("$projectdir/output/figures/unadj_age_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/unadj_age_`disease_'.png", replace
		graph export "$projectdir/output/figures/unadj_age_`disease_'.svg", replace
		*legend(region(fcolor(white%0)) title("Age group", size(small) margin(b=1)) order(1 "0-19" 2 "20-39" 3 "40-59" 4 "60-79" 5 "80+"))		
	
	*Unadjusted incidence moving average, by IMD (lines only)
	twoway line rate_imd1_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) ytitle("`ytitle'", size(medsmall)) || line rate_imd2_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line rate_imd3_ma mo_year_diagn, lcolor(ebblue) lstyle(solid) || line rate_imd4_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line rate_imd5_ma mo_year_diagn, lcolor(navy) lstyle(solid) ylabel(, `format' nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(671 "2016" 695 "2018" 719 "2020" 743 "2022" 767 "2024" 779 " ", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(off) name(unadj_imd_`index', replace) saving("$projectdir/output/figures/unadj_imd_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/unadj_imd_`disease_'.png", replace
		graph export "$projectdir/output/figures/unadj_imd_`disease_'.svg", replace
		*legend(region(fcolor(white%0)) title("IMD quintile", size(small) margin(b=1)) order(1 "1 Most deprived" 2 "2" 3 "3" 4 "4" 5 "5 Least deprived"))
	restore		
	
	*Prevalence graphs
	preserve
	keep if measure=="Prevalence"
	keep if disease == "`disease_'"
	
	***Ranges for prevalence graphs
	egen s_rate_all_av = mean(s_rate_all)
	egen s_rate_male_max = max(s_rate_male)
	egen s_rate_male_min = min(s_rate_male)
	egen s_rate_female_max = max(s_rate_female)
	egen s_rate_female_min = min(s_rate_female)
	gen s_rate_max = max(s_rate_male_max, s_rate_female_max)
	gen s_rate_min = min(s_rate_male_min, s_rate_female_min)
	
	if s_rate_all_av < 1 {
		gen s_rate_all_low = round(0.80 * s_rate_min, 0.01)
		gen s_rate_all_up = round(1.20 * s_rate_max, 0.01)
	}
	else if s_rate_all_av >1 & s_rate_all_av < 10 {
		gen s_rate_all_low = round(0.80 * s_rate_min, 0.1)
		gen s_rate_all_up = round(1.20 * s_rate_max, 0.1)
	}
	else if s_rate_all_av >10 & s_rate_all_av < 100 {
		gen s_rate_all_low = round(0.80 * s_rate_min, 1)
		gen s_rate_all_up = round(1.20 * s_rate_max, 1)
	}
	else if s_rate_all_av >100 & s_rate_all_av < 1000 {
		gen s_rate_all_low = round(0.80 * s_rate_min, 10)
		gen s_rate_all_up = round(1.20 * s_rate_max, 10)
	}
	else if s_rate_all_av >1000 & s_rate_all_av < 10000 {
		gen s_rate_all_low = round(0.80 * s_rate_min, 100)
		gen s_rate_all_up = round(1.20 * s_rate_max, 100)
	}
	else if s_rate_all_av >10000 & s_rate_all_av < 100000 {
		gen s_rate_all_low = round(0.80 * s_rate_min, 1000)
		gen s_rate_all_up = round(1.20 * s_rate_max, 1000)
	}

	di s_rate_all_av
	local lower = s_rate_all_low
	di `lower'
	local upper = s_rate_all_up
	di `upper'
	nicelabels `lower' `upper', local(ylab)
	di "`ylab'"

	*Adjusted prevalence overall/male/female
	twoway connected s_rate_all year, ytitle("", size(med)) color(emerald%30) msymbol(circle) lcolor(emerald) lstyle(solid) ytitle("", size(medsmall)) || connected s_rate_male year, color(eltblue%30) msymbol(circle) lcolor(midblue) lstyle(solid) || connected s_rate_female year, color(orange%30) msymbol(circle) lcolor(red) lstyle(solid) ylabel("`ylab'", nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(2016(1)2023, nogrid) title("`disease_title'", size(medium) margin(b=2)) xline(2020) legend(off) name(prev_adj_`index', replace) saving("$projectdir/output/figures/prev_adj_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/prev_adj_`disease_'.png", replace
		graph export "$projectdir/output/figures/prev_adj_`disease_'.svg", replace
		*legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female"))
		
	*Adjusted prevalence comparison
	twoway connected rate_all year, ytitle("", size(med)) color(gold%30) msymbol(circle) lstyle(solid) lcolor(gold) ytitle("", size(medsmall)) || connected s_rate_all year, color(emerald%30) msymbol(circle) lstyle(solid) lcolor(emerald) ylabel("`ylab'", nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(2016(1)2023, nogrid) xline(2020) title("`disease_title'", size(medium) margin(b=2)) legend(off) name(prev_comp_`index', replace) saving("$projectdir/output/figures/prev_comp_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/prev_comp_`disease_'.png", replace
		graph export "$projectdir/output/figures/prev_comp_`disease_'.svg", replace
		*legend(region(fcolor(white%0)) order(1 "Crude" 2 "Adjusted"))

		restore			
	local `index++'
}

/*Combine graphs (Nb. this doesnt work in OpenSAFELY console)
preserve
cd "$projectdir/output/figures"

foreach stem in inc_adj adj_sex inc_comp unadj_age unadj_imd prev_adj prev_comp {
	graph combine `stem'_1 `stem'_2 `stem'_3 `stem'_4 `stem'_5 `stem'_6 `stem'_7 `stem'_8 `stem'_9 `stem'_10 `stem'_11 `stem'_12 `stem'_13 `stem'_14 `stem'_15 `stem'_16 `stem'_17 `stem'_18 `stem'_19, col(5) name(`stem'_combined, replace)
graph export "`stem'_combined.png", replace
graph export "`stem'_combined.tif", replace width(1800) height(1200)
}
restore
*/

**Do separate graphs for ethnicity due to smaller number of counts in some diseases
use "$projectdir/output/data/redacted_standardised.dta", clear

local index=1

levelsof disease, local(levels)
foreach disease_ of local levels {
	
	***Skip certain diseases and label yaxis incidence
	di "`disease_'"
	
    if "`disease_'" == "rheumatoid" {
		continue
    }
	else if "`disease_'" == "crohns_disease" {
		continue
	}
	else if "`disease_'" == "coeliac" {
		continue
	}
	else if "`disease_'" == "pmr" {
		continue
	}
	else if "`disease_'" == "epilepsy" {
		continue
    } 
	else if "`disease_'" == "multiple_sclerosis" {
		continue
    }
	else if "`disease_'" == "osteoporosis" {
		continue
    } 
	else if "`disease_'" == "ulcerative_colitis" {
		continue
	}
	else if "`disease_'" == "copd" {
		local disease_title "COPD"
	}
	else if "`disease_'" == "dm_type2" {
		local disease_title "Diabetes Mellitus Type 2"
	}
	else if "`disease_'" == "chd" {
		local disease_title "Coronary Heart Disease"
	}
	else if "`disease_'" == "ckd" {
		local disease_title "Chronic Kidney Disease"
	}
	else if "`disease_'" == "depression_broad" {
		local disease_title "Depression and depressive symptoms"
	}
	else if "`disease_'" == "stroke" {
		local disease_title "Stroke and TIA"
	}
	else {
		local disease_title = strproper(subinstr("`disease_'", "_", " ",.))
	}

	*Label y-axis (for combined graph)
	if `index' == 1 | `index' == 5 | `index' == 9 {
		local ytitle "Monthly incidence rate per 100,000"
	}
	else {
		local ytitle ""
	}

	*Label x-axis (for combined graph)
	if `index' == 9 | `index' == 10 | `index' == 11 {
		*local xtitle "Year"
		local xtitle ""
	}
	else {
		local xtitle ""
	}
			
	*Unadjusted incidence moving average, by ethnicity (lines only)
	preserve
	keep if measure=="Incidence"
	keep if disease == "`disease_'"
		
	***Set y-axis format
	egen s_rate_all_min = min(s_rate_all)
	if s_rate_all_min < 1 {
		local format = "format(%03.1f)"
	}
	else if s_rate_all_min >= 1 & s_rate_all_min < 10 {
		local format = "format(%9.2g)"
	}
	else {
		local format = "format(%9.0f)"
	}
	di "`format'"

	twoway line rate_white_ma mo_year_diagn, lcolor(ltblue) lstyle(solid) ytitle("`ytitle'", size(medsmall)) || line rate_mixed_ma mo_year_diagn, lcolor(eltblue) lstyle(solid) || line rate_black_ma mo_year_diagn, lcolor(ebblue) lstyle(solid) || line rate_asian_ma mo_year_diagn, lcolor(blue) lstyle(solid) || line rate_other_ma mo_year_diagn, lcolor(navy) lstyle(solid) ylabel(, `format' nogrid labsize(small)) xtitle("`xtitle'", size(medsmall) margin(medsmall)) xlabel(671 "2016" 695 "2018" 719 "2020" 743 "2022" 767 "2024" 779 " ", nogrid labsize(small))  title("`disease_title'", size(medium) margin(b=2)) xline(722) legend(off) name(unadj_ethn_`index', replace) saving("$projectdir/output/figures/unadj_ethn_`disease_'.gph", replace)
		*graph export "$projectdir/output/figures/unadj_ethn_`disease_'.png", replace
		graph export "$projectdir/output/figures/unadj_ethn_`disease_'.svg", replace
		*legend(region(fcolor(white%0)) title("Ethnicity", size(medsmall) margin(b=1)) order(1 "White" 2 "Mixed" 3 "Black" 4 "Asian" 5 "Chinese/Other"))	
	restore	
			
	local `index++'
}

/*Combine graphs - Nb. this doesn't work in OpenSAFELY console
preserve
cd "$projectdir/output/figures"

foreach stem in unadj_ethn {
	graph combine `stem'_1 `stem'_2 `stem'_3 `stem'_4 `stem'_5 `stem'_6 `stem'_7 `stem'_8 `stem'_9 `stem'_10 `stem'_11, col(4) name(`stem'_combined, replace)
graph export "`stem'_combined.png", replace
graph export "`stem'_combined.tif", replace width(1800) height(1200)
}
restore
*/

log close	
