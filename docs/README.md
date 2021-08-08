# gwas2

gwas2 utitlties to faciliate `gwas2.ado`, `gwas2.batch` and `gwas2.hlp` which rely on `snptest_v2.5.4-beta3`.

The driver program is [setup.sh](setup.sh), which calls [bgi.sql](bgi.sql), [bgi.R](bgi.R) and [bgi.py](bgi.py).

## Data and meta-data

### Data

Chromosome files: `chr{1..23}.bgen/.bgen.bgi`, where .bgi is index file created using command such as `bgenix -g chr9.bgen -index`.

As the genotype data requires indels recoded in I/D format to save memory use by Stata, these utilities work on `.bgi` file instead. On execution, `chr{1.23}.bgen.csv` are generated which contains the SNP information in text format. Note however, the driver program for INTERVAL study does not include chromosome X.

###  Meta-data

There are four eseential files:

   1. `sample_info.dta.gz` (idorder is the samples order in BGEN file)

     ```
     id   idorder   missing
     OMICF10026         1         0
     OMICF10064         2         0
     ...
     ```

   2. `SNPinfo.dta.gz` (type: 0=imputed; 2=genotyped and in reference panel as well; 3=genotyped and not in ref panel)

     ```
     chr          rsid      info   type
       1   rs367896724   .742969      0
       1   rs555500075   .727742      0
        ...
     ```

   3. `Fenland-OMICS.sample` (SNPTEST sample file, Fenland-OMICS is the studyname; change it to your own)


     ```
     ID_1 ID_2 missing
     0 0 0
     OMICF10026 OMICF10026 0
     OMICF10064 OMICF10064 0
     ...
     ```

   4. `Chunks_15.dta` (file list the BP boundaries of chunks in each chromosome. 15 chunks per chromosome, and try to make same number of markers in each chunk in a chromosome)

     ```
     CHR   Sub         P0          P1
      1     1       10177    14405380
      1     2    14405461    28708996
      1     3    28709005    44198392
      ...
      1    15   235984335   249240543
      2     1       10180    14003357
      2     2    14003460    30090194
      2     3    30090341    43676939
      ...
      2    15   229415780   243188367
      3     1       60162    10466985
     ```
