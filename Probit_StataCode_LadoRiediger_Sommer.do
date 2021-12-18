clear all

******************************* PREPARATION ************************************

/* Choose one of the three different counting methods to transform the peak and 
trough months that are published by the ECRI into a binary recession variable, 
i.e. midpoint method, peak method, troughmethod (Nissilä 2020). We decided to 
apply the troughmethod, see section 4 of the paper.
*/


* Load data
import excel "/Users/nicolasladoriediger/Desktop/Aktuelle Forschungsfragen der Ökonometrie/Stata/Probit_DataSet_LadoRiediger_Sommer.xlsx", sheet("Tabelle2") firstrow


* Transform into time series
gen time = monthly(zeit, "MY")
format time %tmNN/CCYY
tsset time, monthly
drop zeit


* Label data, where the source is put into parentheses 
label var time "Sample Period: January 1999 - February 2021" 
label var recession "Binary recession indicator based on ECRI definitions (ECRI)"
label var cdax "Composite DAX (Deutsche Bundesbank)"
label var euribor "3 month Euribor rate (Deutsche Bundesbank)"
label var ifoindex "ifo Business Climate Index, Germany, 2015 = 100 (ifo Institut)"
label var prod "Production in the manufacturing industry without construction, seasonally adjusted, 2015 = 100 (Deutsche Bundesbank)"
label var term10 "The yield of German government bond with maturity of 10 years (Deutsche Bundesbank)"


* Calculated the term spread as the difference between the yield of German government bond with maturity of 10 years and 3 month Euribor rate
generate term_spread10 = term10 - euribor
label var term_spread10 "Term spread between the yield of German government bond with maturity of 10 years and 3 month Euribor rate (own calculations based on data from Deutsche Bundesbank)"	


* Order data
order time recession cdax euribor ifoindex prod term_spread10 term10


/* Remarks on the data:
All data used are calendar and seasonally adjusted following the procedure 
of the Deutsche Bundesbank (IMK Study, p.23)

We use production in the producting sector (without building sector) as a proxy 
for overall economic activity (IMK Study, p.20) 

Euribor & production are integrated of order 1 (see IMK Study, p. 18/19)

We abstract from benchmark revisions, since it is commonly assumed (reference!) 
that they do not significantly change the initially published values. 
*/



********************** DESCRIPTIVES & TRANSFORMATION **********************+****

* Check for non-stationarity. If necessary create stationary variables.
tsline cdax
dfuller cdax
* p-value = 0.9470. We cannot reject the null of an unit root. Non-stationarity
generate cdax_gr = ln(cdax)-ln(L1.cdax)
tsline cdax_gr
dfuller cdax_gr
* p-value = 0.0000. We can reject the null of an unit root. Stationarity

tsline euribor
dfuller euribor
* p-value = 0.9156. We cannot reject the null of an unit root. Non-stationarity
generate euribor_gr = euribor - L1.euribor
tsline euribor_gr
dfuller euribor_gr
* p-value = 0.0000. We can reject the null of an unit root. Stationarity

tsline ifoindex
dfuller ifoindex
* p-value = 0.2871. We cannot reject the null of an unit root. Non-stationarity
generate ifoindex_gr = ln(ifoindex) - ln(L1.ifoindex)
tsline ifoindex_gr
dfuller ifoindex_gr
* p-value = 0.0000. We can reject the null of an unit root. Stationarity

tsline prod
dfuller prod
* p-value = 0.1902. We cannot reject the null of an unit root. Non-stationarity
generate prod_gr = ln(prod) - ln(L1.prod)
tsline prod_gr
dfuller prod_gr
* p-value = 0.0000. We can reject the null of an unit root. Stationarity

tsline term_spread10
dfuller term_spread10
* p-value = 0.2837. We cannot reject the null of an unit root. Non-stationarity
generate ts10_gr = term_spread10 - L1.term_spread10
tsline ts10_gr
dfuller ts10_gr
* p-value = 0.0000. We can reject the null of an unit root. Stationarity


* Summarizing the number of recessionary and expansionary months
tabulate recession
/* From January 1999 until April 2020, 49 months are classified as recession, 
indicated by a 1 in the binary variable whereas 207 months are classified as 
expansion, indicated by a 0 in the binary variable. Note that for May 2020 until
February 2021 the ECRI has not yet provided peak/ trough months. Therefore the 
binary variable has missing values for this period. */



****************************** SELECTION ***************************************

/* We use the Bayesian information criterion (BIC) for model selection. We do 
this for four different models:

1) sta1: The static probit model with forecast horizon of 1 month,  i.e. h=1
2) dyn1: The dynamic probit model with forecast horizon of 1 month, i.e. h=1 
3) sta3: The static probit model with forecast horizon of 3 months, i.e. h=3
4) dyn3: The dynamic probit model with forecast horizon of 1 month, i.e. h=3

For each model we include the information of the last 12 months. This means that
we test through lag 1 up until lag 12 of each included variable.

Since in this paper we want to estimate the recession probabilities under 
real-time conditions, we have to take into account the data availability lag s,
and the recession recognition lag r.

The only explanatory that has a data availability lag s is production. 
For production s=2.
Therefore, for a forecast horizon of h=1, the first lag of production that can 
be included is s+h = 2+1 = 3.
Therefore, for a forecast horizon of h=3, the first lag of production that can 
be included therefore is s+h = 2+3 = 5.

The ECRI has a recession recognition lag of nine month, i.e. r=9.
Therefore, for a forecast horizon of h=1, the first lag of the binary variable 
"recession" that can be included in the dynamic model is r+h = 9+1 = 10.
Therefore, for a forecast horizon of h=3, the first lag of the binary variable 
"recession" that can be included in the dynamic model is r+h = 9+3 = 12.*/

