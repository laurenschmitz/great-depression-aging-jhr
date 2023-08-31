*****************************************************************************************************************************************************************
***CODE FOR CENSUS DATA ANALYSIS***	
	*Project: Early-life Exposure to the Great Depression and Long-term Health and Economic Outcomes, Journal of Human Resources
	*Authors: Valentina Duque and Lauren L. Schmitz 
	*Analyst: Vikas Gawai
	*Date updated: June 2023
*****************************************************************************************************************************************************************

*****************************************************************************************************************************************************************
***TABLE 4: EFFECT OF WAGE DECLINES ON FAMILY CHARACTERISTICS IN CHILDHOOD***	
*****************************************************************************************************************************************************************
clear
set more off

global data "R:\SharedProjects\SharedLSCM\GD_Project\Data" 
global tables "R:\SharedProjects\SharedLSCM\GD_Project\R&R_Files\Tables"  

cd "$tables"  
cd "$data" 

********************************************************************************
*STEP 1: Import the Household, Person, and other Person files of HRS-Census1940 data and merge them*
		
	*Person file*
		use "$data\hrs1940_en_persons.dta", clear  

		*To help differentiate the variable names from the HRS-1940 data and the GD data, lets change the variables names. *
			global hrs_1940person_vars rectype yearp pernum slwtreg momloc stepmom MOMRULE_HIST poploc steppop POPRULE_HIST sploc SPRULE_HIST famsize nchild NCHLT5 famunit eldch yngch nsibs relate age sex race marst marrno chborn slrec bpl nativity citizen hispan mtongue spanname school higrade empstat labforce OCC1950 occscore sei IND1950 classwkr WKSWORK1 WKSWORK2 HRSWORK1 HRSWORK2 incwage incnonwg MIGCITY5 qage qbpl qchborn qcitizen qclasswk qfbpl qempstat qmarst qmtongue qocc qrace qrelate qsursim qschool qsex qyrimm agediff hisprule presgl ERSCOR50 EDSCOR50 NPBOSS50 isrelate subfam sftype sfrelate educ vetstat ind slwt perwt birthyr occ MIGRATE5 MIGPLAC5 MIGMET5 MIGTYPE5 MIGSEA5 MIGFARM5 agemarr mbpl fbpl durunemp uclasswk uocc UOCC95 uind sameplac SAMEMET5 SAMESEA5 agemonth respondt vetwwi VET1940 vetper vetchild sursim ssenroll qmbpl OCC1940 IND1940 migcounty anyallocation
						
				foreach var of varlist $hrs_1940person_vars{
					rename `var' `var'_pers
					}
		
	*Merge with Household File *	
		merge 1:1 hhidpn using "$data\hrs1940_en_household.dta"	 /*Every obs (9654) merged*/
			
		*To help differentiate the variable names from the HRS-1940 data and the GD data, lets change the variables names.*
			global hrs_1940hh_vars numprec subsamp dwsize region stateicp statefip sea metro metarea metdist city citypop sizepl urban gq gqtype gqfunds farm ownershp nfams ncouples nmothers nfathers qfarm qownersh urbpop hhtype cntry nsubfam headloc valueh multgen CPI99 countyicp hhwt dwseq rent respond numperhh slpernum supdist qgqfunds SPLIT40 NUMPREC40 edmiss split splitnum rectypep				

			foreach var of varlist $hrs_1940hh_vars{
				rename `var' `var'_hh
					}
			
		keep if _merge==3 /*9654 hhidpn merged out of 9654*/
		drop _merge	 
				
	*Merge with Other Person File *
		merge 1:m hhidpn using "$data\hrs1940_en_otherp.dta"
			
		keep if _merge==3 /*41,595 individuals merged. 9316 hhidpn merged out of 9654. 338 did not merge.*/
			
		*Similarly, to help differentiate the variable names from the HRS-1940 data and the GD data, lets change the variables names*
			
			global hrs_1940otherpers_vars rectype yearp pernum slwtreg momloc stepmom MOMRULE_HIST poploc steppop POPRULE_HIST sploc SPRULE_HIST famsize nchild NCHLT5 famunit eldch yngch nsibs relate age sex race marst marrno chborn slrec bpl nativity citizen hispan mtongue spanname school higrade empstat labforce OCC1950 occscore sei IND1950 classwkr WKSWORK1 WKSWORK2 HRSWORK1 HRSWORK2 incwage incnonwg MIGCITY5 qage qbpl qchborn qcitizen qclasswk qfbpl qempstat qmarst qmtongue qocc qrace qrelate qsursim qschool qsex qyrimm agediff hisprule presgl ERSCOR50 EDSCOR50 NPBOSS50 isrelate subfam sftype sfrelate educ vetstat ind slwt perwt birthyr occ MIGRATE5 MIGPLAC5 MIGMET5 MIGTYPE5 MIGSEA5 MIGFARM5 agemarr mbpl fbpl durunemp uclasswk uocc UOCC95 uind sameplac SAMEMET5 SAMESEA5 agemonth respondt vetwwi VET1940 vetper vetchild sursim ssenroll qmbpl OCC1940 IND1940 migcounty anyallocation				

				foreach var of varlist $hrs_1940otherpers_vars{
					rename `var' `var'_otherpers
					}
		
		drop _merge  
				
