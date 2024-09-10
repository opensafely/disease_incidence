program hegy, rclass
version 11
syntax varname(ts) [if] [in] [ , Gls MAXLag(integer -1) Det(string) LEVel(integer 10) /*
*/		Mode(string) RESiduals(string) NOReg NOAc]

  local generat = cond("`generate'" == "", "", "`generate'") 
     if "`generat'" != "" {
        capture confirm new variable `generat' 
        if _rc { 
                di in r "`generat' already exists: " _c  
                di in r "specify new variable with generate( ) option"
                exit 110 
				} 
        }
		
    marksample touse
   /* get time variables */
 _ts timevar, sort
 markout `touse' `timevar'
 tsreport if `touse', report
 if r(N_gaps) {
  di in red "sample may not contain gaps"
  exit
 }

 if "`residuals'" != "" {
        capture confirm new variable `residuals' 
        if _rc { 
                di in r "`residuals' already exists" 
                exit 110 
				} 
	}

 if "`mode'" != ""    & "`mode'" != "aic" & "`mode'" != "maic" & /*
*/	"`mode'" != "seq" & "`mode'" != "bic" & "`mode'" != "fix" {
	di in red "Error: mode must be fix, aic, maic, bic or seq"
	di in red "The default mode is maic"
	exit
	}
 qui tsset
 if r(unit1) != "m" & r(unit1) != "q" {
  di in red "hegy must be used with monthly or quarterly data"
  exit
  }
	
  if r(unit1) == "m" & `maxlag' < 0 {
	 local maxlag=floor(12*(_N/100)^0.25)
	}
  if r(unit1) == "q" & `maxlag' < 0 {
	 local maxlag=floor(4*(_N/100)^0.25)
	}

 if r(unit1) == "m" & "`gls'" == "" { /* Monthly with OLS */
// --- Generating Differences and Dummies --------
quietly {
tempvar y yd12 y1 y2 y1a y2a y3a y4a y5a y1b y2b y3b y4b y5b
tempvar trend seas q1 q2 q3 q4 q5 q6 q7 q8 q9 q10 q11 q12
tempvar ts1 ts2 ts3 ts4 ts5 ts6 ts7 ts8 ts9 ts10 ts11 ts12

gen `y' = `varlist' if `touse'

gen `yd12'=S12.`y'
gen `y1' =  L.`y'  + L2.`y' + L3.`y' + L4.`y' + L5.`y' + L6.`y' + /*
			 */ L7.`y' + L8.`y' + L9.`y' + L10.`y' + L11.`y' + L12.`y' 
gen `y2' = -L.`y' + L2.`y' - L3.`y' + L4.`y' - L5.`y' + L6.`y' - /*
			 */ L7.`y' + L8.`y' - L9.`y' + L10.`y' - L11.`y' + L12.`y' 
gen `y1a'=cos(_pi/6)*L.`y' 		+ cos(2*_pi/6)*L2.`y' + cos(3*_pi/6)*L3.`y' + cos(4*_pi/6)*L4.`y'+cos(5*_pi/6)*L5.`y' + /*
*/		cos(6*_pi/6)*L6.`y'   + cos(7*_pi/6)*L7.`y' + cos(8*_pi/6)*L8.`y' + cos(9*_pi/6)*L9.`y'+cos(10*_pi/6)*L10.`y' + /*
*/		cos(11*_pi/6)*L11.`y' + cos(12*_pi/6)*L12.`y'
gen `y2a'=cos(_pi/3)*L.`y' 		+ cos(2*_pi/3)*L2.`y' + cos(3*_pi/3)*L3.`y' + cos(4*_pi/3)*L4.`y'+cos(5*_pi/3)*L5.`y' + /*
*/		cos(6*_pi/3)*L6.`y'   + cos(7*_pi/3)*L7.`y' + cos(8*_pi/3)*L8.`y' + cos(9*_pi/3)*L9.`y'+cos(10*_pi/3)*L10.`y' + /*
*/		cos(11*_pi/3)*L11.`y' + cos(12*_pi/3)*L12.`y'
gen `y3a'=cos(_pi/2)*L.`y' 		+ cos(2*_pi/2)*L2.`y' + cos(3*_pi/2)*L3.`y' + cos(4*_pi/2)*L4.`y'+cos(5*_pi/2)*L5.`y' + /*
*/		cos(6*_pi/2)*L6.`y'   + cos(7*_pi/2)*L7.`y' + cos(8*_pi/2)*L8.`y' + cos(9*_pi/2)*L9.`y'+cos(10*_pi/2)*L10.`y' + /*
*/		cos(11*_pi/2)*L11.`y' + cos(12*_pi/2)*L12.`y'
gen `y4a'=cos(2*_pi/3)*L.`y' 	  + cos(2*2*_pi/3)*L2.`y' + cos(2*3*_pi/3)*L3.`y' + cos(2*4*_pi/3)*L4.`y'+cos(2*5*_pi/3)*L5.`y' + /*
*/		cos(2*6*_pi/3)*L6.`y'   + cos(2*7*_pi/3)*L7.`y' + cos(2*8*_pi/3)*L8.`y' + cos(2*9*_pi/3)*L9.`y'+cos(2*10*_pi/3)*L10.`y' + /*
*/		cos(2*11*_pi/3)*L11.`y' + cos(2*12*_pi/3)*L12.`y'
gen `y5a'=cos(5*_pi/6)*L.`y' 	  + cos(5*2*_pi/6)*L2.`y' + cos(5*3*_pi/6)*L3.`y' + cos(5*4*_pi/6)*L4.`y'+cos(5*5*_pi/6)*L5.`y' + /*
*/		cos(5*6*_pi/6)*L6.`y'   + cos(5*7*_pi/6)*L7.`y' + cos(5*8*_pi/6)*L8.`y' + cos(5*9*_pi/6)*L9.`y'+cos(5*10*_pi/6)*L10.`y' + /*
*/		cos(5*11*_pi/6)*L11.`y' + cos(5*12*_pi/6)*L12.`y'
gen `y1b'=-(sin(_pi/6)*L.`y' 	  + sin(2*_pi/6)*L2.`y' + sin(3*_pi/6)*L3.`y' + sin(4*_pi/6)*L4.`y'+sin(5*_pi/6)*L5.`y' + /*
*/		  sin(6*_pi/6)*L6.`y'   + sin(7*_pi/6)*L7.`y' + sin(8*_pi/6)*L8.`y' + sin(9*_pi/6)*L9.`y'+sin(10*_pi/6)*L10.`y' + /*
*/		  sin(11*_pi/6)*L11.`y' + sin(12*_pi/6)*L12.`y')
gen `y2b'=-(sin(_pi/3)*L.`y' 	  + sin(2*_pi/3)*L2.`y' + sin(3*_pi/3)*L3.`y' + sin(4*_pi/3)*L4.`y'+sin(5*_pi/3)*L5.`y' + /*
*/		  sin(6*_pi/3)*L6.`y'   + sin(7*_pi/3)*L7.`y' + sin(8*_pi/3)*L8.`y' + sin(9*_pi/3)*L9.`y'+sin(10*_pi/3)*L10.`y' + /*
*/		  sin(11*_pi/3)*L11.`y' + sin(12*_pi/3)*L12.`y')
gen `y3b'=-(sin(_pi/2)*L.`y' 	  + sin(2*_pi/2)*L2.`y' + sin(3*_pi/2)*L3.`y' + sin(4*_pi/2)*L4.`y'+sin(5*_pi/2)*L5.`y' + /*
*/		  sin(6*_pi/2)*L6.`y'   + sin(7*_pi/2)*L7.`y' + sin(8*_pi/2)*L8.`y' + sin(9*_pi/2)*L9.`y'+sin(10*_pi/2)*L10.`y' + /*
*/		  sin(11*_pi/2)*L11.`y' + sin(12*_pi/2)*L12.`y')
gen `y4b'=-(sin(2*_pi/3)*L.`y' 	    + sin(2*2*_pi/3)*L2.`y' + sin(2*3*_pi/3)*L3.`y' + sin(2*4*_pi/3)*L4.`y'+sin(2*5*_pi/3)*L5.`y' + /*
*/		  sin(2*6*_pi/3)*L6.`y'   + sin(2*7*_pi/3)*L7.`y' + sin(2*8*_pi/3)*L8.`y' + sin(2*9*_pi/3)*L9.`y'+sin(2*10*_pi/3)*L10.`y' + /*
*/		  sin(2*11*_pi/3)*L11.`y' + sin(2*12*_pi/3)*L12.`y')

gen `y5b'=-(sin(5*_pi/6)*L.`y'      + sin(5*2*_pi/6)*L2.`y' + sin(5*3*_pi/6)*L3.`y' + sin(5*4*_pi/6)*L4.`y'+sin(5*5*_pi/6)*L5.`y' + /*
*/		  sin(5*6*_pi/6)*L6.`y'   + sin(5*7*_pi/6)*L7.`y' + sin(5*8*_pi/6)*L8.`y' + sin(5*9*_pi/6)*L9.`y'+sin(5*10*_pi/6)*L10.`y' + /*
*/		  sin(5*11*_pi/6)*L11.`y' + sin(5*12*_pi/6)*L12.`y')
}

egen `trend'=fill(1 2)
egen `seas'=fill(1/12 1/12)
forv i=1 (1) 12 {
	gen  `q`i''=(`seas'==`i')
	gen `ts`i''=`q`i''*`trend'
	}

local aux "err"
 if "`det'"=="none" {
  local aux ", noc"
  local daux "None"
  local case 1
  } 
 if "`det'"=="const" {
  local aux " "
  local daux "Constant"
  local case 2
  }
 if "`det'"=="" | "`det'" =="seas" {
  local aux "`q1' `q2' `q3' `q4' `q5' `q6' `q7' `q8' `q9' `q10' `q11'" 
  local daux "Seasonal dummies"
  local case 3 
  }
 if "`det'"=="trend" { 
  local aux "`trend'" 
  local daux "Constant and trend"
  local case 4
  }
 if "`det'"=="strend" { 
  local aux " `q1' `q2' `q3' `q4' `q5' `q6' `q7' `q8' `q9' `q10' `q11' `trend' " 
  local daux "Seasonal dummies and linear trend"
  local case 5
  }
 if "`det'"=="mult" {
  local aux "`q1' `q2' `q3' `q4' `q5' `q6' `q7' `q8' `q9' `q10' `q11' `ts1' `ts2' `ts3' `ts4' `ts5' `ts6' `ts7' `ts8' `ts9' `ts10' `ts11' `ts12'"
  local daux "Seasonal dummies and seasonal trends"
  local case 6
  }
 if "`aux'"=="err" {
  di in red "Error: det must be none, const, seas, trend, strend or mult"
  exit
  }

// --- Detecting optimal lag ----------------------
 local augment ""
 local lag = 0
if `maxlag' > 0 {
 if "`mode'"=="fix" {
 local lag = `maxlag'
 local augment = "L(1/`lag').`yd12'"
 local method = "The lag is fixed by user"
 }
 // --- t-test for the last lag -------------------
 if "`mode'"=="seq" {
	local method = "Sequential at `level'% level"
	forv i = `maxlag' (-1) 1 {
		qui regress `yd12' `y1' `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b' L(1/`i').`yd12' `aux'
		qui test L`i'.`yd12'
		if `r(p)' < `level'*0.01 {
			local lag = `i'
			continue,break
			}
		}
	if `lag'>0   local augment = "L(1/`lag').`yd12'"
 }
 // --- Akaike Information Criteria ---
 if "`mode'" =="aic" {
 local method = "Akaike Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `yd12' `y1' `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b' L(1/`i').`yd12' `aux'
	else     qui regress `yd12' `y1' `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b' `aux'
	qui estimates stats
	matrix mm`i' = r(S)
	local aic`i' = mm`i'[1,5]
	}
 local min = `aic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `aic`i'' < `min' {
		local min = `aic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`yd12'"
 }
 // --- Bayesian Information Criteria ---
 if "`mode'" =="bic" {
 local method = "Bayesian Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `yd12' `y1' `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b' L(1/`i').`yd12' `aux'
	else     qui regress `yd12' `y1' `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b' `aux'
	qui estimates stats
	matrix mm`i' = r(S)
	local bic`i' = mm`i'[1,6]
	}
 local min = `bic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `bic`i'' < `min' {
		local min = `bic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`yd12'"
 }
 // --- Modified AIC ------------------
