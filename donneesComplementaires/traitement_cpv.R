# Traiter la classification CPV
library(stringr)
classification = read.csv2('classification_cpv.csv', header = TRUE, stringsAsFactors = F)

classification$FR = gsub(';', ',', classification$FR)
classification$CODE_light = str_remove(gsub('(.*)-(.*)', '\\1', classification$CODE), "0+$")
classification$niveau = nchar(classification$CODE_light)
classification$genealogieCode = ''
classification$genealogieLabel = ''


for (i in 1:nrow(classification)){
  parents = c()
  for (j in 1:(nchar(classification$CODE_light[i])-1)){
    parent = substr(classification$CODE_light[i], 1, j)
    if (parent %in% unique(classification$CODE_light)){
      parents = c(parents, parent)
      
    }
  }
  print(parents)
  parentsLabels = classification$FR[match(parents, classification$CODE_light)]
  
  classification$genealogieCode[i] = paste(parents, collapse = '|')
  classification$genealogieLabel[i] = paste(parentsLabels, collapse = '|')
  
}

write.csv2(classification, 'genealogie_cpv.csv', row.names = FALSE, quote = TRUE)