********************************************************************************			
*STEP 2: Basic Analysis*

*Variable Cleaning and creating*
							
	*Dwelling Ownership*
							
		recode ownershp_hh (10=1) (20=0) (0=.), gen(ownershp_hh_r)
		/* Own = 10, rent = 20, N/A = 0 */
			label variable ownershp_hh_r "Dwelling Owner"
		
		*Father Present*
			gen fpresent = 0 if poploc_pers ==0
				replace fpresent = 1 if poploc_pers >0
					label variable fpresent "Father Present"
		
		
		*Family Income (not household.) (Income from all members in the family, even HRS-linked person income. Within household there might be two families.).*
			sort hhidpn_new hhid_new 
				recode incwage_otherpers (999998=.) (999999=.), gen (income_otherperson)
		
			recode incwage_pers (999998=.) (999999=.), gen (income_pers) /*Income of HRS person*/
				egen income_othr_and_resp = rowtotal(income_otherperson income_pers), missing  
									
			bysort hhidpn_new: egen total_familyinc = sum(income_othr_and_resp)/*Total income in the family*/

				label var total_familyinc "Family Income ($1940)"
				hist total_familyinc 
		
			gen tot_family_login = log(total_familyinc)
				label var tot_family_login "Log (Family Income) "  
				hist tot_family_login 
		
		*Family Income Dummy*
			gen nonzeroinc = 0 if total_familyinc==0
				replace nonzeroinc =1 if total_familyinc!=0 & total_familyinc!=.
				label variable nonzeroinc "Family Non-Zero Income(0-1)"
								
	*Now that we do not need all the other persons details, we will just keep one observation for each hhidpsn person.*
		sort hhidpn_new  
		by hhidpn_new : gen dup = cond(_N==1,0,_n)  

		drop if dup >1
		save "$data\hrs1940_hh_ind_other.dta", replace 
		
********************************************************************************							
*STEP 3: Merge with the HRS_Great_Depression_New_Deal_Data_Cleaned_w_ETS_Vars_9-21 data*
				
	use "R:\SharedProjects\SharedLSCM\GD_Project\R&R_Files\Data\HRS_Great_Depression_New_Deal_Data_Cleaned_w_ETS_Vars_9-21.dta", clear 
				
		*Create string varibles of hhidpn and hhid to help merge
			tostring hhidpn, gen(hhidpn_new)
				replace hhidpn_new = string(real(hhidpn_new), "%09.0f")
		
			tostring hhid, gen(hhid_new)
				replace hhid_new = string(real(hhid_new), "%06.0f")
	
				keep if year==1992
		
		*Merge with Individual_household data
			drop _merge  
			
			merge 1:1 hhidpn_new hhid_new using "$data\hrs1940_hh_ind_other.dta"
	
		*Gen variable to identify matched
			gen matched = 0 /*Who do not matched because they are the other persons in the households and not a pat of HRS sample */
				replace matched =1 if _merge==3  
		
		*Now matched with the Tracker file of Census that also has a matched and not matched varible. We do this to check, if our matchning was perfect
			drop _merge 
			
			merge 1:1 hhidpn_new using "R:\SharedProjects\SharedLSCM\GD_Project\R&R_Files\Data\Census_tracker_HRS1940\trk2018tr_r.dta", force /*43,398 matchd, 6 does not match*/
		
		*Create an indicator if the match is not proper
			gen diff =1 if matched==1 & census1940 !=1
		
			keep if _merge==3    /*Keep only what is merged*/
	
		*Merge with the GD-sample-variable data
			drop _merge
		
			merge 1:1 hhidpn using "R:\SharedProjects\SharedLSCM\GD_Project\Data\gd_sample_variable.dta", force

********************************************************************************
*STEP 4: Regression Analysis

	drop if census1940==.
	
	keep if matched ==1 /*Since we are interested in the sample that is matched*/

	*Generating some variables as required

		gen salaries_32 = (salariesi_3 + salariesi_2)/2
			label variable salaries_32 "Wage Index age -3 and -2"

		gen salariesi_1f = -1 * salariesi_1
			label var salariesi_1f "Wage Decline in-Utero "

		egen z_salariesi_1f = std(salariesi_1f)  
			label variable z_salariesi_1f "Wage Decline in-Utero (STD)"

	*Mechanism analysis

		global outcomes "tot_family_login nonzeroinc ownershp_hh_r fpresent"
		global fixedcov "i.birthyr i.st_born2 i.region_hh#c.birthyr"  

		eststo clear

		foreach var of varlist $outcomes{  

			reg `var' z_salariesi_1f i.female i.white $fixedcov [aw=perwt_pers] if birthyr>=1929 & birthyr<=1940 ,  cluster(st_born2)
				estadd ysumm
					outreg2 using "R:\SharedProjects\SharedLSCM\GD_Project\R&R_Files\Tables\mechanism_regiont.xls", excel keep(z_salariesi_1f `yvar' 1.female 1.white) addstat(Mean of Dependent Variable, e(ymean)) alpha(0.01 , 0.05, 0.1) addtext(Birth year FE, Yes, Birth State- FE, Yes, Region FE X Birth Year FE, Yes) label br dec(5) nocons append
			}