/* We proceed by the following scheme:

We start at lag 1 and go up to lag 12. For each lag we go through different 
stages. In the first stage we compare the "baseline model" with models where we 
included the particular lag for each variable. For the first stage of lag 1, 
this means: 

probit recession
vs. 
probit recession L1.cdax_gr
vs.
probit recession L1.euribor_gr
vs.
probit recession L1.ifoindex_gr
vs.
probit recession L1.ts10_gr

Note that neither a lag of recession nor of production can be included here due 
to the above mentioned constraints.

The model that has the lowest IC value is the one that moves to the second 
stage for lag 1. The second stage may then look like follows:

probit recession L1.cdax_gr
vs.
probit recession L1.cdax_gr L1.euribor_gr
vs.
probit recession L1.cdax_gr L1.ifoindex_gr
vs.
probit recession L1.cdax_gr L1.ts10_gr

This procedure is repeated until the "baseline model" is the model with the 
lowest BIC value. In other words, no other alternative model beats the 
"baseline model". 

Then, the "baseline model" for lag 1 moves to the first stage of lag 2 and the 
procedure follows the same pattern as described for lag 1. 
We do this for all lags up until lag 12. This gives us in the end our four 
final models: sta1, dyn 1, sta3, dyn3.
*/


/* We start with the model selection based on BIC. Since the last trough month 
as defined by the ECRI is April 2020 and due to testing up to twelve lags, our 
in-sample period is 02/2000 - 04/2020. */

* The first model we look at in the following is the static model for h=1


* L1 - First stage 

probit recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 249.7936
probit recession L1.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 246.1558
probit recession L1.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.0601
probit recession L1.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.7588
probit recession L1.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 250.6792

* According to BIC, the model with L1.ifoindex_gr performs best


* L1 - Second stage 

probit recession L1.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.7588
probit recession L1.ifoindex_gr L1.cdax_gr  if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.3295
probit recession L1.ifoindex_gr L1.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.6478
probit recession L1.ifoindex_gr L1.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.8103

* According to BIC, the model with L1.ifoindex_gr and L1.euribor_gr performs best


* L1 - Third stage 

probit recession L1.ifoindex_gr L1.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.6478
probit recession L1.ifoindex_gr L1.euribor_gr  L1.cdax_gr  if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.7631
probit recession L1.ifoindex_gr L1.euribor_gr  L1.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.2639

* According to BIC, the model with L1.ifoindex_gr and L1.euribor_gr performs best


* L2 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.6478
probit recession L1.ifoindex_gr L1.euribor_gr L2.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.6738
probit recession L1.ifoindex_gr L1.euribor_gr L2.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.9348
probit recession L1.ifoindex_gr L1.euribor_gr L2.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.0342
probit recession L1.ifoindex_gr L1.euribor_gr L2.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.9235

* According to BIC, the model with L1.ifoindex_gr and L1.euribor_gr performs best


* L3 - First stage: Note that now enters the production, i.e. prod_gr

probit recession L1.ifoindex_gr L1.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.6478
probit recession L1.ifoindex_gr L1.euribor_gr L3.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.7056
probit recession L1.ifoindex_gr L1.euribor_gr L3.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.0368
probit recession L1.ifoindex_gr L1.euribor_gr L3.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 234.2419
probit recession L1.ifoindex_gr L1.euribor_gr L3.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.1396
probit recession L1.ifoindex_gr L1.euribor_gr L3.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.0785

* According to BIC, the model with L1.ifoindex_gr and L1.euribor_gr performs best


* L4 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.6478
probit recession L1.ifoindex_gr L1.euribor_gr L4.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.6466
probit recession L1.ifoindex_gr L1.euribor_gr L4.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.5869
probit recession L1.ifoindex_gr L1.euribor_gr L4.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.4652
probit recession L1.ifoindex_gr L1.euribor_gr L4.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.9233
probit recession L1.ifoindex_gr L1.euribor_gr L4.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.6355

* According to BIC, the model with L1.ifoindex_gr and L1.euribor_gr performs best


* L5 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.6478
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.1396
probit recession L1.ifoindex_gr L1.euribor_gr L5.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.7218
probit recession L1.ifoindex_gr L1.euribor_gr L5.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 234.7116
probit recession L1.ifoindex_gr L1.euribor_gr L5.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.3838
probit recession L1.ifoindex_gr L1.euribor_gr L5.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.1585

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr and L5.cdax_gr performs best


* L5 - Second stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.1396
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L5.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 234.1099
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L5.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.7231
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L5.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.0943
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L5.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 232.8074

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr and L5.cdax_gr performs best


* L6 - First stage 
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.1396
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.145
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.9771
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 232.1651
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 234.6888
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.7198

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr and L6.cdax_gr performs best


