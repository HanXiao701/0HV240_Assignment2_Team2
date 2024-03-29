/////////////////////////////////////////////////////////////////////////////////
////Workshop Data Analysis part 1__QS in Health 0HM240 2023////
/////////////////////////////////////////////////////////////////////////////////
*This do-file is provided as an example for the data-analysis. Use it smart! 

clear all 						//to clear memory and start with the new fresh dataset again
set more off					//to avoid clicking on 'more' all the time to see more output
graph drop _all					//in case you save graphs by giving them a name, you need to drop them when you run the analysis again
use "QS-2022 data merged.dta" , replace		//load dataset (and replace in case there is still data in memory)
									//this short syntax only works when the dta-file is in the same folder as the do-file. Otherwise, you need to type "C:\..yourfilelocation..\QS-2022 ESM data merged.dta"

*Let's see what we've got:
summarize 						
*Not all is relevant for us now, so let's select what we need:
keep Response_ID Date_submitted Participant_ID Affect Energy Stress Mood Motivation

*********Transformation of the data, to make it convenient to use***************
rename Participant_ID student 		//because typing 'student' is easier
label variable student "Participant ID"  // label for graphs

*We will create seperate date / time variables first:
gen Date = substr(Date_submitted,1,10)
gen Time = substr(Date_submitted,12,8)

* Now we want to make variables for the order of the measurements: a variable for 
* the n-th measurement per student, lets call it [time], a number for the n-th
* day, let's call it [day], and a number for the n-th measurement on that
* specific day, let's call it [timeonday]. You don't need to have a detailed 
* understanding of these commands, you may just assume that it works, and check
* if you understand the resulting variables. 

egen day=group(Date)
tab Date day //only run this command to check if it works as expected 

sort student day Response_ID
by student: gen time=_n			 //Generates a number for the n-th measurement per student
by student day: gen timeonday=_n //Generates a number for the n-th measurement per student on a specific day
*Run the following line (delete the *) to browse the data and check if it worked as planned, and make sure you understand what the variables comprise. 
*browse student Date_submitted Date Time day time timeonday 

drop if Date_submitted == "" 	//drop the missing values, we cannot use them 

*Now we will check the dependent variables one by one and see if they make sense to us:

//AFFECT -> SLEEPINESS//
rename Affect Sleepiness_original 	//it seems like something went wrong in the labelling here, as the descriptions clearly refer to sleepiness
egen Sleepiness_temp = group(Sleepiness_original)
tab Sleepiness_original Sleepiness_temp //check assigned values for the various labels
gen Sleepiness = .
replace Sleepiness = 4 if Sleepiness_temp == 1
replace Sleepiness = 7 if Sleepiness_temp == 2
replace Sleepiness = 1 if Sleepiness_temp == 3
replace Sleepiness = 5 if Sleepiness_temp == 4
replace Sleepiness = 2 if Sleepiness_temp == 5
replace Sleepiness = 3 if Sleepiness_temp == 6
replace Sleepiness = 6 if Sleepiness_temp == 7

/* given the coding:
1=Feeling active, vital, alert, or wide awake
2=Functioning at high levels, but not at peak; able to concentrate
3=Relaxed, awake, not at full alertness, responsive
4=A little foggy, not at peak, let down
5=Fogginess, beginning to lose interest in remaining awake, slowed down
6=Sleepiness, prefer to be lying down, fighting sleep, woozy
7=Almost in reverie, sleep onset soon, lost struggle to remain awake
*/

*to check if it went well:
tab Sleepiness Sleepiness_original 	//yes, check, it worked as expected
drop Sleepiness_temp

//VITALITY//
hist Energy
*all good

//STRESS//
*We should be aware that high values correspond to 'calm' and low numbers to 'tense'. Since the variable is named Stress, I suggest to flip it:
rename Stress Stress_original
gen Stress = 10-Stress_original
*scatter Stress Stress_original
*all good
drop Stress_original

//MOOD -> HAPPY//
rename Mood Happy 	//I feel that 'happy' describes it better than 'mood'

//MOTIVATION//
replace Motivation = "1" if Motivation == "not motivated at all"
replace Motivation = "2" if Motivation == "somewhat motivated"
replace Motivation = "3" if Motivation == "neutral"
replace Motivation = "4" if Motivation == "motivated"
replace Motivation = "5" if Motivation == "strongly motivated"
destring Motivation, replace

*********Inspect data, to get a first idea what is in there******************
sum student day time timeonday Sleepiness Energy Stress Happy Motivation

