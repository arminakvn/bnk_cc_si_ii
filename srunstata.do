cd "/scratch/arminakhavan/"
log using srunmain2.log, replace
use "exporting_v10.dta"

* Make cityname usable
destring cityname, gen(cityname2)
encode cityname, gen(citname2)

* Summarize time to institution
foreach fi in bnk cc {
foreach mode in car pt foot {
sum time_`fi'_`mode'_minutes, det
}
}
* Generate difference variable
foreach mode in car pt foot {
gen df_`mode'=time_bnk_`mode'_minutes - time_cc_`mode'_minutes
label variable df_`mode' "Bnk tm-cc tm, `mode'"
sum df_`mode', det
}
* Generate 1/0 outcome variable
foreach mode in car pt foot {
gen ccclsr_`mode' = 0 
replace ccclsr_`mode' = . if df_`mode' ==.
replace ccclsr_`mode' = 0 if df_`mode' <= 0
replace ccclsr_`mode' = 1 if df_`mode' > 1
label variable ccclsr_`mode' "Cc closer, `mode'"
tab1 ccclsr_`mode'
}
* Some correlations 
foreach fi in bnk cc{
foreach mode in car pt foot {
pwcorr time_`fi'_`mode'_minutes blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt 
}
}
foreach mode in car pt foot {
bysort ccclsr_`mode': sum blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt 
}

* Predictions, nested models, difference outcome 
* 1 OLS
foreach mode in car pt foot {
reg df_`mode' blc15 lat15 asia15
reg df_`mode' blc15 lat15 asia15 pov15
reg df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15
reg df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00
reg df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt
 }
* 2 Fixed effects (equivalent to areg  w/ vce(cluster citname))
foreach mode in car pt foot {
reg df_`mode' blc15 lat15 asia15 i.citname2, robust cluster(citname2)
reg df_`mode' blc15 lat15 asia15 pov15 i.citname2, robust cluster(citname2)
reg df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 i.citname2, robust cluster(citname2)
reg df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 i.citname2, robust cluster(citname2)
reg df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt i.citname2, robust cluster(citname2)
 }
* 3 Spatial error with fixed effects, last model
 * Set data as spatial
spset geoid
spset, modify coord(x y)
spset, modify coordsys(latlong, kilometers)
 * To just use 600 cases as test
 * do test_600 
 * spmatrix clear
 * use temp.dta, clear
* Create weight matrix with truncation after 5km
spmatrix create idistance idistwm, vtruncate(1/5) replace
spmatrix note idistwm: idist w mtrx 1/5km trunc
spmatrix summarize idistwm
spmatrix save idistwm using idistwm.stswm, replace
foreach mode in car pt foot {
spregress df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt i.citname, ml errorlag(idistwm) force
}
* Spatial error + spatial indepvar lag
foreach mode in car pt foot {
spregress df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt i.citname, ml errorlag(idistwm) ivarlag(idistwm: blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt) force
}
log close