*****************************************************************************************************************************************************************
***APPENDIX TABLE 4 (COLUMN 1): COMPARISON OF MEAN DEMOGRAPHIC AND SOCIOECONOMIC CHARACTERISTICS IN CHILDHOOD IN THE 1% 1940 CENSUS AND HRS SAMPLES***	
*****************************************************************************************************************************************************************
clear

clear mata 
clear matrix
set maxvar 30000

*Project Directory *
	global projectdir "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD"

*Table Directory*
	global tabledir "$projectdir/analysis_vikas/table"

	cd "$projectdir"
	cd "$tabledir"

*Import the data of Census 1940 1% linked with GD data *
	use "$projectdir/analysis_vikas/data/raw/Census_1940_with_GD_variables.dta"  

*Step-1*
*Import and merge salary.dta data *
*And remove the previous salaries variable.*
	drop salaries*
	drop _merge

	joinby bstate year using "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD/Salaries.dta", unmatched(master)  

*Step-2*
*Clean variables 
	gen homeown = (ownershp==1) if !missing(ownershp) 
	label var homeown "Home Ownership" 

	label var salaries_1 "Wage Index In-utero"  
	label var female "Female" 
	label var white "White"
	label var hh_urban "Urban"
	label var meduc_lths "Mother Edu < HS"
	label var fpresent  "Father Present"