if "`mode'"=="" | "`mode'" =="maic" {
 local method = "Modified AIC"
 tempvar x xf
 qui gen `x' = `varlist' if `touse'
 qui regress `x'  `aux'
 qui predict `xf' if e(sample)
 
 tempvar z zd12 z1 z2 z1a z2a z3a z4a z5a z1b z2b z3b z4b z5b
 qui {
gen `z' = `x' - `xf'
gen `zd12'=S12.`z'
gen `z1' =  L.`z'  + L2.`z' + L3.`z' + L4.`z' + L5.`z' + L6.`z' + /*
			 */ L7.`z' + L8.`z' + L9.`z' + L10.`z' + L11.`z' + L12.`z' 
gen `z2' = -L.`z' + L2.`z' - L3.`z' + L4.`z' - L5.`z' + L6.`z' - /*
			 */ L7.`z' + L8.`z' - L9.`z' + L10.`z' - L11.`z' + L12.`z' 
gen `z1a'=cos(_pi/6)*L.`z' 		+ cos(2*_pi/6)*L2.`z' + cos(3*_pi/6)*L3.`z' + cos(4*_pi/6)*L4.`z'+cos(5*_pi/6)*L5.`z' + /*
*/		cos(6*_pi/6)*L6.`z'   + cos(7*_pi/6)*L7.`z' + cos(8*_pi/6)*L8.`z' + cos(9*_pi/6)*L9.`z'+cos(10*_pi/6)*L10.`z' + /*
*/		cos(11*_pi/6)*L11.`z' + cos(12*_pi/6)*L12.`z'
gen `z2a'=cos(_pi/3)*L.`z' 		+ cos(2*_pi/3)*L2.`z' + cos(3*_pi/3)*L3.`z' + cos(4*_pi/3)*L4.`z'+cos(5*_pi/3)*L5.`z' + /*
*/		cos(6*_pi/3)*L6.`z'   + cos(7*_pi/3)*L7.`z' + cos(8*_pi/3)*L8.`z' + cos(9*_pi/3)*L9.`z'+cos(10*_pi/3)*L10.`z' + /*
*/		cos(11*_pi/3)*L11.`z' + cos(12*_pi/3)*L12.`z'
gen `z3a'=cos(_pi/2)*L.`z' 		+ cos(2*_pi/2)*L2.`z' + cos(3*_pi/2)*L3.`z' + cos(4*_pi/2)*L4.`z'+cos(5*_pi/2)*L5.`z' + /*
*/		cos(6*_pi/2)*L6.`z'   + cos(7*_pi/2)*L7.`z' + cos(8*_pi/2)*L8.`z' + cos(9*_pi/2)*L9.`z'+cos(10*_pi/2)*L10.`z' + /*
*/		cos(11*_pi/2)*L11.`z' + cos(12*_pi/2)*L12.`z'
gen `z4a'=cos(2*_pi/3)*L.`z' 	  + cos(2*2*_pi/3)*L2.`z' + cos(2*3*_pi/3)*L3.`z' + cos(2*4*_pi/3)*L4.`z'+cos(2*5*_pi/3)*L5.`z' + /*
*/		cos(2*6*_pi/3)*L6.`z'   + cos(2*7*_pi/3)*L7.`z' + cos(2*8*_pi/3)*L8.`z' + cos(2*9*_pi/3)*L9.`z'+cos(2*10*_pi/3)*L10.`z' + /*
*/		cos(2*11*_pi/3)*L11.`z' + cos(2*12*_pi/3)*L12.`z'
gen `z5a'=cos(5*_pi/6)*L.`z' 	  + cos(5*2*_pi/6)*L2.`z' + cos(5*3*_pi/6)*L3.`z' + cos(5*4*_pi/6)*L4.`z'+cos(5*5*_pi/6)*L5.`z' + /*
*/		cos(5*6*_pi/6)*L6.`z'   + cos(5*7*_pi/6)*L7.`z' + cos(5*8*_pi/6)*L8.`z' + cos(5*9*_pi/6)*L9.`z'+cos(5*10*_pi/6)*L10.`z' + /*
*/		cos(5*11*_pi/6)*L11.`z' + cos(5*12*_pi/6)*L12.`z'
gen `z1b'=-(sin(_pi/6)*L.`z' 	  + sin(2*_pi/6)*L2.`z' + sin(3*_pi/6)*L3.`z' + sin(4*_pi/6)*L4.`z'+sin(5*_pi/6)*L5.`z' + /*
*/		  sin(6*_pi/6)*L6.`z'   + sin(7*_pi/6)*L7.`z' + sin(8*_pi/6)*L8.`z' + sin(9*_pi/6)*L9.`z'+sin(10*_pi/6)*L10.`z' + /*
*/		  sin(11*_pi/6)*L11.`z' + sin(12*_pi/6)*L12.`z')
gen `z2b'=-(sin(_pi/3)*L.`z' 	  + sin(2*_pi/3)*L2.`z' + sin(3*_pi/3)*L3.`z' + sin(4*_pi/3)*L4.`z'+sin(5*_pi/3)*L5.`z' + /*
*/		  sin(6*_pi/3)*L6.`z'   + sin(7*_pi/3)*L7.`z' + sin(8*_pi/3)*L8.`z' + sin(9*_pi/3)*L9.`z'+sin(10*_pi/3)*L10.`z' + /*
*/		  sin(11*_pi/3)*L11.`z' + sin(12*_pi/3)*L12.`z')
gen `z3b'=-(sin(_pi/2)*L.`z' 	  + sin(2*_pi/2)*L2.`z' + sin(3*_pi/2)*L3.`z' + sin(4*_pi/2)*L4.`z'+sin(5*_pi/2)*L5.`z' + /*
*/		  sin(6*_pi/2)*L6.`z'   + sin(7*_pi/2)*L7.`z' + sin(8*_pi/2)*L8.`z' + sin(9*_pi/2)*L9.`z'+sin(10*_pi/2)*L10.`z' + /*
*/		  sin(11*_pi/2)*L11.`z' + sin(12*_pi/2)*L12.`z')
gen `z4b'=-(sin(2*_pi/3)*L.`z' 	    + sin(2*2*_pi/3)*L2.`z' + sin(2*3*_pi/3)*L3.`z' + sin(2*4*_pi/3)*L4.`z'+sin(2*5*_pi/3)*L5.`z' + /*
*/		  sin(2*6*_pi/3)*L6.`z'   + sin(2*7*_pi/3)*L7.`z' + sin(2*8*_pi/3)*L8.`z' + sin(2*9*_pi/3)*L9.`z'+sin(2*10*_pi/3)*L10.`z' + /*
*/		  sin(2*11*_pi/3)*L11.`z' + sin(2*12*_pi/3)*L12.`z')
gen `z5b'=-(sin(5*_pi/6)*L.`z'      + sin(5*2*_pi/6)*L2.`z' + sin(5*3*_pi/6)*L3.`z' + sin(5*4*_pi/6)*L4.`z'+sin(5*5*_pi/6)*L5.`z' + /*
*/		  sin(5*6*_pi/6)*L6.`z'   + sin(5*7*_pi/6)*L7.`z' + sin(5*8*_pi/6)*L8.`z' + sin(5*9*_pi/6)*L9.`z'+sin(5*10*_pi/6)*L10.`z' + /*
*/		  sin(5*11*_pi/6)*L11.`z' + sin(5*12*_pi/6)*L12.`z')
}
 
 tempvar s1 s2 sa1 sa2 sa3 sa4 sa5 sb1 sb2 sb3 sb4 sb5
 forv i=1 (1) 5 {
	if `i'<=2 {
		qui gen `s`i'' = sum(`z`i''^2)
		local ss`i' = `s`i''[_N] - `s`i''[12+`maxlag']
		}
	qui gen `sa`i'' = sum(`z`i'a'^2)
	qui gen `sb`i'' = sum(`z`i'b'^2)
	local ssa`i' = `sa`i''[_N] - `sa`i''[12+`maxlag']
	local ssb`i' = `sb`i''[_N] - `sb`i''[12+`maxlag']
	}
	
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b' L(1/`i').`zd12', noconstant
	else     qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b', noconstant
	mat   b    = e(b)
	local denom = e(N) - `maxlag'
	local sig2 = e(rss) / `denom' 
	local tau  = (b[1,1]^2) * `ss1' + (b[1,2]^2) * `ss2' + (b[1,3]^2) * `sa1' + (b[1,4]^2) * `sb1' + /*
*/				 (b[1,5]^2) * `sa2' + (b[1,6]^2) * `sb2' + (b[1,7]^2) * `sa3' + (b[1,8]^2) * `sb3' + /*
*/				 (b[1,9]^2) * `sa4' + (b[1,10]^2)* `sb4' + (b[1,11]^2)* `sa5' + (b[1,12]^2)* `sb5'
	local tau = `tau' / `sig2'
	local maic`i' = ln(`sig2') + 2*(`tau' + `i'+12) / `denom'
	}
 local min = `maic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `maic`i'' < `min' {
		local min = `maic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`yd12'"
 }
}
tempvar res1
// --- Starting Regressions ----------
qui regress `yd12' `y1' `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b' `augment' `aux'
	if "`residuals'" != "" {
			qui predict `residuals', resid
			label var `residuals' "Residuals from Seasonal Unit Root test"
		}
	
	if "`noac'" == "" {
		qui predict `res1', resid
		}
	
	local df=e(df_r)	
	matrix b = get(_b)
	matrix dia = vecdiag(e(V))
	local n =e(N) 

return scalar N = `n'

// --- Generating F-test and t-test results -----
return scalar t1=b[1,1]/sqrt(dia[1,1])
return scalar t2=b[1,2]/sqrt(dia[1,2])

qui test `y1a' `y1b'
return scalar F1 = `r(F)'

qui test `y2a' `y2b'
return scalar F2 = `r(F)'

qui test `y3a' `y3b'
return scalar F3 = `r(F)'

qui test `y4a' `y4b'
return scalar F4 = `r(F)'

qui test `y5a' `y5b'
return scalar F5 = `r(F)'

qui test      `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b'
return scalar F25 = `r(F)'

qui test `y1' `y2' `y1a' `y1b' `y2a' `y2b' `y3a' `y3b' `y4a' `y4b' `y5a' `y5b'
return scalar F15 = `r(F)'


 GetCV `case' `n' 0 12
 matrix cv= r(ck)

// --- Displaying Results -----------------------
di in gr " "
 di in gr "HEGY Monthly seasonal unit root test for " in ye  "`varlist'"
 di in gr " "
 di in gr "Number of observations  :  `n' "  
 di in gr "Deterministic variables : `daux'"
 if `maxlag'>0 di in gr "Optimal lag selection method: `method'"
 di in gr "Lags tested: `maxlag'"
 di in gr "Augmented by lags : `lag'"
 di in gr " "
 di in gr _col(16) "Stat" _col(24) "1% critical" _col(37) "5% critical" _col(50) "10% critical" 
 di in gr _dup(78) "-"
 di in ye /* 
 */ "t[0]"        _col(12) %9.3f `return(t1)' _col(23)   %9.3f cv[1,1]   _col(36) %9.3f cv[1,2]   _col(49) %9.3f cv[1,3]
 di "t[Pi]"       _col(12) %9.3f `return(t2)' _col(23)   %9.3f cv[1,4]   _col(36) %9.3f cv[1,5]   _col(49) %9.3f cv[1,6] 
 di " "
 di "F[Pi/6]"     _col(12) %9.3f `return(F1)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[Pi/3]"     _col(12) %9.3f `return(F2)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[Pi/2]"     _col(12) %9.3f `return(F3)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[2*Pi/3]"   _col(12) %9.3f `return(F4)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[5*Pi/6]"   _col(12) %9.3f `return(F5)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[All seas]" _col(12) %9.3f `return(F25)' _col(23)  %9.3f cv[1,10]  _col(36) %9.3f cv[1,11]  _col(49) %9.3f cv[1,12]
 di "F[All]"      _col(12) %9.3f `return(F15)' _col(23)  %9.3f cv[1,13]  _col(36) %9.3f cv[1,14]  _col(49) %9.3f cv[1,15]
 
 if "`noreg'" == "" {
	local gls1 = 0
	di ""
	di in gr "Testing regression:"
	DiReg12 `gls1' `case' `lag' `b' `dia'
	}

 if "`noac'" == "" {
	 di ""
	 di in gr "Correlogram  of residuals:"
	 corrgram `res1', lags(`maxlag')
	 }
 exit
}

 if r(unit1) == "m" & "`gls'" != "" { /* Monthly with GLS */
// --- Generating Dummies --------
quietly {
tempvar trend seas q1 q2 q3 q4 q5 q6 q7 q8 q9 q10 q11 q12 
tempvar qq1 qq2 qq3 qq4 qq5 qq6 qq7 qq8 qq9 qq10 qq11 qq12
tempvar ts1 ts2 ts3 ts4 ts5 ts6 ts7 ts8 ts9 ts10 ts11 ts12
egen `trend'=fill(1 2)
egen `seas'=fill(1/12 1/12)
forv i=1 (1) 12 {
	gen `qq`i''=(`seas'==`i')
	}

gen `q1'=1
gen `q2'= cos(`trend'*_pi/6)
gen `q3'= sin(`trend'*_pi/6)
gen `q4'= cos(`trend'*_pi/3)
gen `q5'= sin(`trend'*_pi/3)
gen `q6'= cos(`trend'*_pi/2)
gen `q7'= sin(`trend'*_pi/2)
gen `q8'= cos(`trend'*2*_pi/3)
gen `q9'= sin(`trend'*2*_pi/3)
gen `q10'=cos(`trend'*5*_pi/6)
gen `q11'=sin(`trend'*5*_pi/6)
gen `q12'=cos(`trend'*_pi)

gen `ts1'= `trend'
gen `ts2'= `trend'*`q2'
gen `ts3'= `trend'*`q3'
gen `ts4'= `trend'*`q4'
gen `ts5'= `trend'*`q5'
gen `ts6'= `trend'*`q6'
gen `ts7'= `trend'*`q7'
gen `ts8'= `trend'*`q8'
gen `ts9'= `trend'*`q9'
gen `ts10'=`trend'*`q10'
gen `ts11'=`trend'*`q11'
gen `ts12'=`trend'*`q12'
}
// -------- Mode Selection ---------------------
local aux "err"
 if "`det'"=="const" {
  local aux " "
  local daux "Constant"
  local case 2
  }
 if "`det'"=="" | "`det'" =="seas" {
  local aux "`q1' `q2' `q3' `q4' `q5' `q6' `q7' `q8' `q9' `q10' `q11'" 
  local daux "Seasonal dummies"
  local case 3 
  }
 if "`det'"=="trend" { 
  local aux "`trend'" 
  local daux "Constant and trend"
  local case 4
  }
 if "`det'"=="strend" { 
  local aux " `q1' `q2' `q3' `q4' `q5' `q6' `q7' `q8' `q9' `q10' `q11' `trend' " 
  local daux "Seasonal dummies and linear trend"
  local case 5
  }
 if "`det'"=="mult" {
  local aux "`q1' `q2' `q3' `q4' `q5' `q6' `q7' `q8' `q9' `q10' `q11' `ts1' `ts2' `ts3' `ts4' `ts5' `ts6' `ts7' `ts8' `ts9' `ts10' `ts11' `ts12'"
  local daux "Seasonal dummies and seasonal trends"
  local case 6
  }
 if "`aux'"=="err" {
  di in red "Error: det can't be none"
  exit
  }

// --- Generating Differences --------  
tempvar x xf
qui gen `x' = `varlist'  if `touse'
qui summarize `x'
local tt= r(N)

if `case' == 2 {
	local c1=0
	local c2=0
	local c3=0
	local c4=0
	local c5=0
	local c5=0
	local c6=0
	local c0=-7
	}
if `case' == 3 {
	local c1=-3.75
	local c2=-3.75
	local c3=-3.75
	local c4=-3.75
	local c5=-3.75
	local c5=-3.75
	local c6=-7
	local c0=-7
	}
if `case' == 4 {
	local c1=0
	local c2=0
	local c3=0
	local c4=0
	local c5=0
	local c5=0
	local c6=0
	local c0=-13.5
	}
if `case' == 5 {
	local c1=-3.75
	local c2=-3.75
	local c3=-3.75
	local c4=-3.75
	local c5=-3.75
	local c5=-3.75
	local c6=-7
	local c0=-13.5
	}
if `case' == 6 {
	local c1=-8.65
	local c2=-8.65
	local c3=-8.65
	local c4=-8.65
	local c5=-8.65
	local c5=-8.65
	local c6=-13.5
	local c0=-13.5
	}
local a_0=1+`c0'/`tt'
local a_1=1+`c1'/`tt'
local a_2=1+`c2'/`tt'
local a_3=1+`c3'/`tt'
local a_4=1+`c4'/`tt'
local a_5=1+`c5'/`tt'
local a_6=1+`c6'/`tt'

local m0=-`a_0'
local m1=-2*`a_1'*cos(_pi/6)   
local m2=-2*`a_2'*cos(_pi/3)   
local m3=-2*`a_3'*cos(_pi/2)
local m4=-2*`a_4'*cos(2*_pi/3)
local m5=-2*`a_5'*cos(5*_pi/6)
local m6=`a_6'

local n1=`a_1'^2
local n2=`a_2'^2
local n3=`a_3'^2
local n4=`a_4'^2
local n5=`a_5'^2