*Please delete the (*) in the rows below to generate the graphs. For now I just "commented them out", because drawing them 
*takes quite a lot of time everytime we run our script. 
tab day timeonday										//most of the days, students responded 3-7 times. 
														//Most replies on the second day. Also we see a little increase on the last day.
*hist day, by(student) freq xtitle("Day of week")		//some students were more responsive than others
*scatter Sleepiness time, by(student) connect(l) xtitle("Nr. of assessment") ytitle("Sleepiness")				
//when you want to keep a graph on your screen - and not overwrite it as soon as you make another picture, write 'name(yournameforthegraph)' after the comma
*scatter Energy time, by(student) connect(l) xtitle("Nr. of assessment") ytitle("Vitality (0=Depleted-10=Energetic)")

*graph twoway (scatter Stress timeonday if day==1, by(student) connect(l) xtitle("Nr. of assessment per day") ytitle("Stress (0=Relaxed-10=Tense)")) (scatter Stress timeonday if day==2, by(student) connect(l)) (scatter Stress timeonday if day==3, by(student) connect(l)) (scatter Stress timeonday if day==4, by(student) connect(l)) (scatter Stress timeonday if day==5, by(student) connect(l)), legend(label(1 Day 1) label(2 Day 2) label(3 Day 3) label(4 Day 4) label(5 Day 5))

*hist Happy, by(student) freq xtitle("Happy")	//you might also want to see the distribution for every student


*Visualize correlations for all (pairs of) variables
*To this end, we will work with standardized variables (mean=0 and std=1).
*We will use small caps for the std-variables, so we can easily go back to the original variables if required. 
egen sleepiness=std(Sleepiness)
egen energy=std(Energy)
egen stress=std(Stress)
egen happy=std(Happy)
egen motivation=std(Motivation)
summarize 

*pwcorr sleepiness energy stress happy motivation, sig star(0.05)	//you can use this command to compute the correlations (but note: our data is nested..)
*scatter sleepiness energy	 										//example of relation
graph matrix sleepiness energy stress happy motivation, jitter(2) half 	//to create all scatterplots of all possible pairs


*********Analysis of the data***************************************************

*Pick two variables, e.g.,
//HAPPY & STRESS


//unconditional model	//clustering of the data needed? --> let's test with a model without fixed part (i.e., without predictors)
mixed Happy				//no clustering of the data
estimates store unconditional_reg
mixed Happy || student:	//adding random intercept
estimates store unconditional_mixed
lrtest unconditional_reg unconditional_mixed // just to illustrate that this is the same value as provided in the results of the null model
estat icc 				//compute intra-class correlation
predict residuals_unconditional_mixed, res	//store residuals
swilk residuals_unconditional_mixed			//shapiro-wilk test to check normality of residuals

//now the conditional models
//Group level (for which we actually know that this isn't the correct analyses, but let's run for illustrative purposes)
reg Happy Stress
mixed Happy Stress		//This comes down to a normal regression, but to compare the likelihoods later on, we need a mixed command here.
estimates store A

//corresponding graphs
*scatter Happy Stress
*scatter Happy Stress || lfit Happy Stress 


//Random intercept model
mixed Happy Stress	 || student:
estimates store B
predict residuals_B, res	//store residuals
swilk residuals_B			//shapiro-wilk test to check normality of residuals
//corresponding graphs
predict pred_cons_student, reffect relevel(student)								//store prediction of model, to plot it later in scatterplot
//plot intercepts deviation across participants
gen zero = 0
twoway  (rspike zero pred_cons_student student, horizontal) (scatter student pred_cons_student, msize(1) mlabsize(1) mlabposition(0)) if time==1, xtitle("Deviation from overall intercept") legend(off)

gen pred_Stress=(pred_cons_student+_b[Happy:_cons])+_b[Happy:Stress]*Stress	//finish modelprediction by combining coefficients with estimations
scatter Happy pred_Stress Stress, by(student,legend(off)) jitter(2) connect(. l) ytitle("Happy")  //make graph of both data and model prediction
drop pred*																		//if you don't drop all predictions, Stata will give you errors when you want to make another model prediction


//Random slope model
mixed Happy Stress	 || student:Stress
estimates store C
predict residuals_C, res	//store residuals
swilk residuals_C			//shapiro-wilk test to check normality of residuals

