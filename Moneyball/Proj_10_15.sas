/* Project 1 SAS Code*/

/* import moneyball dataset in library */
FILENAME REFFILE '/folders/myfolders/moneyball.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.BASEBALL;
	GETNAMES=YES;
RUN;

data bsb;
set work.baseball;
run;

/* create a format to group missing and nonmissing */
proc format;
 value $missfmt ' '='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;
 
 /* check columns for missing and nonmissing values */
proc freq data=bsb; 
format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
tables _CHAR_ / missing missprint nocum nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;

proc univariate data=bsb noprint;
 /* var TARGET_WINS; */ 
 histogram;
run;

/* Drop TEAM_BATTING_BHP since 92% of the data is missing*/ 
data bsb_nohbp;
set bsb;
drop TEAM_BATTING_HBP;
run;

/* Data Imputes */ 
data imp_bsb_nohbp;
set bsb_nohbp;
/*Impute TEAM_FIELDING_DOUBLEPLAYS with 0 if no value present */ 
IMP_TEAM_FIELDING_DP = TEAM_FIELDING_DP;
if IMP_TEAM_FIELDING_DP = . then IMP_TEAM_FIELDING_DP = 100;
drop TEAM_FIELDING_DP;
/*Impute IMP_TEAM_PITCHING_STRIKEOUTS with the mean if no value present */ 
IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = . then IMP_TEAM_PITCHING_SO = 800;
if IMP_TEAM_PITCHING_SO = 0 then IMP_TEAM_PITCHING_SO = 1;
drop TEAM_PITCHING_SO;
/*Impute TEAM_BASERUN_STOLENBASES with 0 if no value present */ 
IMP_TEAM_BASERUN_SB  = TEAM_BASERUN_SB;
if IMP_TEAM_BASERUN_SB = . then IMP_TEAM_BASERUN_SB = 100;
drop TEAM_BASERUN_SB;
/*Impute TEAM_BATTING_STRIKEOUTS  with mean if no value present */
IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = . then IMP_TEAM_BATTING_SO = 700;  
drop TEAM_BATTING_SO;
/*Impute TEAM_BASERUN_CAUGHTSTEALING with analogy between means of TEAM_BASERUN_STOLENBASES - TEAM_BASERUN_CAUGHTSTEALING */
IMP_TEAM_BASERUN_CS = TEAM_BASERUN_CS; 
if IMP_TEAM_BASERUN_CS = . then IMP_TEAM_BASERUN_CS = IMP_TEAM_BASERUN_SB/14;
drop TEAM_BASERUN_CS;
run;

proc print data=imp_bsb_nohbp(obs=20); run;

/*Histogram of all variables */ 
proc univariate data=imp_bsb_nohbp noprint;
 /* var TARGET_WINS; */ 
 histogram;
run;

/* Data Normalization */
data trsf_imp_bsb_nohbp;
set imp_bsb_nohbp;
/*Reciprocal Transformation of TEAM_PITCHING_H */
TRSF_TEAM_PITCHING_H = TEAM_PITCHING_H;
TRSF_TEAM_PITCHING_H = (-1/TRSF_TEAM_PITCHING_H);
drop TEAM_PITCHING_H;
/*Log Transformation of TEAM_PITCHING_BB */
TRSF_TEAM_PITCHING_BB = TEAM_PITCHING_BB;
TRSF_TEAM_PITCHING_BB = log(TRSF_TEAM_PITCHING_BB);
drop TEAM_PITCHING_BB;
/*Log Transformation of TEAM_FIELDING_E */
TRSF_TEAM_FIELDING_E = TEAM_FIELDING_E;
TRSF_TEAM_FIELDING_E = log(TRSF_TEAM_FIELDING_E);
drop TEAM_FIELDING_E;
/*Log Transformation of IMP_TEAM_PITCHING_SO */
TRSF_IMP_TEAM_PITCHING_SO = IMP_TEAM_PITCHING_SO;
TRSF_IMP_TEAM_PITCHING_SO = log(TRSF_IMP_TEAM_PITCHING_SO);
drop IMP_TEAM_PITCHING_SO;
/*Log Transformation of TEAM_BATTING_3B */
TRSF_TEAM_BATTING_3B = TEAM_BATTING_3B;
TRSF_TEAM_BATTING_3B = log(TRSF_TEAM_BATTING_3B);
drop TEAM_BATTING_3B;
/*Log Transformation of IMP_TEAM_BASERUN_SB */
TRSF_IMP_TEAM_BASERUN_SB = IMP_TEAM_BASERUN_SB;
TRSF_IMP_TEAM_BASERUN_SB = log(TRSF_IMP_TEAM_BASERUN_SB);
drop IMP_TEAM_BASERUN_SB;
/*Log Transformation of IMP_TEAM_BASERUN_CS */
TRSF_IMP_TEAM_BASERUN_CS = IMP_TEAM_BASERUN_CS;
TRSF_IMP_TEAM_BASERUN_CS = log(TRSF_IMP_TEAM_BASERUN_CS);
drop IMP_TEAM_BASERUN_CS;
run;