local fac_1=(`m1'+`m2'+`m3'+`m4'+`m5')
local fac_2=((`n1'+`n2'+`n3'+`m1'*`m2'+`m3'*(`m1'+`m2'))+(`m4'+`m5')*(`m1'+`m2'+`m3')+(`n4'+`n5'+`m4'*`m5'))
local fac_3=((`m3'*(`n1'+`n2'+`m1'*`m2')+`n3'*(`m1'+`m2')+(`m1'*`n2'+`n1'*`m2'))+ /*
*/			(`m4'+`m5')*(`n1'+`n2'+`n3'+`m1'*`m2'+`m3'*(`m1'+`m2'))+(`n4'+`n5'+`m4'*`m5')*(`m1'+`m2'+`m3')+ /*
*/			(`m4'*`n5'+`n4'*`m5'))
local fac_4=((`m3'*(`m1'*`n2'+`n1'*`m2')+`n3'*(`n1'+`n2'+`m1'*`m2')+`n1'*`n2')+(`m4'+`m5')*(`m3'*(`n1'+`n2'+`m1'*`m2')+ /*
*/			`n3'*(`m1'+`m2')+(`m1'*`n2'+`n1'*`m2'))+(`n4'+`n5'+`m4'*`m5')*(`n1'+`n2'+`n3'+`m1'*`m2'+`m3'*(`m1'+`m2'))+ /*
*/			(`m4'*`n5'+`n4'*`m5')*(`m1'+`m2'+`m3')+`n4'*`n5')
local fac_5=((`m3'*`n1'*`n2'+`n3'*(`m1'*`n2'+`n1'*`m2'))+(`m4'+`m5')*(`m3'*(`m1'*`n2'+`n1'*`m2')+ /*
*/			`n3'*(`n1'+`n2'+`m1'*`m2')+`n1'*`n2')+(`n4'+`n5'+`m4'*`m5')*(`m3'*(`n1'+`n2'+`m1'*`m2')+`n3'*(`m1'+`m2')+ /*
*/			(`m1'*`n2'+`n1'*`m2'))+(`m4'*`n5'+`n4'*`m5')*(`n1'+`n2'+`n3'+`m1'*`m2'+`m3'*(`m1'+`m2'))+(`m1'+`m2'+`m3')*`n4'*`n5')
local fac_6=(`n1'*`n2'*`n3'+(`m4'+`m5')*(`m3'*`n1'*`n2'+`n3'*(`m1'*`n2'+`n1'*`m2'))+(`n4'+`n5'+`m4'*`m5')* /*
*/			(`m3'*(`m1'*`n2'+`n1'*`m2')+`n3'*(`n1'+`n2'+`m1'*`m2')+`n1'*`n2')+(`m4'*`n5'+`n4'*`m5')*(`m3'*(`n1'+`n2'+`m1'*`m2')+ /*
*/			`n3'*(`m1'+`m2')+(`m1'*`n2'+`n1'*`m2'))+`n4'*`n5'*(`n1'+`n2'+`n3'+`m1'*`m2'+`m3'*(`m1'+`m2')))
local fac_7=((`m4'+`m5')*`n1'*`n2'*`n3'+(`n4'+`n5'+`m4'*`m5')*(`m3'*`n1'*`n2'+`n3'*(`m1'*`n2'+`n1'*`m2'))+ /*
*/			(`m4'*`n5'+`n4'*`m5')*(`m3'*(`m1'*`n2'+`n1'*`m2')+`n3'*(`n1'+`n2'+`m1'*`m2')+`n1'*`n2')+ /*
*/			`n4'*`n5'*(`m3'*(`n1'+`n2'+`m1'*`m2')+`n3'*(`m1'+`m2')+(`m1'*`n2'+`n1'*`m2')))
local fac_8=((`n4'+`n5'+`m4'*`m5')*`n1'*`n2'*`n3'+(`m4'*`n5'+`n4'*`m5')*(`m3'*`n1'*`n2'+`n3'*(`m1'*`n2'+`n1'*`m2'))+ /*
*/			`n4'*`n5'*(`m3'*(`m1'*`n2'+`n1'*`m2')+`n3'*(`n1'+`n2'+`m1'*`m2')+`n1'*`n2'))
local fac_9=(`n1'*`n2'*`n3'*(`m4'*`n5'+`n4'*`m5')+`n4'*`n5'*(`m3'*`n1'*`n2'+`n3'*(`m1'*`n2'+`n1'*`m2')))
local fac_10=(`n1'*`n2'*`n3'*`n4'*`n5')

local a1=(`a_0'-`a_6')-`fac_1'
local a2=(-`fac_2'+(`a_0'-`a_6')*`fac_1'+`a_0'*`a_6')
local a3=(-`fac_3'+(`a_0'-`a_6')*`fac_2'+`a_0'*`a_6'*`fac_1')
local a4=(-`fac_4'+(`a_0'-`a_6')*`fac_3'+`a_0'*`a_6'*`fac_2')
local a5=(-`fac_5'+(`a_0'-`a_6')*`fac_4'+`a_0'*`a_6'*`fac_3')
local a6=(-`fac_6'+(`a_0'-`a_6')*`fac_5'+`a_0'*`a_6'*`fac_4')
local a7=(-`fac_7'+(`a_0'-`a_6')*`fac_6'+`a_0'*`a_6'*`fac_5')
local a8=(-`fac_8'+(`a_0'-`a_6')*`fac_7'+`a_0'*`a_6'*`fac_6')
local a9=(-`fac_9'+(`a_0'-`a_6')*`fac_8'+`a_0'*`a_6'*`fac_7')
local a10=(-`fac_10'+(`a_0'-`a_6')*`fac_9'+`a_0'*`a_6'*`fac_8')
local a11=((`a_0'-`a_6')*`fac_10'+`a_0'*`a_6'*`fac_9')
local a12=(`a_0'*`a_6'*`fac_10')


tempvar xc sd1 sd2 sd3 sd4 sd5 sd6 sd7 sd8 sd9 sd10 sd11 sd12 
tempvar st1 st2 st3 st4 st5 st6 st7 st8 st9 st10 st11 st12 tr
qui { 
gen `xc'=0
gen `tr'=0

forv i=1 (1) 12 {
	gen `sd`i''=0
	gen `st`i''=0
	}

replace `xc' = `x' if _n==1
replace `tr' = `trend' if _n==1
forv j=1 (1) 12 {
	replace `sd`j'' = `q`j'' if _n==1
	replace `st`j'' = `ts`j'' if _n==1
	}

forv i=1 (1) 11 {
	replace `xc'=`x' if _n==(`i'+1)
	replace `tr'=`trend' if _n==(`i'+1)
	forv k=1 (1) `i' {
		replace `xc'=`xc'-`a`k''*L`k'.`x' if _n==(`i'+1)
		replace `tr'=`tr'-`a`k''*L`k'.`trend' if _n==(`i'+1)
		}
	forv j=1 (1) 12 {
		replace `sd`j'' = `q`j'' if _n==(`i'+1)
		replace `st`j'' = `ts`j'' if _n==(`i'+1)
		forv k=1 (1) `i' {	
			replace `sd`j'' = `sd`j'' - `a`k'' * L`k'.`q`j'' if _n==(`i'+1)
			replace `st`j'' = `st`j'' - `a`k'' * L`k'.`ts`j'' if _n==(`i'+1)
			}
		}
	}

	replace `xc'=`x' if _n>12
	replace `tr'=`trend' if _n>12
	forv k=1 (1) 12 {
		replace `xc'=`xc'-`a`k''*L`k'.`x' if _n>12
		replace `tr'=`tr'-`a`k''*L`k'.`trend' if _n>12
		}
	forv j=1 (1) 12 {
		replace `sd`j'' = `q`j'' if _n>12
		replace `st`j'' = `ts`j'' if _n>12
		forv k=1 (1) 12 {	
			replace `sd`j'' = `sd`j'' - `a`k'' * L`k'.`q`j'' if _n>12
			replace `st`j'' = `st`j'' - `a`k'' * L`k'.`ts`j'' if _n>12
			}
		}
}
// ------------ GLS detrending ----------------------------------------
qui {
if `case' == 2 {
	regress `xc' `sd1', noconstant
	matrix b0 = get(_b)
	gen `xf' =  b0[1,1]*`q1'
	}
if `case' == 3 {
	regress `xc' `sd1' `sd2' `sd3' `sd4' `sd5' `sd6' `sd7' `sd8' `sd9' `sd10' `sd11' `sd12', noconstant
	matrix b0 = get(_b)
	gen `xf' =  0
	forv i=1 (1) 12 {		
		replace `xf'=`xf' + b0[1,`i']*`q`i''
		}
	}
if `case' == 4 {
	regress `xc' `sd1' `tr', noconstant
	matrix b0 = get(_b)
	gen `xf' =  b0[1,1]*`q1' + b0[1,2]*`trend'
	}
if `case' == 5 {
	regress `xc' `sd1' `sd2' `sd3' `sd4' `sd5' `sd6' `sd7' `sd8' `sd9' `sd10' `sd11' `sd12' `tr', noconstant
	matrix b0 = get(_b)
	gen `xf' =  b0[1,13]*`trend'
	forv i=1 (1) 12 {
		replace `xf'=`xf' + b0[1,`i']*`q`i''
		}
	}
if `case' == 6 {
	regress `xc' `sd1' `sd2' `sd3' `sd4' `sd5' `sd6' `sd7' `sd8' `sd9' `sd10' `sd11' `sd12' `st1' `st2' `st3' `st4' `st5' `st6' `st7' `st8' `st9' `st10' `st11' `st12', noconstant
	matrix b0 = get(_b)
	gen `xf' =  0
	forv i=1 (1) 12 {
		replace `xf'=`xf' + b0[1,`i']*`q`i'' + b0[1,`i'+12]*`ts`i''
		}
	}
}

tempvar z zd12 z1 z2 z1a z2a z3a z4a z5a z1b z2b z3b z4b z5b
qui {
gen `z' = `x'-`xf'
gen `zd12'=S12.`z'
gen `z1' =  L.`z'  + L2.`z' + L3.`z' + L4.`z'  + L5.`z'  + L6.`z' + /*
*/ 			L7.`z' + L8.`z' + L9.`z' + L10.`z' + L11.`z' + L12.`z' 
gen `z2' = -L.`z'  + L2.`z' - L3.`z' + L4.`z'  - L5.`z'  + L6.`z' - /*
*/ 			L7.`z' + L8.`z' - L9.`z' + L10.`z' - L11.`z' + L12.`z' 
gen `z1a'=cos(_pi/6)*L.`z' 	  + cos(2*_pi/6)*L2.`z' + cos(3*_pi/6)*L3.`z' + cos(4*_pi/6)*L4.`z'+cos(5*_pi/6)*L5.`z' + /*
*/		cos(6*_pi/6)*L6.`z'   + cos(7*_pi/6)*L7.`z' + cos(8*_pi/6)*L8.`z' + cos(9*_pi/6)*L9.`z'+cos(10*_pi/6)*L10.`z' + /*
*/		cos(11*_pi/6)*L11.`z' + cos(12*_pi/6)*L12.`z'
gen `z2a'=cos(_pi/3)*L.`z' 	  + cos(2*_pi/3)*L2.`z' + cos(3*_pi/3)*L3.`z' + cos(4*_pi/3)*L4.`z'+cos(5*_pi/3)*L5.`z' + /*
*/		cos(6*_pi/3)*L6.`z'   + cos(7*_pi/3)*L7.`z' + cos(8*_pi/3)*L8.`z' + cos(9*_pi/3)*L9.`z'+cos(10*_pi/3)*L10.`z' + /*
*/		cos(11*_pi/3)*L11.`z' + cos(12*_pi/3)*L12.`z'
gen `z3a'=cos(_pi/2)*L.`z' 	  + cos(2*_pi/2)*L2.`z' + cos(3*_pi/2)*L3.`z' + cos(4*_pi/2)*L4.`z'+cos(5*_pi/2)*L5.`z' + /*
*/		cos(6*_pi/2)*L6.`z'   + cos(7*_pi/2)*L7.`z' + cos(8*_pi/2)*L8.`z' + cos(9*_pi/2)*L9.`z'+cos(10*_pi/2)*L10.`z' + /*
*/		cos(11*_pi/2)*L11.`z' + cos(12*_pi/2)*L12.`z'
gen `z4a'=cos(2*_pi/3)*L.`z'    + cos(2*2*_pi/3)*L2.`z' + cos(2*3*_pi/3)*L3.`z' + cos(2*4*_pi/3)*L4.`z'+cos(2*5*_pi/3)*L5.`z' + /*
*/		cos(2*6*_pi/3)*L6.`z'   + cos(2*7*_pi/3)*L7.`z' + cos(2*8*_pi/3)*L8.`z' + cos(2*9*_pi/3)*L9.`z'+cos(2*10*_pi/3)*L10.`z' + /*
*/		cos(2*11*_pi/3)*L11.`z' + cos(2*12*_pi/3)*L12.`z'
gen `z5a'=cos(5*_pi/6)*L.`z' 	+ cos(5*2*_pi/6)*L2.`z' + cos(5*3*_pi/6)*L3.`z' + cos(5*4*_pi/6)*L4.`z'+cos(5*5*_pi/6)*L5.`z' + /*
*/		cos(5*6*_pi/6)*L6.`z'   + cos(5*7*_pi/6)*L7.`z' + cos(5*8*_pi/6)*L8.`z' + cos(5*9*_pi/6)*L9.`z'+cos(5*10*_pi/6)*L10.`z' + /*
*/		cos(5*11*_pi/6)*L11.`z' + cos(5*12*_pi/6)*L12.`z'
gen `z1b'=-(sin(_pi/6)*L.`z' 	+ sin(2*_pi/6)*L2.`z' + sin(3*_pi/6)*L3.`z' + sin(4*_pi/6)*L4.`z'+sin(5*_pi/6)*L5.`z' + /*
*/		  sin(6*_pi/6)*L6.`z'   + sin(7*_pi/6)*L7.`z' + sin(8*_pi/6)*L8.`z' + sin(9*_pi/6)*L9.`z'+sin(10*_pi/6)*L10.`z' + /*
*/		  sin(11*_pi/6)*L11.`z' + sin(12*_pi/6)*L12.`z')
gen `z2b'=-(sin(_pi/3)*L.`z' 	+ sin(2*_pi/3)*L2.`z' + sin(3*_pi/3)*L3.`z' + sin(4*_pi/3)*L4.`z'+sin(5*_pi/3)*L5.`z' + /*
*/		  sin(6*_pi/3)*L6.`z'   + sin(7*_pi/3)*L7.`z' + sin(8*_pi/3)*L8.`z' + sin(9*_pi/3)*L9.`z'+sin(10*_pi/3)*L10.`z' + /*
*/		  sin(11*_pi/3)*L11.`z' + sin(12*_pi/3)*L12.`z')
gen `z3b'=-(sin(_pi/2)*L.`z' 	+ sin(2*_pi/2)*L2.`z' + sin(3*_pi/2)*L3.`z' + sin(4*_pi/2)*L4.`z'+sin(5*_pi/2)*L5.`z' + /*
*/		  sin(6*_pi/2)*L6.`z'   + sin(7*_pi/2)*L7.`z' + sin(8*_pi/2)*L8.`z' + sin(9*_pi/2)*L9.`z'+sin(10*_pi/2)*L10.`z' + /*
*/		  sin(11*_pi/2)*L11.`z' + sin(12*_pi/2)*L12.`z')
gen `z4b'=-(sin(2*_pi/3)*L.`z' 	  + sin(2*2*_pi/3)*L2.`z' + sin(2*3*_pi/3)*L3.`z' + sin(2*4*_pi/3)*L4.`z'+sin(2*5*_pi/3)*L5.`z' + /*
*/		  sin(2*6*_pi/3)*L6.`z'   + sin(2*7*_pi/3)*L7.`z' + sin(2*8*_pi/3)*L8.`z' + sin(2*9*_pi/3)*L9.`z'+sin(2*10*_pi/3)*L10.`z' + /*
*/		  sin(2*11*_pi/3)*L11.`z' + sin(2*12*_pi/3)*L12.`z')
gen `z5b'=-(sin(5*_pi/6)*L.`z'    + sin(5*2*_pi/6)*L2.`z' + sin(5*3*_pi/6)*L3.`z' + sin(5*4*_pi/6)*L4.`z'+sin(5*5*_pi/6)*L5.`z' + /*
*/		  sin(5*6*_pi/6)*L6.`z'   + sin(5*7*_pi/6)*L7.`z' + sin(5*8*_pi/6)*L8.`z' + sin(5*9*_pi/6)*L9.`z'+sin(5*10*_pi/6)*L10.`z' + /*
*/		  sin(5*11*_pi/6)*L11.`z' + sin(5*12*_pi/6)*L12.`z')
}

  // --- t-test for the last lag -------------------
 local augment ""
 local lag = 0
if `maxlag' > 0 {
 if "`mode'"=="fix" {
 local lag = `maxlag'
 local augment = "L(1/`lag').`zd12'"
 local method = "The lag is fixed by user"
 }
 if "`mode'"=="seq" {
	local method = "Sequential at `level'% level"
	forv i = `maxlag' (-1) 1 {
		qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b' L(1/`i').`zd12', noconstant
		qui test L`i'.`zd12'
		if `r(p)' < `level'*0.01 {
			local lag = `i'
			continue,break
			}
		}
	if `lag'>0   local augment = "L(1/`lag').`zd12'"
 }
 // --- Akaike Information Criteria ---
 if "`mode'" =="aic" {
 local method = "Akaike Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b' L(1/`i').`zd12', noconstant
	else     qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b', noconstant
	qui estimates stats
	matrix mm`i' = r(S)
	local aic`i' = mm`i'[1,5]
	}
 local min = `aic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `aic`i'' < `min' {
		local min = `aic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`zd12'"
 }
 // --- Bayesian Information Criteria ---
 if "`mode'" =="bic" {
 local method = "Bayesian Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b' L(1/`i').`zd12', noconstant
	else     qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b', noconstant
	qui estimates stats
	matrix mm`i' = r(S)
	local bic`i' = mm`i'[1,6]
	}
 local min = `bic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `bic`i'' < `min' {
		local min = `bic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`zd12'"
 }
 // --- Modified AIC ------------------
if "`mode'"=="" | "`mode'" =="maic" {
 local method = "Modified AIC"
 tempvar xf2
 forv i=1 (1) 12 {
	qui replace  `q`i''=(`seas'==`i')
	qui replace `ts`i''=`q`i''*`trend'
	}
 
 qui regress `x'  `aux'
 qui predict `xf2' if e(sample)
 
 tempvar zz zzd12 zz1 zz2 zz1a zz2a zz3a zz4a zz5a zz1b zz2b zz3b zz4b zz5b
 qui {
gen `zz' = `x' - `xf2'
gen `zzd12'=S12.`zz'
gen `zz1' =  L.`zz'  + L2.`zz' + L3.`zz' + L4.`zz' + L5.`zz' + L6.`zz' + /*
			 */ L7.`zz' + L8.`zz' + L9.`zz' + L10.`zz' + L11.`zz' + L12.`zz' 
gen `zz2' = -L.`zz' + L2.`zz' - L3.`zz' + L4.`zz' - L5.`zz' + L6.`zz' - /*
			 */ L7.`zz' + L8.`zz' - L9.`zz' + L10.`zz' - L11.`zz' + L12.`zz' 
gen `zz1a'=cos(_pi/6)*L.`zz' 		+ cos(2*_pi/6)*L2.`zz' + cos(3*_pi/6)*L3.`zz' + cos(4*_pi/6)*L4.`zz'+cos(5*_pi/6)*L5.`zz' + /*
*/		cos(6*_pi/6)*L6.`zz'   + cos(7*_pi/6)*L7.`zz' + cos(8*_pi/6)*L8.`zz' + cos(9*_pi/6)*L9.`zz'+cos(10*_pi/6)*L10.`zz' + /*
*/		cos(11*_pi/6)*L11.`zz' + cos(12*_pi/6)*L12.`zz'
gen `zz2a'=cos(_pi/3)*L.`zz' 		+ cos(2*_pi/3)*L2.`zz' + cos(3*_pi/3)*L3.`zz' + cos(4*_pi/3)*L4.`zz'+cos(5*_pi/3)*L5.`zz' + /*
*/		cos(6*_pi/3)*L6.`zz'   + cos(7*_pi/3)*L7.`zz' + cos(8*_pi/3)*L8.`zz' + cos(9*_pi/3)*L9.`zz'+cos(10*_pi/3)*L10.`zz' + /*
*/		cos(11*_pi/3)*L11.`zz' + cos(12*_pi/3)*L12.`zz'
gen `zz3a'=cos(_pi/2)*L.`zz' 		+ cos(2*_pi/2)*L2.`zz' + cos(3*_pi/2)*L3.`zz' + cos(4*_pi/2)*L4.`zz'+cos(5*_pi/2)*L5.`zz' + /*
*/		cos(6*_pi/2)*L6.`zz'   + cos(7*_pi/2)*L7.`zz' + cos(8*_pi/2)*L8.`zz' + cos(9*_pi/2)*L9.`zz'+cos(10*_pi/2)*L10.`zz' + /*
*/		cos(11*_pi/2)*L11.`zz' + cos(12*_pi/2)*L12.`zz'
gen `zz4a'=cos(2*_pi/3)*L.`zz' 	  + cos(2*2*_pi/3)*L2.`zz' + cos(2*3*_pi/3)*L3.`zz' + cos(2*4*_pi/3)*L4.`zz'+cos(2*5*_pi/3)*L5.`zz' + /*
*/		cos(2*6*_pi/3)*L6.`zz'   + cos(2*7*_pi/3)*L7.`zz' + cos(2*8*_pi/3)*L8.`zz' + cos(2*9*_pi/3)*L9.`zz'+cos(2*10*_pi/3)*L10.`zz' + /*
*/		cos(2*11*_pi/3)*L11.`zz' + cos(2*12*_pi/3)*L12.`zz'
gen `zz5a'=cos(5*_pi/6)*L.`zz' 	  + cos(5*2*_pi/6)*L2.`zz' + cos(5*3*_pi/6)*L3.`zz' + cos(5*4*_pi/6)*L4.`zz'+cos(5*5*_pi/6)*L5.`zz' + /*
*/		cos(5*6*_pi/6)*L6.`zz'   + cos(5*7*_pi/6)*L7.`zz' + cos(5*8*_pi/6)*L8.`zz' + cos(5*9*_pi/6)*L9.`zz'+cos(5*10*_pi/6)*L10.`zz' + /*
*/		cos(5*11*_pi/6)*L11.`zz' + cos(5*12*_pi/6)*L12.`zz'
gen `zz1b'=-(sin(_pi/6)*L.`zz' 	  + sin(2*_pi/6)*L2.`zz' + sin(3*_pi/6)*L3.`zz' + sin(4*_pi/6)*L4.`zz'+sin(5*_pi/6)*L5.`zz' + /*
*/		  sin(6*_pi/6)*L6.`zz'   + sin(7*_pi/6)*L7.`zz' + sin(8*_pi/6)*L8.`zz' + sin(9*_pi/6)*L9.`zz'+sin(10*_pi/6)*L10.`zz' + /*
*/		  sin(11*_pi/6)*L11.`zz' + sin(12*_pi/6)*L12.`zz')
gen `zz2b'=-(sin(_pi/3)*L.`zz' 	  + sin(2*_pi/3)*L2.`zz' + sin(3*_pi/3)*L3.`zz' + sin(4*_pi/3)*L4.`zz'+sin(5*_pi/3)*L5.`zz' + /*
*/		  sin(6*_pi/3)*L6.`zz'   + sin(7*_pi/3)*L7.`zz' + sin(8*_pi/3)*L8.`zz' + sin(9*_pi/3)*L9.`zz'+sin(10*_pi/3)*L10.`zz' + /*
*/		  sin(11*_pi/3)*L11.`zz' + sin(12*_pi/3)*L12.`zz')
gen `zz3b'=-(sin(_pi/2)*L.`zz' 	  + sin(2*_pi/2)*L2.`zz' + sin(3*_pi/2)*L3.`zz' + sin(4*_pi/2)*L4.`zz'+sin(5*_pi/2)*L5.`zz' + /*
*/		  sin(6*_pi/2)*L6.`zz'   + sin(7*_pi/2)*L7.`zz' + sin(8*_pi/2)*L8.`zz' + sin(9*_pi/2)*L9.`zz'+sin(10*_pi/2)*L10.`zz' + /*
*/		  sin(11*_pi/2)*L11.`zz' + sin(12*_pi/2)*L12.`zz')
gen `zz4b'=-(sin(2*_pi/3)*L.`zz' 	    + sin(2*2*_pi/3)*L2.`zz' + sin(2*3*_pi/3)*L3.`zz' + sin(2*4*_pi/3)*L4.`zz'+sin(2*5*_pi/3)*L5.`zz' + /*
*/		  sin(2*6*_pi/3)*L6.`zz'   + sin(2*7*_pi/3)*L7.`zz' + sin(2*8*_pi/3)*L8.`zz' + sin(2*9*_pi/3)*L9.`zz'+sin(2*10*_pi/3)*L10.`zz' + /*
*/		  sin(2*11*_pi/3)*L11.`zz' + sin(2*12*_pi/3)*L12.`zz')
gen `zz5b'=-(sin(5*_pi/6)*L.`zz'      + sin(5*2*_pi/6)*L2.`zz' + sin(5*3*_pi/6)*L3.`zz' + sin(5*4*_pi/6)*L4.`zz'+sin(5*5*_pi/6)*L5.`zz' + /*
*/		  sin(5*6*_pi/6)*L6.`zz'   + sin(5*7*_pi/6)*L7.`zz' + sin(5*8*_pi/6)*L8.`zz' + sin(5*9*_pi/6)*L9.`zz'+sin(5*10*_pi/6)*L10.`zz' + /*
*/		  sin(5*11*_pi/6)*L11.`zz' + sin(5*12*_pi/6)*L12.`zz')
}
 
 tempvar s1 s2 sa1 sa2 sa3 sa4 sa5 sb1 sb2 sb3 sb4 sb5
 forv i=1 (1) 5 {
	if `i'<=2 {
		qui gen `s`i'' = sum(`zz`i''^2)
		local ss`i' = `s`i''[_N] - `s`i''[12+`maxlag']
		}
	qui gen `sa`i'' = sum(`zz`i'a'^2)
	qui gen `sb`i'' = sum(`zz`i'b'^2)
	local ssa`i' = `sa`i''[_N] - `sa`i''[12+`maxlag']
	local ssb`i' = `sb`i''[_N] - `sb`i''[12+`maxlag']
	}
	
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `zzd12' `zz1' `zz2' `zz1a' `zz1b' `zz2a' `zz2b' `zz3a' `zz3b' `zz4a' `zz4b' `zz5a' `zz5b' L(1/`i').`zzd12', noconstant
	else     qui regress `zzd12' `zz1' `zz2' `zz1a' `zz1b' `zz2a' `zz2b' `zz3a' `zz3b' `zz4a' `zz4b' `zz5a' `zz5b', noconstant
	mat   b    = e(b)
	local denom = e(N) - `maxlag'
	local sig2 = e(rss) / `denom' 
	local tau  = (b[1,1]^2) * `ss1' + (b[1,2]^2) * `ss2' + (b[1,3]^2) * `sa1' + (b[1,4]^2) * `sb1' + /*
*/				 (b[1,5]^2) * `sa2' + (b[1,6]^2) * `sb2' + (b[1,7]^2) * `sa3' + (b[1,8]^2) * `sb3' + /*
*/				 (b[1,9]^2) * `sa4' + (b[1,10]^2)* `sb4' + (b[1,11]^2)* `sa5' + (b[1,12]^2)* `sb5'
	local tau = `tau' / `sig2'
	local maic`i' = ln(`sig2') + 2*(`tau' + `i'+12) / `denom'
	}
 local min = `maic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `maic`i'' < `min' {
		local min = `maic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`zd12'"
 }

}
tempvar res1
// --- Starting Regressions ----------
qui regress `zd12' `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b' `augment', noconstant
	if "`residuals'" != "" {
			qui predict `residuals', resid
			label var `residuals' "Residuals from Seasonal Unit Root test"
		}
	
	if "`noac'" == "" {
		qui predict `res1', resid
		}
	
	local df=e(df_r)	
	matrix b = get(_b)
	matrix dia = vecdiag(e(V))
	local n =e(N) 
	
return scalar N = `n'

// --- Generating F-test and t-test results -----
return scalar t1=b[1,1]/sqrt(dia[1,1])
return scalar t2=b[1,2]/sqrt(dia[1,2])

qui test `z1a' `z1b'
return scalar F1 = `r(F)'

qui test `z2a' `z2b'
return scalar F2 = `r(F)'

qui test `z3a' `z3b'
return scalar F3 = `r(F)'

qui test `z4a' `z4b'
return scalar F4 = `r(F)'

qui test `z5a' `z5b'
return scalar F5 = `r(F)'

qui test      `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b'
return scalar F25 = `r(F)'

qui test `z1' `z2' `z1a' `z1b' `z2a' `z2b' `z3a' `z3b' `z4a' `z4b' `z5a' `z5b'
return scalar F15 = `r(F)'


 GetCV `case' `n' 1 12
 matrix cv= r(ck)

// --- Displaying Results -----------------------
di in gr " "
 di in gr "HEGY Monthly seasonal unit root test with GLS detrending for " in ye  "`varlist'"
 di in gr " "
 di in gr "Number of observations  :  `n' "  
 di in gr "Deterministic variables : `daux'"
 if `maxlag'>0 di in gr "Optimal lag selection method: `method'"
 di in gr "Lags tested: `maxlag'"
 di in gr "Augmented by lags : `lag'"
 di in gr " "
 di in gr _col(16) "Stat" _col(24) "1% critical" _col(37) "5% critical" _col(50) "10% critical" 
 di in gr _dup(78) "-"
 di in ye /* 
 */ "t[0]"        _col(12) %9.3f `return(t1)' _col(23)   %9.3f cv[1,1]   _col(36) %9.3f cv[1,2]   _col(49) %9.3f cv[1,3]
 di "t[Pi]"       _col(12) %9.3f `return(t2)' _col(23)   %9.3f cv[1,4]   _col(36) %9.3f cv[1,5]   _col(49) %9.3f cv[1,6] 
 di " "
 di "F[Pi/6]"     _col(12) %9.3f `return(F1)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[Pi/3]"     _col(12) %9.3f `return(F2)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[Pi/2]"     _col(12) %9.3f `return(F3)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[2*Pi/3]"   _col(12) %9.3f `return(F4)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[5*Pi/6]"   _col(12) %9.3f `return(F5)' _col(23)   %9.3f cv[1,7]   _col(36) %9.3f cv[1,8]   _col(49) %9.3f cv[1,9]
 di "F[All seas]" _col(12) %9.3f `return(F25)' _col(23)  %9.3f cv[1,10]  _col(36) %9.3f cv[1,11]  _col(49) %9.3f cv[1,12]
 di "F[All]"      _col(12) %9.3f `return(F15)' _col(23)  %9.3f cv[1,13]  _col(36) %9.3f cv[1,14]  _col(49) %9.3f cv[1,15]
 
 if "`noreg'" == "" {
	local gls1 = 1
	di ""
	di in gr "Testing regression:"
	DiReg12 `gls1' `case' `lag' `b' `dia'
	}
 
  if "`noac'" == "" {
	 di ""
	 di in gr "Correlogram  of residuals:"
	 corrgram `res1', lags(`maxlag')
	 }
 exit
}

 if r(unit1) == "q" & "`gls'" == "" { /* Quarterly with OLS */
// --- Generating Differences and Dummies --------
quietly {
tempvar y y1 y2 y3 y4 yd4 trend seas q1 q2 q3 q4 ts1 ts2 ts3 ts4
gen `y' = `varlist' if `touse'
gen `y1'= L1.`y'+L2.`y'+L3.`y'+L4.`y'
gen `y2'=-L1.`y'+L2.`y'-L3.`y'+L4.`y'
gen `y3'=       -L2.`y'       +L4.`y'
gen `y4'=-L1.`y'       +L3.`y'
gen `yd4'=S4.`y'
		}

egen `trend'=fill(1 2)
egen `seas'=fill(1/4 1/4)
forv i=1 (1) 4 {
	gen  `q`i''=(`seas'==`i')
	gen `ts`i''=`q`i''*`trend'
	}

local aux "err"
 if "`det'"=="none" {
  local aux ", noc"
  local daux "None"
  local case 1
  } 
 if "`det'"=="const" {
  local aux " "
  local daux "Constant"
  local case 2
  }
 if "`det'"=="" | "`det'" =="seas" {
  local aux "`q1' `q2' `q3'" 
  local daux "Seasonal dummies"
  local case 3 
  }
 if "`det'"=="trend" { 
  local aux "`trend'" 
  local daux "Constant and trend"
  local case 4
  }
 if "`det'"=="strend" { 
  local aux " `q1' `q2' `q3' `trend' " 
  local daux "Seasonal dummies and linear trend"
  local case 5
  }
 if "`det'"=="mult" {
  local aux "`q1' `q2' `q3' `ts1' `ts2' `ts3' `ts4'"
  local daux "Seasonal dummies and seasonal trends"
  local case 6
  }
 if "`aux'"=="err" {
  di in red "Error: det must be none, const, seas, trend, strend or mult"
  exit
  }
  
// --- t-test for the last lag -------------------
 local augment ""
 local lag = 0
if `maxlag' > 0 {
 if "`mode'"=="fix" {
 local lag = `maxlag'
 local augment = "L(1/`lag').`yd4'"
 local method = "The lag is fixed by user"
 }
 if "`mode'"=="seq" {
	local method = "Sequential at `level'% level"
	forv i = `maxlag' (-1) 1 {
		qui regress `yd4' `y1' `y2' `y3' `y4' L(1/`i').`yd4' `aux'
		qui test L`i'.`yd4'
		if `r(p)' < `level'*0.01 {
			local lag = `i'
			continue,break
			}
		}
	if `lag'>0   local augment = "L(1/`lag').`yd4'"
 }
 // --- Akaike Information Criteria ---
 if "`mode'" =="aic" {
 local method = "Akaike Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `yd4' `y1' `y2' `y3' `y4' L(1/`i').`yd4' `aux'
	else     qui regress `yd4' `y1' `y2' `y3' `y4' `aux'
	qui estimates stats
	matrix mm`i' = r(S)
	local aic`i' = mm`i'[1,5]
	}
 local min = `aic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `aic`i'' < `min' {
		local min = `aic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`yd4'"
 }
 // --- Bayesian Information Criteria ---
 if "`mode'" =="bic" {
 local method = "Bayesian Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `yd4' `y1' `y2' `y3' `y4' L(1/`i').`yd4' `aux'
	else     qui regress `yd4' `y1' `y2' `y3' `y4' `aux'
	qui estimates stats
	matrix mm`i' = r(S)
	local bic`i' = mm`i'[1,6]
	}
 local min = `bic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `bic`i'' < `min' {
		local min = `bic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`yd4'"
 }
 // --- Modified AIC ------------------
if "`mode'"=="" | "`mode'" =="maic" {
 local method = "Modified AIC"
 tempvar x xf
 qui gen `x' = `varlist' if `touse'
 qui regress `x'  `aux'
 qui predict `xf' if e(sample)
 
 tempvar z z1 z2 z3 z4 zd4
 qui {
  gen `z' = `x' - `xf'
  gen `z1'= L1.`z'+L2.`z'+L3.`z'+L4.`z'
  gen `z2'=-L1.`z'+L2.`z'-L3.`z'+L4.`z'
  gen `z3'=       -L2.`z'       +L4.`z'
  gen `z4'=-L1.`z'       +L3.`z'
  gen `zd4'=S4.`z'
}
 
 tempvar s1 s2 s3 s4
 forv i=1 (1) 4 {
	qui gen `s`i'' = sum(`z`i''^2)
	local ss`i' = `s`i''[_N] - `s`i''[4+`maxlag']
	}
	
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `zd4' `z1' `z2' `z3' `z4' L(1/`i').`zd4', noconstant
	else     qui regress `zd4' `z1' `z2' `z3' `z4', noconstant
	mat   b    = e(b)
	local denom = e(N) - `maxlag'
	local sig2 = e(rss) / `denom' 
	local tau  = 0 
	forv j=1 (1) 4 {
		local tau = `tau' + (b[1,`j']^2) * `ss`j''
		}
	local tau = `tau' / `sig2'
	local maic`i' = ln(`sig2') + 2*(`tau' + `i'+4) / `denom'
	}
 local min = `maic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `maic`i'' < `min' {
		local min = `maic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`yd4'"
 }
}
tempvar res1
// --- Starting Regressions ----------
qui regress `yd4' `y1' `y2' `y3' `y4' `augment' `aux'
	if "`residuals'" != "" {
			qui predict `residuals', resid
			label var `residuals' "Residuals from Seasonal Unit Root test"
		}
	
	if "`noac'" == "" {
		qui predict `res1', resid
		}
	
	local df = e(df_r)
	matrix b = get(_b)
	matrix dia = vecdiag(e(V))
	local n =e(N)
	
return scalar N = `n'

// --- Generating F-test and t-test results -----
return scalar t1=b[1,1]/sqrt(dia[1,1])
return scalar t2=b[1,2]/sqrt(dia[1,2])

qui test `y3' `y4'
return scalar F34 = `r(F)'

qui test `y2' `y3' `y4'
return scalar F234 = `r(F)'

qui test `y1' `y2' `y3' `y4'
return scalar F1234 = `r(F)'

 GetCV `case' `n' 0 4
 matrix cv= r(ck)

// --- Displaying Results -----------------------
di in gr " "
 di in gr "HEGY Quarterly seasonal unit root test for " in ye  "`varlist'"
 di in gr " "
 di in gr "Number of observations  :  `n' "  
 di in gr "Deterministic variables : `daux'"
 if `maxlag'>0 di in gr "Optimal lag selection method: `method'"
 di in gr "Lags tested: `maxlag'"
 di in gr "Augmented by lags : `lag'"
 di in gr " "
 di in gr _col(16) "Stat" _col(24) "1% critical" _col(37) "5% critical" _col(50) "10% critical"  
 di in gr _dup(78) "-"
 di in ye /* 
 */ "t[0]"        _col(12) %9.3f `return(t1)'    _col(23)  %9.3f cv[1,1]  _col(36) %9.3f cv[1,2]  _col(49) %9.3f cv[1,3] 
 di "t[Pi]"       _col(12) %9.3f `return(t2)'    _col(23)  %9.3f cv[1,4]  _col(36) %9.3f cv[1,5]  _col(49) %9.3f cv[1,6] 
 di " "
 di "F[Pi/2]"     _col(12) %9.3f `return(F34)'   _col(23)  %9.3f cv[1,7]  _col(36) %9.3f cv[1,8]  _col(49) %9.3f cv[1,9]
 di "F[All seas]" _col(12) %9.3f `return(F234)'  _col(23)  %9.3f cv[1,10] _col(36) %9.3f cv[1,11] _col(49) %9.3f cv[1,12]
 di "F[All]"      _col(12) %9.3f `return(F1234)' _col(23)  %9.3f cv[1,13] _col(36) %9.3f cv[1,14] _col(49) %9.3f cv[1,15]
 
 if "`noreg'" == "" {
	local gls1 = 0
	di ""
	di in gr "Testing regression:"
	DiReg4 `gls1' `case' `lag' `b' `dia' 
	}

  if "`noac'" == "" {
	 di ""
	 di in gr "Correlogram  of residuals:"
	 corrgram `res1', lags(`maxlag')
	 }
