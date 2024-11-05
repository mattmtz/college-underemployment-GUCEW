/******************************
*** NAME:    MATT MARTINEZ
*** PROJECT: UNDEREMPLOYMENT
*** PURPOSE: SETUP 
*** DATE:    10/14/2024
******************************/

clear
capture log close
macro drop _all
set more off, perm
set rmsg on
*ssc install unique

** SET KEY CUTOFFS **
global MINAGE 22
global MAXAGE 54
global NFLAG 75 // minimum number of observations to consider median wages
global EDUC_PREM = 0.1 // expected premium per addt'l year of education
global BA_PREM1 (1 + 4*$EDUC_PREM ) // cutoff for BA wage premium over HS wage
global BA_PREM2 (1 + 2*$EDUC_PREM ) // cutoff for BA wage premium over AA wage

** INCLUDE OTHER AGE CATEGORIES? **
* value of 1 --> include 22-54, 25-34, 35-44, 45-54 -- see code file A3 line 128
global INCLUDEAGES 0 

** SET WORKING DIRECTORY GLOBAL **
global CD "C:/Users/mattm/Desktop/Underemployment/college-underemployment-GUCEW"
cd "$CD"

** DEFINE OUTPUT FILE **
global FILE "output/underemployment_backup.xlsx"

** SET IPUMS DATA DOWNLOAD NAME **
global IPUMS "usa_00004.dat"

** RUN CODE **
do "code/A1_ACS Download.do"
cd "$CD"
do "code/A2_Filter ACS Data.do"
do "code/A3_Create BLS Merged Dataset.do"
do "code/B1_Create Categorized Dataset.do"
do "code/B2_Calculate Underemployment.do"
do "code/C1_Analyze Underemployment Shares.do"
do "code/C2_Analyze Occupational Education Distributions.do"
do "code/D1_Define Alternative Underemployment Measures.do"
do "code/D2_Alternate Underemployment by Race and Sex.do"
do "code/D3_Alternate Underemployment Graphs.do"

** TYPICAL RUNTIME: ~16-25 minutes
