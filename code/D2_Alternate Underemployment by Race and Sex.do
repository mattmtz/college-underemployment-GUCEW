/*************************************
*** NAME:    MATT MARTINEZ
*** PROJECT: UNDEREMPLOYMENT
*** PURPOSE: UNDEREMP BY DEMOGRAPHICS
*** DATE:    10/14/2024
*************************************/

***************************************
*** DEFINE UNDEREMPLOYMENT MEASURES ***
***************************************

** GET COMPARISON WAGES FOR EP DEFINITION **
use "intermediate/data_by_occupation", clear
	keep if cln_educ_cat == "bachelors" & ftfy == 1 & ///
	 age_cat == "25-54" & bls!= "All occupations"
	
	keep occ_acs occ_soc age_cat comp_wage suff_flag
	
	tempfile OCCDAT
	save `OCCDAT'

use "intermediate/clean_acs_data", clear
	keep if agedum_25_54 == 1 & cln_educ_cat == "bachelors" & ftfy == 1
	
	merge m:1 occ_soc occ_acs using `OCCDAT'
		assert _merge == 3
		drop _merge
		
** DEFINE EP UNDEREMPLOYMENT **
gen ep_underemp = perwt
	replace ep_underemp = 0 if incwage>$BA_PREM1 * comp_wage & educ_req_nbr == 2
	replace ep_underemp = 0 if incwage>$BA_PREM2 * comp_wage & ///
	 inlist(educ_req_nbr, 3, 4)
	replace ep_underemp = 0 if educ_req_nbr >= 5 | mi(comp_wage)
	
gen ep_perwt = perwt
	replace ep_perwt = 0 if suff == 0

** ADD RM/DEMING DEFINITIONS **
merge m:1 occ_soc occ_acs using "intermediate/alt_underemployment_defs"
	* Occupations with no BA workers:
	tab bls_occ if _merge == 2
	drop if _merge == 2
	drop _merge

gen oer_underemp = perwt
	replace oer_underemp = 0 if oer_ba_job == 1

gen deming_underemp = perwt
	replace deming_underemp = 0 if deming_ba_job == 1
	
gen rm_maj_underemp = perwt
	replace rm_maj_underemp = 0 if college_occ_maj == 1
	
gen rm_plur_underemp = perwt
	replace rm_plur_underemp = 0 if college_occ_plur == 1
 
** DEFINE RACE CATEGORIES **
gen cln_race = "Hispanic" if hispan != 0
	replace cln_race = "White" if hispan == 0 & race == 1
	replace cln_race = "Black" if hispan == 0 & race == 2
	replace cln_race = "AA" if hispan == 0 & inlist(race, 4, 5, 6) & ///
	!inlist(raced, 680, 682, 685, 689, 690, 699) // separate out Pacific Islander 
	replace cln_race = "Other" if mi(cln_race)
	
*************************************
*** CREATE UNDEREMPLOYMENT GRAPHS ***
*************************************

** ALL WORKERS **
preserve
	* Create data
	collapse (sum) perwt ep_perwt *_underemp
	
	replace ep_underemp = 100*ep_underemp / ep_perwt
	foreach var of varlist oer deming rm_m rm_p {
		replace `var' = 100 * `var' / perwt
	}

* Create graph
graph bar oer_underemp rm_maj deming rm_plur ep_under, ///
 blabel(bar, format(%4.1f) size(vsmall)) title("Underemployment by definition") ///
 legend(order(1 "OER" 2 "RM (Maj)" 3 "Deming" 4 "RM (Plur)" 5 "EP") rows(1)) ///
 ytitle("Underemployment (%)") yscale(titlegap(*20))

graph export "output/alt_underemp_25_54.png", width(3000) height(2200) replace 

* Save data
tempfile ALL_ALT
save `ALL_ALT'
restore

** BY SEX **
preserve
	* Create data
	collapse (sum) perwt ep_perwt *_underemp, by(sex)
	
	replace ep_underemp = 100*ep_underemp / ep_perwt
	foreach var of varlist oer deming rm_m rm_p {
		replace `var' = 100 * `var' / perwt
	}
	
* Create graph
graph bar oer_underemp rm_maj deming rm_plur ep_under, over(sex) ///
 blabel(bar, format(%4.1f) size(vsmall)) title("Underemployment by definition & sex") ///
 legend(order(1 "OER" 2 "RM (Maj)" 3 "Deming" 4 "RM (Plur)" 5 "EP") rows(1)) ///
 ytitle("Underemployment (%)") yscale(titlegap(*20))
 
graph export "output/alt_underemp_25_54_by_sex.png", width(3400) height(2200) replace

* Save data
tempfile ALT_BY_SEX
save `ALT_BY_SEX'
restore

** BY RACE **
preserve
	* Create data
	collapse (sum) perwt ep_perwt *_underemp, by(cln_race)
	
	replace ep_underemp = 100*ep_underemp / ep_perwt
	foreach var of varlist oer deming rm_m rm_p {
		replace `var' = 100 * `var' / perwt
	}

* Create graph
graph bar oer_underemp rm_maj deming rm_plur ep_under, over(cln_race) ///
 blabel(bar, format(%4.1f) size(vsmall)) title("Underemployment by definition & race") ///
 legend(order(1 "OER" 2 "RM (Maj)" 3 "Deming" 4 "RM (Plur)" 5 "EP") rows(1)) ///
 ytitle("Underemployment (%)") yscale(titlegap(*20))
 
graph export "output/alt_underemp_25_54_by_race.png", width(3400) height(2200) replace 

* Save data
tempfile ALT_BY_RACE
save `ALT_BY_RACE'
restore

** BY SEX AND RACE **
* Create data
collapse (sum) perwt ep_perwt *_underemp, by(cln_race sex)
	
replace ep_underemp = 100*ep_underemp / ep_perwt
foreach var of varlist oer deming rm_m rm_p {
	replace `var' = 100 * `var' / perwt
}

* Create graphs
graph bar oer_underemp rm_maj deming rm_plur ep_under if sex == 1, over(cln_race) ///
 blabel(bar, format(%4.1f) size(vsmall)) title("Male") ///
 legend(off) ytitle("Underemployment (%)") yscale(titlegap(*10)) name(top, replace)

graph bar oer_underemp rm_maj deming rm_plur ep_under if sex == 2, over(cln_race) ///
 blabel(bar, format(%4.1f) size(vsmall)) title("Female") ///
 legend(order(1 "OER" 2 "RM (Maj)" 3 "Deming" 4 "RM (Plur)" 5 "EP") rows(1)) ///
 ytitle("Underemployment (%)") yscale(titlegap(*10)) name(bottom, replace)
 
graph combine top bottom, cols(1)
graph export "output/alt_underemp_25_54_by_sex_race.png", width(3000) height(2200) replace 

** EXPORT DATA **
append using `ALL_ALT'
append using `ALT_BY_SEX'
append using `ALT_BY_RACE'

replace cln_race = "All" if mi(cln_race)
gen cln_sex = "Male" if sex == 1
	replace cln_sex = "Female" if sex == 2
	replace cln_sex = "All" if mi(sex)
	
drop sex perwt ep_perwt
rename (cln_sex cln_race) (sex race)

order race sex oer rm_m rm_p deming oer
gsort sex

export excel using "$FILE", first(var) sheet("alt_underemp_pcts", replace) 
graph close _all