* L6 - Second stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.145
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L6.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 229.8736
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L6.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.739
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L6.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 232.2961
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L6.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.8283

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr and L6.cdax_gr performs best


* L7 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.145
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.0528
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 229.1358
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.8104
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.3397
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 233.0489

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr and L7.cdax_gr performs best


* L7 - Second stage

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.0528
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.772
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 229.2823
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 232.371
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.7096

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr and L7.cdax_gr performs best


* L8 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.0528
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 225.4856
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.8722
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.3406
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 229.5721
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 232.049

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr and L8.cdax_gr performs best


* L8 - Second stage

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 225.4856
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 226.8972
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.6304
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.269
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.7424

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr and L8.cdax_gr performs best


* L9 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 225.4856
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.9139
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.5997
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.8176
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 229.2926
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.9529

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr and L9.ifoindex_gr performs best


* L9 - Second stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.8176
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.2694
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 229.6018
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.0075
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.3034

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr and L9.ifoindex_gr performs best


* L10 - First stage 
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.8176
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 223.099
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.9854
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 226.0864
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.1719
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.0745

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr and L10.cdax_gr performs best


* L10 - Second stage

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 223.099
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.7084
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 226.3719
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.5436
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.5801

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr and L10.cdax_gr performs best


* L11 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 223.099
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 219.3535
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 225.704
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 223.0375
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.217
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.5323

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr and L11.cdax_gr performs best


* L11 - Second stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 219.3535
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 222.7845
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 222.736
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 223.5171
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.6962

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr and L11.cdax_gr performs best


* L12 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 219.3535
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 219.4426
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 222.4998
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 220.4093
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.309
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.7573

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr and L11.cdax_gr performs best



* Final static model for h=1 according to BIC
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 219.3535





/* Now we turn to the dynamic probit model for h=1. Again, the first lag of the 
binary recession variable that could enter the model is lag 10, because h=1 and 
a recession recognition lag r=9. Therefore we start at L10. */


* L10 - First stage 

* L10 - First stage 
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 224.8176
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 223.099
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 228.9854
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 226.0864
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.1719
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 209.5666
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.0745

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr and L10.recession performs best


* L10 - Second stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 209.5666
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 211.4333
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L10.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 214.3651
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L10.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 212.6189
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L10.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 214.8288
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L10.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 211.9479

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr and L10.recession performs best


* L11 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 209.5666
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 208.618
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 214.9395
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 212.8404
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 214.9738
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 214.5181
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 212.1919

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.recession and L11.cdax_gr performs best


* L11 - Second stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 208.618
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L11.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 213.9075
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L11.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 213.4701
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L11.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 213.9641
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L11.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 214.0659
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L11.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 213.0254

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.recession and L11.cdax_gr performs best


* L12 - First stage 

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 208.618
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L12.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 211.5344
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L12.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 214.0791
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L12.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 212.3473
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L12.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 213.9912
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 213.1743
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr L12.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 212.5401

* According to BIC, the model with L1.ifoindex_gr, L1.euribor_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.recession and L11.cdax_gr performs best



* Final dynamic model for h=1 according to BIC
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 208.618





/* Now we perform the same exercise for h=3. We start again with the static probit model, where the first lag of production that could enter the model is lag 5 due 
to the data availability lag of two months. */


* L3 - First stage 

probit recession if time > tm(2000m1) & time < tm(2020m5)
estat ic 
* BIC = 249.7936
probit recession L3.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 244.2432
probit recession L3.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 253.0855
probit recession L3.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.2711
probit recession L3.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 255.0701

* According to BIC, the model with L3.ifoindex_gr performs best


* L3 - Second stage 

probit recession L3.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.2711
probit recession L3.ifoindex_gr L3.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.6504
probit recession L3.ifoindex_gr L3.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 247.5951
probit recession L3.ifoindex_gr L3.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 247.4151

* According to BIC, the model with L3.ifoindex_gr performs best


* L4 - First stage

probit recession L3.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.2711
probit recession L3.ifoindex_gr L4.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 243.8354
probit recession L3.ifoindex_gr L4.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 245.5658
probit recession L3.ifoindex_gr L4.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 244.2188
probit recession L3.ifoindex_gr L4.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 246.1701

* According to BIC, the model with L3.ifoindex_gr performs best


* L5 - First stage: Note that now enters production, i.e. prod_gr

probit recession L3.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.2711
probit recession L3.ifoindex_gr L5.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.5005
probit recession L3.ifoindex_gr L5.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 244.7727
probit recession L3.ifoindex_gr L5.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.9114
probit recession L3.ifoindex_gr L5.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 247.6204
probit recession L3.ifoindex_gr L5.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 246.8112

* According to BIC, the model with L3.ifoindex_gr and L5.cdax_gr performs best


* L5 - Second stage 

probit recession L3.ifoindex_gr L5.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.5005
probit recession L3.ifoindex_gr L5.cdax_gr L5.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 244.3145
probit recession L3.ifoindex_gr L5.cdax_gr L5.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.9955
probit recession L3.ifoindex_gr L5.cdax_gr L5.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 245.9421
probit recession L3.ifoindex_gr L5.cdax_gr L5.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 243.8304