exit
}

 if r(unit1) == "q" & "`gls'" != "" { /* Quarterly with GLS */
// --- Generating Dummies --------
tempvar trend seas q1 q2 q3 q4 ts1 ts2 ts3 ts4 qq1 qq2 qq3 qq4
egen `trend'=fill(1 2)
egen `seas'=fill(1/4 1/4)
forv i=1 (1) 4 {
	gen `qq`i''=(`seas'==`i')
	gen `ts`i''=`qq`i''*`trend'
	}

gen `q1' = 1
gen `q2' = cos(`trend'*_pi/2)
gen `q3' = sin(`trend'*_pi/2)
gen `q4' = cos(`trend'*_pi)

// -------- Mode Selection ---------------------
local aux "err"
  if "`det'"=="const" {
  local aux " "
  local daux "Constant"
  local case 2
  }
 if "`det'"=="" | "`det'" =="seas" {
  local aux "`q1' `q2' `q3'" 
  local daux "Seasonal dummies"
  local case 3 
  }
 if "`det'"=="trend" { 
  local aux "`trend'" 
  local daux "Constant and trend"
  local case 4
  }
 if "`det'"=="strend" { 
  local aux " `q1' `q2' `q3' `trend' " 
  local daux "Seasonal dummies and linear trend"
  local case 5
  }
 if "`det'"=="mult" {
  local aux "`q1' `q2' `q3' `ts1' `ts2' `ts3' `ts4'"
  local daux "Seasonal dummies and seasonal trends"
  local case 6
  }
 if "`aux'"=="err" {
  di in red "Error: det can't be none"
  exit
  }

// --- Generating Differences --------  
tempvar x xf
gen `x' = `varlist'  if `touse'
qui summarize `x'
local tt= r(N)

if `case' == 2 {
	local c0=-7
	local c1=0
	local c2=0
	}
if `case' == 3 {
	local c0=-7
	local c1=-3.75
	local c2=-7
	}
if `case' == 4 {
	local c0=-13.5
	local c1=0
	local c2=0
	}
if `case' == 5 {
	local c0=-13.5
	local c1=-3.75
	local c2=-7
	}
if `case' == 6 {
	local c0=-13.5
	local c1=-8.65
	local c2=-13.5
	}
