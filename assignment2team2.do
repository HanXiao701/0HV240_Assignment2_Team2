clear all 						
set more off					
graph drop _all					
use "Data_2024.dta" , replace		
								

*Let's see what we've got:
*summarize 						
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

tab student // lots of high numbers give problems with graphs later on, so we want to recode this variable
// Also there are some people that barely answered any questions, so we might need to think about deleting some

*We will create seperate date / time variables first:
gen Date = substr(Date_submitted,1,10)
gen Time = substr(Date_submitted,12,8)

tab Date if student == 136569
drop if student == 136569

tab Date if student == 233885
drop if student == 233885

tab Date if student == 325430 
drop if student == 325430 

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

replace sleepiness = "6" if sleepiness == "Almost in reverie, sleep onset soon, lost struggle to remain awake" // different answers in previous years, so we have to do the same as before and recode two different answers to one number
replace sleepiness = "6" if sleepiness == "Sleepiness, prefer to be lying down, fightine sleep, woozy"
replace sleepiness = "6" if sleepiness == "Sleepy, woozy, struggling to sleep, prefer to lie down"
replace sleepiness = "5" if sleepiness == "Fogginess, beginning to lose interest in remaining awake, slowed down"
replace sleepiness = "4" if sleepiness == "A little fogy, not at peak, let down"
replace sleepiness = "4" if sleepiness == "A little foggy, not at peak, let down" // typo in some responses but not all
replace sleepiness = "3" if sleepiness == "Relaxed, awake, not at full alertness, responsive"
replace sleepiness = "2" if sleepiness == "Functioning at high levels, but not at peak, able to concentrate"
replace sleepiness = "1" if sleepiness == "Feeling active, vital, alert or wide awake"
replace sleepiness = "1" if sleepiness == "Feeling active, vital, alert, or wide awake" // once again different spellings
destring sleepiness, replace
tab sleepiness

** energylevel
sum energylevel
tab energylevel // nothing weird to see here

* stresslevel should be inverted otherwise it doesn't make sense, since 100 now means someone is extremely calm
rename stresslevel Stress_original
gen stresslevel = 100-Stress_original
*scatter stresslevel Stress_original

*********Inspect data, to get a first idea what is in there******************
tab day timeonday				
sum student day time timeonday sleepiness energylevel stresslevel happiness motivation
//Visalisation histograms

/*

histogram day, frequency gap(1) ytitle("Frequency of questionair responses") xtitle("Day of the week") by(, legend(off)) by(student, iyaxes ixaxes)	
gen graphcolor = .
replace graphcolor = 2022 if day < 6					
replace graphcolor = 2023 if day >5 & day <10
replace graphcolor = 2024 if day > 9


histogram graphcolor, bin(3) frequency gap(1) ytitle("Amount of questionair responses per year") xtitle("Year") xscale(range(2022 2024)) xlabel(#3, ticks tposition(crossing)) legend(off)(bin=3, start=2022, width=.66666667)


graph bar (count), over(day) over(graphcolor) nofill ytitle("Amount of responses per day per year")

*hist day, by(student) freq xtitle("Day of week") binrescale		// Three distinct answering phases due to data from three different years, keep this in mind in further analysis
*/ 
//scatter motivation time, by(student) connect(l) xtitle("Nr. of assessment") ytitle("Motivation")		// 

//when you want to keep a graph on your screen - and not overwrite it as soon as you make another picture, write 'name(yournameforthegraph)' after the comma
//scatter energylevel time, by(student) connect(l) xtitle("Nr. of assessment") ytitle("Vitality (0=Depleted-10=Energetic)")

//scatter stresslevel time, by(student) connect(l) xtitle("Nr. of assessment") ytitle("Stress (low to high)")

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

pwcorr sleepy energy stress happy motivationstd, sig star(0.05)	//you can use this command to compute the correlations (but note: our data is nested..)
// All makes sense now!

graph matrix sleepiness energy stress happy motivation, jitter(2) half 	//relations that we can see make sense, but there could be individual differences. E.g. some people are more motivated by stress to do something about their situation, while stress could paralyze others



*********Analysis of the data***************************************************
// Energy and happiness --> because you can also feel tired and happy, but there is a positive correlation: could be interesting to look at within/between differences


//unconditional model	
mixed happiness				//no clustering of the data
mixed happiness || student:	//adding random intercept, p fo lr test < 0.05 so adding random intercept makes the model better

estat icc 				//compute intra-class correlation
predict residuals_unconditional_mixed, res	//store residuals
swilk residuals_unconditional_mixed			//shapiro-wilk test to check normality of residuals, normality is rejected


//now the conditional models
//Group level (for which we actually know that this isn't the correct analyses, but let's run for illustrative purposes)
*reg happy energylevel
mixed happiness energylevel	// Both p<0.05
estimates store A

//corresponding graphs
scatter happiness energylevel
scatter happiness energylevel || lfit happiness energylevel