* According to BIC, the model with L3.ifoindex_gr and L5.cdax_gr performs best


* L6 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.5005
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.7905
probit recession L3.ifoindex_gr L5.cdax_gr L6.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 243.9284
probit recession L3.ifoindex_gr L5.cdax_gr L6.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.2173
probit recession L3.ifoindex_gr L5.cdax_gr L6.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 244.348
probit recession L3.ifoindex_gr L5.cdax_gr L6.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 244.3059

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr and L6.cdax_gr performs best


* L6 - Second stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.7905
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L6.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.2508
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L6.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.0845
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L6.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.2724
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L6.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 239.8575

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr and L6.cdax_gr performs best


* L7 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.7905
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.4632
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.9568
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 239.6304
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.4259
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.7039

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr and L7.cdax_gr performs best


* L7 - Second stage 
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.4632
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.6705
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.4213
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.5067
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L7.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.5415

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr and L7.cdax_gr performs best


* L8 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.4632
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.914
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.8302
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.6753
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.6512
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.8153

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr and L8.cdax_gr performs best


* L8 - Second stage

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.914
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.05
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 239.9708
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.5393
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L8.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.586

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr and L8.cdax_gr performs best


* L9 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.914
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 237.0085
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.4657
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.0708
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.0046
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 242.3887

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr and L9.ifoindex_gr performs best


* L9 - Second stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.0708
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 239.1995
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.5256
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.514
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L9.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.5605

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr and L9.ifoindex_gr performs best


* L10 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.0708
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.6109
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.5008
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.0902
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.1572
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.3804

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr and L10.cdax_gr performs best


* L10 - Second stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.6109
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.4424
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.6102
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.7541
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L10.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 241.097

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr and L10.cdax_gr performs best


* L11 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.6109
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.5904
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 238.9225
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.4176
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.5374
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 240.7858

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr and L11.cdax_gr performs best


* L11 - Second stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.5904
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.043
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 234.5487
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.6534
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L11.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.0835

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr and L11.cdax_gr performs best


* L12 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.5904
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.9743
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.921
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.2953
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.0699
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.3558

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr and L11.cdax_gr performs best



* Final static model for h=3 according to BIC
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.5904




/* Now we switch to the dynamic probit model for h=3. Due to the recession 
recognition lag of 9 months, i.e. r=9, the first lag of the binary recession 
variable that could enter the model is lag 12. Therefore, we start at L12.*/


* L12 - First stage 

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.5904
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.9743
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.921
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.2953
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 236.0699
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.5017
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 235.3558

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr, L11.cdax_gr and L12.recession performs best


* L12 - Second stage 
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.5017
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession L12.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.4893
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession L12.euribor_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 231.8491
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession L12.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 230.6203
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession L12.prod_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 232.6249
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession L12.ts10_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 229.9377

* According to BIC, the model with L3.ifoindex_gr, L5.cdax_gr, L6.cdax_gr, L7.cdax_gr, L8.cdax_gr, L9.ifoindex_gr, L10.cdax_gr, L11.cdax_gr and L12.recession performs best



* Final dynamic model for h=3 according to BIC
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic
* BIC = 227.5017





******************************* IN-SAMPLE EVALUATION ***************************

* Final static model for h=1 according to BIC
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic

*                       N   ll(null)  ll(model)      df        AIC        BIC
* -------------+---------------------------------------------------------------
*              |      243  -122.1503  -82.21146      10   184.4229   219.3535
* -----------------------------------------------------------------------------

* Pseudo R-squared: Estrella = 1-(ll(model)/ll(null))^((-2/N)*ll(null))
gen Estrella_sta1_bic = 1-(-82.21146/-122.1503)^((-2/243)*(-122.1503))
* .32838956

* Adjusted Pseudo R-squared: AdjEstrella = 1-((ll(model)-df)/ll(null))^((-2/N)*ll(null))
gen AdjEstrella_sta1_bic = 1-((-82.21146-10)/-122.1503)^((-2/243)*(-122.1503))
* .24623355

* AIC = 184.4229

* BIC = 219.3535

* PCP
predict p_sta1_bic if e(sample)
gen bin_p_sta1_bic = (p_sta1_bic > 0.5)
gen diff_rec_sta1_bic = recession - bin_p_sta1_bic
count if diff_rec_sta1_bic == 0
* 207
gen pcp_sta1_bic = 207/243
* .85185188



* Final dynamic model for h=1 according to BIC
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic

*                       N   ll(null)  ll(model)      df        AIC        BIC
* -------------+---------------------------------------------------------------
*              |      243  -122.1503  -76.84368      10   173.6874    208.618
* -----------------------------------------------------------------------------

* Pseudo R-squared: Estrella = 1-(ll(model)/ll(null))^((-2/N)*ll(null))
gen Estrella_dyn1_bic = 1-(-76.84368/-122.1503)^((-2/243)*(-122.1503))
* .37246743

* Adjusted Pseudo R-squared: AdjEstrella = 1-((ll(model)-df)/ll(null))^((-2/N)*ll(null))
gen AdjEstrella_dyn1_bic = 1-((-76.84368-10)/-122.1503)^((-2/243)*(-122.1503))
* .29033938

* AIC = 173.6874

* BIC = 208.618

