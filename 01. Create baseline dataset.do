************************************************************
*				Baseline dataset
************************************************************
* Created by     : Joshua Dawe
* Last updated   : 09/08/2023
* Project        : OAT prescribing in Victoria
* This file      : Create dataset for analysis
************************************************************

* housekeeping
set more off ,perm
clear

* load script data
use "script_l2.dta", clear
count

* reduce to Victoria to reduce size
keep if state == "VIC"

* Condense drug names
gen d_drug_name = scr_drugname_gen+"_"+scr_drugname_trade

* Keep columns of interest 
keep link_id d_event_dte site_id d_drug_name scr_script_dte scr_drug_qty scr_drug_strength scr_dose scr_reason scr_stopreason scr_rpts state STAFFID LocationName
order link_id d_event_dte site_id d_drug_name scr_script_dte scr_drug_qty scr_drug_strength scr_dose scr_reason scr_stopreason scr_rpts state STAFFID LocationName

* generate oat flag
gen oat_flag = .	
	recode oat_flag .=1 if regexm(d_drug_name, "METHADO")
	recode oat_flag .=1 if regexm(d_drug_name, "BIODONE")
	recode oat_flag .=1 if regexm(d_drug_name, "NALTREXONE")
	recode oat_flag .=1 if regexm(d_drug_name, "REVIA")
	recode oat_flag .=1 if regexm(d_drug_name, "SUBUTEX")
	recode oat_flag .=1 if regexm(d_drug_name, "BUPRE")
	recode oat_flag .=1 if regexm(d_drug_name, "NALOX")
	recode oat_flag .=1 if regexm(d_drug_name, "BUVIDAL")
	recode oat_flag .=1 if regexm(d_drug_name, "SUBLOCADE")
	recode oat_flag .=1 if regexm(d_drug_name, "SUBOXONE")
	
* drop non-oat scripts
drop if oat_flag !=1
count // 

* drop naloxone only
gen naloxone = .
	recode naloxone .=1 if regexm(d_drug_name, "NALOX") & !regexm(d_drug_name, "BUPRE") & !regexm(d_drug_name, "SUBOXONE")
recode oat_flag 1=. if naloxone == 1

* drop patch based medications
gen patch = .
	recode patch .=1 if regexm(d_drug_name, "PATCH")
	recode patch .=1 if regexm(d_drug_name, "NORSPAN")
drop if patch == 1

* save baseline OAT data
save "baseline_oat.dta", replace

* load data 
use "baseline_oat.dta", clear

* methadone
gen meth = .
		recode meth .=1 if regexm(d_drug_name,"METHADONE") & oat_flag == 1
		recode meth .=1 if regexm(d_drug_name,"BIODONE") & oat_flag == 1
		recode meth .=1 if regexm(d_drug_name,"DOLOPHINE")  & oat_flag == 1
		recode meth .=1 if regexm(d_drug_name,"METHADOSE") & oat_flag == 1

* buprenorphine
gen bupre = .
		recode bupre .=1 if regexm(d_drug_name, "BUPRE") & oat_flag == 1
		recode bupre .=1 if regexm(d_drug_name, "SUBOXONE") & oat_flag == 1
		recode bupre .=1 if regexm(d_drug_name, "SUBLOCADE") & oat_flag == 1 
		recode bupre .=1 if regexm(d_drug_name, "BUVIDAL") & oat_flag == 1
		recode bupre .=1 if regexm(d_drug_name, "SUBUTEX") & oat_flag == 1

* LAI buprenorphine
gen bupre_lai = .
		recode bupre_lai .=1 if bupre == 1 & regexm(d_drug_name, "INJECT") 
		recode bupre_lai .=1 if bupre == 1 & regexm(d_drug_name, "SUBLOCADE") 
		recode bupre_lai .=1 if bupre == 1 & regexm(d_drug_name, "BUVIDAL") 

recode bupre 1=. if bupre_lai == 1

* naltrexone
gen nalt = .
		recode nalt .=1 if regexm(d_drug_name,"NALTRE") & oat_flag == 1
		recode nalt .=1 if regexm(d_drug_name,"REVIA") & oat_flag == 1
		recode nalt .=1 if regexm(d_drug_name,"VIVITROL") & oat_flag == 1

* remove painkiller with naloxone
drop if regexm(d_drug_name,"TARGIN") & naloxone == 1
drop if regexm(d_drug_name,"OXYCODONE") & naloxone == 1

recode bupre 1=. if bupre_lai == 1

ta meth, m // 375,425 19/10/2021; 473,286 09/08/2023 
ta bupre, m // 212,022 19/10/2021; 293,045 09/08/2023
tab oat_flag, m // 589,801 19/10/2021; 769,771 09/08/2023
tab naloxone, m // 24,472 19/10/2021; 4,615 09/08/2023
tab nalt, m // 3,440 09/08/2023
distinct link_id if oat_flag == 1 // 21283 09082023

* merge in demographics
merge m:1 link_id using "\demographics_l3.dta"
keep if _merge==3

* save dataset
save "\baseline_oat_clean.dta", replace 
