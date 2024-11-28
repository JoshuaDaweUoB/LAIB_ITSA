************************************************************
*				Data cleaning
************************************************************
* Created by     : Joshua Dawe
* Last updated   : 27/07/2024
* Project        : OAT prescribing in Victoria
* This file      : Cleans and manipulates data
************************************************************

* housekeeping
set more off ,perm
clear

* load baseline data
use "baseline_oat_clean.dta", clear

recode bupre 1=. if bupre_lai == 1

* define time periods

* Year var
gen Year = year(d_event_dte) 
ta Year,m 

* Quarterly var
gen Quarter = qofd(d_event_dte)
format Quarter %tq
	
* Month var
gen Month = mofd(d_event_dte)
format Month %tmMonYY
sort Month
la var Month "Month/year"	

* restrict to 2013-2023
drop if Year > 2023
drop if Year < 2013 

* QA checking sites
tab site_id
tab site_id, nolab

tab LocationName
tab LocationName, nolab

* very low caseload clinics
drop if site_id == 2003 
drop if site_id == 2014 
drop if site_id == 2023
drop if site_id == 2036
drop if site_id == 2031
drop if site_id == 2037
drop if site_id == 2031
drop if site_id == 2029

* problem clinics
drop if site_id == 2026
drop if site_id == 2033 // drop old "clinic name ommited" data
drop if site_id == 2021 // "clinic name ommited"  not in ACCESS
drop if site_id == 2015 // "clinic name ommited"  missing data from 2019 onwards

* check for sites with inconsistent or missing years
tab Year site_id
tab Year site_id, nolab // drops in 2020 ("clinic name ommited" ) & 2025 ("clinic name ommited" )

* check for inconsistent or missing months
tab Quarter site_id if site_id == 2020 | site_id == 2025
tab Quarter site_id if site_id == 2020 | site_id == 2025, nolab

* need to look a bit more into "clinic name ommited" 
tab Month site_id if site_id == 2025, nolab // May 2021 was a bumper month, Jan 2021 was slow
tab d_event_dte if (d_event_dte > date("16may2021","DMY") & d_event_dte < date("26may2021","DMY")) & site_id == 2025, nolab // 1,414 scripts written on 22nd May 2021

* sequence IDs to see how many individuals prescribed
bysort link_id: egen id_seq_"clinic name ommited"  = seq() if d_event_dte == date("22may2021","DMY") & site_id == 2025
/* id_seq_"clinic name ommited"  |
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |        839       59.34       59.34
          2 |        363       25.67       85.01
          3 |        152       10.75       95.76
          4 |         50        3.54       99.29
          5 |          9        0.64       99.93
          6 |          1        0.07      100.00
------------+-----------------------------------
      Total |      1,414      100.00

- quite a few people scripted multiple times in one day	  
- a lot still scripted once

*/
format scr_script_dte %td
br link_id d_drug_name scr_drug_qty scr_drug_strength scr_dose scr_rpts if d_event_dte == date("22may2021","DMY") & site_id == 2025

* drop 22nd May 
drop if d_event_dte == date("22may2021","DMY") & site_id == 2025

* check for sites with inconsistent or missing years
tab Year site_id

* Variable creation

* Sequence OST script
gen Total = 1 
sort link_id d_event_dte
by link_id, sort: egen ost_seq = seq() 	
ta ost_seq, m 
su ost_seq, de

* staff sequence
sort STAFFID d_event_dte
by STAFFID, sort: egen staff_id = seq() 	
ta ost_seq, m 
su ost_seq, de

* sex
gen Male = 1 if patient_sex == 1
gen Female = 1 if patient_sex == 2
gen Unknown = 1 if patient_sex == .u
drop if patient_sex == 3

* age
gen age = Year-patient_yob
replace age = . if age > 105

gen Age =.
	replace Age=1 if age>=15 & age<30
	replace Age=2 if age>=30 & age<40
	replace Age=3 if age>=40 & age<50
	replace Age=4 if age>=50 & age<60
	replace Age=5 if age>=60 & age !=.

	label define Age 1 "15-29" 2 "30-39" 3 "40-49" 4 "50-59" 5 "60+", modify 
	label values Age Age
	label variable Age "Age group - 5 groups"

* age vars
gen age_18to29 = 1 if Age == 1
gen age_30to39 = 1 if Age == 2
gen age_40to49 = 1 if Age == 3
gen age_50to59 = 1 if Age == 4
gen age_60plus = 1 if Age == 5

* Label variables
label variable ost_seq "Individual's OST script event sequence"
label variable d_drug_name "Drug name"
label variable scr_dose "Script dose"
label variable scr_rpts "Script repeats"
label variable scr_drug_qty "Script quantity"
label variable scr_drug_strength "Script strength"
label variable scr_script_dte "Script date"

* Create OAT categories
gen oat_type = .
	recode oat_type .=1 if meth == 1
	recode oat_type .=2 if bupre == 1
	recode oat_type .=3 if bupre_lai == 1
	recode oat_type .=4 if nalt == 1

la def oat_type 1 "Methadone" 2 "Buprenorphine" 3 "LAI" 4 "Naltrexone"
la val oat_type oat_type

tab oat_type, m

drop if oat_type == . // 4461 missing 
tab naloxone // 4461 all naloxone

la var meth "Methadone"
la var bupre "Buprenorphine"

rename meth Methadone
rename bupre Buprenorphine
rename naloxone Naloxone
rename d_event_dte Day


drop if Year > 2023
drop if Year < 2012

drop if LocationName == "Undefined" & site_id == 2019 & scr_script_dte == date("01jul2018","DMY")
drop if LocationName == "Undefined" & site_id == 2019 & scr_script_dte == date("02jul2018","DMY")

* save dataset
save "baseline_oat_analysis.dta", replace