* PCP
predict p_dyn1_bic if e(sample)
gen bin_p_dyn1_bic = (p_dyn1_bic > 0.5)
gen diff_rec_dyn1_bic = recession - bin_p_dyn1_bic
count if diff_rec_dyn1_bic == 0
* 215
gen pcp_dyn1_bic = 215/243
* .88477367



* Final static model for h=3 according to BIC
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
estat ic

*                       N   ll(null)  ll(model)      df        AIC        BIC
* -------------+---------------------------------------------------------------
*              |      243  -122.1503  -90.57645       9   199.1529   230.5904
* -----------------------------------------------------------------------------
* Pseudo R-squared: Estrella = 1-(ll(model)/ll(null))^((-2/N)*ll(null))
gen Estrella_sta3_bic = 1-(-90.57645/-122.1503)^((-2/243)*(-122.1503))
* .25966954

* Adjusted Pseudo R-squared: AdjEstrella = 1-((ll(model)-df)/ll(null))^((-2/N)*ll(null))
gen AdjEstrella_sta3_bic = 1-((-90.57645-9)/-122.1503)^((-2/243)*(-122.1503))
* .1856949

* AIC = 199.1529

* BIC = 230.5904

* PCP
predict p_sta3_bic if e(sample)
gen bin_p_sta3_bic = (p_sta3_bic > 0.5)
gen diff_rec_sta3_bic = recession - bin_p_sta3_bic
count if diff_rec_sta3_bic == 0
* 200
gen pcp_sta3_bic = 200/243
* .82304525



* Final dynamic model for h=3 according to BIC
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m5)
estat ic

*                       N   ll(null)  ll(model)      df        AIC        BIC
* -------------+---------------------------------------------------------------
*              |      243  -122.1503  -86.28555      10   192.5711   227.5017
* -----------------------------------------------------------------------------

* Pseudo R-squared: Estrella = 1-(ll(model)/ll(null))^((-2/N)*ll(null))
gen Estrella_dyn3_bic = 1-(-86.28555/-122.1503)^((-2/243)*(-122.1503))
* .29492459

* Adjusted Pseudo R-squared: AdjEstrella = 1-((ll(model)-df)/ll(null))^((-2/N)*ll(null))
gen AdjEstrella_dyn3_bic = 1-((-86.28555-10)/-122.1503)^((-2/243)*(-122.1503))
* .21274848

* AIC = 192.5711

* BIC = 227.5017

* PCP
predict p_dyn3_bic if e(sample)
gen bin_p_dyn3_bic = (p_dyn3_bic > 0.5)
gen diff_rec_dyn3_bic = recession - bin_p_dyn3_bic
count if diff_rec_dyn3_bic == 0
* 205
gen pcp_dyn3_bic = 205/243


******************************+ PLOTS: IN-SAMPLE *******************************


/* We put both the static and the dynamic model for the same forecast horizon #
into one plot. This gives 2 plots in total:
1) BIC: sta1 and dyn1
2) BIC: sta3 and dyn3 */
	
	
* 1) BIC: sta1 and dyn1
twoway ///
		(area recession time, color(gs14)) ///  
        (tsline p_sta1_bic, color(orange)) ///
		(tsline p_dyn1_bic, color(green)), ///
		ytitle("Recession probability", size(medium)) ///
		yline(0.5) ///
		graphregion(fcolor(white)) ///
		xtitle("Time", size(small)) ///
		ylabel(0(0.1)1, labsize(small)) tlabel(, format(%tmCCYY)) ///
		xlabel(,labsize(small)) ///
		legend(size(small) label(1 "ECRI recession months") label(2 "Recession probability static (h=1)") label(3 "Recession probability dynamic (h=1)"))

		
* 2) BIC: sta3 and dyn3		
twoway ///
		(area recession time, color(gs14)) ///
		(tsline p_sta3_bic, color(blue)) ///
		(tsline p_dyn3_bic, color(pink)), ///
		ytitle("Recession probability", size(medium)) ///
		yline(0.5) ///
		graphregion(fcolor(white)) ///
		xtitle("Time", size(small)) ///
		ylabel(0(0.1)1, labsize(small)) tlabel(, format(%tmCCYY)) ///
		xlabel(,labsize(small)) ///
		legend(size(small) label(1 "ECRI recession months") label(2 "Recession probability static (h=3)") label(3 "Recession probability dynamic (h=3)"))	


		
		
****************************** OUT-OF-SAMPLE EVALUATION ************************

/* For the out-of-sample evaluation we use an expanding window that starts in 
May 2018 and runs until April 2020. We re-estimate each model every month, since
the literature (see section 2 of the paper) suggests that iterative forecasts, 
i.e. with a one-step ahead, provide better results than direct forecasts. */



* We start with the final static probit model specification for h = 1 according to BIC:
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m6)
predict p_sta1_1805 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m7)
predict p_sta1_1806 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m8)
predict p_sta1_1807 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m9)
predict p_sta1_1808 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m10)
predict p_sta1_1809 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m11)
predict p_sta1_1810 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m12)
predict p_sta1_1811 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m1)
predict p_sta1_1812 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m2)
predict p_sta1_1901 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m3)
predict p_sta1_1902 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m4)
predict p_sta1_1903 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m5)
predict p_sta1_1904 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m6)
predict p_sta1_1905 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m7)
predict p_sta1_1906 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m8)
predict p_sta1_1907 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m9)
predict p_sta1_1908 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m10)
predict p_sta1_1909 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m11)
predict p_sta1_1910 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m12)
predict p_sta1_1911 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m1)
predict p_sta1_1912 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m2)
predict p_sta1_2001 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m3)
predict p_sta1_2002 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m4)
predict p_sta1_2003 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
predict p_sta1_2004 if e(sample)

* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final static probit model specification for h = 1 according to BIC. The referring column in the data set is poos_p_sta1.




* We perform the same exercise for the final dynamic probit model specification for h=1 according to BIC:
probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2018m6)
predict p_dyn1_1805 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2018m7)
predict p_dyn1_1806 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2018m8)
predict p_dyn1_1807 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2018m9)
predict p_dyn1_1808 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2018m10)
predict p_dyn1_1809 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2018m11)
predict p_dyn1_1810 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2018m12)
predict p_dyn1_1811 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m1)
predict p_dyn1_1812 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m2)
predict p_dyn1_1901 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m3)
predict p_dyn1_1902 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m4)
predict p_dyn1_1903 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m5)
predict p_dyn1_1904 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m6)
predict p_dyn1_1905 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m7)
predict p_dyn1_1906 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m8)
predict p_dyn1_1907 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m9)
predict p_dyn1_1908 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m10)
predict p_dyn1_1909 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m11)
predict p_dyn1_1910 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2019m12)
predict p_dyn1_1911 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m1)
predict p_dyn1_1912 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m2)
predict p_dyn1_2001 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m3)
predict p_dyn1_2002 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m4)
predict p_dyn1_2003 if e(sample)

probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
predict p_dyn1_2004 if e(sample)

* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final dynamic probit model specification for h = 1 according to BIC. The referring column in the data set is poos_p_dyn1.


* We perform the same exercise for h=3. We start with the final static probit model specification for h = 3 according to BIC:
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m6)
predict p_sta3_1805 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m7)
predict p_sta3_1806 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m8)
predict p_sta3_1807 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m9)
predict p_sta3_1808 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m10)
predict p_sta3_1809 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m11)
predict p_sta3_1810 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2018m12)
predict p_sta3_1811 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m1)
predict p_sta3_1812 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m2)
predict p_sta3_1901 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m3)
predict p_sta3_1902 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m4)
predict p_sta3_1903 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m5)
predict p_sta3_1904 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m6)
predict p_sta3_1905 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m7)
predict p_sta3_1906 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m8)
predict p_sta3_1907 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m9)
predict p_sta3_1908 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m10)
predict p_sta3_1909 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m11)
predict p_sta3_1910 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2019m12)
predict p_sta3_1911 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m1)
predict p_sta3_1912 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m2)
predict p_sta3_2001 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m3)
predict p_sta3_2002 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m4)
predict p_sta3_2003 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)
predict p_sta3_2004 if e(sample)

* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final static probit model specification for h = 3 according to BIC. The referring column in the data set is poos_p_sta3.


* We perform the same exercise for the final dynamic probit model specification for h=3 according to BIC:
probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2018m6)
predict p_dyn3_1805 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2018m7)
predict p_dyn3_1806 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2018m8)
predict p_dyn3_1807 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2018m9)
predict p_dyn3_1808 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2018m10)
predict p_dyn3_1809 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2018m11)
predict p_dyn3_1810 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2018m12)
predict p_dyn3_1811 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m1)
predict p_dyn3_1812 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m2)
predict p_dyn3_1901 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m3)
predict p_dyn3_1902 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m4)
predict p_dyn3_1903 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m5)
predict p_dyn3_1904 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m6)
predict p_dyn3_1905 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m7)
predict p_dyn3_1906 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m8)
predict p_dyn3_1907 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m9)
predict p_dyn3_1908 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m10)
predict p_dyn3_1909 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m11)
predict p_dyn3_1910 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2019m12)
predict p_dyn3_1911 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m1)
predict p_dyn3_1912 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m2)
predict p_dyn3_2001 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m3)
predict p_dyn3_2002 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m4)
predict p_dyn3_2003 if e(sample)

probit recession L3.ifoindex_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.cdax_gr L11.cdax_gr L12.recession if time > tm(2000m1) & time < tm(2020m5)
predict p_dyn3_2004 if e(sample)

* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final dynamic probit model specification for h = 3 according to BIC. The referring column in the data set is poos_p_dyn3.




/* Based on the four consolidated columns, i.e. poos_p_sta1, poos_p_dyn1, poos_p_sta3 and poos_p_dyn3, we calculate three out-of-sample evaluation measures, namely the Mean Absolute Error (MAE), the Root Mean Squared Error (RMSE), and the Theil coefficient (Theil) for each of the four models. For the calculations please refer to the attached R code.*/


**************************** PLOT OUT-OF-SAMPLE ********************************

