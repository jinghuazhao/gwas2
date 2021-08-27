# Caprion example

The working directory as with variables is predefined for pilot project on Caprion platform, and we use the appropriate setup for the INTERVAL study.

## setup

```bash
export TMPDIR=${HPC_WORK}/work
export dir=~/rda/projects/Caprion_proteomics
export caprion=${dir}/pilot

. /etc/profile.d/modules.sh
module load ceuadmin/stata

  export full=(RCN3_442625488_VADQDGDSMATR RCN3_442666668_EVAKEFDQLTPEESQAR RCN3_All RCN3_DR)
  export abbrev=(RCN3_44262548~R RCN3_44266666~R RCN3_All RCN3_DR)
  for i in {0..3}
  do
    export y=${full[$i]}
    export trait=${abbrev[$i]}
    if [ ! -d ${caprion}/${y} ]; then mkdir ${caprion}/${y}; fi
    echo ${y} -- ${trait}
    stata-mp -b do ${caprion}/utils/gwas2.do
  done
  for i in {0..3}
  do
    export y=${full[$i]}
    export trait=${abbrev[$i]}
    echo ${y} -- ${trait}
    head -1 ${caprion}/${y}/interval.*.All.txt
    grep -w rs113886122 ${caprion}/${y}/interval.*.All.txt
  done
# _invn
  export abbrev=(RCN3_44262548~n RCN3_44266666~R RCN3_All_invn RCN3_DR_invn)
  for i in {0..3}
  do
    export y=${full[$i]}_invn
    export trait=${abbrev[$i]}
    if [ ! -d ${caprion}/${y} ]; then mkdir ${caprion}/${y}; fi
    echo ${y} -- ${trait}
    stata-mp -b do ${caprion}/utils/gwas2_invn.do
  done
```

Note that long (`full`) names will be abbreviated (`abbrev`) by Stata, whose algorithm does not always produce unique names. We also have versions for raw data and inverse normalised (_invn) data.

## execution

The call to the pipeline is made as follows,

```stata
local dir : env HPC_WORK
local caprion : env caprion
local y : env y
local trait : env trait
set maxvar 21000
insheet using "`caprion'/data2/phase2.dat", delim(" ") case clear
// To fix the glitch of SNPTEST on covariates
foreach x of varlist PC1-PC20 {
   replace `x'=`x'*10000
}
rename ID_1 id
format id %15.0g
merge 1:1 id using "`dir'/data/interval/interval_data"
gwas2 `trait', studyname(interval) dirgenefiles("`caprion'/data2") chr(19) /*
*/    covariates(agePulse bmi PC1 PC2 PC3 PC4 PC5 PC6 PC7 PC8 PC9 PC10 PC11 PC12 PC13 PC14 PC15 PC16 PC17 PC18 PC19 PC20) /*
*/    class(sexPulse ethnicity classification) dirwork("`caprion'/`y'") outfmt(txt)
```

where the `merge` command add a variable named `sex` (0=male, 1=female) as required by the Stata package. Our association model is

$$y \sim age + bmi + sex + ethnicity + classification + PC1 + \ldots + PC20 + genotype$$

Strangely as before, we need to scale up the principal components (PCs) in order for the model to converge under SNPTEST.
