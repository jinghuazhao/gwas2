# gwas2

gwas2 utitlties

## requirement

1. gwas2.ado; gwas2.batch; gwas2.hlp

2. snptest_v2.5.4-beta3

3. Chunks_15.dta

4. Recode indels into I/D format to save memory use by Stata

5. Prepare the data files + four essentials files as follows.

   * Chromosome files: chr{1..23}.bgen/.bgen.bgi, where .bgi is index file created using command such as `bgenix -g chr9.bgen -ndex`.
   * sample_info.dta.gz (idorder is the samples order in BGEN file)
     ```
     id   idorder   missing
     OMICF10026         1         0
     OMICF10064         2         0
     ...
     ```
   * SNPinfo.dta.gz (type: 0=imputed; 2=genotyped and in reference panel as well; 3=genotyped and not in ref panel)
     ```
     chr          rsid      info   type
       1   rs367896724   .742969      0
       1   rs555500075   .727742      0
        ...
     ```
   * Fenland-OMICS.sample (SNPTEST sample file, Fenland-OMICS is the studyname; change it to your own)
     ```
     ID_1 ID_2 missing
     0 0 0
     OMICF10026 OMICF10026 0
     OMICF10064 OMICF10064 0
     ...
     ```

   * Chunks_15.dta (file list the BP boundaries of chunks in each chromosome. 15 chunks per chromosome, and try to make same number of markers in each chunk in a chromosome)
     ```
     CHR   Sub         P0          P1
      1     1       10177    14405380
      1     2    14405461    28708996
      1     3    28709005    44198392
      ....
      1    15   235984335   249240543
      2     1       10180    14003357
      2     2    14003460    30090194
      2     3    30090341    43676939
      ...
      2    15   229415780   243188367
      3     1       60162    10466985
     ```
