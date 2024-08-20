version 16

/*==============================================================================
DO FILE NAME:			define covariates using ehrQL definition
PROJECT:				EIA OpenSAFELY project
DATE: 					03/10/2023
AUTHOR:					M Russell									
DESCRIPTION OF FILE:	data management for EIA project  
						reformat variables 
						categorise variables
						label variables 
DATASETS USED:			data in memory (from output/dataset.csv)
DATASETS CREATED: 		analysis files
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

**Set filepaths
*global projectdir "C:\Users\k1754142\OneDrive\PhD Project\OpenSAFELY\Github Practice"
*global projectdir "C:\Users\Mark\OneDrive\PhD Project\OpenSAFELY\Github Practice"
global projectdir `c(pwd)'

capture mkdir "$projectdir/output/data"
capture mkdir "$projectdir/output/figures"
capture mkdir "$projectdir/output/tables"

global logdir "$projectdir/logs"

**Open a log file
cap log close
log using "$logdir/cleaning_dataset_ehrQL.log", replace

di "$projectdir"
di "$logdir"

import delimited "$projectdir/output/dataset.csv", clear

**Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

**Set index dates ===========================================================*/
global year_preceding = "01/04/2018"
global start_date = "01/04/2019"
global end_date = "01/10/2023"

**Rename variables (some are too long for Stata to handle) =======================================*/
rename chronic_respiratory_disease chronic_resp_disease

/*
**Convert date strings to dates ====================================================*
***Some dates are given with month/year only, so adding day 15 to enable them to be processed as dates 

foreach var of varlist 	 abatacept_date						///
						 adalimumab_date					///	
						 baricitinib_date					///
						 certolizumab_date					///
						 etanercept_date					///
						 golimumab_date						///
						 guselkumab_date					///	
						 infliximab_date					///
						 ixekizumab_date					///
						 methotrexate_hcd_date				///
						 rituximab_date						///
						 sarilumab_date						///
						 secukinumab_date					///	
						 tocilizumab_date					///
						 tofacitinib_date					///
						 upadacitinib_date					///
						 ustekinumab_date					///
						 {
						 	
		capture confirm string variable `var'
		if _rc!=0 {
			assert `var'==.
			rename `var' `var'_date
		}
	
		else {
				replace `var' = `var' + "-15"
				rename `var' `var'_dstr
				replace `var'_dstr = " " if `var'_dstr == "-15"
				gen `var'_date = date(`var'_dstr, "YMD") 
				order `var'_date, after(`var'_dstr)
				drop `var'_dstr
		}
	
	format `var'_date %td
}

*/

**Conversion for dates ====================================================*

foreach var of varlist 	 died_date							///
						 died_date_ons						///
					     eia_code_date 						///
						 rheum_appt_date					///
						 rheum_appt_any_date				///
						 rheum_appt2_date					///
						 rheum_appt3_date					///
					     ra_code_date						///
						 psa_code_date						///
						 anksp_code_date					///
						 undiff_code_date					///
						 last_gp_prerheum_date				///
						 last_gp_precode_date				///	
						 last_gp_refrheum_date				///
						 last_gp_refcode_date				///
						 curr_reg_start						///
						 curr_reg_end						///
						 referral_rheum_prerheum			///
						 referral_rheum_precode				///	
						 chronic_cardiac_disease			///
						 diabetes							///
						 hba1c_mmol_per_mol_date 			///
						 hba1c_percentage_date				///
						 hypertension						///	
						 chronic_resp_disease				///
						 copd								///
						 chronic_liver_disease				///
						 stroke								///
						 lung_cancer						///
						 haem_cancer						///
						 other_cancer						///
						 esrf								///
						 creatinine_date					///
						 bmi_date							///
						 hydroxychloroquine_date			///
						 leflunomide_date					///
						 methotrexate_date					///
						 methotrexate_inj_date				///
						 sulfasalazine_date					///
						 {
						 		 
		capture confirm string variable `var'
		if _rc!=0 {
			assert `var'==.
			rename `var' `var'_date
		}
	
		else {
				rename `var' `var'_dstr
				gen `var'_date = date(`var'_dstr, "YMD") 
				order `var'_date, after(`var'_dstr)
				drop `var'_dstr
				*gen `var'_date15 = `var'_date+15  //don't need this unless high-cost drugs data used
				*order `var'_date15, after(`var'_date)
				*drop `var'_date
				*rename `var'_date15 `var'_date
		}
	
	format `var'_date %td
}

**Rename variables with extra 'date' added to the end of variable names===========================================================*/ 
rename rheum_appt_date_date rheum_appt_date
rename rheum_appt2_date_date rheum_appt2_date
rename rheum_appt3_date_date rheum_appt3_date
rename rheum_appt_any_date_date rheum_appt_any_date
rename eia_code_date_date eia_code_date
rename ra_code_date_date ra_code_date
rename psa_code_date_date psa_code_date
rename anksp_code_date_date anksp_code_date
rename undiff_code_date_date undiff_code_date
rename died_date_date died_date
rename died_date_ons_date died_ons_date
rename last_gp_prerheum_date_date last_gp_prerheum_date
rename last_gp_refrheum_date_date last_gp_refrheum_date
rename last_gp_refcode_date_date last_gp_refcode_date
rename last_gp_precode_date_date last_gp_precode_date
rename hba1c_mmol_per_mol_date_date hba1c_mmol_per_mol_date
rename hba1c_percentage_date_date hba1c_percentage_date
rename creatinine_date_date creatinine_date
rename creatinine creatinine_value 
rename bmi_date_date bmi_date
rename bmi bmi_value
rename hydroxychloroquine_date_date hydroxychloroquine_date	
rename leflunomide_date_date leflunomide_date					
rename methotrexate_date_date methotrexate_date					
rename methotrexate_inj_date_date methotrexate_inj_date				
rename sulfasalazine_date_date sulfasalazine_date		

						 
**Create binary indicator variables for relevant conditions ====================================================*/
//High-cost drugs removed from below

foreach var of varlist 	 eia_code_date 						///
						 rheum_appt_date					///
						 rheum_appt2_date					///
						 rheum_appt3_date					///
						 rheum_appt_any_date				///
					     ra_code_date						///
						 psa_code_date						///
						 anksp_code_date					///
						 undiff_code_date					///
						 died_date							///
						 died_ons_date						///
						 last_gp_prerheum_date				///
						 last_gp_precode_date				///	
						 last_gp_refrheum_date				///
						 last_gp_refcode_date				///
						 referral_rheum_prerheum_date		///
						 referral_rheum_precode_date		///	
						 chronic_cardiac_disease_date		///
						 diabetes_date						///
						 hypertension_date					///
						 chronic_resp_disease_date			///
						 copd_date							///
						 chronic_liver_disease_date			///
						 stroke_date						///
						 lung_cancer_date					///
						 haem_cancer_date					///		
						 other_cancer_date					///
						 esrf_date							///
						 creatinine_date					///
						 hydroxychloroquine_date			///	
						 leflunomide_date					///
						 methotrexate_date					///
						 methotrexate_inj_date				///		
						 sulfasalazine_date					///
 {				
	/*date ranges are applied in definition, so presence of date indicates presence of 
	  disease in the correct time frame*/ 
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'!=. )
	order `newvar', after(`var')
}

**Create and label variables ===========================================================*/

**Demographics
***Sex
gen male = 1 if sex == "male"
replace male = 0 if sex == "female"
lab var male "Male"
lab define male 0 "No" 1 "Yes", modify
lab val male male
tab male, missing

***Ethnicity
replace ethnicity = .u if ethnicity == .
****rearrange in order of prevalence
recode ethnicity 2=6 /* mixed to 6 */
recode ethnicity 3=2 /* south asian to 2 */
recode ethnicity 4=3 /* black to 3 */
recode ethnicity 6=4 /* mixed to 4 */
recode ethnicity 5=4 /* other to 4 */

label define ethnicity 	1 "White"  					///
						2 "Asian/Asian British"		///
						3 "Black"  					///
						4 "Mixed/Other"				///
						.u "Not known"
label values ethnicity ethnicity
lab var ethnicity "Ethnicity"
tab ethnicity, missing

/*
***STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp) //
drop stp_old
*/

***Regions
encode region, gen(nuts_region)
tab region, missing
replace region="Not known" if region==""
gen region_nospace=region
replace region_nospace="SouthWest" if region=="South West"
replace region_nospace="EastMidlands" if region=="East Midlands"
replace region_nospace="East" if region=="East"
replace region_nospace="London" if region=="London"
replace region_nospace="NorthEast" if region=="North East"
replace region_nospace="NorthWest" if region=="North West"
replace region_nospace="SouthEast" if region=="South East"
replace region_nospace="WestMidlands" if region=="West Midlands"
replace region_nospace="YorkshireandTheHumber" if region=="Yorkshire and The Humber"

***IMD
label define imd 1 "1 most deprived" 2 "2" 3 "3" 4 "4" 5 "5 least deprived" .u "Not known"
label values imd imd 
lab var imd "Index of multiple deprivation"
tab imd, missing

***Age variables
*Nb. works if ages 18 and over
*Create categorised age
drop if age<18 & age !=.
drop if age>109 & age !=.
drop if age==.
lab var age "Age"

recode age 18/39.9999 = 1 /// 
           40/49.9999 = 2 ///
		   50/59.9999 = 3 ///
	       60/69.9999 = 4 ///
		   70/79.9999 = 5 ///
		   80/max = 6, gen(agegroup) 

label define agegroup 	1 "18-39" ///
						2 "40-49" ///
						3 "50-59" ///
						4 "60-69" ///
						5 "70-79" ///
						6 "80+"
						
label values agegroup agegroup
lab var agegroup "Age group"
tab agegroup, missing

***Body Mass Index
*Recode strange values 
replace bmi_value = . if bmi_value == 0 
replace bmi_value = . if !inrange(bmi_value, 10, 80)