local a_0=1+`c0'/`tt'
local a_1=1+`c1'/`tt'
local a_2=1+`c2'/`tt'


local a1=(`a_0'-`a_2')+2*`a_1'*cos(_pi/2)
local a2=`a_0'*`a_2'-(`a_0'-`a_2')*2*`a_1'*cos(_pi/2)-`a_1'^2
local a3=(`a_0'-`a_2')*`a_1'^2-`a_0'*`a_2'*2*`a_1'*cos(_pi/2)
local a4=`a_0'*`a_2'*`a_1'^2


tempvar xc sd1 sd2 sd3 sd4 st1 st2 st3 st4 tr cc0 cc1
qui { 
gen `xc' =0
gen `sd1'=0
gen `sd2'=0
gen `sd3'=0
gen `sd4'=0
gen `st1'=0
gen `st2'=0
gen `st3'=0
gen `st4'=0
gen `tr' =0
gen `cc0'=0
gen `cc1'=1

replace `xc' = `x' if _n==1
replace `tr' = `trend' if _n==1
replace `cc0'= `cc1'   if _n==1
forv j=1 (1) 4 {
	replace `sd`j'' = `q`j'' if _n==1
	replace `st`j'' = `ts`j'' if _n==1
	}
replace `xc' = `x'-`a1'*L1.`x' if _n==2
replace `tr' = `trend'-`a1'*L1.`trend' if _n==2
replace `cc0'= `cc1'  -`a1'*L1.`cc1'   if _n==2
forv j=1 (1) 4 {
	replace `sd`j'' = `q`j''  - `a1' * L1.`q`j'' if _n==2
	replace `st`j'' = `ts`j'' - `a1' * L1.`ts`j'' if _n==2
	}
replace `xc' = `x'-`a1'*L1.`x'-`a2'*L2.`x' if _n==3
replace `tr' = `trend'-`a1'*L1.`trend'-`a2'*L2.`trend' if _n==3
replace `cc0'= `cc1'  -`a1'*L1.`cc1'  -`a2'*L2.`cc1'   if _n==3
forv j=1 (1) 4 {
	replace `sd`j'' = `q`j''  - `a1' * L1.`q`j''  - `a2' * L2.`q`j'' if _n==3
	replace `st`j'' = `ts`j'' - `a1' * L1.`ts`j'' - `a2' * L2.`ts`j'' if _n==3
	}
replace `xc' = `x'-`a1'*L1.`x'-`a2'*L2.`x'-`a3'*L3.`x' if _n==4
replace `tr' = `trend'-`a1'*L1.`trend'-`a2'*L2.`trend'-`a3'*L3.`trend' if _n==4
replace `cc0'= `cc1'  -`a1'*L1.`cc1'  -`a2'*L2.`cc1'  -`a3'*L3.`cc1'   if _n==4
forv j=1 (1) 4 {
	replace `sd`j'' = `q`j''  - `a1' * L1.`q`j''  - `a2' * L2.`q`j''  - `a3' * L3.`q`j'' if _n==4
	replace `st`j'' = `ts`j'' - `a1' * L1.`ts`j'' - `a2' * L2.`ts`j'' - `a3' * L3.`ts`j'' if _n==4
	}


replace `xc' = `x'-`a1'*L1.`x'-`a2'*L2.`x'-`a3'*L3.`x'-`a4'*L4.`x' if _n>4
replace `tr' = `trend'-`a1'*L1.`trend'-`a2'*L2.`trend'-`a3'*L3.`trend'-`a4'*L4.`trend' if _n>4
replace `cc0'= `cc1'  -`a1'*L1.`cc1'  -`a2'*L2.`cc1'  -`a3'*L3.`cc1'  -`a4'*L4.`cc1'   if _n>4
forv j=1 (1) 4 {
	replace `sd`j'' = `q`j''  - `a1' * L1.`q`j''  - `a2' * L2.`q`j''  - `a3' * L3.`q`j''  - `a4' * L4.`q`j'' if _n>4
	replace `st`j'' = `ts`j'' - `a1' * L1.`ts`j'' - `a2' * L2.`ts`j'' - `a3' * L3.`ts`j'' - `a4' * L4.`ts`j'' if _n>4
	}
}
// ------------ GLS detrending ----------------------------------------
if `case' == 2 {
	qui regress `xc' `cc0', noconstant
	matrix b0 = get(_b)
	qui gen `xf' = b0[1,1]*`cc1'
	}
if `case' == 3 {
	qui regress `xc' `sd1' `sd2' `sd3' `sd4', noconstant
	matrix b0 = get(_b)
	qui gen `xf' = b0[1,1]*`q1' + b0[1,2]*`q2' +  b0[1,3]*`q3' +  b0[1,4]*`q4'
	}
if `case' == 4 {
	qui regress `xc' `cc0' `tr', noconstant
	matrix b0 = get(_b)
	qui gen `xf' = b0[1,1]*`cc1' + b0[1,2]*`trend'
	}
if `case' == 5 {
	qui regress `xc' `sd1' `sd2' `sd3' `sd4' `tr', noconstant
	matrix b0 = get(_b)
	qui gen `xf' = b0[1,1]*`q1' + b0[1,2]*`q2' +  b0[1,3]*`q3' +  b0[1,4]*`q4' + /*
	*/	           b0[1,5]*`trend'
	}
if `case' == 6 {
	qui regress `xc' `sd1' `sd2' `sd3' `sd4' `st1' `st2' `st3' `st4', noconstant
	matrix b0 = get(_b)
	gen `xf' = b0[1,1]*`q1' + b0[1,2]*`q2' +  b0[1,3]*`q3' +  b0[1,4]*`q4' + /*
	*/	       b0[1,5]*`ts1'+ b0[1,6]*`ts2' + b0[1,7]*`ts3' + b0[1,8]*`ts4'
	}
tempvar z z1 z2 z3 z4 zd4
qui {
gen `z' = `x' - `xf'
gen `z1'= L1.`z'+L2.`z'+L3.`z'+L4.`z'
gen `z2'=-L1.`z'+L2.`z'-L3.`z'+L4.`z'
gen `z3'=       -L2.`z'       +L4.`z'
gen `z4'=-L1.`z'       +L3.`z'
gen `zd4'=S4.`z'
}

  // --- t-test for the last lag -------------------
 local augment ""
 local lag = 0
if `maxlag' > 0 {
 if "`mode'"=="fix" {
 local lag = `maxlag'
 local augment = "L(1/`lag').`zd4'"
 local method = "The lag is fixed by user"
 }
 if "`mode'"=="seq" {
	local method = "Sequential at `level'% level"
	forv i = `maxlag' (-1) 1 {
		qui regress `zd4' `z1' `z2' `z3' `z4' L(1/`i').`zd4', noconstant
		qui test L`i'.`zd4'
		if `r(p)' < `level'*0.01 {
			local lag = `i'
			continue,break
			}
		}
	if `lag'>0   local augment = "L(1/`lag').`zd4'"
 }
 // --- Akaike Information Criteria ---
 if "`mode'" =="aic" {
 local method = "Akaike Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `zd4' `z1' `z2' `z3' `z4' L(1/`i').`zd4', noconstant
	else     qui regress `zd4' `z1' `z2' `z3' `z4', noconstant
	qui estimates stats
	matrix mm`i' = r(S)
	local aic`i' = mm`i'[1,5]
	}
 local min = `aic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `aic`i'' < `min' {
		local min = `aic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`zd4'"
 }
 // --- Bayesian Information Criteria ---
 if "`mode'" =="bic" {
 local method = "Bayesian Information Criteria"
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `zd4' `z1' `z2' `z3' `z4' L(1/`i').`zd4', noconstant
	else     qui regress `zd4' `z1' `z2' `z3' `z4', noconstant
	qui estimates stats
	matrix mm`i' = r(S)
	local bic`i' = mm`i'[1,6]
	}
 local min = `bic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `bic`i'' < `min' {
		local min = `bic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`zd4'"
 }
 // --- Modified AIC ------------------
