************************************************************
*				ITSA
************************************************************
* Created by     : Joshua Dawe
* Last updated   : 28/11/2024
* Project        : OAT prescribing in Victoria
* This file      : Conducts interrupted time series analysis
************************************************************

/// load data ///
use "OAT_scripts_overall_Quarter.dta", clear

/// model setup///

* set data
tsset Quarter

* create an intervention dummy variable (0 before 2019q4, 1 after)
gen post = .
	recode post .=0 if Quarter < 240
	recode post .=1 if Quarter >= 240

* summary statistics for before and after the intervention
bysort post: summ Total
bysort post: summ Methadone
bysort post: summ Buprenorphine

* centre time
gen Quarter_centred = Quarter - 240 

/// modelling ///

* overall prescribing Poisson regression model
glm c.Total c.Quarter_centred##i.post, family(poisson) link(log) eform vce(robust)

* post-intervention trend
lincom  _b[c.Quarter_centred] + _b[1.post#c.Quarter_centred], eform

* predicted values
predict Total_fit, nooffset

* generate the counterfactual
gen Total_fit_cf = exp(_b[_cons] + _b[c.Quarter_centred] * Quarter_centred)
replace Total_fit_cf = exp(_b[_cons] + _b[c.Quarter_centred] * Quarter_centred) if post == 1

* graph overall prescribing
twoway (scatter Total Quarter, mcolor(black)) /// 
       (line Total_fit Quarter, sort lcolor(black) lwidth(medium) lpattern(solid)) ///
       (line Total_fit_cf Quarter, sort lcolor(black) lwidth(medium) lpattern(dash)), ///
       legend(order(1 "Observed" 2 "Predicted" 3 "Counterfactual")) ///
       title("Overall prescribing") ///
       xline(239, lcolor(black) lpattern(shortdash) lwidth(medium)) ///
       xlabel(220(4)255, format(%tqCY)) ///
       graphregion(color(white))
   
* save
graph rename Total, replace  
graph export "Total_poisson_itsa.png", replace

* methadone prescribing Poisson regression model
glm Methadone c.Quarter_centred##i.post, family(poisson) link(log) eform vce(robust)

* post-intervention trend
lincom  _b[c.Quarter_centred] + _b[1.post#c.Quarter_centred], eform

* predicted values
predict Methadone_fit, nooffset

* generate the counterfactual
gen Methadone_fit_cf = exp(_b[_cons] + _b[c.Quarter_centred] * Quarter_centred)
replace Methadone_fit_cf = exp(_b[_cons] + _b[c.Quarter_centred] * Quarter_centred) if post == 1

* graph methadone prescribing
twoway (scatter Methadone Quarter, mcolor(black)) ///
       (line Methadone_fit Quarter, sort lcolor(black) lwidth(medium) lpattern(solid)) ///
       (line Methadone_fit_cf Quarter, sort lcolor(black) lwidth(medium) lpattern(dash)), /// 
       legend(order(1 "Observed" 2 "Predicted" 3 "Counterfactual")) ///
       title("Methadone prescribing") ///
       xline(239, lcolor(black) lpattern(shortdash) lwidth(medium)) ///
	   xlabel(220(4)255, format(%tqCY)) ///
	   graphregion(color(white))

* save
graph rename Methadone, replace 
graph export "Methadone_poisson_itsa.png", replace

* buprenorphine prescribing Poisson regression model
glm c.Buprenorphine c.Quarter_centred##i.post, family(poisson) link(log) eform vce(robust)

* post-intervention trend
lincom  _b[c.Quarter_centred] + _b[1.post#c.Quarter_centred], eform

* predicted values
predict Buprenorphine_fit, nooffset

* generate the counterfactual
gen Buprenorphine_fit_cf = exp(_b[_cons] + _b[c.Quarter_centred] * Quarter_centred)
replace Buprenorphine_fit_cf = exp(_b[_cons] + _b[c.Quarter_centred] * Quarter_centred) if post == 1

* graph
twoway (scatter Buprenorphine Quarter, mcolor(black)) ///
       (line Buprenorphine_fit Quarter, sort lcolor(black) lwidth(medium) lpattern(solid)) ///
       (line Buprenorphine_fit_cf Quarter, sort lcolor(black) lwidth(medium) lpattern(dash)), /// 
	   legend(order(1 "Observed" 2 "Predicted" 3 "Counterfactual")) ///
       title("Buprenorphine prescribing") ///
       xline(239, lcolor(black) lpattern(shortdash) lwidth(medium)) /// 
	   xlabel(220(4)255, format(%tqCY)) ///
	   graphregion(color(white))

* save
graph rename Buprenorphine, replace 
graph export "Buprenorphine_poisson_itsa.png", replace

* define the observation period and interruption point
local interruption_quarter 239 

glm bupre_lai Quarter if Quarter >= `interruption_quarter', family(poisson) link(identity) eform vce(robust)

// generate predicted values
predict bupre_lai_fit if Quarter >= `interruption_quarter'

// plot laib prescribing from interruption onwards
twoway	(scatter bupre_lai Quarter if Quarter >= `interruption_quarter', mcolor(black)) ///
		(line bupre_lai_fit Quarter if Quarter >= `interruption_quarter', sort lcolor(black) lwidth(medium) lpattern(dash)), ///
		legend(order(1 "Observed" 2 "Predicted")) ///
		ytitle("LAIB prescribing") xtitle("Quarter") ///
	    ylabel(0(2000)14000) ///
	    yscale(range(0 14000)) ///
		xlabel(220(4)255, format(%tqCY)) ///
		xline(`interruption_quarter', lcolor(black) lpattern(shortdash)) ///
		graphregion(color(white))

graph rename LAIB, replace 
graph export "Bupre_LAIB_poisson.png", replace

* combine graphs with vertical line
twoway ///
    (scatter Total Quarter, mcolor(black) msize(tiny)) ///
    (line Total_fit Quarter, sort lcolor(black) lwidth(medium)) ///
    (line Total_fit_cf Quarter, sort lcolor(black) lwidth(medium) lpattern(dash)) ///
	(scatter Methadone Quarter, mcolor(blue) msize(tiny)) ///
    (line Methadone_fit Quarter, sort lcolor(blue) lwidth(medium)) ///
    (line Methadone_fit_cf Quarter, sort lcolor(blue) lwidth(medium) lpattern(dash)) ///
	(scatter Buprenorphine Quarter, mcolor(orange) msize(tiny)) ///
    (line Buprenorphine_fit Quarter, sort lcolor(orange) lwidth(medium)) ///
    (line Buprenorphine_fit_cf Quarter, sort lcolor(orange) lwidth(medium) lpattern(dash)) ///
	(scatter bupre_lai Quarter if Quarter >= 239, mcolor(teal) msize(tiny)) /// 
    (line bupre_lai_fit Quarter if Quarter >= 239, sort lcolor(teal) lwidth(medium) lpattern(dash)), /// 
    ytitle("Quarterly number of OAT prescriptions issued") xtitle("Year") ///
    legend(order(1 "Total (Observed)" 2 "Total (Fitted)" 3 "Total (Counterfactual)" 4 "Methadone (Observed)" 5 "Methadone (Fitted)" ///
	6 "Methadone (Counterfactual)" 7 "Buprenorphine (Observed)" 8 "Buprenorphine (Fitted)" 9 "Buprenorphine (Counterfactual)" 10 "LAIB (Observed)" 11 "LAIB (Fitted)")) ///
    xline(239, lcolor(black) lpattern(shortdash) lwidth(medium)) /// 
    xlabel(220(8)255, format(%tqCY)) ///
    graphregion(color(white)) 

graph rename Combined_itsa, replace 
graph export "Combined_itsa.png", width(1200) height(600) replace

/// model checking ///

* checking for seasonality

* create dummy variable for Q1 and Q4
gen q1_q4 = .
	recode q1_q4 .=1 if Quarter == 220 | Quarter == 223 | Quarter == 224 | Quarter == 227 | Quarter == 228 | Quarter == 231 | Quarter == 232 | Quarter == 235 | Quarter == 236 | ///
	Quarter == 239 | Quarter == 240 | Quarter == 243 | Quarter == 244 | Quarter == 247 | Quarter == 248 | Quarter == 251 | Quarter == 252 | Quarter == 255
	recode q1_q4 .=0

* overall prescribing	
glm c.Total c.Quarter##i.post q1_q4, family(poisson) link(log) eform vce(robust)
	
* methadone prescribing
glm c.Methadone c.Quarter##i.post q1_q4, family(poisson) link(log) eform vce(robust)

* buprenorphine prescribing
glm c.Buprenorphine c.Quarter##i.post q1_q4, family(poisson) link(log) eform vce(robust)

* allowing for overdispersion
glm c.Total c.Quarter##i.post, family(poisson) link(log) scale(x2) eform
glm c.Total c.Quarter##i.post, family(poisson) link(log) scale(x2) eform
glm c.Total c.Quarter##i.post, family(poisson) link(log) scale(x2) eform

* tests for autocorrelation
ac Total_fit
graph rename total_ac, replace 
graph export "total_ac.png", replace

pac Total_fit, yw
graph rename total_pac, replace 
graph export "total_pac.png", replace

ac Methadone_fit
graph rename methadone_ac, replace 
graph export "methadone_ac.png", replace

pac Methadone_fit, yw
graph rename methadone_pac, replace 
graph export "methadone_pac.png", replace

ac Buprenorphine_fit
graph rename bupre_ac, replace 
graph export "bupre_ac.png", replace

pac Buprenorphine_fit, yw
graph rename bupre_pac, replace 
graph export "bupre_pac.png", replace