//corresponding graphs
predict pred_slope_student pred_cons_student, reffect relevel(student)			//store prediction of model, to plot it later in scatterplot
//plot slope deviation across participants
twoway  (rspike zero pred_slope_student student, horizontal) (scatter student pred_slope_student, msize(1) mlabsize(1) mlabposition(0)) if time==1, xtitle("Deviation from fixed slope") legend(off)

gen pred_Stress= (pred_cons_student+_b[Happy:_cons])+(pred_slope_student+_b[Happy:Stress])*Stress //finish modelprediction by combining coefficients with estimations, a bit more complex than in the random intercept model
scatter Happy pred_Stress Stress, by(student,legend(off)) jitter(2) connect(. l) ytitle("Happy") //make graph of both data and model prediction
drop pred* 														//drop again


//Likelihoodratio test
lrtest A B
lrtest B C


**2-level or 3-level model? //note that the data could also be described as a 3-level model, which we ignored so far

//to test this, we will use unconditional models (also called null models)
mixed Happy || student:						//2-level model
estimates store nullModel_2level
mixed Happy || student: ||day:				//3-level model
estimates store nullModel_3level
lrtest nullModel_2level nullModel_3level


**we also ignored the centering of the variables. For this, you can either grand-mean or group-mean centering. The first refers to centering all scores around the overall mean, and group-mean centering refers to centering around the cluster mean (i.e., the person's average score)


**grand-mean center scores --> compute deviations from the overall mean
egen Sleepiness_GrandMean = mean(Sleepiness)
egen Energy_GrandMean = mean(Energy)
egen Stress_GrandMean = mean(Stress)
egen Happy_GrandMean = mean(Happy)
egen Motivation_GrandMean = mean(Motivation)

//grand-mean center observations by extracting grand mean from each observation
gen Sleepiness_GMC = Sleepiness-Sleepiness_GrandMean
gen Energy_GMC= Energy-Energy_GrandMean
gen Stress_GMC= Stress-Stress_GrandMean
gen Happy_GMC= Happy-Happy_GrandMean
gen Motivation_GMC= Motivation-Motivation_GrandMean

//now run the models with the grand-mean scores for stress as predictorv (note that we don't use the grand-mean score for the outcome parameter. Why?)
mixed Happy Stress_GMC || student: ||day:				//random intercepts for student and day (nested in student)
predict residuals_D, res	//store residuals
swilk residuals_D			//shapiro-wilk test to check normality of residuals

mixed Happy Stress_GMC || student:Stress_GMC ||day:		//random intercepts + random slope (at participant level --> to what extent do the slopes vary across participants?)
predict residuals_E, res	//store residuals
swilk residuals_E			//shapiro-wilk test to check normality of residuals

**cluster-mean center scores
//compute averages per student
bysort student: egen Sleepiness_ClusterMean = mean(Sleepiness)
bysort student: egen Energy_ClusterMean = mean(Energy)
bysort student: egen Stress_ClusterMean = mean(Stress)
bysort student: egen Happy_ClusterMean = mean(Happy)
bysort student: egen Motivation_ClusterMean = mean(Motivation)
//compute cluster-mean centered scores by extracting students' mean values from the raw scores --> compute deviations from the person's mean
gen Sleepiness_CMC = Sleepiness - Sleepiness_ClusterMean
gen Energy_CMC = Energy - Energy_ClusterMean
gen Stress_CMC = Stress - Stress_ClusterMean
gen Happy_CMC = Happy - Happy_ClusterMean
gen Motivation_CMC = Motivation - Motivation_ClusterMean

//center cluster mean scores by extracting grand mean from each students cluster mean
gen Sleepiness_ClusterMean_centered = Sleepiness_ClusterMean-Sleepiness_GrandMean
gen Energy_ClusterMean_centered = Energy_ClusterMean-Energy_GrandMean
gen Stress_ClusterMean_centered = Stress_ClusterMean-Stress_GrandMean
gen Happy_ClusterMean_centered = Happy_ClusterMean-Happy_GrandMean
gen Motivation_ClusterMean_centered = Motivation_ClusterMean-Motivation_GrandMean

mixed Happy Stress_CMC Stress_ClusterMean_centered || student: || day:			//random intercepts for student and day (nested in student)
predict residuals_F, res	//store residuals
swilk residuals_F			//shapiro-wilk test to check normality of residuals

mixed Happy Stress_CMC Stress_ClusterMean_centered|| student:Stress_CMC || day:	//random intercepts + random slope (at participant level --> to what extent do the slopes vary across participants?)
predict residuals_G, res	//store residuals
swilk residuals_G			//shapiro-wilk test to check normality of residuals