if "`mode'"=="" | "`mode'" =="maic" {
 local method = "Modified AIC"
quietly {
forv i=1 (1) 4 {
	replace `q`i''=(`seas'==`i')
	} 
tempvar y y1 y2 y3 y4 yd4 xf2	
	regress `x'  `aux'
	predict `xf2' if e(sample)

	gen `y' = `x' - `xf2'
	gen `y1'= L1.`y'+L2.`y'+L3.`y'+L4.`y'
	gen `y2'=-L1.`y'+L2.`y'-L3.`y'+L4.`y'
	gen `y3'=       -L2.`y'       +L4.`y'
	gen `y4'=-L1.`y'       +L3.`y'
	gen `yd4'=S4.`y'
	}
 
 tempvar s1 s2 s3 s4
 forv i=1 (1) 4 {
	qui gen `s`i'' = sum(`y`i''^2)
	local ss`i' = `s`i''[_N] - `s`i''[4+`maxlag']
	}
	
 forv i = `maxlag' (-1) 0 {
	if `i'>0 qui regress `yd4' `y1' `y2' `y3' `y4' L(1/`i').`yd4', noconstant
	else     qui regress `yd4' `y1' `y2' `y3' `y4', noconstant
	mat   b    = e(b)
	local denom = e(N) - `maxlag'
	local sig2 = e(rss) / `denom'
	local tau  = 0 
	forv j=1 (1) 4 {
		local tau = `tau' + (b[1,`j']^2) * `ss`j''
		}
	local tau = `tau' / `sig2'
	local maic`i' = ln(`sig2') + 2*(`tau' + `i'+4) / `denom'
	}
 local min = `maic0'
 local lag = 0
 forv i=1 (1) `maxlag' {
	if `maic`i'' < `min' {
		local min = `maic`i''
		local lag = `i'
		}
  }
 if `lag'>0 local augment = "L(1/`lag').`zd4'"
 }
}
// --- Starting Regressions ----------
tempvar res1
qui regress `zd4' `z1' `z2' `z3' `z4' `augment', noconstant
	if "`residuals'" != "" {
			qui predict `residuals', resid
			label var `residuals' "Residuals from Seasonal Unit Root test"
		}
	
	if "`noac'" == "" {
		qui predict `res1', resid
		}
	
	local df=e(df_r)	
	matrix b = get(_b)
	matrix dia = vecdiag(e(V))
	local n =e(N) 
	
return scalar N = `n'

// --- Generating F-test and t-test results -----
return scalar t1=b[1,1]/sqrt(dia[1,1])
return scalar t2=b[1,2]/sqrt(dia[1,2])

qui test `z3' `z4'
return scalar F34 = `r(F)'

qui test `z2' `z3' `z4'
return scalar F234 = `r(F)'

qui test `z1' `z2' `z3' `z4'
return scalar F1234 = `r(F)'

 GetCV `case' `n' 1 4
 matrix cv= r(ck)

// --- Displaying Results -----------------------
di in gr " "
 di in gr "HEGY Quarterly seasonal unit root test with GLS detrending for " in ye  "`varlist'"
 di in gr " "
 di in gr "Number of observations  :  `n' "  
 di in gr "Deterministic variables : `daux'"
 if `maxlag'>0 di in gr "Optimal lag selection method: `method'"
 di in gr "Lags tested: `maxlag'"
 di in gr "Augmented by lags : `lag'"
 di in gr " "
  di in gr _col(16) "Stat" _col(24) "1% critical" _col(37) "5% critical" _col(50) "10% critical"  
 di in gr _dup(78) "-"
 di in ye /* 
 */ "t[0]"        _col(12) %9.3f `return(t1)'    _col(23)  %9.3f cv[1,1]  _col(36) %9.3f cv[1,2]  _col(49) %9.3f cv[1,3] 
 di "t[Pi]"       _col(12) %9.3f `return(t2)'    _col(23)  %9.3f cv[1,4]  _col(36) %9.3f cv[1,5]  _col(49) %9.3f cv[1,6] 
 di " "
 di "F[Pi/2]"     _col(12) %9.3f `return(F34)'   _col(23)  %9.3f cv[1,7]  _col(36) %9.3f cv[1,8]  _col(49) %9.3f cv[1,9]
 di "F[All seas]" _col(12) %9.3f `return(F234)'  _col(23)  %9.3f cv[1,10] _col(36) %9.3f cv[1,11] _col(49) %9.3f cv[1,12]
 di "F[All]"      _col(12) %9.3f `return(F1234)' _col(23)  %9.3f cv[1,13] _col(36) %9.3f cv[1,14] _col(49) %9.3f cv[1,15]
 
 if "`noreg'" == "" {
	local gls1 = 1
	di ""
	di in gr "Testing regression:"
	DiReg4 `gls1' `case' `lag' `b' `dia' 
	}
	
  if "`noac'" == "" {
	 di ""
	 di in gr "Correlogram  of residuals:"
	 corrgram `res1', lags(`maxlag')
	 }
exit
}

end

program define GetCV, rclass
 args c n gls freq
 tempname zt cv ck
 
 local years = `n'/`freq'

 coefs `c' `gls' `freq'
 mat zt = r(coefs1)
 mat cv=J(1,15,0)
 forv i=1 (1) 15 {
	mat cv[1,`i'] = zt[`i',1] + zt[`i',2]*`years'^-1 + zt[`i',3]*`years'^-2 + zt[`i',4]*`years'^-3
	}
 
 return matrix ck cv
end

// -------------------------------------------------------
// 			Displaying Regression
// -------------------------------------------------------
program define DiReg4
        args gls1 case lag b s
	scalar nvar = `e(df_m)' + 1
	local nnvar = nvar
	local c2=invttail(`e(df_r)',0.025)
	
forv i=1 (1) `nnvar' {
	 local b`i' = b[1,`i']
	 local se`i' = sqrt(dia[1,`i'])
	}
        di ""
		di in smcl in gr "{hline 13}{c TT}{hline 64}"
        di in smcl in gr _col(14) "{c |}" /*
                */ _col(21) "Coef." _col(29) "Std. Err." _col(44) "t" /*
                */ _col(49) "P>|t|" _col(59) "[95% Conf. Interval]"
        di in smcl in gr "{hline 13}{c +}{hline 64}"
        di in smcl in gr _col(14) "{c |}"

