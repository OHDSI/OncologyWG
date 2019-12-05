
txt_list <- c("data_clinical_patient", "data_clinical_sample", 
              "data_CNA", "data_fusions", "data_mutations_extended", "data_mutations_mskcc")
length(txt_list) # 6

txt="data_clinical_patient"
for(txt in txt_list){
  read_path <- paste0('./', txt, '.txt')
  txt_table <- read.table(read_path, header=TRUE, sep='\t')
  dim <- paste0(as.character(dim(txt_table))[1], ', ', as.character(dim(txt_table))[2])
  print(paste0('Dimension of ', txt, ': ', dim))
  write_path <- paste0('./Summary/', txt, '.csv')
  write.csv(txt_table, write_path)
}