*Restrict to within 10 years of EIA diagnosis date and aged>16 
gen bmi_time = (eia_code_date - bmi_date)/365.25
gen bmi_age = age - bmi_time
replace bmi_value = . if bmi_age < 16 
replace bmi_value = . if bmi_time > 10 & bmi_time != . 

*Set to missing if no date, and vice versa 
replace bmi_value = . if bmi_date == . 
replace bmi_date = . if bmi_value == . 
replace bmi_time = . if bmi_value == . 
replace bmi_age = . if bmi_value == . 

*Create BMI categories
gen 	bmicat = .
recode  bmicat . = 1 if bmi_value < 18.5
recode  bmicat . = 2 if bmi_value < 25
recode  bmicat . = 3 if bmi_value < 30
recode  bmicat . = 4 if bmi_value < 35
recode  bmicat . = 5 if bmi_value < 40
recode  bmicat . = 6 if bmi_value < .
replace bmicat = .u if bmi_value >= .

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			///
					.u "Not known"
					
label values bmicat bmicat
lab var bmicat "BMI"
tab bmicat, missing

*Create less granular categorisation
recode bmicat 1/3 .u = 1 4 = 2 5 = 3 6 = 4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		

label values obese4cat obese4cat
order obese4cat, after(bmicat)

***Smoking 
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Not known"

gen     smoke = 1  if smoking_status == "N"
replace smoke = 2  if smoking_status == "E"
replace smoke = 3  if smoking_status == "S"
replace smoke = .u if smoking_status == "M"
replace smoke = .u if smoking_status == "" 

label values smoke smoke
lab var smoke "Smoking status"
drop smoking_status
tab smoke, missing

*Create non-missing 3-category variable for current smoking (assumes missing smoking is never smoking)
recode smoke .u = 1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke

**Clinical comorbidities
***eGFR
*Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine_value = . if !inrange(creatinine_value, 20, 3000) 

*Remove creatinine dates if no measurements, and vice versa 
replace creatinine_value = . if creatinine_date == . 
replace creatinine_date = . if creatinine_value == . 
replace creatinine = . if creatinine_value == .
recode creatinine .=0
tab creatinine, missing

*Divide by 88.4 (to convert umol/l to mg/dl) 
gen SCr_adj = creatinine_value/88.4

gen min = .
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no ethnicity"

*Categorise into ckd stages
egen egfr_cat_all = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat_all 0 = 5 15 = 4 30 = 3 45 = 2 60 = 0, generate(ckd_egfr)

gen egfr_cat = .
recode egfr_cat . = 3 if egfr < 30
recode egfr_cat . = 2 if egfr < 60
recode egfr_cat . = 1 if egfr < .
replace egfr_cat = .u if egfr >= .

label define egfr_cat 	1 ">=60" 		///
						2 "30-59"		///
						3 "<30"			///
						.u "Not known"
					
label values egfr_cat egfr_cat
lab var egfr_cat "eGFR"
tab egfr_cat, missing

*If missing eGFR, assume normal
gen egfr_cat_nomiss = egfr_cat
replace egfr_cat_nomiss = 1 if egfr_cat == .u

label define egfr_cat_nomiss 	1 ">=60/not known" 	///
								2 "30-59"			///
								3 "<30"	
label values egfr_cat_nomiss egfr_cat_nomiss
lab var egfr_cat_nomiss "eGFR"
tab egfr_cat_nomiss, missing

gen egfr_date = creatinine_date
format egfr_date %td

*Add in end stage renal failure and create a single CKD variable 
*Missing assumed to not have CKD 
gen ckd = 0
replace ckd = 1 if ckd_egfr != . & ckd_egfr >= 1
replace ckd = 1 if esrf == 1

label define ckd 0 "No" 1 "Yes"
label values ckd ckd
label var ckd "Chronic kidney disease"
tab ckd, missing

*Create date (most recent measure prior to index)
gen temp1_ckd_date = creatinine_date if ckd_egfr >=1
gen temp2_ckd_date = esrf_date if esrf == 1
gen ckd_date = max(temp1_ckd_date,temp2_ckd_date) 
format ckd_date %td 

drop temp1_ckd_date temp2_ckd_date SCr_adj min max ckd_egfr egfr_cat_all

***HbA1c
*Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage <= 0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0

*Change implausible values to missing
replace hba1c_percentage   = . if !inrange(hba1c_percentage, 1, 20)
replace hba1c_mmol_per_mol = . if !inrange(hba1c_mmol_per_mol, 10, 200)

*Set most recent values of >24 months prior to EIA diagnosis date to missing
replace hba1c_percentage   = . if (eia_code_date - hba1c_percentage_date) > 24*30 & hba1c_percentage_date != .
replace hba1c_mmol_per_mol = . if (eia_code_date - hba1c_mmol_per_mol_date) > 24*30 & hba1c_mmol_per_mol_date != .

*Clean up dates
replace hba1c_percentage_date = . if hba1c_percentage == .
replace hba1c_mmol_per_mol_date = . if hba1c_mmol_per_mol == .

*Express  HbA1c as percentage
*Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

*Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 1, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)

*Categorise HbA1c and diabetes
*Group hba1c pct
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
tab hba1ccat, missing

*Express all values as mmol
gen hba1c_mmol = hba1c_mmol_per_mol
replace hba1c_mmol = (hba1c_percentage*10.929)-23.5 if hba1c_percentage<. & hba1c_mmol==.

*Group hba1c mmol
gen 	hba1ccatmm = 0 if hba1c_mmol < 58
replace hba1ccatmm = 1 if hba1c_mmol >= 58 & hba1c_mmol !=.
replace hba1ccatmm =.u if hba1ccatmm==. 
label define hba1ccatmm 0 "HbA1c <58mmol/mol" 1 "HbA1c >=58mmol/mol" .u "Not known"
label values hba1ccatmm hba1ccatmm
lab var hba1ccatmm "HbA1c"
tab hba1ccatmm, missing

*Create diabetes, split by control/not (assumes missing = no diabetes)
gen     diabcatm = 1 if diabetes==0
replace diabcatm = 2 if diabetes==1 & hba1ccatmm==0
replace diabcatm = 3 if diabetes==1 & hba1ccatmm==1
replace diabcatm = 4 if diabetes==1 & hba1ccatmm==.u

label define diabcatm 	1 "No diabetes" 			///
						2 "Diabetes with HbA1c <58mmol/mol"		///
						3 "Diabetes with HbA1c >58mmol/mol" 	///
						4 "Diabetes with no HbA1c measure"
label values diabcatm diabcatm
lab var diabcatm "Diabetes"

*Create cancer variable
gen cancer =0
replace cancer =1 if lung_cancer ==1 | haem_cancer ==1 | other_cancer ==1
lab var cancer "Cancer"
lab define cancer 0 "No" 1 "Yes", modify
lab val cancer cancer
tab cancer, missing

*Create other comorbid variables
gen combined_cv_comorbid =1 if chronic_cardiac_disease ==1 | stroke==1
recode combined_cv_comorbid .=0

*Label variables
lab var hypertension "Hypertension"
lab define hypertension 0 "No" 1 "Yes", modify
lab val hypertension hypertension
lab var diabetes "Diabetes"
lab define diabetes 0 "No" 1 "Yes", modify
lab val diabetes diabetes
lab var stroke "Stroke"
lab define stroke 0 "No" 1 "Yes", modify
lab val stroke stroke
lab var chronic_resp_disease "Chronic respiratory disease"
lab define chronic_resp_disease 0 "No" 1 "Yes", modify
lab val chronic_resp_disease chronic_resp_disease
lab var copd "COPD"
lab define copd 0 "No" 1 "Yes", modify
lab val copd copd
lab var esrf "End-stage renal failure"
lab define esrf 0 "No" 1 "Yes", modify
lab val esrf esrf
lab var chronic_liver_disease "Chronic liver disease"
lab define chronic_liver_disease 0 "No" 1 "Yes", modify
lab val chronic_liver_disease chronic_liver_disease
lab var chronic_cardiac_disease "Chronic cardiac disease"
lab define chronic_cardiac_disease 0 "No" 1 "Yes", modify
lab val chronic_cardiac_disease chronic_cardiac_disease
lab var rheum_appt "Rheumatology appointment"
lab define rheum_appt 0 "No" 1 "Yes", modify
lab val rheum_appt rheum_appt

*Ensure everyone has EIA code=============================================================*/

**All patients should have EIA code
tab eia_code, missing
keep if eia_code==1

**Check first rheum appt date was before EIA code date==================================*/

tab rheum_appt, missing //proportion of patients with an rheum outpatient date (with first attendance option selected) in the 12 months before EIA code appeared in GP record; data only April 2019 onwards
tab rheum_appt if rheum_appt_date>eia_code_date & rheum_appt_date!=. //confirm proportion who had first rheum appt (i.e. not missing) after EIA code
tab rheum_appt if rheum_appt_date>(eia_code_date + 30) & rheum_appt_date!=. //confirm proportion who had first rheum appt 30 days after EIA code 
tab rheum_appt if rheum_appt_date>(eia_code_date + 60) & rheum_appt_date!=. //confirm proportion who had first rheum appt 60 days after EIA code - should be none
replace rheum_appt=0 if rheum_appt_date>(eia_code_date + 60) & rheum_appt_date!=. //replace as missing if first appt >60 days after EIA code - should be none
replace rheum_appt_date=. if rheum_appt_date>(eia_code_date + 60) & rheum_appt_date!=. //replace as missing if first appt >60 days after EIA code - should be none