* We put the four different models according to BIC in one plot for the out-of-sample evaluation.
twoway ///
		(area recession time, color(gs14)) ///
	    (tsline poos_p_sta1, color(orange)) ///
		(tsline poos_p_dyn1, color(green)) ///
		(tsline poos_p_sta3, color(blue)) ///
		(tsline poos_p_dyn3, color(pink)) ///
		if time > tm(2018m4) & time < tm(2020m5), ///
		ytitle("Recession probability", size(medium)) ///
		yline(0.5) ///
		graphregion(fcolor(white)) ///
		xtitle("Time", size(medium)) ///
		ylabel(0(0.1)1, labsize(small)) ///
		xlabel(,labsize(small)) ///
		legend(size(small) label(1 "ECRI recession months") label(2 "Recession probability static (h=1)") label(3 "Recession probability dynamic (h=1)") label(4 "Recession probability static (h=3)") label(5 "Recession probability dynamic (h=3)"))
		
		
***************************** ROBUSTNESS CHECK *********************************

/* As a robustness check we extend the out-of-sample period from two years to 
three years, i.e. to May 2017 to April 2020. Again we manually consolidate the last values of each of these 
estimations. This gives the pseudo out-of-sample probabilities of each of the
four model specifications according to BIC. The referring columns in 
the data set are poos_sta1_rob, poos_dyn1_rob, poos_sta3_rob, and  
poos_p_dyn3_rob.*/
		
		
* We start with the final static probit model specification for h = 1 according to BIC:

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m6)
predict p_sta1_1705_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m7)
predict p_sta1_1706_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m8)
predict p_sta1_1707_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m9)
predict p_sta1_1708_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m10)
predict p_sta1_1709_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m11)
predict p_sta1_1710_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m12)
predict p_sta1_1711_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m1)
predict p_sta1_1712_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m2)
predict p_sta1_1801_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m3)
predict p_sta1_1802_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m4)
predict p_sta1_1803_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m5)
predict p_sta1_1804_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m6)
predict p_sta1_1805_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m7)
predict p_sta1_1806_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m8)
predict p_sta1_1807_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m9)
predict p_sta1_1808_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m10)
predict p_sta1_1809_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m11)
predict p_sta1_1810_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m12)
predict p_sta1_1811_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m1)
predict p_sta1_1812_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m2)
predict p_sta1_1901_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m3)
predict p_sta1_1902_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m4)
predict p_sta1_1903_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m5)
predict p_sta1_1904_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m6)
predict p_sta1_1905_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m7)
predict p_sta1_1906_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m8)
predict p_sta1_1907_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m9)
predict p_sta1_1908_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m10)
predict p_sta1_1909_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m11)
predict p_sta1_1910_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m12)
predict p_sta1_1911_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m1)
predict p_sta1_1912_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m2)
predict p_sta1_2001_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m3)
predict p_sta1_2002_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m4)
predict p_sta1_2003_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
predict p_sta1_2004_rob if e(sample)

* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final dynamic probit model specification for h = 3 according to BIC. The referring column in the data set is poos_p_sta1_rob.


* We perform the same exercise for the final dynamic probit model specification for h=1 according to BIC:

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2017m6)
predict p_dyn1_1705_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2017m7)
predict p_dyn1_1706_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2017m8)
predict p_dyn1_1707_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2017m9)
predict p_dyn1_1708_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2017m10)
predict p_dyn1_1709_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2017m11)
predict p_dyn1_1710_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2017m12)
predict p_dyn1_1711_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m1)
predict p_dyn1_1712_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m2)
predict p_dyn1_1801_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m3)
predict p_dyn1_1802_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m4)
predict p_dyn1_1803_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m5)
predict p_dyn1_1804_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m6)
predict p_dyn1_1805_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m7)
predict p_dyn1_1806_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m8)
predict p_dyn1_1807_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m9)
predict p_dyn1_1808_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m10)
predict p_dyn1_1809_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m11)
predict p_dyn1_1810_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2018m12)
predict p_dyn1_1811_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m1)
predict p_dyn1_1812_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m2)
predict p_dyn1_1901_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m3)
predict p_dyn1_1902_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m4)
predict p_dyn1_1903_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m5)
predict p_dyn1_1904_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m6)
predict p_dyn1_1905_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m7)
predict p_dyn1_1906_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m8)
predict p_dyn1_1907_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m9)
predict p_dyn1_1908_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m10)
predict p_dyn1_1909_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m11)
predict p_dyn1_1910_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2019m12)
predict p_dyn1_1911_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m1)
predict p_dyn1_1912_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m2)
predict p_dyn1_2001_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m3)
predict p_dyn1_2002_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m4)
predict p_dyn1_2003_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr L10.recession if time > tm(2000m1) & time < tm(2020m5)
predict p_dyn1_2004_rob if e(sample)
		
* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final dynamic probit model specification for h = 3 according to BIC. The referring column in the data set is poos_p_dyn1_rob.

		
* We start with the final static probit model specification for h = 3 according to BIC:

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m6)
predict p_sta3_1705_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m7)
predict p_sta3_1706_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m8)
predict p_sta3_1707_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m9)
predict p_sta3_1708_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m10)
predict p_sta3_1709_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m11)
predict p_sta3_1710_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2017m12)
predict p_sta3_1711_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m1)
predict p_sta3_1712_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m2)
predict p_sta3_1801_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m3)
predict p_sta3_1802_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m4)
predict p_sta3_1803_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m5)
predict p_sta3_1804_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m6)
predict p_sta3_1805_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m7)
predict p_sta3_1806_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m8)
predict p_sta3_1807_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m9)
predict p_sta3_1808_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m10)
predict p_sta3_1809_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m11)
predict p_sta3_1810_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2018m12)
predict p_sta3_1811_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m1)
predict p_sta3_1812_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m2)
predict p_sta3_1901_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m3)
predict p_sta3_1902_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m4)
predict p_sta3_1903_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m5)
predict p_sta3_1904_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m6)
predict p_sta3_1905_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m7)
predict p_sta3_1906_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m8)
predict p_sta3_1907_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m9)
predict p_sta3_1908_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m10)
predict p_sta3_1909_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m11)
predict p_sta3_1910_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2019m12)
predict p_sta3_1911_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m1)
predict p_sta3_1912_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m2)
predict p_sta3_2001_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m3)
predict p_sta3_2002_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m4)
predict p_sta3_2003_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time < tm(2020m5)
predict p_sta3_2004_rob if e(sample)


* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final dynamic probit model specification for h = 3 according to BIC. The referring column in the data set is poos_p_sta3_rob.	


* We start with the final dynamic probit model specification for h = 3 according to BIC:

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2017m6)
predict p_dyn3_1705_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2017m7)
predict p_dyn3_1706_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2017m8)
predict p_dyn3_1707_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2017m9)
predict p_dyn3_1708_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2017m10)
predict p_dyn3_1709_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2017m11)
predict p_dyn3_1710_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2017m12)
predict p_dyn3_1711_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m1)
predict p_dyn3_1712_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m2)
predict p_dyn3_1801_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m3)
predict p_dyn3_1802_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m4)
predict p_dyn3_1803_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m5)
predict p_dyn3_1804_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m6)
predict p_dyn3_1805_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m7)
predict p_dyn3_1806_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m8)
predict p_dyn3_1807_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m9)
predict p_dyn3_1808_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m10)
predict p_dyn3_1809_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m11)
predict p_dyn3_1810_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2018m12)
predict p_dyn3_1811_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m1)
predict p_dyn3_1812_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m2)
predict p_dyn3_1901_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m3)
predict p_dyn3_1902_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m4)
predict p_dyn3_1903_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m5)
predict p_dyn3_1904_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m6)
predict p_dyn3_1905_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m7)
predict p_dyn3_1906_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m8)
predict p_dyn3_1907_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m9)
predict p_dyn3_1908_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m10)
predict p_dyn3_1909_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m11)
predict p_dyn3_1910_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2019m12)
predict p_dyn3_1911_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2020m1)
predict p_dyn3_1912_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2020m2)
predict p_dyn3_2001_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2020m3)
predict p_dyn3_2002_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2020m4)
predict p_dyn3_2003_rob if e(sample)

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L3.ifoindex_gr L9.ifoindex_gr L12.recession if time > tm(2000m1) & time < tm(2020m5)
predict p_dyn3_2004_rob if e(sample)
	
		
* Manually consolidating the last values of each of these estimations gives the pseudo out-of-sample probabilities of the final dynamic probit model specification for h = 3 according to BIC. The referring column in the data set is poos_p_sta3_rob.	



/* We use poos_p_sta1_rob, poos_p_dyn1_rob, poos_p_sta3_rob, and poos_p_dyn3_rob
to calculate the MAE, RMSE and Theil values. Please refer to R code for the 
formulas and the results.
*/
		
		

********************************* NOWCAST *************************************

* Based on the in-sample and out-of-sample performance measures we pick the two best performing models for the nowcast. These are the static and the dynamic probit model with h=1.

* Since the last ECRI dated month is a trough in April 2020, the binary recession variable stops there. However, we are able to predict probabilities beyond April 2020 because we dispose of monthly data. This allows us to estimate recession probabilities up until February 2021.

probit recession L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L10.cdax_gr L11.cdax_gr L1.euribor_gr L1.ifoindex_gr L9.ifoindex_gr if time > tm(2000m1) & time  < tm(2020m5)

predict p_nowcast_sta1 if time > tm(2019m12) & time < tm(2021m3)


probit recession L1.ifoindex_gr L1.euribor_gr L5.cdax_gr L6.cdax_gr L7.cdax_gr L8.cdax_gr L9.ifoindex_gr L10.recession L11.cdax_gr if time > tm(2000m1) & time < tm(2020m5)

predict p_nowcast_dyn1 if time > tm(2019m12) & time < tm(2021m3)

* Plotting the results
twoway ///
		(area recession time, color(gs14)) ///
	    (tsline p_nowcast_sta1, color(orange)) ///
		(tsline p_nowcast_dyn1, color(green)) ///
		if time > tm(2019m12) & time < tm(2021m3), ///
		tline(2020m4, lcolor(black) lpattern(dash)) ///
		ytitle("Recession probability", size(medium)) ///
		yline(0.5) ///
		graphregion(fcolor(white)) ///
		xtitle("Time", size(medium)) ///
		ylabel(0(0.1)1, labsize(small)) ///
		xlabel(,labsize(small)) ///
		legend(size(small) label(1 "ECRI recession months") label(2 "Recession probability static (h=1)") label(3 "Recession probability dynamic (h=1)"))


********************************** END ****************************************

