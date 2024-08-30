/******************************
*** NAME:    MATT MARTINEZ
*** PROJECT: UNDEREMPLOYMENT
*** PURPOSE: COMPARISON WAGES 
*** DATE:    07/17/2024
******************************/

use "../intermediate/clean_acs_data_memo", clear
	drop if ftfy == 0

** CREATE COUNTING VARIABLE **
gen n=1

** CREATE LOCAL WITH AGE DUMMIES **
unab AGEDUMS: agedum_*
di "`AGEDUMS'"

*********************************************
*** CREATE COUNTS BY EDUCATION CATEGORIES ***
*********************************************

foreach var of varlist `AGEDUMS' {

** COUNTS **
preserve 
	keep if `var' == 1
	drop if educ_req_nbr == 7
	
	* Fix 22-23 low AA problem
	if ("`var'" == "agedum_22_23") {
	
	di "`var'"
		replace agg_educ = "bls_educ" if educ_req_nbr == 4 & ///
		inlist(cln_educ_cat, "some_college", "associates")	
	} 
	else {
		di "`var'"
	}
	keep if agg_educ_lvl == "bls_educ"
	
	collapse (sum) n_raw=n n_wtd=perwt, by(bls_occ occ_soc educ_re* agg_ed ftfy)

	rename agg_educ cln_educ_cat
	
	gen age_cat = "`var'"
	tempfile COUNTS_`var'
	save `COUNTS_`var''
restore

** WAGES **
preserve
	keep if `var'==1
	drop if educ_req_nbr == 7
	
	* Fix 22-23 low AA problem
	if ("`var'" == "agedum_22_23") {
	
	di "`var'"
		replace agg_educ = "bls_educ" if educ_req_nbr == 4 & ///
		inlist(cln_educ_cat, "some_college", "associates")
		
	} 
	else {
		di "`var'"
	}
		
	collapse (p50) med_wage=incwage (mean) avg_wage=incwage [pw = perwt], ///
	 by(bls occ_soc educ_re* agg_educ ftfy)
		
	rename agg_educ cln_educ_cat
	gen age_cat = "`var'"
	tempfile WAGE_`var'
	save `WAGE_`var''
	
restore
}

****************************
*** CREATE FINAL DATASET ***
****************************

clear
tempfile compdat
save `compdat', emptyok
count
foreach x in `AGEDUMS' {
	append using `COUNTS_`x''
	append using `WAGE_`x''
	save `"`compdat'"', replace
} 

** CLEAN DATASET **
replace bls_occ_title = "All occupations" if bls == ""
replace age_cat = substr(age_cat, strpos(age_cat, "_")+1, .)
replace age_cat = subinstr(age_cat, "_", "-", .)
replace age_cat = "all_workers" if age_cat == "all"

** CREATE FLAG FOR TOO FEW OBSERVATIONS **
gen int_count = 0
	replace int_count = n_raw if cln_educ_cat == "bls_educ"
	bysort age_cat bls ftfy: egen comp_count = max(int_count)
	replace comp_count = 0 if ftfy == 0 | mi(educ_req)
	
gen suff_flag = (comp_count >= $NFLAG )
	replace suff_flag = 1 if educ_req_nbr == 1

drop int_count

** SAVE DATA **
order bls_occ occ_soc educ_req educ_req_n age_cat cln_educ_cat n_w n_r suff_flag
gsort age_cat cln_educ_cat educ_req_nbr occ_soc

save "../intermediate/comparison_data_memo", replace
