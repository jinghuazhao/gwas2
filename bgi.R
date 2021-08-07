library(dplyr)
v <- read.delim("Variant.txt") %>%
     mutate(a1=if_else(allele1<allele2,allele1,allele2),
            a2=if_else(allele1<allele2,allele2,allele1),
            rsid=if_else(rsid==".",paste0("chr",chromosome,":",position,"_",a1,"_",a2),rsid)) %>%
     select(-a1,-a2)
l1 <- with(v,nchar(allele1))
l2 <- with(v,nchar(allele2))
indel <- l1+l2 > 2
id <- indel & (l1 > l2)
di <- indel & (l1 <= l2)
v <- within(v, {
       allele1[id] <- "I"
       allele2[id] <- "D"
       allele1[di] <- "D"
       allele2[di] <- "I"
     })
write.csv(v,"Variant.csv",row.names=FALSE)
