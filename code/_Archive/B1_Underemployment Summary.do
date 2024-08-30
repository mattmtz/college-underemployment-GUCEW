/**************************************
*** NAME:    MATT MARTINEZ
*** PROJECT: UNDEREMPLOYMENT
*** PURPOSE: CREATE MEMO FIGURES/TABLE
*** DATE:    07/17/2024
**************************************/

*** LOAD DATA ***
use "../intermediate/clean_acs_data_memo", clear

****************************************
*** CALCULATE UNDEREMPLOYMENT SHARES ***
****************************************

*** CALCULATE BLS-DEFINED UNDEREMPLOYMENT ***
gen underemp_bls = 0
	replace underemp_bls = perwt if cln_educ_cat=="bachelors" & educ_req_nbr < 5
	
*** CALCULATE COMPARISON WAGE ***
preserve
	keep if agg_educ_lvl == "bls_educ" & ft == 1 & suff == 1
	collapse (p50) comp_wage = incwage [pw = perwt], ///
	 by(age_cat bls educ_re* occ_soc)

	tempfile MEDWAGE
	save `MEDWAGE'
restore

merge m:1 age_cat bls_occ educ_re* occ_soc using `MEDWAGE'
	assert suff_flag == 0 if _merge == 1
	drop _merge
	
*** CALCULATE GUCEW-DEFINED UNDEREMPLOYMENT ***
gen underemp = 0
	replace underemp = perwt if educ_req_nbr == 1 & cln_educ_cat == "bachelors"
	replace underemp = perwt if educ_req_nbr == 2 & ///
	 cln_educ_cat == "bachelors" & incwage <= $BA_PREM1 * comp_wage
	replace underemp = perwt if inlist(educ_req_nbr, 3, 4) & ///
	 cln_educ_cat == "bachelors" & incwage <= $BA_PREM2 * comp_wage
	replace underemp = 0 if suff_flag == 0


