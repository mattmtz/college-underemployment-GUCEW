/********************************
*** NAME:    MATT MARTINEZ
*** PROJECT: UNDEREMPLOYMENT
*** PURPOSE: GET COUNTS/EARNINGS
*** DATE:    10/14/2024
********************************/

use "intermediate/clean_acs_data", clear

** CREATE LOCAL WITH AGE DUMMIES **
unab AGEDUMS: agedum_*
di "`AGEDUMS'"

****************************
*** COUNTS BY OCCUPATION ***
****************************

gen n_raw = 1

foreach var of varlist `AGEDUMS' {

** ALL WORKERS **
preserve
	keep if `var' == 1
	collapse (sum) n_raw n_wtd=perwt, by(occ_acs bls occ_soc educ_re* ftfy)
	gen cln_educ_cat = "all_workers"
	gen age_cat = "`var'"
	tempfile T_counts_`var'
	save `T_counts_`var''
restore
	
** BY DETAILED EDUCATION **
preserve
	keep if `var' == 1
	collapse (sum) n_raw n_wtd=perwt, by(occ_acs bls occ_soc educ_re* cln_educ_cat ftfy)
	gen age_cat = "`var'"
	tempfile D_counts_`var'
	save `D_counts_`var''
restore

** BY AGGREGATE EDUCATION **
preserve
	keep if `var' == 1
	collapse (sum) n_raw n_wtd=perwt, by(occ_acs bls occ_soc educ_re* postsec ftfy)
	gen cln_educ_cat = "BA+" if postsec == 1
		replace cln_educ_cat = "less_BA" if postsec==0
		drop postsec
	gen age_cat = "`var'"
	tempfile A_counts_`var'
	save `A_counts_`var''
restore

** BY BLS JOB REQUIREMENT EDUCATIONAL ATTAINMENT **
preserve
	keep if `var'==1
	drop if educ_req_nbr == 7 // drop unusable education requirement category
	/* FIX 22-23 LOW AA PROBLEM */
	if ("`var'" == "agedum_22_23") {
	di "`var'"
		replace agg_educ = "bls_educ" if educ_req_nbr == 4 & ///
		inlist(cln_educ_cat, "some_college", "associates")	
	} 
	else {
		di "`var'"
	}
		
	collapse (sum) n_raw n_wtd=perwt, by(occ_acs bls occ_soc educ_re* agg_ed ftfy)	
	rename agg_educ cln_educ_cat
	gen age_cat = "`var'"
	tempfile Occ_counts_`var'
	save `Occ_counts_`var''
restore
}

***************************
*** WAGES BY OCCUPATION ***
***************************

foreach var of varlist `AGEDUMS' {

** ALL WORKERS **
preserve
	keep if `var' == 1
	collapse (p50) med_wage=incwage [pw=perwt], by(occ_acs bls occ_soc educ_re* ftfy)
	gen cln_educ_cat = "all_workers"
	gen age_cat = "`var'"
	tempfile T_wages_`var'
	save `T_wages_`var''
restore
	
** BY DETAILED EDUCATION **
preserve
	keep if `var' == 1
	collapse (p50) med_wage=incwage [pw=perwt], ///
	 by(occ_acs bls occ_soc educ_re* cln_educ_cat ftfy) 
	gen age_cat = "`var'"
	tempfile D_wages_`var'
	save `D_wages_`var''
restore

** BY AGGREGATE EDUCATION **
preserve
	keep if `var' == 1
	collapse (p50) med_wage=incwage [pw=perwt], ///
	 by(occ_acs bls occ_soc educ_re* postsec ftfy)
	gen cln_educ_cat = "BA+" if postsec == 1
		replace cln_educ_cat = "less_BA" if postsec==0
		drop postsec
	gen age_cat = "`var'"
	tempfile A_wages_`var'
	save `A_wages_`var''
restore

** BY BLS JOB REQUIREMENT EDUCATIONAL ATTAINMENT **
preserve
	keep if `var'==1
	drop if educ_req_nbr == 7 // drop unusable education requirement category
	/* FIX 22-23 LOW AA PROBLEM */
	if ("`var'" == "agedum_22_23") {
	di "`var'"
		replace agg_educ = "bls_educ" if educ_req_nbr == 4 & ///
		inlist(cln_educ_cat, "some_college", "associates")	
	} 
	else {
		di "`var'"
	}
		
	collapse (p50) med_wage=incw [pw=perwt], by(occ_acs bls occ_soc educ_r* agg_ed ftfy)	
	rename agg_educ cln_educ_cat
	gen age_cat = "`var'"
	tempfile Occ_wages_`var'
	save `Occ_wages_`var''
restore
}

*******************************
*** CREATE COMBINED DATASET ***
*******************************

** COMBINE COUNTS DATA **
clear
tempfile countsdat
save `countsdat', emptyok
count
foreach x in `AGEDUMS' {
	append using `T_counts_`x''
    append using `D_counts_`x''
	append using `A_counts_`x''
	append using `Occ_counts_`x''
	save `"`countsdat'"', replace
} 

** COMBINE WAGE DATA **
clear
tempfile earndat
save `earndat', emptyok
count
foreach x in `AGEDUMS' {
	append using `T_wages_`x''
	append using `D_wages_`x''
	append using `A_wages_`x''
	append using `Occ_wages_`x''
	save `"`earndat'"', replace
} 

merge 1:1 occ_acs bls occ_soc age_cat cln_educ_cat educ_re* ftfy using `countsdat'
	assert _merge == 3
	drop _merge

******************************
*** CLEAN & EXPORT DATASET ***
******************************

** CLEAN AGE CATEGORIES **
replace age_cat = substr(age_cat, strpos(age_cat, "_")+1, .)
replace age_cat = subinstr(age_cat, "_", "-", .)
replace age_cat = "all_workers" if age_cat == "all"

** CREATE FLAG FOR TOO FEW OBSERVATIONS **
gen int_count = 0
	replace int_count = n_raw if cln_educ_cat == "bls_educ"
	bysort age_cat bls ftfy: egen comp_count = max(int_count)
	replace comp_count = 0 if ftfy == 0 | mi(educ_req)
	
gen suff_flag = (comp_count >= $NFLAG )
	replace suff_flag = 1 if educ_req_nbr == 1 | educ_req_nbr >= 5

drop int_count
	
** CREATE COMPARISON VALUE FOR PREMIUM CALCULATION **
gen int_wage = 0
	replace int_wage = med_wage if cln_educ_cat == "bls_educ"
	bysort age_cat bls_occ_title ft: egen comp_wage = max(int_wage)
	replace comp_wage = . if educ_req_nbr == 7 | mi(educ_req) | ftfy == 0 | ///
	 suff_flag == 0
	drop int_wage

** SAVE DATA **
order age_c occ_acs bls_occ occ_soc educ_req educ_req_n cln_educ n_wtd n_raw suff ///
 comp_count comp_wage med_wage
gsort age_cat cln_educ_cat educ_req_nbr bls

save "intermediate/data_by_occupation", replace