proc univariate data=trsf_imp_bsb_nohbp noprint;
  *var TRSF_IMP_TEAM_PITCHING_SO;
 histogram;
run;

/*Frequency table of target wins  */ 
*proc freq data=imp_bsb_nohbp;
*table TARGET_WINS / plots=freqplot;
*run;


/* Fix Outliers!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
proc means data=trsf_imp_bsb_nohbp mean std min p25 median p75 max p5 p95 maxdec=1; run;
* stddev < mean so no outliers seem present;

proc univariate data=trsf_imp_bsb_nohbp noprint;
 histogram;
run;


/*Test model to figure out significant variables */ 
/*Removed following variables due to high VIF: TEAM_BATTING_HR TEAM_BATTING_BB TRSF_TEAM_FIELDING_E 
IMP_TEAM_BATTING_SO TEAM_BATTING_2B TRSF_IMP_TEAM_PITCHING_SO*/ 
proc reg data=trsf_imp_bsb_nohbp plots=diagnostics;
model TARGET_WINS = TEAM_BATTING_H  TEAM_PITCHING_HR IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS 
TEAM_BATTING_HR TEAM_BATTING_BB TRSF_TEAM_FIELDING_E 
IMP_TEAM_BATTING_SO TEAM_BATTING_2B TRSF_IMP_TEAM_PITCHING_SO
/ vif collin;
run;




/*Model construction stepwise*/ 
proc reg data=trsf_imp_bsb_nohbp plots(only label)=(RStudentByLeverage CooksD);
model TARGET_WINS = TEAM_BATTING_H  TEAM_PITCHING_HR IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS 
TEAM_BATTING_HR TEAM_BATTING_BB TRSF_TEAM_FIELDING_E 
IMP_TEAM_BATTING_SO TEAM_BATTING_2B TRSF_IMP_TEAM_PITCHING_SO
/AIC selection=stepwise;
run;

/*Model construction forward*/ 
proc reg data=trsf_imp_bsb_nohbp plots(only label)=(RStudentByLeverage CooksD);
model TARGET_WINS = TEAM_BATTING_H  TEAM_PITCHING_HR IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS 
TEAM_BATTING_HR TEAM_BATTING_BB TRSF_TEAM_FIELDING_E 
IMP_TEAM_BATTING_SO TEAM_BATTING_2B TRSF_IMP_TEAM_PITCHING_SO 
/AIC selection=forward;
run;

/*Model construction backward*/
proc reg data=trsf_imp_bsb_nohbp plots(only label)=(RStudentByLeverage CooksD);
model TARGET_WINS = TEAM_BATTING_H  TEAM_PITCHING_HR IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS 
TEAM_BATTING_HR TEAM_BATTING_BB TRSF_TEAM_FIELDING_E 
IMP_TEAM_BATTING_SO TEAM_BATTING_2B TRSF_IMP_TEAM_PITCHING_SO 
/AIC selection=backward;
run;

/* Variable selection via GLMSelect */
proc glmselect data=trsf_imp_bsb_nohbp ;
model TARGET_WINS = TEAM_BATTING_H  TEAM_PITCHING_HR IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS 
TEAM_BATTING_HR TEAM_BATTING_BB TRSF_TEAM_FIELDING_E 
IMP_TEAM_BATTING_SO TEAM_BATTING_2B TRSF_IMP_TEAM_PITCHING_SO  / selection=forward;
run; quit;

proc reg data=trsf_imp_bsb_nohbp ;
model TARGET_WINS = TEAM_BATTING_H  TEAM_PITCHING_HR IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS / partial;
run; quit;

/*Model construction*/
proc reg data=trsf_imp_bsb_nohbp corr plots(label)=(RStudentByLeverage CooksD);
model TARGET_WINS = TEAM_BATTING_H  IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS 
TEAM_BATTING_HR TEAM_BATTING_BB TRSF_TEAM_FIELDING_E
 TEAM_BATTING_2B
/AIC;
run; quit;


proc reg data=trsf_imp_bsb_nohbp plots(only label)=(RStudentByLeverage CooksD);
model TARGET_WINS = TEAM_BATTING_H  TEAM_PITCHING_HR IMP_TEAM_FIELDING_DP TRSF_TEAM_PITCHING_H 
TRSF_TEAM_PITCHING_BB TRSF_TEAM_BATTING_3B TRSF_IMP_TEAM_BASERUN_SB TRSF_IMP_TEAM_BASERUN_CS 
/AIC;
run;

proc print data=trsf_imp_bsb_nohbp(obs=20); run;