//Random intercept model
mixed happiness energylevel	 || student:
estimates store B
predict residuals_B, res	//store residuals
swilk residuals_B			//shapiro-wilk test to check normality of residuals
//corresponding graphs > normality is rejected
predict pred_cons_student, reffect relevel(student)								//store prediction of model, to plot it later in scatterplot
//plot intercepts deviation across participants
gen zero = 0
<<<<<<< HEAD
twoway  (rspike zero pred_cons_student studentnr, horizontal) (scatter studentnr pred_cons_student, msize(1) mlabsize(1) mlabposition(0)) if time==1, xtitle("Deviation from overall intercept") ytitle("Student number") legend(off) // studentnr instead of student so there are no overlaps due to high numbers for participant ID


gen pred_energy=(pred_cons_student+_b[happiness:_cons])+_b[happiness:energylevel]*energylevel	//finish modelprediction by combining coefficients with estimations
scatter happiness pred_energy energylevel, by(student,legend(off)) jitter(2) connect(. l) ytitle("Happiness")  //make graph of both data and model prediction, looks pretty good at first inspection
drop pred*	
=======
twoway  (rspike zero pred_cons_student student, horizontal) (scatter student pred_cons_student, msize(1) mlabsize(1) mlabposition(0)) if time==1, xtitle("Deviation from overall intercept") legend(off) // studentnr instead of student

gen pred_energy=(pred_cons_student+_b[happiness:_cons])+_b[happiness:energylevel]*energylevel	//finish modelprediction by combining coefficients with estimations
scatter happiness pred_energy energylevel, by(student,legend(off)) jitter(2) connect(. l) ytitle("Happy")  //make graph of both data and model prediction
drop pred*																		//if you don't drop all predictions, Stata will give you errors when you want to make another model prediction
>>>>>>> a08b24299aa3f7b4ccde1845e1d286968463dc65


//Random slope model
mixed happiness energylevel	 || student:energylevel // p<0.05 so a random slope does make sense
estimates store C
predict residuals_C, res	//store residuals
swilk residuals_C			// normality is again rejected

//corresponding graphs
predict pred_slope_student pred_cons_student, reffect relevel(student)			//store prediction of model, to plot it later in scatterplot
//plot slope deviation across participants
<<<<<<< HEAD
twoway  (rspike zero pred_slope_student studentnr, horizontal) (scatter studentnr pred_slope_student, msize(1) mlabsize(1) mlabposition(0)) if time==1, xtitle("Deviation from fixed slope") ytitle("Student number") legend(off)

gen pred_energy= (pred_cons_student+_b[happiness:_cons])+(pred_slope_student+_b[happiness:energylevel])*energylevel //finish modelprediction by combining coefficients with estimations, a bit more complex than in the random intercept model
scatter happiness pred_energy energylevel, by(student,legend(off)) jitter(2) connect(. l) ytitle("Happiness") //make graph of both data and model prediction
drop pred* 										
=======
twoway  (rspike zero pred_slope_student student, horizontal) (scatter student pred_slope_student, msize(1) mlabsize(1) mlabposition(0)) if time==1, xtitle("Deviation from fixed slope") legend(off)

gen pred_energy= (pred_cons_student+_b[happiness:_cons])+(pred_slope_student+_b[happiness:energylevel])*energylevel //finish modelprediction by combining coefficients with estimations, a bit more complex than in the random intercept model
scatter happiness pred_energy energylevel, by(student,legend(off)) jitter(2) connect(. l) ytitle("Happy") //make graph of both data and model prediction
drop pred* 														//drop again
>>>>>>> a08b24299aa3f7b4ccde1845e1d286968463dc65


//Likelihoodratio test
lrtest A B // random intercept is better since p<0.05
lrtest B C // random slope and random intercept is better since p<0.05



**2-level or 3-level model? //note that the data could also be described as a 3-level model, which we ignored so far

//to test this, we will use unconditional models (also called null models)
mixed happiness || student:						//2-level model
estimates store nullModel_2level
mixed happiness || student: ||day:				//3-level model
estimates store nullModel_3level
lrtest nullModel_2level nullModel_3level
<<<<<<< HEAD
// suggests that it is better to use a three level model since p<0.05. This makes sense intuitively speaking since happiness and energy levels can differ significantly between days (just basing off our own experiences)

// run again with 3 levels:
mixed happiness energylevel || student: ||day:	


=======
// suggests that it is better to use a three level model since p<0.05
>>>>>>> a08b24299aa3f7b4ccde1845e1d286968463dc65

