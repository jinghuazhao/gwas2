#!/usr/bin/bash

module load ceuadmin/stata
module load python/3.7
source ~/COVID-19/py37/bin/activate

export interval=~/rds/post_qc_data/interval/
export impute=${interval}/imputed/uk10k_1000g_b37
export snpstats=${interval}/reference_files/genetic/reference_files_genotyped_imputed/

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
{
# sample_info.dta.gz
  ln -sf ${impute}/interval.samples interval.sample
  sed '1,2d' interval.sample > sample_info.txt

  stata <<\ \ END
  //local dir : env impute
    insheet id idorder missing using sample_info.txt, delim(" ")
    format id %15.0g
    format idorder %15.0g
    gzsave sample_info, replace
  END
}

function Chunks()
{
# batches
  if [ -f Chunks15.txt ]; then rm Chunks15.txt; fi
  for chr in {1..22}
  do
     export chr=${chr}
     export start=$(awk 'NR==2 {print $2}' FS="," chr${chr}.bgen.csv)
     export end=$(awk 'END{print $2}' FS="," chr${chr}.bgen.csv)
     R --no-save -q <<\ \ \ \ \ END
       options(echo=FALSE)
       chr <- Sys.getenv("chr")
       start <- as.numeric(Sys.getenv("start"))
       end <- as.numeric(Sys.getenv("end"))
       require(GenomicRanges)
       gr <- GenomicRanges::GRanges(seqnames=chr,IRanges::IRanges(start,end))
       print(GenomicRanges::width(gr))
       tiles <- GenomicRanges::tile(gr, 15)
       region_list <- with(as.data.frame(tiles),cbind(seqnames,start,end))
       write.table(region_list,file="Chunks15.txt",append=TRUE,sep="\t",col.names=FALSE,quote=FALSE)
     END
done
R --no-save -q <<END
   Chunk15 <- read.table("Chunks15.txt",col.names=c("Sub","CHR","P0","P1"))[c("CHR","Sub","P0","P1")]
   head(Chunk15)
   library(foreign)
   write.dta(chunk15,file="Chunks15.dta")
END
}

function SNPinfo()
{
# SNPinfo.dta.gz
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
   if(substr($2,1,4)=="Affx") rsid=snpid; else rsid=$2
   print chr,rsid,a1,a2
}' ${interval}/genotype/affy_ukbiobank_array/genotyped/interval_qced_24.8.18.bim | \
sort -k2,2 > interval.chipsnps

(
  join -12 <(sort -k2,2 interval.snpstats) <(cut -d' ' -f2 interval.chipsnps) | \
  awk '{print $0, 2}'
  join -v1 -12 <(sort -k2,2 interval.snpstats) <(cut -d' ' -f2 interval.chipsnps) | \
  awk '{print $0, 0}'
) > SNPinfo.txt

stata <<END
  insheet rsid chr allele1 allele2 info type using SNPinfo.txt, delim(" ")
  drop allele1 allele2
  gzsave SNPinfo, replace
END
)
