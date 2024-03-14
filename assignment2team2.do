clear all 						
set more off					
graph drop _all					
use "Data_2024.dta" , replace		
								

*Let's see what we've got:
summarize 						
*Not all is relevant for us now, so let's select what we need:
keep Date_submitted Participant_ID Sleepiness Energetic_sliderNegPos Stress_sliderNegPos Happy_smiley Motivation TimeOutdoors 
*********Transformation of the data, to make it convenient to use***************
rename Participant_ID student 
rename Energetic_sliderNegPos energylevel
rename Stress_sliderNegPos stresslevel
rename Sleepiness sleepiness
rename Happy_smiley happiness
rename Motivation motivation
rename TimeOutdoors timeoutdoors	
label variable student "Participant ID"  

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

sort student day 
by student: gen time=_n			 //Generates a number for the n-th measurement per student
by student day: gen timeonday=_n //Generates a number for the n-th measurement per student on a specific day
*Run the following line (delete the *) to browse the data and check if it worked as planned, and make sure you understand what the variables comprise. 
*browse student Date_submitted Date Time day time timeonday 

drop if Date_submitted == "" 	//drop the missing values

*Now we will check the dependent variables one by one and see if they make sense to us:
//MOTIVATION//
replace motivation = "1" if motivation == "Not motivated at all"
replace motivation = "1" if motivation == "not motivated at all" 
* In older versions of the survey, there was no capital letter in the answer, so we have to change this twice
replace motivation = "2" if motivation == "somewhat motivated"
replace motivation = "3" if motivation == "neutral"
replace motivation = "4" if motivation == "motivated"
replace motivation = "5" if motivation == "strongly motivated"
destring motivation, replace
tab motivation

replace sleepiness = "1" if sleepiness == "Almost in reverie, sleep onset soon, lost struggle to remain awake" // different answers in previous years, so we have to do the same as before and recode two different answers to one number
replace sleepiness = "1" if sleepiness == "Sleepiness, prefer to be lying down, fightine sleep, woozy"
replace sleepiness = "1" if sleepiness == "Sleepy, woozy, struggling to sleep, prefer to lie down"
replace sleepiness = "2" if sleepiness == "Fogginess, beginning to lose interest in remaining awake, slowed down"
replace sleepiness = "3" if sleepiness == "A little fogy, not at peak, let down"
replace sleepiness = "3" if sleepiness == "A little foggy, not at peak, let down" // typo in some responses but not all
replace sleepiness = "4" if sleepiness == "Relaxed, awake, not at full alertness, responsive"
replace sleepiness = "5" if sleepiness == "Functioning at high levels, but not at peak, able to concentrate"
replace sleepiness = "6" if sleepiness == "Feeling active, vital, alert or wide awake"
replace sleepiness = "6" if sleepiness == "Feeling active, vital, alert, or wide awake" // once again different spellings
destring sleepiness, replace
tab sleepiness

** energylevel
sum energylevel
tab energylevel // nothing weird to see here

rename stresslevel Stress_original
gen stresslevel = 100-Stress_original
scatter stresslevel Stress_original

*********Inspect data, to get a first idea what is in there******************
tab day timeonday				
sum student day time timeonday sleepiness energylevel stresslevel happiness motivation						
hist day, by(student) freq xtitle("Day of week")		// data looks a little strange, like people answered only in the first half or the second half of the dates. This could be due to the fact that we have data over multiple years, but this is something to keep in mind when further analyzing 
scatter motivation time, by(student) connect(l) xtitle("Nr. of assessment") ytitle("Motivation")		// 

//when you want to keep a graph on your screen - and not overwrite it as soon as you make another picture, write 'name(yournameforthegraph)' after the comma
scatter energylevel time, by(student) connect(l) xtitle("Nr. of assessment") ytitle("Vitality (0=Depleted-10=Energetic)")

//graph twoway (scatter Stress timeonday if day==1, by(student) connect(l) xtitle("Nr. of assessment per day") ytitle("Stress (0=Relaxed-10=Tense)")) (scatter Stress timeonday if day==2, by(student) connect(l)) (scatter Stress timeonday if day==3, by(student) connect(l)) (scatter Stress timeonday if day==4, by(student) connect(l)) (scatter Stress timeonday if day==5, by(student) connect(l)), legend(label(1 Day 1) label(2 Day 2) label(3 Day 3) label(4 Day 4) label(5 Day 5))

*hist Happy, by(student) freq xtitle("Happy")	//you might also want to see the distribution for every student


*Visualize correlations for all (pairs of) variables
*To this end, we will work with standardized variables (mean=0 and std=1).
*We will use small caps for the std-variables, so we can easily go back to the original variables if required. 
egen sleepy=std(sleepiness)
egen energy=std(energylevel)
egen stress=std(stresslevel)
egen happy=std(happiness)
egen motivationstd=std(motivation)
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