**we also ignored the centering of the variables. For this, you can either grand-mean or group-mean centering. The first refers to centering all scores around the overall mean, and group-mean centering refers to centering around the cluster mean (i.e., the person's average score)


**grand-mean center scores --> compute deviations from the overall mean
egen Energy_GrandMean = mean(energylevel)
egen Happy_GrandMean = mean(happiness)

//grand-mean center observations by extracting grand mean from each observation
gen Energy_GMC= energylevel-Energy_GrandMean
gen Happy_GMC= happiness-Happy_GrandMean

//now run the models with the grand-mean scores for energy as predictor (note that we don't use the grand-mean score for the outcome parameter. Why?)
mixed happiness Energy_GMC || student: ||day:				//random intercepts for student and day (nested in student)
predict residuals_D, res	//store residuals
swilk residuals_D			//shapiro-wilk test to check normality of residuals

mixed happiness Energy_GMC || student:Energy_GMC ||day:		//random intercepts + random slope (at participant level --> to what extent do the slopes vary across participants?)
predict residuals_E, res	//store residuals
swilk residuals_E			//shapiro-wilk test to check normality of residuals

**cluster-mean center scores
//compute averages per student
bysort student: egen Energy_ClusterMean = mean(energylevel)
bysort student: egen Happy_ClusterMean = mean(happiness)
//compute cluster-mean centered scores by extracting students' mean values from the raw scores --> compute deviations from the person's mean
gen Energy_CMC = energylevel - Energy_ClusterMean
gen Happy_CMC = happiness - Happy_ClusterMean


//center cluster mean scores by extracting grand mean from each students cluster mean
gen Sleepiness_ClusterMean_centered = Sleepiness_ClusterMean-Sleepiness_GrandMean
gen Energy_ClusterMean_centered = Energy_ClusterMean-Energy_GrandMean
gen Stress_ClusterMean_centered = Stress_ClusterMean-Stress_GrandMean
gen Happy_ClusterMean_centered = Happy_ClusterMean-Happy_GrandMean
gen Motivation_ClusterMean_centered = Motivation_ClusterMean-Motivation_GrandMean

mixed Happy Stress_CMC Stress_ClusterMean_centered || student: || day:			//random intercepts for student and day (nested in student)
predict residuals_F, res	//store residuals
swilk residuals_F			//shapiro-wilk test to check normality of residuals

<<<<<<< HEAD
mixed happiness Energy_CMC Energy_ClusterMean_centered || student: || day:			//random intercepts for student and day (nested in student). p<0.05
predict residuals_F, res	
swilk residuals_F			// normality is rejected

mixed happiness Energy_CMC Energy_ClusterMean_centered|| student:Energy_CMC || day:	//random intercepts + random slope (at participant level --> to what extent do the slopes vary across participants?)
predict residuals_G, res	
swilk residuals_G			// normality is rejected



*** Now for part B, look at our own data***
// Explanation of the variables we have created before, just for an overview >> delete before we hand in this file!!! 
// these are the means of the entire student population and all observations > not super useful for individual observations, I think
// Energy_GrandMean
// Happy_GrandMean

*** How much does the person's score differ from the overall mean at any given time? 
//Energy_CMC
//Happy_CMC 

*** student mean - total mean 
//Energy_ClusterMean_centered 
//Happy_ClusterMean_centered


// The analyses we have run before on the group level
/// mixed happiness Energy_GMC || student: ||day:				//random intercepts for student and day (nested in student)

///mixed happiness Energy_GMC || student:Energy_GMC ||day:		//random intercepts + random slope (at participant level)


//mixed happiness Energy_CMC Energy_ClusterMean_centered || student: || day:			//random intercepts for student and day (nested in student). p<0.05

//mixed happiness Energy_CMC Energy_ClusterMean_centered|| student:Energy_CMC || day:	




*** Student 1 
scatter happiness energylevel if student==325370   || lfit happiness energylevel

tab happiness if student==325370
sum happiness energylevel if student==325370
tab energylevel if student==325370

// Run a 'naive' regression model first
reg happiness energylevel if student==325370 // R squared of 0.2160 which means about 22% of variation is explained by energylevel  
mixed happiness energylevel if student==325370 
// There is a slight positive correlation between energylevel and happiness overall for this student (p=0.002) meaning that the more energy they have, the happier they are. 1 point extra energy leads to 0.39 points extra happiness, so that is a little less than the group average (0.46)
estimates store A1

mixed happiness energylevel || day: if student==325370 

estimates store B1
predict residuals_B1, res
swilk residuals_B1 // normality rejected

lrtest A1 B1 // p>0.05 as we saw before so it does not make sense to add the extra level of day for this student. 



mixed happiness Energy_CMC if student==325370 
mixed happiness Energy_ClusterMean_centered if student==325370 













*** Student 2



*** Student 3





















=======
mixed Happy Stress_CMC Stress_ClusterMean_centered|| student:Stress_CMC || day:	//random intercepts + random slope (at participant level --> to what extent do the slopes vary across participants?)
predict residuals_G, res	//store residuals
swilk residuals_G			//shapiro-wilk test to check normality of residuals
>>>>>>> a08b24299aa3f7b4ccde1845e1d286968463dc65



