************************************************************
*				ITSA
************************************************************
* Created by     : Joshua Dawe
* Last updated   : 28/11/2024
* Project        : OAT prescribing in Victoria
* This file      : Conducts interrupted time series analysis
************************************************************

/// simulate data ///
version 18
clear

* NOTE: this data is simulated for demonstration purposes only

* input columns
input Quarter post Quarter_seq Quarter_after
220	0	0	0
221	0	1	0
222	0	2	0
223	0	3	0
224	0	4	0
225	0	5	0
226	0	6	0
227	0	7	0
228	0	8	0
229	0	9	0
230	0	10	0
231	0	11	0
232	0	12	0
233	0	13	0
234	0	14	0
235	0	15	0
236	0	16	0
237	0	17	0
238	0	18	0
239	1	19	0
240	1	20	1
241	1	21	2
242	1	22	3
243	1	23	4
244	1	24	5
245	1	25	6
246	1	26	7
247	1	27	8
248	1	28	9
249	1	29	10
250	1	30	11
251	1	31	12
252	1	32	13
253	1	33	14
254	1	34	15
255	1	35	16
end

format Quarter %tq

* simulate quarterly number of prescriptions
set obs 36  
generate Methadone = 5000 + (10000 - 5000) * runiform()
generate Buprenorphine = 3000 + (6000 - 3000) * runiform()
generate bupre_lai = 0
replace bupre_lai = (0 + (3000 - 0) * runiform() ) if Quarter >= 239
generate Total = Methadone + Buprenorphine + bupre_lai

/// modelling ///

* summary statistics for before and after the intervention
bysort post: summ Total
bysort post: summ Methadone
bysort post: summ Buprenorphine

* overall prescribing Poisson regression model
glm Total Quarter_seq post c.post#c.Quarter_after, family(poisson) link(log) eform vce(robust)

* post-intervention trend
lincom  _b[Quarter_seq] + _b[post#Quarter_after], eform

* predicted values
predict Total_fit, nooffset

* generate the counterfactual
gen Total_fit_cf = exp(_b[_cons] + _b[c.Quarter_seq] * Quarter_seq)
replace Total_fit_cf = exp(_b[_cons] + _b[c.Quarter_seq] * Quarter_seq) if post == 1
  
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

* methadone prescribing Poisson regression model
glm Methadone Quarter_seq post c.post#c.Quarter_after, family(poisson) link(log) eform vce(robust)

* post-intervention trend
lincom  _b[Quarter_seq] + _b[post#Quarter_after], eform

* predicted values
predict Methadone_fit, nooffset

* generate the counterfactual
gen Methadone_fit_cf = exp(_b[_cons] + _b[c.Quarter_seq] * Quarter_seq)
replace Methadone_fit_cf = exp(_b[_cons] + _b[c.Quarter_seq] * Quarter_seq) if post == 1

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

* buprenorphine prescribing Poisson regression model
glm Buprenorphine Quarter_seq post c.post#c.Quarter_after, family(poisson) link(log) eform vce(robust)

* post-intervention trend
lincom  _b[Quarter_seq] + _b[post#Quarter_after], eform

* predicted values
predict Buprenorphine_fit, nooffset

* generate the counterfactual
gen Buprenorphine_fit_cf = exp(_b[_cons] + _b[c.Quarter_seq] * Quarter_seq)
replace Buprenorphine_fit_cf = exp(_b[_cons] + _b[c.Quarter_seq] * Quarter_seq) if post == 1

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
    xlabel(220(4)255, format(%tqCY)) ///
    graphregion(color(white)) 

graph rename Combined_itsa, replace 

/// model checking ///

* checking for seasonality

* create dummy variable for Q1 and Q4
gen q1_q4 = .
	recode q1_q4 .=1 if Quarter == 220 | Quarter == 223 | Quarter == 224 | Quarter == 227 | Quarter == 228 | Quarter == 231 | Quarter == 232 | Quarter == 235 | Quarter == 236 | ///
	Quarter == 239 | Quarter == 240 | Quarter == 243 | Quarter == 244 | Quarter == 247 | Quarter == 248 | Quarter == 251 | Quarter == 252 | Quarter == 255
	recode q1_q4 .=0

* overall prescribing	
glm Total Quarter_seq post c.post#c.Quarter_after i.q1_q4, family(poisson) link(log) eform vce(robust)
	
* methadone prescribing
glm Methadone Quarter_seq post c.post#c.Quarter_after i.q1_q4, family(poisson) link(log) eform vce(robust)

* buprenorphine prescribing
glm Buprenorphine Quarter_seq post c.post#c.Quarter_after i.q1_q4, family(poisson) link(log) eform vce(robust)

* allowing for overdispersion
glm Total Quarter_seq post c.post#c.Quarter_after, family(poisson) link(log) scale(x2) eform 
glm Methadone Quarter_seq post c.post#c.Quarter_after, family(poisson) link(log) scale(x2) eform
glm Buprenorphine Quarter_seq post c.post#c.Quarter_after, family(poisson) link(log) scale(x2) eform

* tests for autocorrelation
tsset Quarter_seq

ac Total_fit
graph rename total_ac, replace 

pac Total_fit, yw
graph rename total_pac, replace 

ac Methadone_fit
graph rename methadone_ac, replace 

pac Methadone_fit, yw
graph rename methadone_pac, replace 

ac Buprenorphine_fit
graph rename bupre_ac, replace 

pac Buprenorphine_fit, yw
graph rename bupre_pac, replace 
