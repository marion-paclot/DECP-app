server = function(input, output, session) {
  
  # updateSelectizeInput(session, 'acheteur', choices = listeAcheteurs, server = TRUE)
  # updateSelectizeInput(session, 'titulaire', choices = listeTitulaires, server = TRUE)
  
  # Remise à 0 des filtres
  observeEvent(input$remiseA0, priority = 100, {
    updateSelectizeInput(session, "activite", choices = unique(cpv$FR))
    updateSelectizeInput(session, "acheteur", choices = listeAcheteurs)
    updateSelectizeInput(session, "titulaire", choices = listeTitulaires)
    updateDateRangeInput(session, 'date', start = Sys.Date()-365)
    updateCheckboxInput(session, 'dateNonRenseignee', value = TRUE)
    updateSelectizeInput(session, 'zoneGeo', choices = departements$label)
    updateCheckboxInput(session, 'zoneGeoFrance', value = TRUE)
    updateSliderInput(session, "duree", value = c(0, 100))
  })
  
  observeEvent(input$contrat, {
    if (input$contrat == 'Marché'){
      updateCheckboxGroupInput(session, "nature", 
                               choices = formesMarche, selected = formesMarche)
    }
    
    if (input$contrat == 'Concession'){
      updateCheckboxGroupInput(session, "nature", 
                           choices = formesContratConcession, selected = formesContratConcession)
    }
    
  })

    
  filtrerDonnees = reactive({
    #return(data.frame(test = c('a', 'b'), bibi = c('t', 't')))
    if (input$contrat == 'Marché'){
      requeteBase = "SELECT idcontrat, uidcontrat, typecontrat, nature, objet, 
                      codecpv, nomcpv, procedure, 
                      lieuexectypecode, lieuexeccode, lieuexecnom, lieuexeccodedep,
                      dureemois, datenotification, datepublicationdonnees, 
                      montant, formeprix from contrats 
                      WHERE typecontrat = 'marche'"
    }
    
    if (input$contrat == 'Concession'){
      requeteBase = "SELECT idcontrat, uidcontrat, typecontrat, nature, objet, 
                      procedure, 
                      lieuexectypecode, lieuexeccode, lieuexecnom, lieuexeccodedep, 
                      dureemois, dateSignature, datePublicationDonnees, 
                      dateDebutExecution, valeurGlobale, montantSubventionPublique
                      from contrats WHERE typecontrat = 'contrat-concession'"
    }
    requete = requeteBase
    
    # Filtre de type de marche
    if (length(input$nature)>0 & length(input$nature) < 4){
      nature = paste(paste0("'", input$nature, "'"), collapse = ', ')
      requete_ajout = sprintf("AND nature LIKE any (array[%s])", nature)
      requete = paste(requete, requete_ajout)
      print(requete)
    }

    # Filtre de secteur
    if (length(input$activite)>0 & input$contrat == 'Marché'){
      code = cpv$CODE[cpv$FR %in% input$activite]
      code = str_remove(substr(code, 1,8), "0+$")
      code = paste(paste0("'", code, '%', "'"), collapse = ', ')

      requete_ajout = sprintf("AND codeCPV LIKE any (array[%s])", code)
      requete = paste(requete, requete_ajout)
    }


    # Filtre géo, par défaut tout, sinon filtrage
    listeDep = departements$codeDep[departements$label %in% input$zoneGeo]
    if (length(input$zoneGeo) == 0){
      listeDep = departements$codeDep
    }
    listeDep = c(listeDep, c('FRANCE')[input$zoneGeoFrance])

    if (length(listeDep) != (length(departements$codeDep) +1)){
      listeDep = paste(paste0("'", listeDep, '', "'"), collapse = ', ')
      requete_ajout = sprintf("AND lieuExecCodeDep IN (%s)", listeDep)
      requete = paste(requete, requete_ajout)
    }

    # Filtre d'acheteurs et de titulaires
    uidContrat1 = c()
    uidContrat2 = c()
    if (length(input$acheteur)>0){
      sirenAcheteurs = acheteurs$sirenacheteur[acheteurs$nomsirenacheteur %in% input$acheteur]
      listeA = paste(paste0("'", sirenAcheteurs, '', "'"), collapse = ', ')
      # Requête intermédiaire
      requeteAcheteurs =  sprintf("SELECT uidContrat FROM acheteurs WHERE sirenAcheteur IN (%s)", listeA)
      uidContrat1 <- dbGetQuery(con, requeteAcheteurs)
      uidContrat1 = set_utf8(uidContrat1)$uidcontrat
    }
    if (length(input$titulaire)>0){
      sirenTitulaires = titulaires$sirentitulaire[titulaires$nomsirentitulaire %in% input$titulaire]
      listeT = paste(paste0("'", sirenTitulaires, '', "'"), collapse = ', ')
      print(listeT)
      # Requête intermédiaire
      requeteTitulaires =  sprintf("SELECT uidContrat FROM titulaires WHERE sirenTitulaire IN (%s)", listeT)
      uidContrat2 <- dbGetQuery(con, requeteTitulaires)
      uidContrat2 = set_utf8(uidContrat2)$uidcontrat
    }
    if (length(uidContrat1)>0 | length(uidContrat2) >0){
      if (length(uidContrat1)>0 & length(uidContrat2) >0){
        uidContrat = intersect(uidContrat1, uidContrat1)
      }
      else {
        uidContrat = c(uidContrat1, uidContrat2)
      }
      listeUid = paste(paste0("'", uidContrat, '', "'"), collapse = ', ')
      requete_ajout = sprintf("AND uidContrat IN (%s)", listeUid)
      requete = paste(requete, requete_ajout)
    }

    # Filtre de date
    dateDebut = min(input$date)
    dateFin = max(input$date)

    if (dateDebut != Sys.Date()-365 | dateFin != Sys.Date() | !input$dateNonRenseignee){
      requete_ajout = sprintf("AND ((dateNotification >= '%s' AND dateNotification <= '%s')
                                    OR
                                    (dateSignature >= '%s' AND dateSignature <='%s')
                                    OR (dateNotification is null OR dateSignature is null))",
                              dateDebut, dateFin, dateDebut, dateFin)
      if(!input$dateNonRenseignee){
        requete_ajout = gsub('OR (dateNotification is null OR dateSignature is null)', '', requete_ajout)
      }
      requete = paste(requete, requete_ajout)
    }

    # Filtre de durée
    if (input$duree[1] != 0 | input$duree[2] != 100){
      requete_ajout = sprintf("AND dureemois >= %s AND dureemois <= %s",
                              input$duree[1], input$duree[2])
      requete = paste(requete, requete_ajout)

    }

    if (requeteBase == requete){
      requete = paste(requeteBase, 'LIMIT 1000')
    }
    requete = gsub('\n|\t', '', requete)
    
    selection <- dbGetQuery(con, requete)
    # Faire plus propre à un autre moment
    if (nrow(selection) == 0){
      return(data.frame("Vide" = "Pas de marchés correspondant à ces critères"))
    }

    selection = set_utf8(selection)
    listeUid = paste(paste0("'", selection$uidcontrat, '', "'"), collapse = ', ')
    
    # Jointure avec titulaires
    requeteT = sprintf("SELECT DISTINCT uidcontrat, sirentitulaire, nomsirentitulaire, idtitulaire FROM titulaires WHERE uidContrat IN (%s)", 
                        listeUid)
    requeteT <- dbGetQuery(con, requeteT)
    requeteT = set_utf8(requeteT)
    
    # On aggrège les données relatives aux titulaires d'un marché
    requeteT$codelabeltitulaire = paste(requeteT$nomsirentitulaire, ' (', requeteT$sirentitulaire, ')')
    titulaireParMarche = requeteT %>%
      group_by(uidcontrat) %>%
      mutate(titulaire = paste0(codelabeltitulaire, collapse = "<br>"))
    titulaireParMarche = data.frame(titulaireParMarche[, c('uidcontrat', 'titulaire')])
    titulaireParMarche = unique(titulaireParMarche)
    selection = merge(titulaireParMarche, selection, by = "uidcontrat", all = TRUE)
    
    # Jointure avec acheteurs
    requeteA = sprintf("SELECT DISTINCT uidcontrat, sirenacheteur, nomsirenacheteur, idacheteur FROM acheteurs WHERE uidContrat IN (%s)", 
                       listeUid)
    requeteA <- dbGetQuery(con, requeteA)
    requeteA = set_utf8(requeteA)
    requeteA$acheteur = paste(requeteA$nomsirenacheteur, ' (', requeteA$sirenacheteur, ')')
    acheteurParMarche = data.frame(requeteA[, c('uidcontrat', 'acheteur', 'idacheteur')])
    selection = merge(acheteurParMarche, selection, by = "uidcontrat", all = TRUE)
    
    #Allègement de la table
    selection$lieuexecnom = paste(selection$lieuexecnom, selection$lieuexeccode, 
                                   sep = "<br>")
    #selection$lieuexectypecode,
    colnames(selection) = gsub('lieuexeccodedep', 'departement', colnames(selection))
    colRetrait = c('uidcontrat', 'idcontrat', 'typecontrat', 'lieuexectypecode', 
                   'lieuexeccode', 'datepublicationdonnees', 'idacheteur', 'idtitulaire')
    selection_sauvegarde = selection
    uidContrat <<- paste(paste0("'", unique(selection$uidcontrat), '', "'"), collapse = ', ')
    
    selection  = selection[, -which(colnames(selection)%in% colRetrait)]
    
    # Requête géographique
    requeteGeo = sprintf("SELECT acheteurs.*, titulaires.*, 
        s1.longitude as long_acheteur, s1.latitude as lat_acheteur,
        s2.longitude as long_titulaire, s2.latitude as lat_titulaire
        FROM acheteurs
        INNER JOIN titulaires
        ON acheteurs.uidcontrat = titulaires.uidcontrat
        INNER JOIN siret_geo s1
        ON acheteurs.idacheteur = s1.siret 
        INNER JOIN siret_geo s2
        ON titulaires.idtitulaire = s2.siret 
        WHERE acheteurs.uidcontrat IN (%s);", uidContrat)
    requeteGeo = gsub('\n|\t', '', requeteGeo)
    selectionGeo <- dbGetQuery(con, requeteGeo)

    
    return(list(selection = selection, 
                selectionGeo = selectionGeo))
  })
  


  ##############################################################################
  ############ FILTRAGE
  
  ## Tables de sortie
  output$donnees <- DT::renderDataTable(
    filtrerDonnees()$selection,
    options = list(scrollX = TRUE, "pageLength" = 10, autoWidth = TRUE,
                   language = list(url = 'French.json'),
                   columnDefs = list(
                     list(targets=c(0), visible = FALSE),
                     list(targets=c(which(colnames(filtrerDonnees()) == 'objet')), visible=TRUE, width='350'),
                     list(targets=c(which(colnames(filtrerDonnees()) == 'acheteur')), visible=TRUE, width='250'),
                     list(targets=c(which(colnames(filtrerDonnees()) == 'titulaire')), visible=TRUE, width='250'),
                     list(targets=c(which(colnames(filtrerDonnees()) == 'lieuexecnom')), visible=TRUE, width='100'),
                     list(targets=c(which(colnames(filtrerDonnees()) == 'nomcpv')), visible=TRUE, width='200'),
                     list(targets=c(which(colnames(filtrerDonnees()) == 'procedure')), visible=TRUE, width='150')
                   )
                   ),
    escape = FALSE
  )
  
  # Carte
  output$map <- renderLeaflet({
    acheteursUniques = unique(filtrerDonnees()$selectionGeo)
    # print(head(acheteursUniques))
    leaflet() %>%
      addTiles() %>%  
      setView(lng = 4, lat = 47.5,  zoom = 5)   %>%
    addCircleMarkers( lng = acheteursUniques$long_acheteur, 
                      lat = acheteursUniques$lat_acheteur, 
                      popup = acheteursUniques$acheteur,
                      layerId = acheteursUniques$idacheteur,
                      group = 'acheteurs',
                      radius = 4, color = "blue", opacity = 1
    )
    
  })
  
  ## Observe mouse clicks and add circles
  observeEvent(input$map_marker_click, {
    click <- input$map_marker_click
    
    print(click)
    
    if (click$group == 'acheteurs'){
      shinyjs::hide(id = "infos_menu_flottant")
      
      titulairesAssocies = subset(filtrerDonnees()$selectionGeo, idacheteur == click$id)
      
      map = leafletProxy('map') %>% 
        clearGroup("titulaires") %>% # Retrait des titulaires déjà présents
        clearGroup("titulaires_lignes") 
      for (i in 1:nrow(titulairesAssocies)){
        map %>% addPolylines(lng = as.numeric(titulairesAssocies[i, c('long_acheteur', 'long_titulaire')]), 
                             lat = as.numeric(titulairesAssocies[i, c('lat_acheteur', 'lat_titulaire')]), 
                             group = "titulaires_lignes", 
                             weight = 1, opacity = 1) 
      }
      map %>% 
        addCircleMarkers(
          lng = titulairesAssocies$long_titulaire, 
          lat = titulairesAssocies$lat_titulaire, 
          group = "titulaires", radius = 2, color='red', opacity=1,
          popup = paste("Titulaire : ", titulairesAssocies$idacheteur,
                "</br> Plus d'infos : à définir")
        )
      
    }
    
    if (click$group == 'titulaires'){
      shinyjs::show(id = "infos_menu_flottant")
      
    }

  })
 
  ## Charger les données
  output$downloadData <- downloadHandler(
    filename = function() {
     'Donnees_DECP.xlsx'
    },
    content = function(file) {
      wb <- loadWorkbook(file, create = TRUE)
      
      createSheet(wb,"DECP")
      writeWorksheet(wb,data = filtrerDonnees()$selection, sheet = "DECP")
      setColumnWidth(wb, sheet = "DECP", column = 1:ncol(filtrerDonnees()$selection), width = -1)
      
      saveWorkbook(wb)
    },
    contentType="application/xlsx"
  )
  



}