**As above - for differently specified rheumatology appointments - should be none for all of below
replace rheum_appt_any=0 if rheum_appt_any_date>(eia_code_date + 60) & rheum_appt_any_date!=. //replace as missing those appts >60 days after EIA code
replace rheum_appt_any_date=. if rheum_appt_any_date>(eia_code_date + 60) & rheum_appt_any_date!=. //replace as missing those appts >60 days after EIA code
replace rheum_appt2=0 if rheum_appt2_date>(eia_code_date + 60) & rheum_appt2_date!=. //replace as missing those appts >60 days after EIA code
replace rheum_appt2_date=. if rheum_appt2_date>(eia_code_date + 60) & rheum_appt2_date!=. //replace as missing those appts >60 days after EIA code_yea
replace rheum_appt3=0 if rheum_appt3_date>(eia_code_date + 60) & rheum_appt3_date!=. //replace as missing those appts >60 days after EIA code
replace rheum_appt3_date=. if rheum_appt3_date>(eia_code_date + 60) & rheum_appt3_date!=. //replace as missing those appts >60 days after EIA code

*Check if first csDMARD/biologic was after rheum appt date=====================================================*/

**csDMARDs (not including high cost MTX; wouldn't be shared care)
gen csdmard=1 if hydroxychloroquine==1 | leflunomide==1 | methotrexate==1 | methotrexate_inj==1 | sulfasalazine==1
recode csdmard .=0 
tab csdmard, missing

/*
**csDMARDs (including high cost MTX)
gen csdmard_hcd=1 if hydroxychloroquine==1 | leflunomide==1 | methotrexate==1 | methotrexate_inj==1 | methotrexate_hcd==1 | sulfasalazine==1
recode csdmard_hcd .=0 
tab csdmard_hcd, missing
*/

**Date of first csDMARD script (not including high cost MTX prescriptions)
gen csdmard_date=min(hydroxychloroquine_date, leflunomide_date, methotrexate_date, methotrexate_inj_date, sulfasalazine_date)
format %td csdmard_date

/*
**Date of first csDMARD script (including high cost MTX prescriptions)
gen csdmard_hcd_date=min(hydroxychloroquine_date, leflunomide_date, methotrexate_date, methotrexate_inj_date, methotrexate_hcd_date, sulfasalazine_date)
format %td csdmard_hcd_date

**Biologic use
gen biologic=1 if abatacept==1 | adalimumab==1 | baricitinib==1 | certolizumab==1 | etanercept==1 | golimumab==1 | guselkumab==1 | infliximab==1 | ixekizumab==1 | rituximab==1 | sarilumab==1 | secukinumab==1 | tocilizumab==1 | tofacitinib==1 | upadacitinib==1 | ustekinumab==1 
recode biologic .=0
tab biologic, missing

**Date of first biologic script
gen biologic_date=min(abatacept_date, adalimumab_date, baricitinib_date, certolizumab_date, etanercept_date, golimumab_date, guselkumab_date, infliximab_date, ixekizumab_date, rituximab_date, sarilumab_date, secukinumab_date, tocilizumab_date, tofacitinib_date, upadacitinib_date, ustekinumab_date)
format %td biologic_date
*/

**Exclude if first csdmard or biologic was before first rheum appt
tab csdmard if rheum_appt_date!=. & csdmard_date!=. & csdmard_date<rheum_appt_date
tab csdmard if rheum_appt_date!=. & csdmard_date!=. & (csdmard_date + 60)<rheum_appt_date 
drop if rheum_appt_date!=. & csdmard_date!=. & (csdmard_date + 60)<rheum_appt_date //drop if first csDMARD more than 60 days before first attendance at a rheum appt 
tab csdmard if rheum_appt_date==. & rheum_appt_any_date!=. & csdmard_date!=. & (csdmard_date + 60)<rheum_appt_any_date
drop if rheum_appt_date==. & rheum_appt_any_date!=. & csdmard_date!=. & (csdmard_date + 60)<rheum_appt_any_date //drop if first csDMARD more than 60 days before first captured rheum appt that did not have first attendance tag

/*
tab biologic if rheum_appt_date!=. & biologic_date!=. & biologic_date<rheum_appt_date 
tab biologic if rheum_appt_date!=. & biologic_date!=. & (biologic_date + 60)<rheum_appt_date 
drop if rheum_appt_date!=. & biologic_date!=. & (biologic_date + 60)<rheum_appt_date //drop if first biologic more than 60 days before first rheum_appt_date
tab biologic if rheum_appt_date==. & rheum_appt_any_date!=. & biologic_date!=. & (biologic_date + 60)<rheum_appt_any_date
drop if rheum_appt_date==. & rheum_appt_any_date!=. & biologic_date!=. & (biologic_date + 60)<rheum_appt_any_date //drop if first biologic more than 60 days before first captured rheum appt that did not have first attendance tag
*/

*Generate diagnosis date===============================================================*/

*Use eia code date (in GP record) as diagnosis date
gen diagnosis_date=eia_code_date
format diagnosis_date %td

*Refine diagnostic window=============================================================*/

**Keep patients with diagnosis date was after 1st April 2019 and before end date - should be none
keep if diagnosis_date>=date("$start_date", "DMY") & diagnosis_date!=. 
tab eia_code, missing
keep if diagnosis_date<date("$end_date", "DMY") & diagnosis_date!=. 
tab eia_code, missing

*Include only most recent EIA sub-diagnosis=============================================*/

replace ra_code =0 if psa_code_date > ra_code_date & psa_code_date !=.
replace ra_code =0 if anksp_code_date > ra_code_date & anksp_code_date !=.
replace ra_code =0 if undiff_code_date > ra_code_date & undiff_code_date !=.
replace psa_code =0 if ra_code_date >= psa_code_date & ra_code_date !=.
replace psa_code =0 if anksp_code_date > psa_code_date & anksp_code_date !=.
replace psa_code =0 if undiff_code_date > psa_code_date & undiff_code_date !=.
replace anksp_code =0 if psa_code_date >= anksp_code_date & psa_code_date !=.
replace anksp_code =0 if ra_code_date >= anksp_code_date & ra_code_date !=.
replace anksp_code =0 if undiff_code_date > anksp_code_date & undiff_code_date !=.
replace undiff_code =0 if ra_code_date >= undiff_code_date & ra_code_date !=.
replace undiff_code =0 if psa_code_date >= undiff_code_date & psa_code_date !=.
replace undiff_code =0 if anksp_code_date >= undiff_code_date & anksp_code_date !=.
gen eia_diagnosis=1 if ra_code==1
replace eia_diagnosis=2 if psa_code==1
replace eia_diagnosis=3 if anksp_code==1
replace eia_diagnosis=4 if undiff_code==1
lab define eia_diagnosis 1 "RA" 2 "PsA" 3 "AxSpA" 4 "Undiff IA", modify
lab val eia_diagnosis eia_diagnosis
tab eia_diagnosis, missing
drop if eia_diagnosis==. //should be none

decode eia_diagnosis, gen(eia_diag)
replace eia_diag="Undiff_IA" if eia_diagnosis==4

*Number of EIA diagnoses in 6-month time windows=========================================*/

**Month/Year of EIA code
gen year_diag=year(eia_code_date)
format year_diag %ty
gen month_diag=month(eia_code_date)
gen mo_year_diagn=ym(year_diag, month_diag)
format mo_year_diagn %tmMon-CCYY
generate str16 mo_year_diagn_s = strofreal(mo_year_diagn,"%tmCCYY!mNN")
lab var mo_year_diagn "Month/Year of Diagnosis"
lab var mo_year_diagn_s "Month/Year of Diagnosis"

**Month/Year of rheum appt
gen year_appt=year(rheum_appt_date) if rheum_appt_date!=.
format year_appt %ty
gen month_appt=month(rheum_appt_date) if rheum_appt_date!=. 
gen mo_year_appt=ym(year_appt, month_appt)
format mo_year_appt %tmMon-CCYY
generate str16 mo_year_appt_s = strofreal(mo_year_appt,"%tmCCYY!mNN")

**Separate into 3-month time windows (for diagnosis date)
gen diagnosis_3m=1 if diagnosis_date>=td(01apr2019) & diagnosis_date<td(01jul2019)
replace diagnosis_3m=2 if diagnosis_date>=td(01jul2019) & diagnosis_date<td(01oct2019)
replace diagnosis_3m=3 if diagnosis_date>=td(01oct2019) & diagnosis_date<td(01jan2020)
replace diagnosis_3m=4 if diagnosis_date>=td(01jan2020) & diagnosis_date<td(01apr2020)
replace diagnosis_3m=5 if diagnosis_date>=td(01apr2020) & diagnosis_date<td(01jul2020)
replace diagnosis_3m=6 if diagnosis_date>=td(01jul2020) & diagnosis_date<td(01oct2020)
replace diagnosis_3m=7 if diagnosis_date>=td(01oct2020) & diagnosis_date<td(01jan2021)
replace diagnosis_3m=8 if diagnosis_date>=td(01jan2021) & diagnosis_date<td(01apr2021)
replace diagnosis_3m=9 if diagnosis_date>=td(01apr2021) & diagnosis_date<td(01jul2021)
replace diagnosis_3m=10 if diagnosis_date>=td(01jul2021) & diagnosis_date<td(01oct2021)
replace diagnosis_3m=11 if diagnosis_date>=td(01oct2021) & diagnosis_date<td(01jan2022)
replace diagnosis_3m=12 if diagnosis_date>=td(01jan2022) & diagnosis_date<td(01apr2022)
replace diagnosis_3m=13 if diagnosis_date>=td(01apr2022) & diagnosis_date<td(01jul2022)
replace diagnosis_3m=14 if diagnosis_date>=td(01jul2022) & diagnosis_date<td(01oct2022)
replace diagnosis_3m=15 if diagnosis_date>=td(01oct2022) & diagnosis_date<td(01jan2023)
replace diagnosis_3m=16 if diagnosis_date>=td(01jan2023) & diagnosis_date<td(01apr2023)
replace diagnosis_3m=17 if diagnosis_date>=td(01apr2023) & diagnosis_date<td(01jul2023)
replace diagnosis_3m=18 if diagnosis_date>=td(01jul2023) & diagnosis_date<td(01oct2023)
lab define diagnosis_3m 1 "Apr 2019-Jun 2019" 2 "Jul 2019-Sep 2019" 3 "Oct 2019-Dec 2019" 4 "Jan 2020-Mar 2020" 5 "Apr 2020-Jun 2020" 6 "Jul 2020-Sep 2020" 7 "Oct 2020-Dec 2020" 8 "Jan 2021-Mar 2021" 9 "Apr 2021-Jun 2021" 10 "Jul 2021-Sep 2021" 11 "Oct 2021-Dec 2021" 12 "Jan 2022-Mar 2022" 13 "Apr 2022-Jun 2022" 14 "Jul 2022-Sep 2022" 15 "Oct 2022-Dec 2022" 16 "Jan 2023-Mar 2023" 17 "Apr 2023-Jun 2023" 18 "Jul 2023-Sep 2023", modify
lab val diagnosis_3m diagnosis_3m
lab var diagnosis_3m "Time period for diagnosis"
tab diagnosis_3m, missing
bys eia_diagnosis: tab diagnosis_3m, missing

**Separate into 6-month time windows (for diagnosis date)
gen diagnosis_6m=1 if diagnosis_date>=td(01apr2019) & diagnosis_date<td(01oct2019)
replace diagnosis_6m=2 if diagnosis_date>=td(01oct2019) & diagnosis_date<td(01apr2020)
replace diagnosis_6m=3 if diagnosis_date>=td(01apr2020) & diagnosis_date<td(01oct2020)
replace diagnosis_6m=4 if diagnosis_date>=td(01oct2020) & diagnosis_date<td(01apr2021)
replace diagnosis_6m=5 if diagnosis_date>=td(01apr2021) & diagnosis_date<td(01oct2021)
replace diagnosis_6m=6 if diagnosis_date>=td(01oct2021) & diagnosis_date<td(01apr2022)
replace diagnosis_6m=7 if diagnosis_date>=td(01apr2022) & diagnosis_date<td(01oct2022)
replace diagnosis_6m=8 if diagnosis_date>=td(01oct2022) & diagnosis_date<td(01apr2023)
replace diagnosis_6m=9 if diagnosis_date>=td(01apr2023) & diagnosis_date<td(01oct2023)
lab define diagnosis_6m 1 "Apr 2019-Oct 2019" 2 "Oct 2019-Apr 2020" 3 "Apr 2020-Oct 2020" 4 "Oct 2020-Apr 2021" 5 "Apr 2021-Oct 2021" 6 "Oct 2021-Apr 2022" 7 "Apr 2022-Oct 2022" 8 "Oct 2022-Apr 2023" 9 "Apr 2023-Oct 2023", modify
lab val diagnosis_6m diagnosis_6m
lab var diagnosis_6m "Time period for diagnosis"
tab diagnosis_6m, missing
bys eia_diagnosis: tab diagnosis_6m, missing

**Separate into 12-month time windows (for diagnosis date)
gen diagnosis_year=1 if diagnosis_date>=td(01apr2019) & diagnosis_date<td(01apr2020)
replace diagnosis_year=2 if diagnosis_date>=td(01apr2020) & diagnosis_date<td(01apr2021)
replace diagnosis_year=3 if diagnosis_date>=td(01apr2021) & diagnosis_date<td(01apr2022)
replace diagnosis_year=4 if diagnosis_date>=td(01apr2022) & diagnosis_date<td(01apr2023)
replace diagnosis_year=5 if diagnosis_date>=td(01apr2023) & diagnosis_date<td(01apr2024)
lab define diagnosis_year 1 "Apr 2019-Apr 2020" 2 "Apr 2020-Apr 2021" 3 "Apr 2021-Apr 2022" 4 "Apr 2022-Apr 2023" 5 "Apr 2023-Apr 2024", modify
lab val diagnosis_year diagnosis_year
lab var diagnosis_year "Year of diagnosis"
tab diagnosis_year, missing
bys eia_diagnosis: tab diagnosis_year, missing

**Separate into 3-month time windows (for appt date)
gen appt_3m=1 if rheum_appt_date>=td(01apr2019) & rheum_appt_date<td(01jul2019)
replace appt_3m=2 if rheum_appt_date>=td(01jul2019) & rheum_appt_date<td(01oct2019)
replace appt_3m=3 if rheum_appt_date>=td(01oct2019) & rheum_appt_date<td(01jan2020)
replace appt_3m=4 if rheum_appt_date>=td(01jan2020) & rheum_appt_date<td(01apr2020)
replace appt_3m=5 if rheum_appt_date>=td(01apr2020) & rheum_appt_date<td(01jul2020)
replace appt_3m=6 if rheum_appt_date>=td(01jul2020) & rheum_appt_date<td(01oct2020)
replace appt_3m=7 if rheum_appt_date>=td(01oct2020) & rheum_appt_date<td(01jan2021)
replace appt_3m=8 if rheum_appt_date>=td(01jan2021) & rheum_appt_date<td(01apr2021)
replace appt_3m=9 if rheum_appt_date>=td(01apr2021) & rheum_appt_date<td(01jul2021)
replace appt_3m=10 if rheum_appt_date>=td(01jul2021) & rheum_appt_date<td(01oct2021)
replace appt_3m=11 if rheum_appt_date>=td(01oct2021) & rheum_appt_date<td(01jan2022)
replace appt_3m=12 if rheum_appt_date>=td(01jan2022) & rheum_appt_date<td(01apr2022)
replace appt_3m=13 if rheum_appt_date>=td(01apr2022) & rheum_appt_date<td(01jul2022)
replace appt_3m=14 if rheum_appt_date>=td(01jul2022) & rheum_appt_date<td(01oct2022)
replace appt_3m=15 if rheum_appt_date>=td(01oct2022) & rheum_appt_date<td(01jan2023)
replace appt_3m=16 if rheum_appt_date>=td(01jan2023) & rheum_appt_date<td(01apr2023)
replace appt_3m=17 if rheum_appt_date>=td(01apr2023) & rheum_appt_date<td(01jul2023)
replace appt_3m=18 if rheum_appt_date>=td(01jul2023) & rheum_appt_date<td(01oct2023)
lab define appt_3m 1 "Apr 2019-Jun 2019" 2 "Jul 2019-Sep 2019" 3 "Oct 2019-Dec 2019" 4 "Jan 2020-Mar 2020" 5 "Apr 2020-Jun 2020" 6 "Jul 2020-Sep 2020" 7 "Oct 2020-Dec 2020" 8 "Jan 2021-Mar 2021" 9 "Apr 2021-Jun 2021" 10 "Jul 2021-Sep 2021" 11 "Oct 2021-Dec 2021" 12 "Jan 2022-Mar 2022" 13 "Apr 2022-Jun 2022" 14 "Jul 2022-Sep 2022" 15 "Oct 2022-Dec 2022" 16 "Jan 2023-Mar 2023" 17 "Apr 2023-Jun 2023" 18 "Jul 2023-Sep 2023", modify
lab val appt_3m appt_3m
lab var appt_3m "Time period for first rheumatology appt"
tab appt_3m, missing
bys eia_diagnosis: tab appt_3m, missing

**Separate into 6-month time windows (for appt date)
gen appt_6m=1 if rheum_appt_date>=td(01apr2019) & rheum_appt_date<td(01oct2019)
replace appt_6m=2 if rheum_appt_date>=td(01oct2019) & rheum_appt_date<td(01apr2020)
replace appt_6m=3 if rheum_appt_date>=td(01apr2020) & rheum_appt_date<td(01oct2020)
replace appt_6m=4 if rheum_appt_date>=td(01oct2020) & rheum_appt_date<td(01apr2021)
replace appt_6m=5 if rheum_appt_date>=td(01apr2021) & rheum_appt_date<td(01oct2021)
replace appt_6m=6 if rheum_appt_date>=td(01oct2021) & rheum_appt_date<td(01apr2022)
replace appt_6m=7 if rheum_appt_date>=td(01apr2022) & rheum_appt_date<td(01oct2022)
replace appt_6m=8 if rheum_appt_date>=td(01oct2022) & rheum_appt_date<td(01apr2023)
replace appt_6m=9 if rheum_appt_date>=td(01apr2023) & rheum_appt_date<td(01oct2023)
lab define appt_6m 1 "Apr 2019-Oct 2019" 2 "Oct 2019-Apr 2020" 3 "Apr 2020-Oct 2020" 4 "Oct 2020-Apr 2021" 5 "Apr 2021-Oct 2021" 6 "Oct 2021-Apr 2022" 7 "Apr 2022-Oct 2022" 8 "Oct 2022-Apr 2023" 9 "Apr 2023-Oct 2023", modify
lab val appt_6m appt_6m
lab var appt_6m "Time period for first rheumatology appt"
tab appt_6m, missing
bys eia_diagnosis: tab appt_6m, missing

**Separate into 12-month time windows (for appt date)
gen appt_year=1 if rheum_appt_date>=td(01apr2019) & rheum_appt_date<td(01apr2020)
replace appt_year=2 if rheum_appt_date>=td(01apr2020) & rheum_appt_date<td(01apr2021)
replace appt_year=3 if rheum_appt_date>=td(01apr2021) & rheum_appt_date<td(01apr2022)
replace appt_year=4 if rheum_appt_date>=td(01apr2022) & rheum_appt_date<td(01apr2023)
replace appt_year=5 if rheum_appt_date>=td(01apr2023) & rheum_appt_date<td(01apr2024)
lab define appt_year 1 "Apr 2019-Apr 2020" 2 "Apr 2020-Apr 2021" 3 "Apr 2021-Apr 2022" 4 "Apr 2022-Apr 2023" 5 "Apr 2023-Apr 2024", modify
lab val appt_year appt_year
lab var appt_year "Year of first rheumatology appt"
tab appt_year, missing
bys eia_diagnosis: tab appt_year, missing

*Define appointments and referrals======================================*/

**Proportion of patients with at least 6 or 12 months of GP registration after rheum appt (i.e. diagnosis date)
rename has_6m_follow_up has_6m_follow_up_s 
gen has_6m_follow_up=1 if has_6m_follow_up_s=="T"
recode has_6m_follow_up .=0
drop has_6m_follow_up_s
tab has_6m_follow_up
rename has_12m_follow_up has_12m_follow_up_s 
gen has_12m_follow_up=1 if has_12m_follow_up_s=="T"
recode has_12m_follow_up .=0
drop has_12m_follow_up_s
tab has_12m_follow_up 
tab mo_year_diagn has_6m_follow_up
tab mo_year_diagn has_12m_follow_up

*For appt and csDMARD analyses, all patients must have 1) rheum appt 2) GP appt before rheum appt 3) 12m follow-up after rheum appt 4) 12m of registration after appt
gen has_6m_post_appt=1 if rheum_appt_date!=. & rheum_appt_date<(date("$end_date", "DMY")-180) & has_6m_follow_up==1 & last_gp_prerheum==1
recode has_6m_post_appt .=0
lab var has_6m_post_appt "GP/rheum/registration 6m+"
lab define has_6m_post_appt 0 "No" 1 "Yes", modify
lab val has_6m_post_appt has_6m_post_appt
tab has_6m_post_appt
gen has_12m_post_appt=1 if rheum_appt_date!=. & rheum_appt_date<(date("$end_date", "DMY")-365) & has_12m_follow_up==1 & last_gp_prerheum==1
recode has_12m_post_appt .=0
lab var has_12m_post_appt "GP/rheum/registration 12m+"
lab define has_12m_post_appt 0 "No" 1 "Yes", modify
lab val has_12m_post_appt has_12m_post_appt
tab has_12m_post_appt

