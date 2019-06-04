
library(shinydashboard)
ui <- dashboardPage(
  
  dashboardHeader(
    # Ligne d'entête
    title = "Marchés publics",
    # titleWidth = 350,
    tags$li(
      class = "dropdown",
      tags$a(href = "https://framaforms.org/donnees-essentielles-de-la-commande-publique-1559574654", 
             "Donner mon avis")),
    tags$li(
      class = "dropdown",
      tags$a(href = "https://github.com/marion-paclot/DECP-app/", 
             "Voir le code source"))
  ),
  
  dashboardSidebar(
    # width = 350,
    sidebarMenu(

      # Type de contrats
      menuItem("Type de contrat", tabName = 'tab_contrat', icon = icon("file-signature"),
               radioButtons("contrat", "", choices = c('Marché', 'Concession'), inline = TRUE),
               checkboxGroupInput("nature", "",
                                  choices = formesMarche, selected = formesMarche)),


      # Secteur d'activité - code CPV
      menuItem("Secteur d'activité", tabName = "tab_secteur", icon = icon("industry"),
               selectizeInput("activite", "", multiple = TRUE,
                              choices = unique(cpv$FR),
                              options = list(placeholder = 'Tous les secteurs')
               )
      ),

      # Acheteurs
      menuItem("Acheteurs", tabName = "tab_acheteur", icon = icon("institution"),
               selectizeInput("acheteur", "", multiple = TRUE,
                              choices = listeAcheteurs,
                              options = list(placeholder = 'Tous les acheteurs')
               )
      ),

      # Fournisseurs
      menuItem("Titulaires", tabName = "tab_titulaire", icon = icon("truck"),
               selectizeInput("titulaire", "", multiple = TRUE,
                              choices = listeTitulaires,
                              options = list(placeholder = 'Tous les titulaires')
               )
      ),

      # Date d'attribution du marché
      menuItem("Date d'attribution", tabName = "tab_date", icon = icon("calendar"),
               dateRangeInput('date', "", separator = '-',
                              language = 'fr', start = Sys.Date()-365),
               checkboxInput('dateNonRenseignee',
                             "Inclure les marchés avec date d'attribution inconnue", value = TRUE)
      ),

      # Lieu d'exécution du marché
      menuItem("Lieu d'exécution", tabName = "tab_zoneGeo", icon = icon("map-marker"),
               selectizeInput('zoneGeo', '', multiple = TRUE,
                              choices = departements$label,
                              options = list(placeholder = 'Tous les départements')
               ),
               checkboxInput('zoneGeoFrance', 'Inclure les marchés France entière', value = TRUE)
      ),

      # Durée du marché
      menuItem("Durée du marché", tabName = "tab_durée", icon = icon("hourglass-half"),
               sliderInput("duree", "En mois",
                           min = 0, max = 100, value = c(0, 100))
      ),

      # Effacer tous les filtres
      actionButton("remiseA0", "Effacer les filtres"),
      fluidPage(downloadButton("downloadData", "Télécharger la sélection", style="color: #fff; background-color: #337ab7; border-color: #2e6da4"))

      
    )
      ),
  
  dashboardBody(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$head(
      tags$style(HTML(
        ".tabbable ul li:nth-child(1) { float: left; }"
      ))
    ),
    tags$style(type = "text/css", "#map {height: calc(100vh - 110px) !important;}"),
    tabsetPanel(type = "tabs", id = 'onglets',
                
                tabPanel("Marchés détaillés",
                         br(),
                         fluidPage(dataTableOutput("donnees"))
                         ),
                tabPanel("Indicateurs",
                         br(),
                         fluidPage(h4('En construction'))
                ),
                tabPanel("Carte",
                         # br(),
                         leafletOutput("map"),
                         useShinyjs(),
                         hidden(
                           absolutePanel(id = "infos_menu_flottant", 
                                       class = "panel panel-default", 
                                       fixed = TRUE,
                                       draggable = TRUE, 
                                       top = "auto", 
                                       left = "auto", 
                                       right = 20, 
                                       bottom = 0,
                                       width = 200, 
                                       height = '80%',
                                       h4('Informations sur le lien acheteur-titulaire ? En construction')
                           )
                         )
                )
    ),
    div(style = "clear: both")
    
  )
)

