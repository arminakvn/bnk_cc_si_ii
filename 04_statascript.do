cd "/home/arminakvn/Google Drive/banking_checkcashing/"
log using main11.log, replace
use "exporting_v11.dta"


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

* Create weight matrix with truncation after 5km
* spmatrix create idistance idistwm, vtruncate(1/5) replace
* spmatrix note idistwm: idist w mtrx 1/5km trunc
* spmatrix summarize idistwm
* spmatrix save idistwm using idistwm_all.stswm, replace
spmatrix use idistwm using idistwm_all.stswm, replace

foreach mode in car pt foot {
spregress df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt i.citname, ml errorlag(idistwm) force
}
* Spatial error + spatial indepvar lag
foreach mode in car pt foot {
spregress df_`mode' blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt i.citname, ml errorlag(idistwm) ivarlag(idistwm: blc15 lat15 asia15 pov15 frn15 popden_natlog15 edu15 ump15 own15  hu15 vacrat15 blb00 comdenpercapt) force
}
log close