**Rheumatology appt 
tab rheum_appt, missing //proportion of patients with an rheum outpatient date (with first attendance option selected) in the 12 months before EIA code appeared in GP record; data only April 2019 onwards
tab rheum_appt_any, missing //proportion of patients with a rheum outpatient date (without first attendance option selected) in the 6 months before EIA code appeared in GP record; data only April 2019 onwards
tab rheum_appt2, missing //proportion of patients with a rheum outpatient date (without first attendance option selected) in the 6 months before EIA code appeared in GP record; data only April 2019 onwards
tab rheum_appt3, missing //proportion of patients with a rheum outpatient date (without first attendance option selected) in the 2 years before EIA code appeared in GP record; data only April 2019 onwards

*Gen rheum appt var only for those with 12m follow-up
gen rheum_appt_to21=rheum_appt if rheum_appt_date<(date("$end_date", "DMY")-365) 
recode rheum_appt_to21 .=0
lab var rheum_appt_to21 "Rheumatology appt 12m+"
lab define rheum_appt_to21 0 "No" 1 "Yes", modify
lab val rheum_appt_to21 rheum_appt_to21

*Gen rheum appt var only for those with 6m+ follow-up
gen rheum_appt_to6m=rheum_appt if rheum_appt_date<(date("$end_date", "DMY")-180) 
recode rheum_appt_to6m .=0
lab var rheum_appt_to6m "Rheumatology appt 6m+"
lab define rheum_appt_to6m 0 "No" 1 "Yes", modify
lab val rheum_appt_to6m rheum_appt_to6m