// ------------ Auxilarily Variables ---------------------
	di in smcl in gr _col(7) "Freq.0 {c |}" in ye /*
                */ _col(17) %9.0g `b1' /*
                */ _col(28) %9.0g `se1' /*
                */ _col(38) %8.2f `b1'/`se1' /*
                */ _col(48) %6.3f tprob(e(df_r),`b1'/`se1') /*
                */ _col(58) %9.0g `b1' - `c2'*`se1' /*
                */ _col(70) %9.0g `b1' + `c2'*`se1'

	di in smcl in gr _col(5) "Freq.1/2 {c |}" in ye /*
               */ _col(17) %9.0g `b2' /*
                */ _col(28) %9.0g `se2' /*
                */ _col(38) %8.2f `b2'/`se2' /*
                */ _col(48) %6.3f tprob(e(df_r),`b2'/`se2') /*
                */ _col(58) %9.0g `b2' - `c2'*`se2' /*
                */ _col(70) %9.0g `b2' + `c2'*`se2'

	di in smcl in gr _col(5) "L.Annual {c |}" in ye /*
                */ _col(17) %9.0g `b3' /*
                */ _col(28) %9.0g `se3' /*
                */ _col(38) %8.2f `b3'/`se3' /*
                */ _col(48) %6.3f tprob(e(df_r),`b3'/`se3') /*
                */ _col(58) %9.0g `b3' - `c2'*`se3' /*
                */ _col(70) %9.0g `b3' + `c2'*`se3'

	di in smcl in gr _col(7) "Annual {c |}" in ye /*
                */ _col(17) %9.0g `b4' /*
                */ _col(28) %9.0g `se4' /*
                */ _col(38) %8.2f `b4'/`se4' /*
                */ _col(48) %6.3f tprob(e(df_r),`b4'/`se4') /*
                */ _col(58) %9.0g `b4' - `c2'*`se4' /*
                */ _col(70) %9.0g `b4' + `c2'*`se4'
				
// ------------ AR Terms ---------------------------------
	if `lag'>=1 {
	di in smcl in gr _col(14) "{c |}"
	di in smcl in gr _col(6) "AR lags {c |}"
	local c1 = `lag'+4
	
	forv i=5 (1) `c1' {
		 local i2=`i'-4
		 if `i2'<10 local space = 10
			else local    space = 9
		 di in smcl in gr _col(`space') "L`i2'. {c |}" in ye /*
                */ _col(17) %9.0g `b`i'' /*
                */ _col(28) %9.0g `se`i'' /*
                */ _col(38) %8.2f `b`i''/`se`i'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
                */ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
                */ _col(70) %9.0g `b`i'' + `c2'*`se`i''
		}
	}

// ------------ Deterministic Components -----------------	
if `gls1'==0 {
	local c3 = 5 + `lag'
	local nnvar1 = `nnvar' - 1
	local nnvar2 = `nnvar' - 2
	if `case'!= 1 di in smcl in gr _col(14) "{c |}"
	if `case'== 2 {
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}

	else if `case'== 3 {
		 forv i=`c3' (1) `nnvar1' {
			local i3 = `i'-`c3'+1
			di in smcl in gr _col(11) "Q`i3' {c |}" in ye /*
                */ _col(17) %9.0g `b`i'' /*
                */ _col(28) %9.0g `se`i'' /*
                */ _col(38) %8.2f `b`i''/`se`i'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
                */ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
                */ _col(70) %9.0g `b`i'' + `c2'*`se`i''
			}
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}
	
	else if `case'== 4 {
		 di in smcl in gr _col(8) "Trend {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar1'' /*
                */ _col(28) %9.0g `se`nnvar1'' /*
                */ _col(38) %8.2f `b`nnvar1''/`se`nnvar1'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar1''/`se`nnvar1'') /*
                */ _col(58) %9.0g `b`nnvar1'' - `c2'*`se`nnvar1'' /*
                */ _col(70) %9.0g `b`nnvar1'' + `c2'*`se`nnvar1''
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}	
	else if `case'== 5 {
		 forv i=`c3' (1) `nnvar2' {
			local i3 = `i'-`c3'+1
			di in smcl in gr _col(11) "Q`i3' {c |}" in ye /*
                */ _col(17) %9.0g `b`i'' /*
                */ _col(28) %9.0g `se`i'' /*
                */ _col(38) %8.2f `b`i''/`se`i'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
                */ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
                */ _col(70) %9.0g `b`i'' + `c2'*`se`i''
			}
		 di in smcl in gr _col(8) "Trend {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar1'' /*
                */ _col(28) %9.0g `se`nnvar1'' /*
                */ _col(38) %8.2f `b`nnvar1''/`se`nnvar1'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar1''/`se`nnvar1'') /*
                */ _col(58) %9.0g `b`nnvar1'' - `c2'*`se`nnvar1'' /*
                */ _col(70) %9.0g `b`nnvar1'' + `c2'*`se`nnvar1''
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}
	
	else if `case'== 6 {
		 forv i=`c3' (1) `nnvar1' {
			local i3 = `i'-`c3'+1
			if `i3'<4 {
				di in smcl in gr _col(11) "Q`i3' {c |}" in ye /*
					*/ _col(17) %9.0g `b`i'' /*
					*/ _col(28) %9.0g `se`i'' /*
					*/ _col(38) %8.2f `b`i''/`se`i'' /*
					*/ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
					*/ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
					*/ _col(70) %9.0g `b`i'' + `c2'*`se`i'' 
				}
			 else {
				 local i4=`i3'-3
				 di in smcl in gr _col(10) "Tr`i4' {c |}" in ye /*
					*/ _col(17) %9.0g `b`i'' /*
					*/ _col(28) %9.0g `se`i'' /*
					*/ _col(38) %8.2f `b`i''/`se`i'' /*
					*/ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
					*/ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
					*/ _col(70) %9.0g `b`i'' + `c2'*`se`i'' 
				}
			}
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}
	}
	di in smcl in gr _col(14) "{c |}"
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
end

program define DiReg12
        args gls1 case lag b s
	scalar nvar = `e(df_m)' + 1
	local nnvar = nvar
	local c2=invttail(`e(df_r)',0.025)
	
forv i=1 (1) `nnvar' {
	 local b`i' = b[1,`i']
	 local se`i' = sqrt(dia[1,`i'])
	}
        di ""
		di in smcl in gr "{hline 13}{c TT}{hline 64}"
        di in smcl in gr _col(14) "{c |}" /*
                */ _col(21) "Coef." _col(29) "Std. Err." _col(44) "t" /*
                */ _col(49) "P>|t|" _col(59) "[95% Conf. Interval]"
        di in smcl in gr "{hline 13}{c +}{hline 64}"
        di in smcl in gr _col(14) "{c |}"

// ------------ Auxilarily Variables ---------------------
	di in smcl in gr _col(7) "Freq.0 {c |}" in ye /*
                */ _col(17) %9.0g `b1' /*
                */ _col(28) %9.0g `se1' /*
                */ _col(38) %8.2f `b1'/`se1' /*
                */ _col(48) %6.3f tprob(e(df_r),`b1'/`se1') /*
                */ _col(58) %9.0g `b1' - `c2'*`se1' /*
                */ _col(70) %9.0g `b1' + `c2'*`se1'

	di in smcl in gr _col(5) "Freq.1/2 {c |}" in ye /*
               */ _col(17) %9.0g `b2' /*
                */ _col(28) %9.0g `se2' /*
                */ _col(38) %8.2f `b2'/`se2' /*
                */ _col(48) %6.3f tprob(e(df_r),`b2'/`se2') /*
                */ _col(58) %9.0g `b2' - `c2'*`se2' /*
                */ _col(70) %9.0g `b2' + `c2'*`se2'
	
	forv i=3 (1) 12 {
		 local i1 = `i' - 3
		 di in smcl in gr _col(8) "Aux.`i1' {c |}" in ye /*
                */ _col(17) %9.0g `b`i'' /*
                */ _col(28) %9.0g `se`i'' /*
                */ _col(38) %8.2f `b`i''/`se`i'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
                */ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
                */ _col(70) %9.0g `b`i'' + `c2'*`se`i''
		}
				
// ------------ AR Terms ---------------------------------
	if `lag'>=1 {
	di in smcl in gr _col(14) "{c |}"
	di in smcl in gr _col(6) "AR lags {c |}"
	local c1 = `lag'+12
	
	forv i=13 (1) `c1' {
		 local i2=`i'-12
		 if `i2'<10 local space = 10
			else local    space = 9
		 di in smcl in gr _col(`space') "L`i2'. {c |}" in ye /*
                */ _col(17) %9.0g `b`i'' /*
                */ _col(28) %9.0g `se`i'' /*
                */ _col(38) %8.2f `b`i''/`se`i'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
                */ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
                */ _col(70) %9.0g `b`i'' + `c2'*`se`i''
		}
	}

// ------------ Deterministic Components -----------------	
if `gls1'==0 {
	local c3 = 13 + `lag'
	local nnvar1 = `nnvar' - 1
	local nnvar2 = `nnvar' - 2
	if `case'!= 1 di in smcl in gr _col(14) "{c |}"
	if `case'== 2 {
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}

	else if `case'== 3 {
		 forv i=`c3' (1) `nnvar1' {
			local i3 = `i'-`c3'+1
			if `i3'<10 local space = 11
				else local   space = 10
			di in smcl in gr _col(`space') "Q`i3' {c |}" in ye /*
                */ _col(17) %9.0g `b`i'' /*
                */ _col(28) %9.0g `se`i'' /*
                */ _col(38) %8.2f `b`i''/`se`i'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
                */ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
                */ _col(70) %9.0g `b`i'' + `c2'*`se`i''
			}
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}
	
	else if `case'== 4 {
		 di in smcl in gr _col(8) "Trend {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar1'' /*
                */ _col(28) %9.0g `se`nnvar1'' /*
                */ _col(38) %8.2f `b`nnvar1''/`se`nnvar1'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar1''/`se`nnvar1'') /*
                */ _col(58) %9.0g `b`nnvar1'' - `c2'*`se`nnvar1'' /*
                */ _col(70) %9.0g `b`nnvar1'' + `c2'*`se`nnvar1''
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}	
	else if `case'== 5 {
		 forv i=`c3' (1) `nnvar2' {
			local i3 = `i'-`c3'+1
			if `i3'<10 local space = 11
			else local space = 10
			di in smcl in gr _col(`space') "Q`i3' {c |}" in ye /*
                */ _col(17) %9.0g `b`i'' /*
                */ _col(28) %9.0g `se`i'' /*
                */ _col(38) %8.2f `b`i''/`se`i'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
                */ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
                */ _col(70) %9.0g `b`i'' + `c2'*`se`i''
			}
		 di in smcl in gr _col(8) "Trend {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar1'' /*
                */ _col(28) %9.0g `se`nnvar1'' /*
                */ _col(38) %8.2f `b`nnvar1''/`se`nnvar1'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar1''/`se`nnvar1'') /*
                */ _col(58) %9.0g `b`nnvar1'' - `c2'*`se`nnvar1'' /*
                */ _col(70) %9.0g `b`nnvar1'' + `c2'*`se`nnvar1''
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}
	
	else if `case'== 6 {
		 forv i=`c3' (1) `nnvar1' {
			local i3 = `i'-`c3'+1
			if `i3'<12 {
				if `i3'<10 local space = 11
			    else local space = 10
				di in smcl in gr _col(`space') "Q`i3' {c |}" in ye /*
					*/ _col(17) %9.0g `b`i'' /*
					*/ _col(28) %9.0g `se`i'' /*
					*/ _col(38) %8.2f `b`i''/`se`i'' /*
					*/ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
					*/ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
					*/ _col(70) %9.0g `b`i'' + `c2'*`se`i'' 
				}
			 else {
				 local i4=`i3'-11
				 if `i4'==1 di in smcl in gr _col(14) "{c |}"
				 if `i4'<10 local space = 10
				 else local space = 9
				 di in smcl in gr _col(`space') "Tr`i4' {c |}" in ye /*
					*/ _col(17) %9.0g `b`i'' /*
					*/ _col(28) %9.0g `se`i'' /*
					*/ _col(38) %8.2f `b`i''/`se`i'' /*
					*/ _col(48) %6.3f tprob(e(df_r),`b`i''/`se`i'') /*
					*/ _col(58) %9.0g `b`i'' - `c2'*`se`i'' /*
					*/ _col(70) %9.0g `b`i'' + `c2'*`se`i'' 
				}
			}
		 di in smcl in gr _col(8) "Const {c |}" in ye /*
                */ _col(17) %9.0g `b`nnvar'' /*
                */ _col(28) %9.0g `se`nnvar'' /*
                */ _col(38) %8.2f `b`nnvar''/`se`nnvar'' /*
                */ _col(48) %6.3f tprob(e(df_r),`b`nnvar''/`se`nnvar'') /*
                */ _col(58) %9.0g `b`nnvar'' - `c2'*`se`nnvar'' /*
                */ _col(70) %9.0g `b`nnvar'' + `c2'*`se`nnvar''
		}
	}
	di in smcl in gr _col(14) "{c |}"
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
end

program define coefs, rclass
 args c1 gls freq
 tempname coefs1 coefs2

 mat input ols4 = (/*
Deterministic term is none
Frequency is 4
*/      -2.5676678       0.47516783       -2.0866101        11.057007  \ /*
*/      -1.9411654       0.65898524       -1.3763645        11.727207  \ /*
*/      -1.6168177       0.65676244      -0.67963198        6.1568001  \ /*
*/      -2.5677929       0.39461038      -0.57613774        3.9353396  \ /*
*/      -1.9410209       0.56672883        1.1513010       -5.4928701  \ /*
*/      -1.6167719       0.59752691       0.68462318       -1.8546284  \ /*
*/       4.7298820        1.2719035       -1.2462890        15.707069  \ /*
*/       3.1105441      -0.47461635      -0.58267156        7.0978537  \ /*
*/       2.4094103      -0.88414709        1.7175107       -9.3520629  \ /*
*/       3.9360076        2.1138295        1.5101301        2.2413873  \ /*
*/       2.7444305       0.30960883      -0.99512150        7.6669009  \ /*
*/       2.2154677      -0.26964074       0.67703277       -2.6692922  \ /*
*/       3.4810704        2.8444620      -0.73302974        23.059449  \ /*
*/       2.5212908       0.78682142      -0.17383853        3.6302940  \ /*
*/       2.0866174       0.14362515       0.66683400       -3.1813570  \ /*
Deterministic term is const
Frequency is 4
*/      -3.4279930      -0.58122008        2.5521031       -28.067062  \ /*
*/      -2.8602236       0.23170727        1.0513884       -9.7978441  \ /*
*/      -2.5660487       0.49846225       0.50061794       -4.2384347  \ /*
*/      -2.5654843       0.33278964        2.0609683       -11.813474  \ /*
*/      -1.9409957       0.64407136       0.19919366        1.7642012  \ /*
*/      -1.6169878       0.66476432     -0.058310126        3.1426989  \ /*
*/       4.7324106      -0.10668131        1.2958689        28.570727  \ /*
*/       3.1101654       -1.3008103     -0.078482600        18.377518  \ /*
*/       2.4091106       -1.4663395       0.21079267        13.804404  \ /*
*/       3.9340198        1.3414927       -1.2242778        37.889254  \ /*
*/       2.7441775      -0.31384041      -0.85485001        16.809288  \ /*
*/       2.2145428      -0.68409937      -0.85121981        13.143561  \ /*
*/       4.3786638        4.8517259       -6.4152528        81.284739  \ /*
*/       3.3069139        1.6576716       -3.9239019        37.871160  \ /*
*/       2.8079755       0.60790886       -1.7231322        15.977384  \ /*
Deterministic term is trend
Frequency is 4
*/      -3.9578302      -0.95063027      0.045280054       -18.612543  \ /*
*/      -3.4096333      0.057242292       0.62360541       -9.3269809  \ /*
*/      -3.1271451       0.48224946      -0.52447487       0.79311180  \ /*
*/      -2.5667639       0.17693653       0.69950518       -5.3095400  \ /*
*/      -1.9411076       0.44326384       0.85436876       -3.2174850  \ /*
*/      -1.6167623       0.46959333       0.64073955       -1.1257551  \ /*
*/       4.7315810       -1.5950089        6.5630488        32.858942  \ /*
*/       3.1104266       -2.4251299        6.5757176       -2.6263650  \ /*
*/       2.4090477       -2.3224461        5.2016427       -3.3865231  \ /*
*/       3.9358326       0.47449633       0.54970285        59.866301  \ /*
*/       2.7450620       -1.0033942        3.0899005        9.5584463  \ /*
*/       2.2156122       -1.2923094        3.4962851       -1.1475224  \ /*
*/       5.2504668        6.3605264       0.54897335        83.532860  \ /*
*/       4.0936030        2.4357024       -1.1958470        36.041727  \ /*
*/       3.5482854        1.0664806      -0.60926013        17.885635  \ /*
Deterministic term is seas
Frequency is 4
*/      -3.4297763       0.36001376      0.048111637       -26.143721  \ /*
*/      -2.8606730       0.97223479       0.26045241       -9.2990100  \ /*
*/      -2.5665713        1.1718978      -0.17083371       -1.9030244  \ /*
*/      -3.4286971       0.39772945       -1.8735404       -12.559216  \ /*
*/      -2.8616439        1.0286748      -0.81450059       -3.3678362  \ /*
*/      -2.5669902        1.1774820      -0.18065850       -2.3249076  \ /*
*/       8.8019274        3.3538848        14.277935        70.724390  \ /*
*/       6.6424614      -0.92667897        2.4713914        34.417913  \ /*
*/       5.6266552       -2.1387320     -0.065003639        22.338578  \ /*
*/       7.5396048        7.5991821        8.7130426        104.98413  \ /*
*/       5.9104902        1.9392848        5.3296319        18.793816  \ /*
*/       5.1271615       0.32007337      -0.95729121        25.507557  \ /*
*/       6.8331686        10.088421        11.745679        108.79019  \ /*
*/       5.4859552        4.2840335        1.1083491        45.083524  \ /*
*/       4.8355430        2.0705299      -0.86649686        26.985332  \ /*
Deterministic term is strend
Frequency is 4
*/      -3.9591996     0.0092665103       -3.2784932       -20.098089  \ /*
*/      -3.4091581       0.76224153       0.75572437       -14.450850  \ /*
*/      -3.1264299        1.1007609       0.40405671       -3.7484708  \ /*
*/      -3.4288406       0.43970705       -2.9928732       -7.7696786  \ /*
*/      -2.8613813        1.0097287      -0.86423766       -1.1243402  \ /*
*/      -2.5670798        1.1690247      -0.48726385        1.8289946  \ /*
*/       8.8079433        1.3768422        27.927537        43.673534  \ /*
*/       6.6484906       -2.4078609        13.518526       -6.3163026  \ /*
*/       5.6313541       -3.1794977        5.3193418        5.0928481  \ /*
*/       7.5430500        6.4424174        17.852255        94.686737  \ /*
*/       5.9137395        1.1626669        11.496638       -3.2857448  \ /*
*/       5.1309255      -0.38618742        4.8934131        2.3557045  \ /*
*/       7.6191556        12.071510        16.260612        157.81323  \ /*
*/       6.2116903        5.0771543        9.0521913        24.511814  \ /*
*/       5.5243556        2.7015249        1.4485982        23.006445  \ /*
Deterministic term is mult
Frequency is 4
*/      -3.9588101      -0.26099430       -6.8041457       -28.554100  \ /*
*/      -3.4103017       0.60746397       -2.5274287       -11.745063  \ /*
*/      -3.1270704       0.92161079       -1.8381578       0.62060474  \ /*
*/      -3.9592924      -0.20648349       -6.9819350       -31.230843  \ /*
*/      -3.4104150       0.59059676       -2.1206633       -13.207976  \ /*
*/      -3.1275135       0.90402932       -1.2230855       -2.8750693  \ /*
*/       12.207936        9.5227497        22.455666        358.76220  \ /*
*/       9.7445908        1.5427798        9.9435242        98.777146  \ /*
*/       8.5712092      -0.98585619        2.4692880        52.913858  \ /*
*/       10.750947        16.028405        21.898973        446.20257  \ /*
*/       8.8662471        6.7413723        10.228860        135.52841  \ /*
*/       7.9494832        3.3764254        3.6260652        67.391514  \ /*
*/       9.9188917        20.406505        17.886062        501.64223  \ /*
*/       8.3530514        10.128553        9.8759863        159.10682  \ /*
*/       7.5807963        6.4076414     -0.039221509        101.85158  )
 
 mat input gls4 = (/*
Deterministic term is const
Frequency is 4
*/      -2.6017744       -11.576394        103.59152       -396.96190  \ /*
*/      -1.9890882       -13.271645        124.01966       -460.71773  \ /*
*/      -1.6709987       -14.719768        140.06090       -515.29043  \ /*
*/      -2.5633008      -0.14334257       -2.9538673        14.146696  \ /*
*/      -1.9396597       0.29797905       -3.7835909        21.564794  \ /*
*/      -1.6154096       0.33501888       -2.5383989        13.526894  \ /*
*/       4.7455076      0.088391710        9.2387492       -4.5591302  \ /*
*/       3.1157636      -0.91730683        2.3154692       0.16499043  \ /*
*/       2.4101268      -0.98312773      -0.60507862        11.350452  \ /*
*/       3.9375752        2.0481440        4.6598029        8.3126654  \ /*
*/       2.7463841       0.22557615        2.1941347       0.12343295  \ /*
*/       2.2153354      -0.21665313        1.2369000      -0.57292537  \ /*
*/       3.4591416        13.786047       -56.194826        183.58524  \ /*
*/       2.5003904        10.751192       -52.532820        129.29991  \ /*
*/       2.0644772        9.6646754       -51.480407        116.29608  \ /*
Deterministic term is trend
Frequency is 4
*/      -3.4294600       -9.7579046        82.481958       -310.64282  \ /*
*/      -2.8745889       -10.209661        100.40630       -379.15980  \ /*
*/      -2.5895772       -10.773139        112.83004       -431.11607  \ /*
*/      -2.5648603      -0.72207957       -1.6630053        5.1855040  \ /*
*/      -1.9396038      -0.25439051       -1.2392589        9.0240309  \ /*
*/      -1.6157063      -0.11295406       -1.0298877        7.4431335  \ /*
*/       4.7319420       0.43404756        8.7469067        23.626831  \ /*
*/       3.1124684       -1.0782544        5.9701458        2.9993925  \ /*
*/       2.4105288       -1.2820898        4.6041636      -0.48669346  \ /*
*/       3.9359790        2.1304154        13.614065       -16.254418  \ /*
*/       2.7454947       0.34711481        4.7715588        5.4579053  \ /*
*/       2.2152630      -0.15978846        3.8089946       -1.9892152  \ /*
*/       4.4016081        20.771288       -121.55971        503.01758  \ /*
*/       3.3400212        17.111022       -131.87092        508.37418  \ /*
*/       2.8472804        15.794686       -137.36540        528.29785  \ /*
Deterministic term is seas
Frequency is 4
*/      -2.5990665       -12.047061        85.687973       -313.47376  \ /*
*/      -1.9838830       -13.928391        115.12810       -418.81782  \ /*
*/      -1.6671559       -15.262401        132.19935       -478.62541  \ /*
*/      -2.5974222       -12.235628        89.523079       -333.16689  \ /*
*/      -1.9841934       -13.936898        115.37681       -419.67485  \ /*
*/      -1.6677888       -15.228615        131.54416       -474.62520  \ /*
*/       4.7198851        26.092445       -76.364389        193.84426  \ /*
*/       3.0977204        22.073034       -68.871248        99.894313  \ /*
*/       2.3932811        20.125496       -59.807989        47.881951  \ /*
*/       3.8908411        32.625569       -95.725256        261.93441  \ /*
*/       2.7031125        27.816240       -96.678618        197.87319  \ /*
*/       2.1750663        25.431190       -90.365416        151.30750  \ /*
*/       3.4294484        34.789140       -100.53054        300.41199  \ /*
*/       2.4707113        29.916552       -103.76200        231.20254  \ /*
*/       2.0364976        27.593827       -100.52671        190.05771  \ /*
Deterministic term is strend
Frequency is 4
*/      -3.4240594       -10.555798        66.839623       -252.60934  \ /*
*/      -2.8694267       -10.939314        87.891982       -332.34765  \ /*
*/      -2.5859015       -11.344668        99.533099       -378.36706  \ /*
*/      -2.6002007       -12.738076        87.668208       -326.35103  \ /*
*/      -1.9843278       -14.491218        117.00689       -429.04365  \ /*
*/      -1.6677164       -15.740811        133.48634       -483.72754  \ /*
*/       4.7204106        26.102737       -70.902319        196.40945  \ /*
*/       3.0925571        22.430856       -70.177911        106.56658  \ /*
*/       2.3878910        20.555888       -63.130510        60.869493  \ /*
*/       3.8906697        33.381043       -90.309043        273.66357  \ /*
*/       2.7004043        28.523640       -94.299930        194.36907  \ /*
*/       2.1718384        26.098291       -89.188768        145.03976  \ /*
*/       4.3652945        41.380478       -148.50333        602.59639  \ /*
*/       3.3081417        35.649826       -161.41505        543.91920  \ /*
*/       2.8154926        33.249670       -166.76296        535.00317  \ /*
Deterministic term is mult
Frequency is 4
*/      -3.4217626       -13.179493        71.560370       -301.72588  \ /*
*/      -2.8684513       -13.120393        91.332760       -366.27019  \ /*
*/      -2.5849263       -13.352406        103.26190       -410.92894  \ /*
*/      -3.4250965       -13.019092        69.285867       -291.10874  \ /*
*/      -2.8703909       -13.034822        90.663643       -366.62196  \ /*
*/      -2.5865534       -13.274299        102.48787       -409.96937  \ /*
*/       8.6583190        54.666891       -108.73738        537.09139  \ /*
*/       6.5914446        47.231376       -173.72113        638.06151  \ /*
*/       5.6307484        44.497686       -199.79752        691.47889  \ /*
*/       7.5183670        64.231225       -183.85832        1080.1022  \ /*
*/       5.9550030        56.090770       -246.30303        1090.4206  \ /*
*/       5.2153158        52.660717       -268.92965        1100.1364  \ /*
*/       6.8682745        67.762763       -215.13830        1312.4729  \ /*
*/       5.5787523        59.621558       -273.76368        1277.0575  \ /*
*/       4.9624761        56.003649       -294.43467        1265.3690  )
 
 mat input ols12 = (/*
 Deterministic term is none
Frequency is 12
*/      -2.5675401        1.3094475       -2.3015686        9.8562761  \ /*
*/      -1.9417622        1.0719636      -0.51224492       0.58055632  \ /*
*/      -1.6175985       0.96263173       -1.0662905        5.0677654  \ /*
*/      -2.5664128        1.2292061       -1.2555395        6.2523839  \ /*
*/      -1.9407732       0.99387457       0.34360137       -1.5542122  \ /*
*/      -1.6170914       0.91633645      -0.54376168        4.0409648  \ /*
*/       4.7322746       -2.5629962       -1.1271589        13.311456  \ /*
*/       3.1095037       -2.0146195       -1.7868307        12.504621  \ /*
*/       2.4070460       -1.6520329       -2.0280066        12.957738  \ /*
*/       2.3456470       0.28491852       -1.0546447        7.1881190  \ /*
*/       1.8775094      -0.13830753       -1.2240437        5.5672143  \ /*
*/       1.6550286      -0.29355936       -1.0243531        4.1683709  \ /*
*/       2.2890432       0.40020356      -0.62816805        5.9506023  \ /*
*/       1.8481484     -0.080911444      -0.23332386       0.60589613  \ /*
*/       1.6369129      -0.21882533      -0.72160961        2.8142843  \ /*
Deterministic term is const
Frequency is 12
*/      -3.4307657        1.2029985       -2.1075018        4.2503217  \ /*
*/      -2.8610683        1.1901521      -0.84641464        1.6992724  \ /*
*/      -2.5674250        1.2274372       -1.8215069        7.6229947  \ /*
*/      -2.5658514        1.1654154       0.72217674       -3.4849549  \ /*
*/      -1.9400205       0.96591540        1.2559339       -5.9754130  \ /*
*/      -1.6158989       0.85108610       0.94671298       -3.8560344  \ /*
*/       4.7347231       -3.1429516        3.0630371       -6.3132977  \ /*
*/       3.1113755       -2.4513097        1.5869998       -2.5064560  \ /*
*/       2.4088408       -2.0257630        1.2244484       -1.9689176  \ /*
*/       2.3447725      0.025158169       0.98280235       -3.6657225  \ /*
*/       1.8780538      -0.34713990      -0.21384611        1.8730848  \ /*
*/       1.6550581      -0.45109894      -0.61094604        3.5495146  \ /*
*/       2.5342473       0.57016652      -0.90487963        10.131331  \ /*
*/       2.0695665     -0.019938837      -0.62626988        3.7168939  \ /*
*/       1.8454335      -0.23289325      -0.42314075        1.5754821  \ /*
Deterministic term is trend
Frequency is 12
*/      -3.9549846        1.0122235        3.4984414       -30.675131  \ /*
*/      -3.4083525        1.2863159       0.51188055       -6.9046369  \ /*
*/      -3.1255590        1.3222249       0.37964221       -4.9865777  \ /*
*/      -2.5662560        1.1300491       0.40339422       -3.0012104  \ /*
*/      -1.9411086       0.98045594      -0.15456280        2.9056916  \ /*
*/      -1.6165843       0.84099081      0.091448416        1.7285454  \ /*
*/       4.7319190       -3.4930734        1.4612942        13.170863  \ /*
*/       3.1100357       -2.6862001       0.70787752        7.7103220  \ /*
*/       2.4080743       -2.2397875        1.1979622        1.7845587  \ /*
*/       2.3445369      -0.11785483      -0.63097494        10.633739  \ /*
*/       1.8777836      -0.51559365     -0.067879271        3.9232476  \ /*
*/       1.6550991      -0.61494772      -0.33241107        5.1974024  \ /*
*/       2.7887716       0.98176025       -5.6804247        39.999899  \ /*
*/       2.3078427      0.057863104       -1.3829160        11.691416  \ /*
*/       2.0734750      -0.22504063      -0.44292362        4.0147672  \ /*
Deterministic term is seas
Frequency is 12
*/      -3.4305843        2.3483579       -3.6773595        5.3848125  \ /*
*/      -2.8622944        2.2297365       -2.8249245        8.4082381  \ /*
*/      -2.5677525        2.0958616       -2.4516818        10.745195  \ /*
*/      -3.4305505        2.3500403       -3.6558281        4.4179047  \ /*
*/      -2.8606026        2.0657875       0.15886793       -6.0454210  \ /*
*/      -2.5655316        1.9159787       0.87515889       -6.1630405  \ /*
*/       8.8059579       -10.372729        13.962657     -0.026354168  \ /*
*/       6.6439349       -8.9382092        7.0052185       0.87993246  \ /*
*/       5.6291142       -8.0390517        5.5872678       -5.0031789  \ /*
*/       5.1879385        1.8400227       0.83055765        28.431909  \ /*
*/       4.4703393       0.12985135       -1.4541350        15.043602  \ /*
*/       4.1108956      -0.55490497       -2.3373856        11.801312  \ /*
*/       5.0832624        2.4113652        2.7749309        15.916600  \ /*
*/       4.4050600       0.57786059      -0.43861369        8.9351938  \ /*
*/       4.0639292      -0.15341110       -1.9719314        10.047546  \ /*
Deterministic term is strend
Frequency is 12
*/      -3.9559888        2.3216257       -2.0198937       -4.5424273  \ /*
*/      -3.4088741        2.3214439      -0.85205799       0.88782690  \ /*
*/      -3.1255230        2.2260245       0.36176910       -1.8467394  \ /*
*/      -3.4282036        2.1868232       -1.0145889       -6.0207827  \ /*
*/      -2.8612384        2.1208895      -0.96760247        1.7471590  \ /*
*/      -2.5661124        1.9492966       0.19192629       -1.2086890  \ /*
*/       8.8084506       -11.014045        17.130188       -7.8454988  \ /*
*/       6.6445821       -9.2838275        7.5795355       0.43730924  \ /*
*/       5.6294078       -8.3078736        5.8984249       -5.4548148  \ /*
*/       5.1872176        1.6501231        1.3986009        22.779383  \ /*
*/       4.4699058     0.0051320780       -2.0261104        15.795071  \ /*
*/       4.1118809      -0.77106095      -0.95479506        1.6726229  \ /*
*/       5.3142769        2.6984230        2.4181515        19.104695  \ /*
*/       4.6223044       0.79321478       -2.1911885        17.976482  \ /*
*/       4.2759089     -0.099684413       -1.6781388        5.9888628  \ /*
Deterministic term is mult
Frequency is 12
*/      -3.9559128        2.1481761       -5.6798976        6.2843492  \ /*
*/      -3.4087024        2.1353073       -2.8526172        10.533851  \ /*
*/      -3.1262605        2.0826855       -1.8548174        11.965616  \ /*
*/      -3.9600056        2.3310207       -8.2349019        17.322549  \ /*
*/      -3.4120999        2.2749461       -4.6162299        17.309801  \ /*
*/      -3.1281091        2.1448211       -2.4136137        12.862881  \ /*
*/       12.214080       -14.953704        37.803806       -35.469902  \ /*
*/       9.7501738       -13.736069        21.923671       -48.117166  \ /*
*/       8.5753322       -12.681100        14.044172       -38.983239  \ /*
*/       7.9955643        5.5364164        9.6733272        66.803089  \ /*
*/       7.1481837        2.2480373        3.1483006        14.525138  \ /*
*/       6.7192513       0.80714794       0.59725141       -1.3134692  \ /*
*/       7.8673893        6.5760940        10.458514        64.373974  \ /*
*/       7.0632075        3.0625000        4.7586321        7.0607786  \ /*
*/       6.6546712        1.5835817       0.27545972        3.4407029  )

mat input gls12 = (/*
Deterministic term is const
Frequency is 12
*/      -2.6064538       -10.175621        107.06159       -402.02016  \ /*
*/      -1.9928579       -12.360973        127.92231       -477.93486  \ /*
*/      -1.6750552       -13.950681        143.98809       -538.39363  \ /*
*/      -2.5653690        1.0884361       -2.5664519        12.626518  \ /*
*/      -1.9399909       0.88741346      -0.83355204        5.3743644  \ /*
*/      -1.6159129       0.77305443      -0.56572100        4.4067282  \ /*
*/       4.7332408       -2.6292837       -1.6384555        15.680200  \ /*
*/       3.1100621       -2.0903709       -2.0046105        16.114836  \ /*
*/       2.4080405       -1.7772591      -0.77557285        7.3328665  \ /*
*/       2.3426785       0.42808389       -4.0327865        23.752202  \ /*
*/       1.8781229      -0.19242857      -0.86833969        5.3513218  \ /*
*/       1.6547904      -0.28778292       -1.6601140        8.7904756  \ /*
*/       2.2801347        3.5575784       -20.034165        55.871893  \ /*
*/       1.8413546        2.8052868       -18.320792        46.396554  \ /*
*/       1.6302099        2.5580081       -18.336290        46.626318  \ /*
Deterministic term is trend
Frequency is 12
*/      -3.4304315       -7.4282461        91.886777       -356.69718  \ /*
*/      -2.8781125       -8.4054363        104.26608       -402.18423  \ /*
*/      -2.5934679       -9.1778755        114.42316       -445.30801  \ /*
*/      -2.5646271       0.77224587       0.39600462       -2.0871711  \ /*
*/      -1.9396988       0.65851311        1.0901346       -4.1652911  \ /*
*/      -1.6155446       0.57221896        1.1731581       -4.6940397  \ /*
*/       4.7325103       -2.8332203        2.1462070        6.5769371  \ /*
*/       3.1102995       -2.2223455       0.39148271        7.1689207  \ /*
*/       2.4073859       -1.7890958       -1.0971038        13.233966  \ /*
*/       2.3441970       0.24263481      -0.16043800        7.1934005  \ /*
*/       1.8770934      -0.16308213       -1.4027531        11.669285  \ /*
*/       1.6550325      -0.34899254      -0.53525570        5.8125377  \ /*
*/       2.5458633        5.4555905       -48.924177        195.25074  \ /*
*/       2.0850750        4.6714437       -49.067748        194.37183  \ /*
*/       1.8627893        4.3530181       -48.705273        192.25109  \ /*
Deterministic term is seas
Frequency is 12
*/      -2.6032254       -10.565431        89.999290       -324.73774  \ /*
*/      -1.9900710       -12.720026        114.68568       -416.39375  \ /*
*/      -1.6723983       -14.264588        132.26462       -483.87790  \ /*
*/      -2.6033922       -10.571855        90.112070       -326.24338  \ /*
*/      -1.9882113       -12.875656        117.75139       -433.64868  \ /*
*/      -1.6700677       -14.477611        136.40506       -506.43205  \ /*
*/       4.7221492        22.174520       -129.90660        361.83506  \ /*
*/       3.0965730        20.490423       -109.26157        251.84211  \ /*
*/       2.3935497        19.062754       -90.431116        167.21374  \ /*
*/       2.3262363        19.097837       -44.878795        56.146641  \ /*
*/       1.8606476        16.958423       -38.289220        16.810367  \ /*
*/       1.6390210        15.815438       -33.022949       -9.2209065  \ /*
*/       2.2664664        20.290791       -51.106630        72.442815  \ /*
*/       1.8262331        18.238574       -47.567433        47.302576  \ /*
*/       1.6157800        17.136718       -43.799072        28.997292  \ /*
Deterministic term is strend
Frequency is 12
*/      -3.4262229       -7.9358366        72.645255       -264.86438  \ /*
*/      -2.8737864       -8.9013045        89.260973       -338.73215  \ /*
*/      -2.5904240       -9.5647527        99.205847       -380.26877  \ /*
*/      -2.6033096       -10.851371        91.946728       -337.23634  \ /*
*/      -1.9890582       -12.985181        116.53786       -426.26983  \ /*
*/      -1.6704546       -14.597529        135.88504       -502.82602  \ /*
*/       4.7219074        22.132648       -126.63915        356.32214  \ /*
*/       3.0964846        20.463844       -106.47170        239.52831  \ /*
*/       2.3940686        19.002652       -86.878466        147.08193  \ /*
*/       2.3260625        19.106758       -42.357516        44.817087  \ /*
*/       1.8601860        17.015625       -37.070350        11.463137  \ /*
*/       1.6382999        15.895696       -32.409380       -12.082042  \ /*
*/       2.5298922        22.052039       -73.866840        189.47025  \ /*
*/       2.0693866        19.910300       -71.399675        168.54082  \ /*
*/       1.8476919        18.791946       -68.234817        151.99540  \ /*
Deterministic term is mult
Frequency is 12
*/      -3.4255075       -10.916232        78.735441       -301.87954  \ /*
*/      -2.8735277       -11.421414        93.029268       -359.18202  \ /*
*/      -2.5897606       -11.918101        103.72760       -405.92011  \ /*
*/      -3.4306407       -10.619913        73.569174       -276.34133  \ /*
*/      -2.8764177       -11.285219        90.881955       -348.71474  \ /*
*/      -2.5927494       -11.781383        101.68756       -396.43024  \ /*
*/       8.6680306        41.175588       -206.52703        763.13099  \ /*
*/       6.5991203        39.046128       -242.56219        878.43064  \ /*
*/       5.6375963        38.436568       -261.67489        952.63835  \ /*
*/       5.2745442        46.189689       -199.46349        862.48093  \ /*
*/       4.6063816        43.236638       -217.73805        876.83087  \ /*
*/       4.2719648        41.957602       -226.62313        887.03499  \ /*
*/       5.1863965        47.703900       -211.37367        928.73124  \ /*
*/       4.5515347        44.753360       -231.17955        948.01106  \ /*
*/       4.2336770        43.432724       -240.63387        962.66299  )

if `gls'==0 {
	if      `c1'==1 {
		local nrow = 1
		}
	else if `c1'==2 {
		local nrow = 16
		}
	else if `c1'==4 {
		local nrow = 31
		}
	else if `c1'==3 {
		local nrow = 46
		}
	else if `c1'==5 {
		local nrow = 61
		}
	else if `c1'==6 {
		local nrow = 76
		}
	}
 else {
	if      `c1'==2 {
		local nrow = 1
		}
	else if `c1'==4 {
		local nrow = 16
		}
	else if `c1'==3 {
		local nrow = 31
		}
	else if `c1'==5 {
		local nrow = 46
		}
	else if `c1'==6 {
		local nrow = 61
		}
	}
if `freq' == 4 & `gls' == 0 {
	mat coefs2 = ols4[`nrow'...,1...]
	}
if `freq' == 4 & `gls' == 1 {
	mat coefs2 = gls4[`nrow'...,1...]
	}
if `freq' == 12 & `gls' == 0 {
	mat coefs2 = ols12[`nrow'...,1...]
	}
if `freq' == 12 & `gls' == 1 {
	mat coefs2 = gls12[`nrow'...,1...]
	}

	return matrix coefs1 coefs2
end
