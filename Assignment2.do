* The file for assignment 2

clear all 						//to clear memory and start with the new fresh dataset again
set more off					//to avoid clicking on 'more' all the time to see more output
graph drop _all					//in case you save graphs by giving them a name, you need to drop them when you run the analysis again
use "Data_2024.dta" , replace		//load dataset (and replace in case there is still data in memory)

*********Transformation of the data, to make it convenient to use***************
rename Participant_ID student 		//because typing 'student' is easier
label variable student "Participant ID"  // label for graphs

*We will create seperate date / time variables first:
gen Time = substr(Date_submitted,12,8)