**Check number of rheumatology appts in the year before EIA code
tabstat rheum_appt_count, stat (n mean sd p50 p25 p75)
bys diagnosis_year: tabstat rheum_appt_count, stat (n mean sd p50 p25 p75)
bys appt_year: tabstat rheum_appt_count, stat (n mean sd p50 p25 p75)

**Check medium used for rheumatology appointment
tab rheum_appt_medium, missing
**Amend once above known
/*
gen rheum_appt_medium_clean = rheum_appt_medium if rheum_appt_medium >0 & rheum_appt_medium<100
recode rheum_appt_medium_clean 3=2 //recode telemedicine=telephone
replace rheum_appt_medium_clean=10 if rheum_appt_medium_clean>2 & rheum_appt_medium_clean!=.
recode rheum_appt_medium_clean .=.u
lab define rheum_appt_medium_clean 1 "Face-to-face" 2 "Telephone" 10 "Other" .u "Missing", modify
lab val rheum_appt_medium_clean rheum_appt_medium_clean
lab var rheum_appt_medium_clean "Rheumatology consultation medium"
tab rheum_appt_medium_clean if has_12m_post_appt==1, missing
bys appt_year: tab rheum_appt_medium_clean if has_12m_post_appt==1, missing
*/

**Rheumatology referrals (Nb. low capture of coded rheumatology referrals at present, therefore last GP appt used as proxy of referral date currently - see below)
tab referral_rheum_prerheum //last rheum referral in the 2 years before rheumatology outpatient (requires rheum appt to have been present)
tab referral_rheum_prerheum if rheum_appt!=0 & referral_rheum_prerheum_date<=rheum_appt_date  //last rheum referral in the 2 years before rheumatology outpatient, assuming ref date before rheum appt date (should be accounted for by Python code)
tab referral_rheum_precode //last rheum referral in the 2 years before EIA code 
gen referral_rheum_comb_date = referral_rheum_prerheum_date if referral_rheum_prerheum_date!=.
replace referral_rheum_comb_date = referral_rheum_precode_date if referral_rheum_prerheum_date==. & referral_rheum_precode_date!=.
format %td referral_rheum_comb_date

**GP appointments
tab last_gp_refrheum //proportion with last GP appointment in 2 years before rheum referral (pre-rheum appt); requires there to have been a rheum referral before a rheum appt

gen last_gp_prerheum_to21=last_gp_prerheum if rheum_appt_date!=. & rheum_appt_date<(date("$end_date", "DMY")-365)
recode last_gp_prerheum_to21 .=0
lab var last_gp_prerheum_to21 "GP and rheum appt 12m+"
lab define last_gp_prerheum_to21 0 "No" 1 "Yes", modify
lab val last_gp_prerheum_to21 last_gp_prerheum_to21

gen last_gp_prerheum_to6m=last_gp_prerheum if rheum_appt_date!=. & rheum_appt_date<(date("$end_date", "DMY")-180)
recode last_gp_prerheum_to6m .=0
lab var last_gp_prerheum_to6m "GP and rheum appt 6m+"
lab define last_gp_prerheum_to6m 0 "No" 1 "Yes", modify
lab val last_gp_prerheum_to6m last_gp_prerheum_to6m

gen all_appts=1 if last_gp_refrheum==1 & referral_rheum_prerheum==1 & rheum_appt==1 & last_gp_refrheum_date<=referral_rheum_prerheum_date & referral_rheum_prerheum_date<=rheum_appt_date
recode all_appts .=0
tab all_appts, missing //proportion who had a last gp appt, then rheum ref, then rheum appt
tab last_gp_refcode //last GP appointment before rheum ref (pre-eia code ref); requires there to have been a rheum referral before an EIA code (i.e. rheum appt could have been missing)
tab last_gp_prerheum //last GP appointment before rheum appt; requires there to have been a rheum appt before and EIA code
tab last_gp_precode //last GP appointment before EIA code

*Time to rheum referral (see notes above)=============================================*/

**Time from last GP to rheum ref before rheum appt (i.e. if appts are present and in correct time order)
gen time_gp_rheum_ref_appt = (referral_rheum_prerheum_date - last_gp_refrheum_date) if referral_rheum_prerheum_date!=. & last_gp_refrheum_date!=. & rheum_appt_date!=. & referral_rheum_prerheum_date>=last_gp_refrheum_date & referral_rheum_prerheum_date<=rheum_appt_date
tabstat time_gp_rheum_ref_appt, stats (n mean p50 p25 p75) //all patients (should be same number as all_appts)

gen gp_ref_cat=1 if time_gp_rheum_ref_appt<=3 & time_gp_rheum_ref_appt!=. 
replace gp_ref_cat=2 if time_gp_rheum_ref_appt>3 & time_gp_rheum_ref_appt<=7 & time_gp_rheum_ref_appt!=. & gp_ref_cat==.
replace gp_ref_cat=3 if time_gp_rheum_ref_appt>7 & time_gp_rheum_ref_appt!=. & gp_ref_cat==.
lab define gp_ref_cat 1 "Within 3 days" 2 "Between 3-7 days" 3 "More than 7 days", modify
lab val gp_ref_cat gp_ref_cat
lab var gp_ref_cat "Time to GP referral"
tab gp_ref_cat, missing

gen gp_ref_3d=1 if time_gp_rheum_ref_appt<=3 & time_gp_rheum_ref_appt!=. 
replace gp_ref_3d=2 if time_gp_rheum_ref_appt>3 & time_gp_rheum_ref_appt!=.
lab define gp_ref_3d 1 "Within 3 days" 2 "More than 3 days", modify
lab val gp_ref_3d gp_ref_3d
lab var gp_ref_3d "Time to GP referral"
tab gp_ref_3d, missing

**Time from last GP to rheum ref before eia code (sensitivity analysis; includes those with no rheum appt)
gen time_gp_rheum_ref_code = (referral_rheum_precode_date - last_gp_refcode_date) if referral_rheum_precode_date!=. & last_gp_refcode_date!=. & referral_rheum_precode_date>=last_gp_refcode_date & referral_rheum_precode_date<=eia_code_date
tabstat time_gp_rheum_ref_code, stats (n mean p50 p25 p75)

**Time from last GP to rheum ref (combined - sensitivity analysis; includes those with no rheum appt)
gen time_gp_rheum_ref_comb = time_gp_rheum_ref_appt 
replace time_gp_rheum_ref_comb = time_gp_rheum_ref_code if time_gp_rheum_ref_appt==. & time_gp_rheum_ref_code!=.
tabstat time_gp_rheum_ref_comb, stats (n mean p50 p25 p75)