*Step-3: Summary Statistics (Note: this data is the merged 1%1940 census with the GD related data. So, the summary stat is for the after merged data.*

	global vars "hh_urban fpresent female white meduc_lths"
	eststo clear  
	asdoc sum $vars if birthyr >=1929 & birthyr <=1940, label save(sumsta_oneperccens1940.doc), replace

*****************************************************************************************************************************************************************
***APPENDIX TABLE 6: EFFECT OF WAGE INDEX DECLINES IN UTERO ON EDUCATIONAL ATTAINMENT AND LABOR MARKET OUTCOMES IN THE 1960-1990 DECENNIAL CENSUSES***	
*****************************************************************************************************************************************************************

********************************************************************************
***PANEL A (1960 CENSUS)***
	clear
	clear mata 
	clear matrix
	set maxvar 30000

	*Project Directory *
		global projectdir "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD"

	*Table Directory*
		global tabledir "$projectdir/analysis_vikas/table"

		cd "$projectdir"
		cd "$tabledir"

	*Import the data of Census 1960 1% linked with GD data*
		use "$projectdir/1960_census_/usa_00029.dta", clear

	*Clean variables*
		drop year  

		gen bstate=bpl if bpl<99
		gen year= birthyr

	*Merge with wage index data*
		joinby bstate year using "$projectdir/Salaries.dta", unmatched(master) 

	*Outcome Variables*
		*Education *
			gen lths=1 if educ<6
				replace lths=0 if educ>=6
					label variable lths "Less than High-Schl"
			gen hs=1 if educ>=6
				replace hs=0 if educ<6
					ren hs hsplus
					label variable hsplus "High School and above"

	*Years of Education*
		gen yearsed =  .
			replace yearsed = 0 if educd==2
			replace yearsed = 1 if educd==12  /*KG. */
			replace yearsed = 2 if educd ==14 /*gr1. */
			replace yearsed = 3 if educd ==15 /*gr2. */
			replace yearsed = 4 if educd ==16 /*gr3. */
			replace yearsed = 5 if educd ==17 /*gr4. */
			replace yearsed = 6 if educd ==22 /*gr5. */	
			replace yearsed = 7 if educd ==23 /*gr6. */
			replace yearsed = 8 if educd ==25 /* gr7 */
			replace yearsed = 9 if educd ==26 /* gr8 */
			replace yearsed = 10 if educd ==30 /* gr9*/

			replace yearsed = 11 if educd ==40 /*gr10*/  
			replace yearsed = 12 if educd ==50 /*gr11*/  
			replace yearsed = 13 if educd ==60 /*gr12*/
			replace yearsed = 14 if educd ==70 /* 1year college. */
			replace yearsed = 15 if educd ==80 /* 2year college. */
			replace yearsed = 16 if educd ==90 /* 3year college. */
			replace yearsed = 17 if educd ==100 /* 4year college */
			replace yearsed = 18 if educd ==110 /* 5+year college*/
			replace yearsed = 19 if educd ==111 /* 6year college */
			label variable yearsed "Years of Education"
	
	*Employment Status*
		gen employed=1 if empstat==1
			replace employed=0 if empstat==2
			replace employed=. if empstat==0 | empstat==3
				label variable employed "Employed " /*1= emploed. 0= not employed, . = NA or Not in labor force */

	*Occupation Income Score*
		sum occscore

	*Respondent's income*
		gen incwag_r= incwage if incwage>=0&incwage<99999
			label var incwag_r "Indiv. Income "

		gen lincwag_r=log(incwag_r) if incwag_r>0
			label var lincwag_r "Indiv. LogIncome"

	*Non_zero Income*
		gen nonzero_ind_income = 1 if incwag_r >0 & incwag_r !=.
			replace nonzero_ind_income =0 if incwag_r==0
				label variable nonzero_ind_income "Individual Income Non-Zero"

	*Sex*
		gen male=(sex==1) if !missing(sex) 
			label variable male "Male"

	*Race*
		gen white =(race==1) if !missing(race)
			label variable white " White"

	*Treatment Variable*
		*Flip the sign*
			gen salaries_1f = salaries_1 * -1 /*flip the sign*/
				label variable salaries_1f "Wage Decline In-Utero"
					sum salaries_1f  
					
		*Standardise the treatment*
			zscore salaries_1f  
				label variable z_salaries_1f "Wage Decline in-Utero (STDZ)"

	*Regression Analysis*
		global outcomevars60 "yearsed lths employed lincwag_r  occscore "
		global fixed_covmechanism60 "i.year i.bstate i.region#i.year" 

			eststo clear
				estimates clear
					foreach var of varlist $outcomevars60{
						reg `var' z_salaries_1f i.male i.white $fixed_covmechanism60 if year > 1928 & year < 1941 [aweight=perwt], cl(bstate) 
							estadd ysumm  
								outreg2 using "$tabledir/mechanism1960_wt.xls", excel keep(z_salaries_1f `yvar' 1.male 1.white) addstat(Mean of dependent variable, e(ymean)) alpha(.01 , .05 , .1) addtext(Birth year FE, YES, Birth State FE, YES, Region FE X Birth Year FE, YES) label br dec(5) nocons append 

					} 
					
********************************************************************************
***PANEL B (1970 CENSUS)***
	clear
	clear mata 
	clear matrix
	set maxvar 30000

	*Project Directory*
		global projectdir "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD"

	*Table Directory*
		global tabledir "$projectdir/analysis_vikas/table"

		cd "$projectdir"
		cd "$tabledir"

	*Import the data of Census 1970 1% linked with GD data *
		use "$projectdir/1970_census_/usa_00033.dta", clear

	*Clean variables*
		drop year  

		gen bstate=bpl if bpl<99
		gen year= birthyr

	*Merge with Wage Index Data*
		joinby bstate year using "$projectdir/Salaries.dta", unmatched(master) 
	
	*Outcome Variables*
		*Education*
			gen lths=1 if educ<6
				replace lths=0 if educ>=6
				label variable lths "Less than High-Schl"
			gen hs=1 if educ>=6
				replace hs=0 if educ<6
				ren hs hsplus
				label variable hsplus "High School and above"

		*Years of Education*
			gen yearsed =  .
				replace yearsed = 0 if educd==2
				replace yearsed = 1 if educd==12  /*KG. */
				replace yearsed = 2 if educd ==14 /*gr1. */
				replace yearsed = 3 if educd ==15 /*gr2. */
				replace yearsed = 4 if educd ==16 /*gr3. */
				replace yearsed = 5 if educd ==17 /*gr4. */
				replace yearsed = 6 if educd ==22 /*gr5. */	
				replace yearsed = 7 if educd ==23 /*gr6. */
				replace yearsed = 8 if educd ==25 /* gr7 */
				replace yearsed = 9 if educd ==26 /* gr8 */
				replace yearsed = 10 if educd ==30 /* gr9*/

				replace yearsed = 11 if educd ==40 /*gr10*/  
				replace yearsed = 12 if educd ==50 /*gr11*/  
				replace yearsed = 13 if educd ==60 /*gr12*/
				replace yearsed = 14 if educd ==70 /* 1year college. */
				replace yearsed = 15 if educd ==80 /* 2year college. */
				replace yearsed = 16 if educd ==90 /* 3year college. */
				replace yearsed = 17 if educd ==100 /* 4year college */
				replace yearsed = 18 if educd ==110 /* 5+year college*/
				replace yearsed = 19 if educd ==111 /* 6year college */
		
					label variable yearsed "Years of Education"
		
		*Employment Status*
			gen employed=1 if empstat==1
				replace employed=0 if empstat==2
				replace employed=. if empstat==0 | empstat==3
					label variable employed "Employed " /*1= emploed. 0= not employed, . = NA or Not in labor force */

		*Occ Income Score*
			sum occscore 

		*Respondent Income*
			gen incwag_r= incwage if incwage>=0&incwage<99999
				label var incwag_r "Indiv. Income "

			gen lincwag_r=log(incwag_r) if incwag_r>0
				label var lincwag_r "Indiv. LogIncome"

		*Non_zero Income*
			gen nonzero_ind_income = 1 if incwag_r >0 & incwag_r !=.
				replace nonzero_ind_income =0 if incwag_r==0
					label variable nonzero_ind_income "Individual Income Non-Zero"

		*Sex*
			gen male=(sex==1) if !missing(sex) 
				label variable male "Male"

		*Race*
			gen white =(race==1) if !missing(race)
				label variable white " White"

	*Treatment Variable*
	
		*Flip the sign*
			gen salaries_1f = salaries_1 * -1 /*flip the sign*/
				label variable salaries_1f "Wage Decline In-Utero"
					sum salaries_1f  

		*Standardize the treatment*
			zscore salaries_1f  
				label variable z_salaries_1f "Wage Decline in-Utero (STDZ)"

	*Regression Analysis*

		global outcomevars70 "yearsed lths employed lincwag_r  occscore "
		global fixed_covmechanism70 "i.year i.bstate i.region#i.year" 

		eststo clear

		foreach var of varlist $outcomevars70{
			reg `var' z_salaries_1f i.male i.white $fixed_covmechanism70 if year > 1928 & year < 1941 [aweight=perwt], cl(bstate) 
				estadd ysumm  
					outreg2 using "$tabledir/mechanism1970_wt.xls", excel keep(z_salaries_1f `yvar' 1.male 1.white) addstat(Mean of dependent variable, e(ymean)) alpha(.01 , .05 , .1) addtext(Birth year FE, YES, Birth State FE, YES, Region FE X Birth Year FE, YES) label br dec(5) nocons append 
		} 

********************************************************************************
***PANEL C (1980 CENSUS)***
	clear
	clear mata 
	clear matrix
	set maxvar 30000

	*Project Directory *
		global projectdir "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD"

	*Table Directory*
		global tabledir "$projectdir/analysis_vikas/table"

		cd "$projectdir"
		cd "$tabledir"

	*Import the data of Census 1980 5% linked with GD data *
		use "$projectdir/1980_census_/usa_00035.dta", clear

	*Clean variables*
		drop year  

		gen bstate=bpl if bpl<99
		gen year= birthyr

	*Merge with salary Data
		joinby bstate year using "$projectdir/Salaries.dta", unmatched(master) 

	*Outcome Variables
		*Education*
			gen lths=1 if educ<6
				replace lths=0 if educ>=6
					label variable lths "Less than High-Schl"
			gen hs=1 if educ>=6
				replace hs=0 if educ<6
				ren hs hsplus
					label variable hsplus "High School and above"

		*Years of Education*
			gen yearsed =  .
				replace yearsed = 0 if educd==2
				replace yearsed = 1 if educd==12  /*KG. */
				replace yearsed = 2 if educd ==14 /*gr1. */
				replace yearsed = 3 if educd ==15 /*gr2. */
				replace yearsed = 4 if educd ==16 /*gr3. */
				replace yearsed = 5 if educd ==17 /*gr4. */
				replace yearsed = 6 if educd ==22 /*gr5. */	
				replace yearsed = 7 if educd ==23 /*gr6. */
				replace yearsed = 8 if educd ==25 /* gr7 */
				replace yearsed = 9 if educd ==26 /* gr8 */
				replace yearsed = 10 if educd ==30 /* gr9*/
		
				replace yearsed = 11 if educd ==40 /*gr10*/  
				replace yearsed = 12 if educd ==50 /*gr11*/  
				replace yearsed = 13 if educd ==60 /*gr12*/
				replace yearsed = 14 if educd ==70 /* 1year college. */
				replace yearsed = 15 if educd ==80 /* 2year college. */
				replace yearsed = 16 if educd ==90 /* 3year college. */
				replace yearsed = 17 if educd ==100 /* 4year college */
				replace yearsed = 18 if educd ==110 /* 5+year college*/
				replace yearsed = 19 if educd ==111 /* 6year college */
					label variable yearsed "Years of Education"
			
		*Employment Status*
			gen employed=1 if empstat==1
				replace employed=0 if empstat==2
				replace employed=. if empstat==0 | empstat==3
					label variable employed "Employed " /*1= emploed. 0= not employed, . = NA or Not in labor force */

		*Occ Income Score*
			sum occscore 

		*Respondent Income*
			gen incwag_r= incwage if incwage>=0&incwage<99999
				label var incwag_r "Indiv. Income "

			gen lincwag_r=log(incwag_r) if incwag_r>0
				label var lincwag_r "Indiv. LogIncome"

		*Non_zero Income*
			gen nonzero_ind_income = 1 if incwag_r >0 & incwag_r !=.
				replace nonzero_ind_income =0 if incwag_r==0
					label variable nonzero_ind_income "Individual Income Non-Zero"

		*Sex*
			gen male=(sex==1) if !missing(sex) 
				label variable male "Male"

		*Race*
			gen white =(race==1) if !missing(race)
				label variable white " White"

	*Treatment Variable*
		*Flip the sign*
			gen salaries_1f = salaries_1 * -1 /*flip the sign*/
				label variable salaries_1f "Wage Decline In-Utero"
					sum salaries_1f  

		*Standardize the Treatment*
			zscore salaries_1f  
				label variable z_salaries_1f "Wage Decline in-Utero (STDZ)"

	*Regression Analysis*

		global outcomevars80 "yearsed lths employed lincwag_r  occscore "
		global fixed_covmechanism80 "i.year i.bstate i.region#i.year" 

			eststo clear
			estimates clear 
			
				foreach var of varlist $outcomevars80{
					reg `var' z_salaries_1f i.male i.white $fixed_covmechanism80 if year > 1928 & year < 1941 [aweight=perwt], cl(bstate) 
						estadd ysumm  
							outreg2 using "$tabledir/mechanism1980_wt.xls", excel keep(z_salaries_1f `yvar' 1.male 1.white) addstat(Mean of dependent variable, e(ymean)) alpha(.01 , .05 , .1) addtext(Birth year FE, YES, Birth State FE, YES, Region FE X Birth Year FE, YES) label br dec(5) nocons append 
				} 

********************************************************************************
***PANEL D (1990 CENSUS)***
	clear
	clear mata 
	clear matrix
	set maxvar 30000

	*Project Directory*
		global projectdir "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD"

	*Table Directory*
		global tabledir "$projectdir/analysis_vikas/table"

		cd "$projectdir"
		cd "$tabledir"

	*Import the data of Census 1990 5% linked with GD data *
		use "$projectdir/1990_census_/usa_00032.dta", clear  

	*Clean variables*
		drop year  

		gen bstate=bpl if bpl<99
		gen year= birthyr

	*Merge with salary Data*
		joinby bstate year using "$projectdir/Salaries.dta", unmatched(master) 

	*Outcome Variables*
		*Education*
			gen lths=1 if educ<6
				replace lths=0 if educ>=6
					label variable lths "Less than High-Schl"
			gen hs=1 if educ>=6
				replace hs=0 if educ<6
				ren hs hsplus
					label variable hsplus "High School and above"

		*Years of Education*
			gen yearsed =  .
			replace yearsed = 0 if educd==2
			replace yearsed = 1 if educd==12  /*KG. */
			replace yearsed = 2 if educd ==14 /*gr1. */
			replace yearsed = 3 if educd ==15 /*gr2. */
			replace yearsed = 4 if educd ==16 /*gr3. */
			replace yearsed = 5 if educd ==17 /*gr4. */
			replace yearsed = 6 if educd ==22 /*gr5. */	
			replace yearsed = 7 if educd ==23 /*gr6. */
			replace yearsed = 8 if educd ==25 /* gr7 */
			replace yearsed = 9 if educd ==26 /* gr8 */
			replace yearsed = 10 if educd ==30 /* gr9*/

			replace yearsed = 11 if educd ==40 /*gr10*/  
			replace yearsed = 12 if educd ==50 /*gr11*/  
			replace yearsed = 13 if educd ==60 /*gr12*/
			replace yearsed = 14 if educd ==70 /* 1year college. */
			replace yearsed = 15 if educd ==80 /* 2year college. */
			replace yearsed = 16 if educd ==90 /* 3year college. */
			replace yearsed = 17 if educd ==100 /* 4year college */
			replace yearsed = 18 if educd ==110 /* 5+year college*/
			replace yearsed = 19 if educd ==111 /* 6year college */
			label variable yearsed "Years of Education"
			
		*Employment Status*
			gen employed=1 if empstat==1
				replace employed=0 if empstat==2
				replace employed=. if empstat==0 | empstat==3
					label variable employed "Employed " /*1= emploed. 0= not employed, . = NA or Not in labor force */

		*Occ Income Score*
			sum occscore

		*Respondent Income*
			gen incwag_r= incwage if incwage>=0&incwage<99999
				label var incwag_r "Indiv. Income "

			gen lincwag_r=log(incwag_r) if incwag_r>0
				label var lincwag_r "Indiv. LogIncome"

		*Non_zero Income*
			gen nonzero_ind_income = 1 if incwag_r >0 & incwag_r !=.
				replace nonzero_ind_income =0 if incwag_r==0
					label variable nonzero_ind_income "Individual Income Non-Zero"

		*Sex*
			gen male=(sex==1) if !missing(sex) 
				label variable male "Male"

		*Race*
			gen white =(race==1) if !missing(race)
				label variable white " White"

	*Treatment Variable*
		*Flip the sign*
			gen salaries_1f = salaries_1 * -1 /*flip the sign*/
				label variable salaries_1f "Wage Decline In-Utero"
					sum salaries_1f  

		*Standardize the treatment*
			zscore salaries_1f  
				label variable z_salaries_1f "Wage Decline in-Utero (STDZ)"

	*Regression Analysis*
		global outcomevars90 " yearsed lths employed lincwag_r occscore"
		global fixed_covmechanism90 "i.year i.bstate i.region#i.year" 

		eststo clear
		estimates clear  
		
			foreach var of varlist $outcomevars90{
				reg `var' z_salaries_1f i.male i.white $fixed_covmechanism90 if year > 1928 & year < 1941 [aweight=perwt], cl(bstate) 
					estadd ysumm  
						outreg2 using "$tabledir/mechanism1990_wt.xls", excel keep(z_salaries_1f `yvar' 1.male 1.white) addstat(Mean of dependent variable, e(ymean)) alpha(.01 , .05 , .1) addtext(Birth year FE, YES, Birth State FE, YES, Region FE X Birth Year FE, YES) label br dec(5) nocons append 
			} 

*****************************************************************************************************************************************************************
***APPENDIX TABLE 14: ASSOCIATION BETWEEN WAGE INDEX DECLINES AND FEMALE FERTILITY IN THE 1930s***	
*****************************************************************************************************************************************************************

clear
clear mata 
clear matrix
set maxvar 30000


	*SET PROJECT DIRECTORIES
		*Project Directory *
			global projectdir "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD"

		*Table Directory*
			global tabledir "$projectdir/analysis_vikas/table"

			cd "$projectdir"
			cd "$tabledir"
	
	*MERGE WAGE DATA WITH 1% 1940 CENSUS BY YEAR AND STATE OF BIRTH
		use "$projectdir/analysis_vikas/data/raw/Census_1940_with_GD_variables.dta"  

			joinby bstate year using "/Users/vikasgawai/Dropbox/Intergenerational_GD_Paper/GD/Salaries.dta", unmatched(master)  

		*CLEAN THE VARIABLES
		
			*Infant Mortality in '29 *
				gen temp = imort_tot if birthyr==1929
					bysort bstate : egen imort_tot29 = max(temp)
						drop temp  

			*Mother's mortality*
				gen temp = mmrate if birthyr==1929
					bysort bstate : egen mmrate29 = max(temp)
						drop temp  

			*Mother has high school education or above*
				gen meduc_hs=1 if meduc>=6 & meduc<.
					replace meduc_hs=0 if meduc<6 & meduc!= .


			*Reverse the sign of the wage index variable so it reflects declines in the wage index
				gen salaries_32f = salaries_32 * -1
				gen salaries_1f = salaries_1 * -1  

			*Generate missing variable dummies for age and marital status*

				replace hhmage_30=0 if hhmage_30==.
					gen hhmage_30_mis=(hhmage_30==.)

				replace hhmage_31_39=0 if hhmage_31_39==.
					gen hhmage_31_39_mis=(hhmage_31_39==.)

				replace hhmmarried=0 if hhmmarried==.
					gen hhmmarried_mis=(hhmmarried==.) 

			*Label Variables*
				label var salaries_1f "Wage Decline In-utero"  
				label var salaries_32f "Wage Decline Age -3 to -2"
				label var female "Female" 
				label var age "Age" 
				label var white "White"
				label var black "Black"
				label var hh_urban "Urban"
				label var hh_size "Hh Size"  
				label var hh_income "HH Income" 
				label var lhh_income "HH Log Income"  
				label var hhmage_30 "Mother Age <= 30"
				label var hhmage_31_39 "Mother Age 31-39"
				label var hhmmarried "Mother is Married"
				label var meduc_lths "Mother Edu < HS"
				label var meduc_hs "Mother Edu HS"  
				label var fpresent  "Father Present"
				label var fsiblings "Fertility Post GD Child"  

	*REGRESSION ANALYSIS
	
		*Outcome Varible*
			global outcomevars "fsiblings"  

		*Covariates*
			global covr "female white hhmage_30 hhmage_31_39 hhmmarried meduc_lths meduc_hs hh_urban"

		*Fixed Effects*
			global fixed_cov1 "i.year i.bstate i.region#i.year c.man75#i.year c.imort_tot29#i.year c.mmrate29#i.year"

		*Interaction with control variables*
			global treatcov_interct "c.salaries_1f##i.female c.salaries_1f##i.white c.salaries_1f##i.hhmage_30 c.salaries_1f##i.hhmage_30_mis c.salaries_1f##i.hhmage_31_39 c.salaries_1f##i.hhmage_31_39_mis c.salaries_1f##i.hhmmarried c.salaries_1f##i.hhmmarried_mis c.salaries_1f##i.meduc_lths c.salaries_1f##i.meduc_hs c.salaries_1f##i.hh_urban"

		*Regression analysis
			foreach var of varlist $outcomevars {
				*Without interactions*
					reg `var' salaries_32f salaries_1f $fixed_cov1 if year > 1928 & year < 1941 & fsiblings<11, cl(bstate) 
						outreg2 using "$tabledir/fertilitypnas.xls", excel keep(salaries_32f salaries_1f) alpha(.01 , .05 , .1) addtext(Birth year FE, YES, Birth State FE, YES, Region FE X Birth Year FE, YES, Manuf.75 X Birth Year Trend, YES, Infant Mort. X Birth Year Trend, YES, Maternal Mort. X Birth Year Trend, YES) label br dec(5) nocons append 
				
				*With Interactions*
					reg `var' salaries_32f salaries_1f $treatcov_interct $fixed_cov1 if year > 1928 & year < 1941 & fsiblings<11, cl(bstate) 
						outreg2 using "$tabledir/fertilitypnas.xls", excel keep(salaries_32f salaries_1f c.salaries_1f#1.female c.salaries_1f#1.white c.salaries_1f#1.black c.salaries_1f#1.hhmage_30 c.salaries_1f#1.hhmage_31_39 c.salaries_1f#1.hhmmarried c.salaries_1f#1.meduc_lths c.salaries_1f#1.meduc_hs c.salaries_1f#1.hh_urban) alpha(.01 , .05 , .1) addtext(Birth year FE, YES, Birth State FE, YES, Region FE X Birth Year FE, YES, Manuf.75 X Birth Year Trend, YES, Infant Mort. X Birth Year Trend, YES, Maternal Mort. X Birth Year Trend, YES ) label br dec(5) nocons append						
			}

						
*****************************************************************************************************************************************************************
***APPENDIX TABLE 15: ASSOCIATION BETWEEN WAGE INDEX DECLINES AND SELECTIVE SURVIVAL AT BIRTH***	
*****************************************************************************************************************************************************************
clear all
set mem 300m
set trace off
set more off
  
	*OPEN DATA (1% representative sample of the 1940 Census)
		clear
			global mypath "$mipath\Census_1940"

		*Path Tree
			global Salaries "$mypath\Data\Salary_Data_w_ETS_FINAL.dta"  	
			global Mortality_mortality "$mypath\Data\Maternal_Mortality_Rate_Data_FINAL.dta" 
			global Manufacture_1929 "$mypath\Data\Census_Manf_Share_Data_FINAL.dta" 
			global Infant_mortality "$mypath\Data\NBER_Infant_Mortality_Data_FINAL.dta" 

	*GENERATE NEEDED VARIABLES	
		drop year
		gen year=1940-age
		drop if year<1925
		sum year

		*Create Cohort Size
			gen female=(sex==2)
				bysort bstate year: egen cohort_size=count(female) 

		*Create Sex Ratio
			bysort bstate year: egen tot_fem=total(female) 
				gen male=(female==0)
			bysort bstate year: egen tot_male=total(male) 
				gen sex_ratio=tot_male/tot_fem

		*Collapse the data at the birth state and birth year level
			collapse (mean) sex_ratio  cohort_size , by (bstate year)

		*Create log(cohort_size) and log(sex_ratio)
			gen lcohort_size=log(cohort_size)
			gen lsex_ratio=log(sex_ratio)

	*MERGE DATA WITH WAGE INDEX AND STATE-LEVEL COVARIATES

		*Wage index data
			joinby bstate year using "Salaries" , unmatched(master)
				drop if bstate>56
				gen salaries_32=(salaries_3 + salaries_2)/2
				gen salaries_iu=(salaries_1 + salaries)/2
				gen salaries12=(salaries1 + salaries2)/2
				gen salaries34=(salaries3 + salaries4)/2
				gen salaries56=(salaries5 + salaries6)/2

		*Maternal mortality data
			drop _merge 
			joinby bstate year using "Mortality_mortality" , unmatched(master)
				gen mmrate_29= mmrate if year==1929
					bysort bstate: egen mmrate29=max(mmrate_29)
						drop mmrate_29

		*Merge with share of manufacturing data 
			drop _merge
			joinby bstate year using "Manufacture_1929" , unmatched(master)
			count
			bysort bstate: egen max_manf_share=max(manf_share) if year>1920&year<1950
				gen man75 =1 if max_manf_share>=.2750076&max_manf_share!=. 
					replace man75 =0 if max_manf_share<.2750076&max_manf_share!=. 

		*Drop duplicates 
			sort bstate year
				gen x=1 if bstate==45&bstate[_n-1]==45&year==year[_n-1]
					tab x,m
					drop if x==1

		*Create region of birth variables
			*New England: Connecticut, Maine, Massachusetts, New Hampshire, Rhode Island, Vermont
			*Middle Atlantic: Delaware, Maryland, New Jersey, New York, Pennsylvania
			*South: Alabama, Arkansas, Florida, Georgia, Kentucky, Louisiana, Mississippi, Missouri, North Carolina, South Carolina, Tennessee, Virginia, West Virginia
			*Midwest: Illinois, Indiana, Iowa, Kansas, Michigan, Minnesota, Nebraska, North Dakota, Ohio, South Dakota, Wisconsin
			*Southwest:	Arizona, New Mexico, Oklahoma, Texas
			*West: Alaska, California, Colorado, Hawaii, Idaho, Montana, Nevada, Oregon, Utah, Washington, Wyoming
				gen bregion=1 if bstate==9|bstate==23|bstate==25|bstate==33|bstate==44|bstate==50
					replace bregion=2 if bstate==10|bstate==24|bstate==34|bstate==36|bstate==42
					replace bregion=3 if bstate==1| bstate==5|bstate==12|bstate==13|bstate==21|bstate==22|bstate==28|bstate==29|bstate==37|bstate==45|bstate==47|bstate==51|bstate==54
					replace bregion=4 if bstate==17|bstate==18|bstate==19|bstate==20|bstate==26|bstate==27|bstate==31|bstate==38|bstate==39|bstate==45|bstate==55
					replace bregion=5 if bstate==4|bstate==35|bstate==40|bstate==48
					replace bregion=6 if bstate==6|bstate==8|bstate==16|bstate==30|bstate==32|bstate==41|bstate==49|bstate==53|bstate==56

	*RUN EMPIRICAL MODELS

		reghdfe lcohort_size salaries_32 salaries_iu , absorb(year bstate i.bregion#i.year) cl(bstate)

		reghdfe lsex_ratio salaries_32 salaries_iu , absorb(year bstate i.bregion#i.year) cl(bstate)


