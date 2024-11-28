************************************************************
*				OAT Tables
************************************************************
* Created by     : Joshua Dawe
* Last updated   : 01/08/2024
* Project        : OAT prescribing in Victoria
* This file      : Creates OAT Excel tables
************************************************************

* housekeeping
set more off ,perm
clear

******** Overall OAT prescribing ********

* set macro
local values "Quarter Year"

foreach value of local values {

* load 
use ".\baseline_oat_analysis", clear

* drop
drop if Year < 2015
keep if Year <= 2023
keep if Naloxone != 1
drop if nalt == 1

* collapse 
collapse (rawsum) Total Methadone Buprenorphine bupre_lai Male Female Unknown age_18to29 age_30to39 age_40to49 age_50to59 age_60plus, by(`value')

* save
save ".\OAT_scripts_overall_`value'.dta", replace
export excel ".\OAT_scripts_overall_`value'.xlsx", firstrow(variables) replace
}

*

******** Individual OAT prescribing ********

local values "Quarter Year"

foreach value of local values {

* load 
use ".\baseline_oat_analysis", clear
drop if nalt == 1
drop if Year < 2015
keep if Year <= 2023
keep if Naloxone != 1

* OAT 
foreach var of varlist Methadone Buprenorphine bupre_lai{
bysort link_id `value': egen `var'_all = max(`var')
recode `var' .=0
}

* bupre and methadone
gen multiple = .
	recode multiple . = 1 if Methadone_all == 1 & Buprenorphine_all == 1
	recode multiple . = 1 if Methadone_all == 1 & bupre_lai_all == 1
	recode multiple . = 1 if bupre_lai_all == 1 & Buprenorphine_all == 1
	recode multiple . = 1 if Methadone_all == 1 & Buprenorphine_all == 1 & bupre_lai_all == 1
	
foreach var of varlist Methadone_all Buprenorphine_all bupre_lai_all {
recode `var' 1=0 if multiple ==1.
}

* demographics
foreach var of varlist Total  {
bysort link_id `value': egen `var'_all = min(`var')
}

* keep first record for each time period
bysort link_id `value': egen id_seq = seq()
keep if id_seq == 1

* collapse by time period
collapse (rawsum) Total Methadone_all Buprenorphine_all bupre_lai_all multiple  Male Female Unknown age_18to29 age_30to39 age_40to49 age_50to59 age_60plus, by(`value')

* save 
save ".\OAT_scripts_person_`value'.dta", replace
export excel ".\OAT_scripts_person_`value'.xlsx", firstrow(variables) replace

}
*

******** OAT total sample ********

* load 
use ".\baseline_oat_analysis", clear
drop if nalt == 1
drop if Year < 2015
keep if Year <= 2023
keep if Naloxone != 1

* OAT 
foreach var of varlist Methadone Buprenorphine bupre_lai{
bysort link_id: egen `var'_all = max(`var')
recode `var' .=0
}

* bupre and methadone
gen multiple = .
	recode multiple . = 1 if Methadone_all == 1 & Buprenorphine_all == 1
	recode multiple . = 1 if Methadone_all == 1 & bupre_lai_all == 1
	recode multiple . = 1 if bupre_lai_all == 1 & Buprenorphine_all == 1
	recode multiple . = 1 if Methadone_all == 1 & Buprenorphine_all == 1 & bupre_lai_all == 1
	
foreach var of varlist Methadone_all Buprenorphine_all bupre_lai_all {
recode `var' 1=0 if multiple ==1.
}

* demographics
foreach var of varlist Total  {
bysort link_id: egen `var'_all = min(`var')
}

* keep first record
bysort link_id: egen id_seq = seq()
keep if id_seq == 1

* collapse by time period
collapse (rawsum) Total Methadone_all Buprenorphine_all bupre_lai_all multiple  Male Female Unknown age_18to29 age_30to39 age_40to49 age_50to59 age_60plus

* save 
save ".\OAT_scripts_person_total.dta", replace
export excel ".\OAT_scripts_person_total.xlsx", firstrow(variables) replace

******** OAT type at first script ********

* set macro
local values "Quarter Year"

foreach value of local values {

* load 
use ".\baseline_oat_analysis", clear

* drop
keep if Naloxone != 1
drop if nalt == 1

* sequence oat prescriptions
sort link_id Day
bysort link_id: egen oat_seq = seq()

* keep first script 
keep if oat_seq == 1

* drop
keep if Year >= 2015
keep if Year <= 2023

* collapse 
collapse (rawsum) Total Methadone Buprenorphine bupre_lai Male Female Unknown age_18to29 age_30to39 age_40to49 age_50to59 age_60plus, by(`value')

* save data
save ".\OAT_scripts_person_first_`value'.dta", replace
export excel ".\OAT_scripts_person_first_`value'.xlsx", firstrow(variables) replace
}
*