*Time to rheum appointment=============================================*/

**Time from last GP pre-rheum appt to first rheum appt (proxy for referral to appt delay)
gen time_gp_rheum_appt = (rheum_appt_date - last_gp_prerheum_date) if rheum_appt_date!=. & last_gp_prerheum_date!=. & rheum_appt_date>=last_gp_prerheum_date
tabstat time_gp_rheum_appt, stats (n mean p50 p25 p75)

**Time from rheum ref to rheum appt (i.e. if appts are present and in correct order)
gen time_ref_rheum_appt = (rheum_appt_date - referral_rheum_prerheum_date) if rheum_appt_date!=. & referral_rheum_prerheum_date!=. & referral_rheum_prerheum_date<=rheum_appt_date
tabstat time_ref_rheum_appt, stats (n mean p50 p25 p75)

gen gp_appt_cat=1 if time_gp_rheum_appt<=21 & time_gp_rheum_appt!=. 
replace gp_appt_cat=2 if time_gp_rheum_appt>21 & time_gp_rheum_appt<=42 & time_gp_rheum_appt!=. & gp_appt_cat==.
replace gp_appt_cat=3 if time_gp_rheum_appt>42 & time_gp_rheum_appt!=. & gp_appt_cat==.
lab define gp_appt_cat 1 "Within 3 weeks" 2 "Between 3-6 weeks" 3 "More than 6 weeks", modify
lab val gp_appt_cat gp_appt_cat
lab var gp_appt_cat "Time to rheumatology assessment, overall"
tab gp_appt_cat, missing

gen gp_appt_cat_19=gp_appt_cat if appt_year==1
gen gp_appt_cat_20=gp_appt_cat if appt_year==2
gen gp_appt_cat_21=gp_appt_cat if appt_year==3
gen gp_appt_cat_22=gp_appt_cat if appt_year==4
gen gp_appt_cat_23=gp_appt_cat if appt_year==5
lab define gp_appt_cat_19 1 "Within 3 weeks" 2 "Between 3-6 weeks" 3 "More than 6 weeks", modify
lab val gp_appt_cat_19 gp_appt_cat_19
lab var gp_appt_cat_19 "Time to rheumatology assessment, Apr 2019-2020"
lab define gp_appt_cat_20 1 "Within 3 weeks" 2 "Between 3-6 weeks" 3 "More than 6 weeks", modify
lab val gp_appt_cat_20 gp_appt_cat_20
lab var gp_appt_cat_20 "Time to rheumatology assessment, Apr 2020-2021"
lab define gp_appt_cat_21 1 "Within 3 weeks" 2 "Between 3-6 weeks" 3 "More than 6 weeks", modify
lab val gp_appt_cat_21 gp_appt_cat_21
lab var gp_appt_cat_21 "Time to rheumatology assessment, Apr 2021-2022"
lab define gp_appt_cat_22 1 "Within 3 weeks" 2 "Between 3-6 weeks" 3 "More than 6 weeks", modify
lab val gp_appt_cat_22 gp_appt_cat_22
lab var gp_appt_cat_22 "Time to rheumatology assessment, Apr 2022-2023"
lab define gp_appt_cat_23 1 "Within 3 weeks" 2 "Between 3-6 weeks" 3 "More than 6 weeks", modify
lab val gp_appt_cat_23 gp_appt_cat_23
lab var gp_appt_cat_23 "Time to rheumatology assessment, Apr 2023-2024"

gen gp_appt_3w=1 if time_gp_rheum_appt<=21 & time_gp_rheum_appt!=. 
replace gp_appt_3w=2 if time_gp_rheum_appt>21 & time_gp_rheum_appt!=.
lab define gp_appt_3w 1 "Within 3 weeks" 2 "More than 3 weeks", modify
lab val gp_appt_3w gp_appt_3w
lab var gp_appt_3w "Time to rheumatology assessment, overall"
tab gp_appt_3w, missing

gen ref_appt_cat=1 if time_ref_rheum_appt<=21 & time_ref_rheum_appt!=. 
replace ref_appt_cat=2 if time_ref_rheum_appt>21 & time_ref_rheum_appt<=42 & time_ref_rheum_appt!=. & ref_appt_cat==.
replace ref_appt_cat=3 if time_ref_rheum_appt>42 & time_ref_rheum_appt!=. & ref_appt_cat==.
lab define ref_appt_cat 1 "Within 3 weeks" 2 "Between 3-6 weeks" 3 "More than 6 weeks", modify
lab val ref_appt_cat ref_appt_cat
lab var ref_appt_cat "Time to rheumatology assessment"
tab ref_appt_cat, missing

gen ref_appt_3w=1 if time_ref_rheum_appt<=21 & time_ref_rheum_appt!=. 
replace ref_appt_3w=2 if time_ref_rheum_appt>21 & time_ref_rheum_appt!=.
lab define ref_appt_3w 1 "Within 3 weeks" 2 "More than 3 weeks", modify
lab val ref_appt_3w ref_appt_3w
lab var ref_appt_3w "Time to rheumatology assessment"
tab ref_appt_3w, missing

**Time from rheum ref or last GP to rheum appt (combined; includes those with no rheum ref)
gen time_refgp_rheum_appt = time_ref_rheum_appt
replace time_refgp_rheum_appt = time_gp_rheum_appt if time_ref_rheum_appt==. & time_gp_rheum_appt!=.
tabstat time_refgp_rheum_appt, stats (n mean p50 p25 p75)

*Time to EIA code==================================================*/

**Time from last GP pre-code to EIA code (sensitivity analysis; includes those with no rheum ref and/or no rheum appt)
gen time_gp_eia_code = (eia_code_date - last_gp_precode_date) if eia_code_date!=. & last_gp_precode_date!=. & eia_code_date>=last_gp_precode_date
tabstat time_gp_eia_code, stats (n mean p50 p25 p75)

**Time from last GP to EIA diagnosis (combined - sensitivity analysis; includes those with no rheum appt)
gen time_gp_eia_diag = time_gp_rheum_appt
replace time_gp_eia_diag = time_gp_eia_code if time_gp_rheum_appt==. & time_gp_eia_code!=.
tabstat time_gp_eia_diag, stats (n mean p50 p25 p75)

**Time from rheum ref to EIA code (sensitivity analysis; includes those with no rheum appt)
gen time_ref_rheum_eia = (eia_code_date - referral_rheum_precode_date) if eia_code_date!=. & referral_rheum_precode_date!=. & referral_rheum_precode_date<=eia_code_date  
tabstat time_ref_rheum_eia, stats (n mean p50 p25 p75)

**Time from rheum ref to EIA diagnosis (combined - sensitivity analysis; includes those with no rheum appt)
gen time_ref_rheum_eia_comb = time_ref_rheum_appt
replace time_ref_rheum_eia_comb = time_ref_rheum_eia if time_ref_rheum_appt==. & time_ref_rheum_eia!=.
tabstat time_ref_rheum_eia_comb, stats (n mean p50 p25 p75)

**Time from rheum appt to EIA code
gen time_rheum_eia_code = (eia_code_date - rheum_appt_date) if eia_code_date!=. & rheum_appt_date!=. 
tabstat time_rheum_eia_code, stats (n mean p50 p25 p75) 
gen time_rheum2_eia_code = (eia_code_date - rheum_appt2_date) if eia_code_date!=. & rheum_appt2_date!=. 
tabstat time_rheum2_eia_code, stats (n mean p50 p25 p75) 
gen time_rheum3_eia_code = (eia_code_date - rheum_appt3_date) if eia_code_date!=. & rheum_appt3_date!=. 
tabstat time_rheum3_eia_code, stats (n mean p50 p25 p75) 

*Time from rheum appt to first csDMARD prescriptions on primary care record======================================================================*/

**Time to first csDMARD script for RA patients not including high cost MTX prescriptions; prescription must be within 6 months of first rheum appt for all csDMARDs below ==================*/
gen time_to_csdmard=(csdmard_date-rheum_appt_date) if csdmard==1 & rheum_appt_date!=. & (csdmard_date<=rheum_appt_date+180)
tabstat time_to_csdmard if ra_code==1, stats (n mean p50 p25 p75)

/*
**Time to first csDMARD script for RA patients (including high cost MTX prescriptions)
gen time_to_csdmard_hcd=(csdmard_hcd_date-rheum_appt_date) if csdmard_hcd==1 & rheum_appt_date!=. & (csdmard_hcd_date<=rheum_appt_date+180)
tabstat time_to_csdmard_hcd if ra_code==1, stats (n mean p50 p25 p75) 
*/

**Time to first csDMARD script for PsA patients (not including high cost MTX prescriptions)
tabstat time_to_csdmard if psa_code==1, stats (n mean p50 p25 p75)

/*
**Time to first csDMARD script for PsA patients (including high cost MTX prescriptions)
tabstat time_to_csdmard_hcd if psa_code==1, stats (n mean p50 p25 p75) 
*/

**Time to first csDMARD script for axSpA patients (not including high cost MTX prescriptions)
tabstat time_to_csdmard if anksp_code==1, stats (n mean p50 p25 p75)

**Time to first csDMARD script for Undiff IA patients (not including high cost MTX prescriptions)
tabstat time_to_csdmard if undiff_code==1, stats (n mean p50 p25 p75)

**csDMARD time categories (not including high cost MTX prescriptions)
gen csdmard_time=1 if time_to_csdmard<=90 & time_to_csdmard!=. 
replace csdmard_time=2 if time_to_csdmard>90 & time_to_csdmard<=180 & time_to_csdmard!=.
replace csdmard_time=3 if time_to_csdmard>180 | time_to_csdmard==.
lab define csdmard_time 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months", modify
lab val csdmard_time csdmard_time
lab var csdmard_time "csDMARD in primary care, overall" 
tab csdmard_time if ra_code==1, missing 
tab csdmard_time if psa_code==1, missing
tab csdmard_time if anksp_code==1, missing
tab csdmard_time if undiff_code==1, missing

