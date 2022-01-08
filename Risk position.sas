options compress = yes;

/*Import excel*/
PROC IMPORT OUT=WORK.Outfile1
		DATAFILE="S:\Residual Values\Reforecasting\AllVeicoli"
		DBMS=EXCEL Replace;
		sheet="Feuil1";
Run;

/*Keep only relevant columns*/
data Outfile2;
set Outfile1;
keep Codice_Infocar Origine_previsione Previsione_____a_6_mesi0 Previsione_____a_12_mesi0 Previsione_____a_24_mesi0 Previsione_____a_36_mesi0 Previsione_____a_48_mesi0 Previsione_____a_60_mesi0;
run;

/*Sorting*/
proc sort data=Outfile2 out=Outfile3;
	by Codice_Infocar Origine_previsione;
run;

/*Transpose*/
proc transpose data=Outfile3 out=Outfile4;
	by Codice_Infocar Origine_previsione;
	var Previsione_____a_6_mesi0 Previsione_____a_12_mesi0 Previsione_____a_24_mesi0 Previsione_____a_36_mesi0 Previsione_____a_48_mesi0 Previsione_____a_60_mesi0;
run;

/*Prepare table more*/
data Outfile5;
set Outfile4;
Drop _NAME_ COL2;
Origine_previsione=substr(Origine_previsione,1,5);
If substr(_LABEL_,18,2)="6 " then _LABEL_="6";
If substr(_LABEL_,18,2)="12" then _LABEL_="12";
If substr(_LABEL_,18,2)="24" then _LABEL_="24";
If substr(_LABEL_,18,2)="36" then _LABEL_="36";
If substr(_LABEL_,18,2)="48" then _LABEL_="48";
If substr(_LABEL_,18,2)="60" then _LABEL_="60";
rename _LABEL_=Term;
rename COL1=RV;
run;

/*Export excel*/
proc export
	data= Outfile5
	dbms=xlsx
	outfile="S:\Residual Values\Reforecasting\AllVeicoliOutput.xlsx"
	Replace;
run;

