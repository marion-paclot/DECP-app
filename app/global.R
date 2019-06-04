# Chargement des données

library(shiny)
library(plyr)
library(plotly)
library(ggplot2)
library(scales)
library(data.table)
library(DT)
library(shinyjs)
library(stringr)
library(leaflet)
library(magrittr)

library(pool)
library(RPostgreSQL)
library(writexl)

options(shiny.sanitize.errors = FALSE)
options(digits = 4, scipen=999)
options(shiny.usecairo=T, shiny.reactlog = T, stringsAsFactors = FALSE)

# A appliquer à toutes les requêtes SQL pour gérer l'encodage
set_utf8 <- function(x) {
  chr = sapply(x, is.character)
  x[, chr] = lapply(x[, chr, drop = FALSE], `Encoding<-`, "UTF-8")
  Encoding(names(x)) = "UTF-8"
  x
}


# Chargement des données. Encodage UTF-8
departements = read.csv('donneesComplementaires//departement.csv', stringsAsFactors = F, 
                        colClasses = 'character')
departements$codeDep = gsub('^\\s+', '', formatC(departements$codeDep, width = 2, flag = '0'))
departements$label = sprintf('%s (%s)', departements$nomDepMin, departements$codeDep)

cpv = read.csv2('donneesComplementaires/genealogie_cpv.csv', 
                stringsAsFactors = F, colClasses = "character")
cpv$genealogieLabel = NULL


# Création de la connection PSQL
config = readLines('config.csv')

print("Starting new connection")

con <- dbPool(
 drv = dbDriver("PostgreSQL", max.con = 100),
 dbname = "decp",
 host = config[3],
 user = config[1],
 password = config[2],
 idleTimeout = 3600000
)

# drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname = "decp",
#                  host = config[3], port = 5432,
#                  user = config[1], password = config[2])
print("Done new connection")
#on.exit(dbDisconnect(con))
#lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

formesContratConcession = c("Concession de travaux", "Concession de service",
                            "Concession de service public", "Délégation de service public")
formesMarche = c("Marché", "Marché de partenariat", "Accord-cadre", 'Marché subséquent')


# Acheteurs et Titulaires

print("Liste acheteurs et titulaires")
acheteurs = dbGetQuery(con, "SELECT * from liste_acheteurs")
acheteurs = set_utf8(acheteurs)
listeAcheteurs = sort(unique(acheteurs$nomsirenacheteur))

titulaires = dbGetQuery(con, "SELECT * from liste_titulaires")
titulaires = set_utf8(titulaires)
listeTitulaires = sort(unique(titulaires$nomsirentitulaire))
print('Fin liste acheteurs et titulaires')



################### Vision globale

labelMultiLigne = function(chaine){
  chaine = paste(strwrap(chaine, width=40), collapse = '\n')
  return(chaine)
}