gen csdmard_time_19=csdmard_time if appt_year==1
recode csdmard_time_19 .=4
gen csdmard_time_20=csdmard_time if appt_year==2
recode csdmard_time_20 .=4
gen csdmard_time_21=csdmard_time if appt_year==3
recode csdmard_time_21 .=4
gen csdmard_time_22=csdmard_time if appt_year==4
recode csdmard_time_22 .=4
gen csdmard_time_23=csdmard_time if appt_year==5
recode csdmard_time_23 .=4
lab define csdmard_time_19 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months" 4 "Outside 2019", modify
lab val csdmard_time_19 csdmard_time_19
lab var csdmard_time_19 "csDMARD in primary care, Apr 2019-2020" 
lab define csdmard_time_20 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months" 4 "Outside 2020", modify
lab val csdmard_time_20 csdmard_time_20
lab var csdmard_time_20 "csDMARD in primary care, Apr 2020-2021" 
lab define csdmard_time_21 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months" 4 "Outside 2021", modify
lab val csdmard_time_21 csdmard_time_21
lab var csdmard_time_21 "csDMARD in primary care, Apr 2021-2022" 
lab define csdmard_time_22 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months" 4 "Outside 2022", modify
lab val csdmard_time_22 csdmard_time_22
lab var csdmard_time_22 "csDMARD in primary care, Apr 2022-2023" 
lab define csdmard_time_23 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months" 4 "Outside 2022", modify
lab val csdmard_time_23 csdmard_time_23
lab var csdmard_time_23 "csDMARD in primary care, Apr 2023-2024" 

**csDMARD time categories - binary 6 months
gen csdmard_6m=1 if time_to_csdmard<=180 & time_to_csdmard!=. 
replace csdmard_6m=0 if time_to_csdmard>180 | time_to_csdmard==.
lab define csdmard_6m 1 "Yes" 0 "No", modify
lab val csdmard_6m csdmard_6m
lab var csdmard_6m "csDMARD in primary care within 6 months" 
tab csdmard_6m, missing 

/*
**csDMARD time categories (including high cost MTX prescriptions)
gen csdmard_hcd_time=1 if time_to_csdmard_hcd<=90 & time_to_csdmard_hcd!=. 
replace csdmard_hcd_time=2 if time_to_csdmard_hcd>90 & time_to_csdmard_hcd<=180 & time_to_csdmard_hcd!=.
replace csdmard_hcd_time=3 if time_to_csdmard_hcd>180 | time_to_csdmard_hcd==.
lab define csdmard_hcd_time 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months", modify
lab val csdmard_hcd_time csdmard_hcd_time
lab var csdmard_hcd_time "csDMARD in primary care" 
tab csdmard_hcd_time if ra_code==1, missing 
tab csdmard_hcd_time if psa_code==1, missing
tab csdmard_hcd_time if anksp_code==1, missing 
tab csdmard_hcd_time if undiff_code==1, missing
*/

**What was first csDMARD in GP record (not including high cost MTX prescriptions) - removed leflunomide (for OpenSAFELY report) due to small counts at more granular time periods
gen first_csD=""
foreach var of varlist hydroxychloroquine_date methotrexate_date methotrexate_inj_date sulfasalazine_date {
	replace first_csD="`var'" if csdmard_date==`var' & csdmard_date!=. & (`var'<=(rheum_appt_date+180)) & time_to_csdmard!=.
	}
gen first_csDMARD = substr(first_csD, 1, length(first_csD) - 5) if first_csD!="" 
drop first_csD
replace first_csDMARD="Methotrexate" if first_csDMARD=="methotrexate" | first_csDMARD=="methotrexate_inj" //combine oral and s/c MTX
replace first_csDMARD="Sulfasalazine" if first_csDMARD=="sulfasalazine"
replace first_csDMARD="Hydroxychloroquine" if first_csDMARD=="hydroxychloroquine" 
tab first_csDMARD if ra_code==1 //for RA patients
tab first_csDMARD if psa_code==1 //for PsA patients
tab first_csDMARD if anksp_code==1 //for axSpA patients
tab first_csDMARD if undiff_code==1 //for Undiff IA patients

/*
**What was first csDMARD in GP record (including high cost MTX prescriptions)
gen first_csD_hcd=""
foreach var of varlist hydroxychloroquine_date methotrexate_date methotrexate_inj_date methotrexate_hcd_date sulfasalazine_date {
	replace first_csD_hcd="`var'" if csdmard_hcd_date==`var' & csdmard_hcd_date!=. & (csdmard_hcd_date<=rheum_appt_date+180) & time_to_csdmard_hcd!=.
	}
gen first_csDMARD_hcd = substr(first_csD_hcd, 1, length(first_csD_hcd) - 5) if first_csD_hcd!=""
drop first_csD_hcd
tab first_csDMARD_hcd if ra_code==1 //for RA patients
tab first_csDMARD_hcd if psa_code==1 //for PsA patients
tab first_csDMARD_hcd if anksp_code==1 //for axSpA patients
tab first_csDMARD_hcd if undiff_code==1 //for Undiff IA patients
*/
 
**Methotrexate use (not including high cost MTX prescriptions)
gen mtx=1 if methotrexate==1 | methotrexate_inj==1
recode mtx .=0 

/*
**Methotrexate use (including high cost MTX prescriptions)
gen mtx_hcd=1 if methotrexate==1 | methotrexate_inj==1 | methotrexate_hcd==1
recode mtx_hcd .=0 
*/

**Date of first methotrexate script (not including high cost MTX prescriptions)
gen mtx_date=min(methotrexate_date, methotrexate_inj_date)
format %td mtx_date

/*
**Date of first methotrexate script (including high cost MTX prescriptions)
gen mtx_hcd_date=min(methotrexate_date, methotrexate_inj_date, methotrexate_hcd_date)
format %td mtx_hcd_date
*/

**Methotrexate use (not including high cost MTX prescriptions)
tab mtx if ra_code==1 //for RA patients; Nb. this is just a check; need time-to-MTX instead (below)
tab mtx if ra_code==1 & (mtx_date<=rheum_appt_date+180) //with 6-month limit
tab mtx if ra_code==1 & (mtx_date<=rheum_appt_date+365) //with 12-month limit
tab mtx if psa_code==1 //for PsA patients
tab mtx if psa_code==1 & (mtx_date<=rheum_appt_date+180) //with 6-month limit
tab mtx if psa_code==1 & (mtx_date<=rheum_appt_date+365) //with 12-month limit
tab mtx if undiff_code==1 //for undiff IA patients
tab mtx if undiff_code==1 & (mtx_date<=rheum_appt_date+180) //with 6-month limit
tab mtx if undiff_code==1 & (mtx_date<=rheum_appt_date+365) //with 12-month limit

/*
**Methotrexate use (including high cost MTX prescriptions)
tab mtx_hcd if ra_code==1 //for RA patients
tab mtx_hcd if ra_code==1 & (mtx_hcd_date<=rheum_appt_date+180) //with 6-month limit
tab mtx_hcd if ra_code==1 & (mtx_hcd_date<=rheum_appt_date+365) //with 12-month limit
tab mtx_hcd if psa_code==1 //for PsA patients
tab mtx_hcd if psa_code==1 & (mtx_hcd_date<=rheum_appt_date+180) //with 6-month limit
tab mtx_hcd if psa_code==1 & (mtx_hcd_date<=rheum_appt_date+365) //with 12-month limit
tab mtx_hcd if undiff_code==1 //for undiff IA patients
tab mtx_hcd if undiff_code==1 & (mtx_hcd_date<=rheum_appt_date+180) //with 6-month limit
tab mtx_hcd if undiff_code==1 & (mtx_hcd_date<=rheum_appt_date+365) //with 12-month limit
*/

**Check if medication issued >once
gen mtx_shared=1 if mtx==1 & (methotrexate_count>1 | methotrexate_inj_count>1)
recode mtx_shared .=0
tab mtx_shared

**Methotrexate use (shared care)
tab mtx_shared if ra_code==1 //for RA patients; Nb. this is just a check; need time-to-MTX instead (below)
tab mtx_shared if ra_code==1 & (mtx_date<=rheum_appt_date+180) //with 6-month limit
tab mtx_shared if psa_code==1 //for PsA patients
tab mtx_shared if psa_code==1 & (mtx_date<=rheum_appt_date+180) //with 6-month limit
tab mtx_shared if undiff_code==1 //for undiff IA patients
tab mtx_shared if undiff_code==1 & (mtx_date<=rheum_appt_date+180) //with 6-month limit

**Check medication issue number
gen mtx_issue=0 if mtx==1 & (methotrexate_count==0 | methotrexate_inj_count==0)
replace mtx_issue=1 if mtx==1 & (methotrexate_count==1 | methotrexate_inj_count==1)
replace mtx_issue=2 if mtx==1 & (methotrexate_count>1 | methotrexate_inj_count>1)
tab mtx_issue

**Time to first methotrexate script for RA patients (not including high cost MTX prescriptions)
gen time_to_mtx=(mtx_date-rheum_appt_date) if mtx==1 & rheum_appt_date!=. & (mtx_date<=rheum_appt_date+180)
tabstat time_to_mtx if ra_code==1, stats (n mean p50 p25 p75)

/*
**Time to first methotrexate script for RA patients (including high cost MTX prescriptions)
gen time_to_mtx_hcd=(mtx_hcd_date-rheum_appt_date) if mtx_hcd==1 & rheum_appt_date!=. & (mtx_hcd_date<=rheum_appt_date+180)
tabstat time_to_mtx_hcd if ra_code==1, stats (n mean p50 p25 p75)
*/

