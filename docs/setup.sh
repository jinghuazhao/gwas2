#!/usr/bin/bash

module load ceuadmin/stata
module load python/3.7
source ~/COVID-19/py37/bin/activate

export interval=~/rds/post_qc_data/interval/
export impute=${interval}/imputed/uk10k_1000g_b37
export snpstats=${interval}/reference_files/genetic/reference_files_genotyped_imputed/
export X=/rds/project/jmmh2/rds-jmmh2-projects/covid/ace2/interval_genetic_data/interval_imputed_data
export INTERVALdata=~/COVID-19/HGI/20210317/INTERVALdata_17MAR2021.csv
export OmicsMap=~/COVID-19/HGI/20210317/INTERVAL_OmicsMap_20210317.csv
export TMPDIR=${HPC_WORK}/work

function bgen_bgi()
{
  for chr in {1..22}
  do
    echo Chromosome ${chr}
    ln -sf ${impute}/impute_${chr}_interval.bgen chr${chr}.bgen
    cp ${impute}/impute_${chr}_interval.bgen.bgi chr${chr}.bgen.bgi
    sqlite3 chr${chr}.bgen.bgi < bgi.sql
    R --no-save -q < bgi.R
    awk -v FS="," '{print "chr"$1":"$2"_"$5"_"$6,$5,$6}' Variant.csv > chr${chr}.variant
    export csvfile=chr${chr}.bgen.csv
    python bgi.py --bgi chr${chr}.bgen.bgi
  done
}

function sample_info()
# sample_info.dta.gz
{
  ln -sf ${impute}/interval.samples interval.sample
  sed '1,2d' interval.sample > sample_info.txt
  stata <<\ \ END
    insheet id idorder missing using sample_info.txt, delim(" ")
    format id %15.0g
    format idorder %15.0g
    gzsave sample_info, replace
    //
    local d : env INTERVALdata
    insheet using "`d'", case clear comma
    keep identifier sexPulse
    rename sexPulse sex
    replace sex=sex-1
    save interval_data, replace
    local om : env OmicsMap
    insheet using "`om'", case clear comma
    keep identifier Affymetrix_gw~l
    rename Affymetrix_gw~l id
    merge 1:1 identifier using interval_data
    drop if _merge!=3 | id==.
    drop identifier _merge
    format id %15.0g
    save interval_data, replace
  END
  rm sample_info.txt
}

function byvariants()
{
  export N=$(($(sed '1d' chr${chr}.bgen.csv| wc -l)/15+1))
  sed '1d' chr${chr}.bgen.csv | split - -d -l ${N} chr${chr}.
  for region in {00..14}
  do
     export start=$(awk 'NR==1 {print $2}' FS="," chr${chr}.${region})
     export end=$(awk 'END{print $2}' FS="," chr${chr}.${region})
     export sub=$(expr ${region} + 1)
     echo ${chr} ${sub} ${start} ${end}
  done
  rm chr${chr}.??
}

functino txt2dta_by_stata()
{
  stata -q <<\ \ END
    insheet CHR Sub P0 P1 using Chunks_15.txt, delim(" ") case clear
    l in 1/10
    format P0 %15.0g
    format P1 %15.0g
    save Chunks_15, replace
  END
}

function Chunks()
# Chunks_15.dta
{
  if [ -f Chunks_15.txt ]; then rm Chunks_15.txt; fi
  (
    for chr in {1..22}
    do
    #  byregion
       byvariants
    done
  ) > Chunks_15.txt
  txt2dta_by_stata
}

function SNPinfo()
# SNPinfo.dta.gz
{
  (
    for chr in {1..22}
    do
      cut -f1,3-6,19 $snpstats/impute_${chr}_interval.snpstats | \
      awk 'NR>1{
       chr=$2+0
       pos=$3
       a1=$4
       a2=$5
       if(a1>a2) snpid="chr"chr":"pos"_"a2"_"a1;
       else snpid="chr"chr":"pos"_"a1"_"a2
       if($1==".") rsid=snpid; else rsid=$1
       print chr,rsid,a1,a2,$6
      }'
    done
  ) | sort -k1,1 > interval.snpstats
  awk '
  {
     chr=$1
     pos=$4
     a1=$5
     a2=$6
     if(a1>a2) snpid="chr"chr":"pos"_"a2"_"a1;
     else snpid="chr"chr":"pos"_"a1"_"a2
     if (substr($2,1,4)=="Affx") rsid=snpid; else rsid=$2
     print chr,rsid,a1,a2
  }' ${interval}/genotype/affy_ukbiobank_array/genotyped/interval_qced_24.8.18.bim | \
  sort -k2,2 > interval.chipsnps
  (
    join -12 <(sort -k2,2 interval.snpstats) <(cut -d' ' -f2 interval.chipsnps) | \
    awk '{print $0, 2}'
    join -v1 -12 <(sort -k2,2 interval.snpstats) <(cut -d' ' -f2 interval.chipsnps) | \
    awk '{print $0, 0}'
  ) > SNPinfo.txt
  stata <<\ \ END
    local dir : env HPC_WORK
    insheet rsid chr allele1 allele2 info type using "`dir'/data/interval/SNPinfo.txt", delim(" ")
    drop allele1 allele2
    gzsave SNPinfo, replace
  END
)

function tidy_up()
{
 rm SNPinfo.txt
 rm interval.snpstats
 rm Variant.txt metadata.txt
 rm interval.chipsnps
 rm chr*bgen*csv
 rm Chunks_15.txt
}

# --- legacy code --- #

function byregion()
{
  export chr=${chr}
  export start=$(awk 'NR==2 {print $2}' FS="," chr${chr}.bgen.csv)
  export end=$(awk 'END{print $2}' FS="," chr${chr}.bgen.csv)
  R --no-save -q <<\ \ END
    options(echo=FALSE)
    chr <- Sys.getenv("chr")
    start <- as.integer(Sys.getenv("start"))
    end <- as.integer(Sys.getenv("end"))
    require(GenomicRanges)
    gr <- GenomicRanges::GRanges(seqnames=chr,IRanges::IRanges(start,end))
    print(GenomicRanges::width(gr))
    tiles <- GenomicRanges::tile(gr, 15)
    region_list <- with(as.data.frame(tiles),cbind(seqnames,start,end))
    write.table(region_list,file="Chunks_15.txt",append=TRUE,sep="\t",col.names=FALSE,quote=FALSE)
  END
}

function txt2dta_by_R()
{
  R --no-save -q <<\ \ END
    vars <- c("CHR","Sub","P0","P1")
    Chunks_15 <- read.table("Chunks_15.txt",col.names=c("Sub","CHR","P0","P1"))[vars]
    head(Chunks_15)
    library(foreign)
    write.dta(Chunks_15,file="Chunks_15.dta")
  END
}