**Time to first methotrexate script for PsA patients (not including high cost MTX prescriptions)
tabstat time_to_mtx if psa_code==1, stats (n mean p50 p25 p75)

/*
**Time to first methotrexate script for PsA patients (including high cost MTX prescriptions)
tabstat time_to_mtx_hcd if psa_code==1, stats (n mean p50 p25 p75)
*/

**Time to first methotrexate script for Undiff IA patients (not including high cost MTX prescriptions)
tabstat time_to_mtx if undiff_code==1, stats (n mean p50 p25 p75)

**Methotrexate time categories (not including high-cost MTX)  
gen mtx_time=1 if time_to_mtx<=90 & time_to_mtx!=. 
replace mtx_time=2 if time_to_mtx>90 & time_to_mtx<=180 & time_to_mtx!=.
replace mtx_time=3 if time_to_mtx>180 | time_to_mtx==.
lab define mtx_time 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months", modify
lab val mtx_time mtx_time
lab var mtx_time "Methotrexate in primary care" 
tab mtx_time if ra_code==1, missing 
tab mtx_time if psa_code==1, missing
tab mtx_time if undiff_code==1, missing 

/*
**Methotrexate time categories for RA patients (including high-cost MTX)
gen mtx_hcd_time=1 if time_to_mtx_hcd<=90 & time_to_mtx_hcd!=. 
replace mtx_hcd_time=2 if time_to_mtx_hcd>90 & time_to_mtx_hcd<=180 & time_to_mtx_hcd!=.
replace mtx_hcd_time=3 if time_to_mtx_hcd>180 | time_to_mtx_hcd==.
lab define mtx_hcd_time 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months", modify
lab val mtx_hcd_time mtx_hcd_time
lab var mtx_hcd_time "Methotrexate in primary care" 
tab mtx_hcd_time if ra_code==1, missing 
tab mtx_hcd_time if psa_code==1, missing
tab mtx_hcd_time if undiff_code==1, missing 
*/

**Sulfasalazine use
gen ssz=1 if sulfasalazine==1
recode ssz .=0 

**Time to first sulfasalazine script for RA patients
gen time_to_ssz=(sulfasalazine_date-rheum_appt_date) if sulfasalazine_date!=. & rheum_appt_date!=. & (sulfasalazine_date<=rheum_appt_date+180)
tabstat time_to_ssz if ra_code==1, stats (n mean p50 p25 p75)
tabstat time_to_ssz if psa_code==1, stats (n mean p50 p25 p75)

**Sulfasalazine time categories  
gen ssz_time=1 if time_to_ssz<=90 & time_to_ssz!=. 
replace ssz_time=2 if time_to_ssz>90 & time_to_ssz<=180 & time_to_ssz!=.
replace ssz_time=3 if time_to_ssz>180 | time_to_ssz==.
lab define ssz_time 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months", modify
lab val ssz_time ssz_time
lab var ssz_time "Sulfasalazine in primary care" 
tab ssz_time if ra_code==1, missing 
tab ssz_time if psa_code==1, missing
tab ssz_time if undiff_code==1, missing 

**Check if medication issued >once
gen ssz_shared=1 if ssz==1 & sulfasalazine_count>1
recode ssz_shared .=0
tab ssz_shared

**sulfasalazine use (shared care)
tab ssz_shared if ra_code==1 
tab ssz_shared if ra_code==1 & (sulfasalazine_date<=rheum_appt_date+180)
tab ssz_shared if psa_code==1 
tab ssz_shared if psa_code==1 & (sulfasalazine_date<=rheum_appt_date+180) 
tab ssz_shared if undiff_code==1
tab ssz_shared if undiff_code==1 & (sulfasalazine_date<=rheum_appt_date+180)

**Check medication issue number
gen ssz_issue=0 if ssz==1 & sulfasalazine_count==0 
replace ssz_issue=1 if ssz==1 & sulfasalazine_count==1 
replace ssz_issue=2 if ssz==1 & sulfasalazine_count>1
tab ssz_issue

**Hydroxychloroquine use
gen hcq=1 if hydroxychloroquine==1
recode hcq .=0 

**Time to first hydroxychloroquine script for RA patients
gen time_to_hcq=(hydroxychloroquine_date-rheum_appt_date) if hydroxychloroquine_date!=. & rheum_appt_date!=. & (hydroxychloroquine_date<=rheum_appt_date+180)
tabstat time_to_hcq if ra_code==1, stats (n mean p50 p25 p75)
tabstat time_to_hcq if psa_code==1, stats (n mean p50 p25 p75)

**Hydroxychloroquine time categories  
gen hcq_time=1 if time_to_hcq<=90 & time_to_hcq!=. 
replace hcq_time=2 if time_to_hcq>90 & time_to_hcq<=180 & time_to_hcq!=.
replace hcq_time=3 if time_to_hcq>180 | time_to_hcq==.
lab define hcq_time 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months", modify
lab val hcq_time hcq_time
lab var hcq_time "Hydroxychloroquine in primary care" 
tab hcq_time if ra_code==1, missing 
tab hcq_time if psa_code==1, missing
tab hcq_time if undiff_code==1, missing 

**Check if medication issued >once
gen hcq_shared=1 if hcq==1 & hydroxychloroquine_count>1
recode hcq_shared .=0
tab hcq_shared

**hydroxychloroquine use (shared care)
tab hcq_shared if ra_code==1 
tab hcq_shared if ra_code==1 & (hydroxychloroquine_date<=rheum_appt_date+180)
tab hcq_shared if psa_code==1 
tab hcq_shared if psa_code==1 & (hydroxychloroquine_date<=rheum_appt_date+180) 
tab hcq_shared if undiff_code==1
tab hcq_shared if undiff_code==1 & (hydroxychloroquine_date<=rheum_appt_date+180)

**Check medication issue number
gen hcq_issue=0 if hcq==1 & hydroxychloroquine_count==0 
replace hcq_issue=1 if hcq==1 & hydroxychloroquine_count==1 
replace hcq_issue=2 if hcq==1 & hydroxychloroquine_count>1
tab hcq_issue

**Leflunomide use
gen lef=1 if leflunomide==1
recode lef .=0 

**Time to first leflunomide script for RA patients
gen time_to_lef=(leflunomide_date-rheum_appt_date) if leflunomide_date!=. & rheum_appt_date!=. & (leflunomide_date<=rheum_appt_date+180)
tabstat time_to_lef if ra_code==1, stats (n mean p50 p25 p75)
tabstat time_to_lef if psa_code==1, stats (n mean p50 p25 p75)

**Leflunomide time categories  
gen lef_time=1 if time_to_lef<=90 & time_to_lef!=. 
replace lef_time=2 if time_to_lef>90 & time_to_lef<=180 & time_to_lef!=.
replace lef_time=3 if time_to_lef>180 | time_to_lef==.
lab define lef_time 1 "Within 3 months" 2 "3-6 months" 3 "No prescription within 6 months", modify
lab val lef_time lef_time
lab var lef_time "Leflunomide in primary care" 
tab lef_time if ra_code==1, missing 
tab lef_time if psa_code==1, missing
tab lef_time if undiff_code==1, missing 

**Check if medication issued >once
gen lef_shared=1 if lef==1 & leflunomide_count>1
recode lef_shared .=0
tab lef_shared

**leflunomide use (shared care)
tab lef_shared if ra_code==1 
tab lef_shared if ra_code==1 & (leflunomide_date<=rheum_appt_date+180)
tab lef_shared if psa_code==1 
tab lef_shared if psa_code==1 & (leflunomide_date<=rheum_appt_date+180) 
tab lef_shared if undiff_code==1
tab lef_shared if undiff_code==1 & (leflunomide_date<=rheum_appt_date+180)

**Check medication issue number
gen lef_issue=0 if lef==1 & leflunomide_count==0 
replace lef_issue=1 if lef==1 & leflunomide_count==1 
replace lef_issue=2 if lef==1 & leflunomide_count>1
tab lef_issue

**For all csDMARDs, check if issued more than once 
gen csdmard_shared=1 if lef_shared==1 | mtx_shared==1 | hcq_shared==1 | ssz_shared==1 
recode csdmard_shared .=0
tab csdmard_shared
tab csdmard //for comparison

**Time to first biologic script; high_cost drug data available to Nov 2020. Not for analysis currently due to small numbers======================================================================*/

/* 
*Below analyses are only for patients with at least 12 months of follow-up available after rheum appt
gen time_to_biologic=(biologic_date-rheum_appt_date) if biologic==1 & rheum_appt_date!=. & (biologic_date<=rheum_appt_date+365)
tabstat time_to_biologic, stats (n mean p50 p25 p75) //for all EIA patients


**What was first biologic
gen first_bio=""
foreach var of varlist abatacept_date adalimumab_date baricitinib_date certolizumab_date etanercept_date golimumab_date guselkumab_date infliximab_date ixekizumab_date rituximab_date sarilumab_date secukinumab_date tocilizumab_date tofacitinib_date upadacitinib_date ustekinumab_date {
	replace first_bio="`var'" if biologic_date==`var' & biologic_date!=.
	}
gen first_biologic = substr(first_bio, 1, length(first_bio) - 5)	
drop first_bio
tab first_biologic //for all EIA patients

**Biologic time categories (for all patients)
gen biologic_time=1 if time_to_biologic<=180 & time_to_biologic!=. 
replace biologic_time=2 if time_to_biologic>180 & time_to_biologic<=365 & time_to_biologic!=.
replace biologic_time=3 if time_to_biologic>365 | time_to_biologic==.
lab define biologic_time 1 "Within 6 months" 2 "6-12 months" 3 "No prescription within 12 months", modify
lab val biologic_time biologic_time
lab var biologic_time "bDMARD/tsDMARD prescription" 
tab biologic_time

**Biologic time categories (by year)
bys diagnosis_6m: tab biologic_time
*/

save "$projectdir/output/data/file_eia_all_ehrQL", replace

log close
