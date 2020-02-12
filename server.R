server = function(input, output, session) {
  
  updateSelectizeInput(session, 'acheteur', choices = listeAcheteurs, server = TRUE)
  updateSelectizeInput(session, 'titulaire', choices = listeTitulaires, server = TRUE)

   
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
     
      # Reformatage des input
     
      a = input$acheteur
      b = input$titulaire

      var_marche = input$contrat
      var_marche = ifelse(var_marche == 'Marché', 'marche', 'contrat_concession')
      
      var_nature = input$nature

      var_cpv = cpv$CODE[cpv$FR %in% input$activite]
      var_cpv = str_remove(substr(var_cpv, 1,8), "0+$")
      var_cpv = ifelse(length(var_cpv)>0, paste0(var_cpv, '%'), '')
      
      var_geo = input$zoneGeo
      var_geo = gsub('.* \\((.*)\\)', '%\\1%', var_geo)
      var_geo = ifelse(input$zoneGeoFrance, c(var_geo, '%FRANCE%'), var_geo)
      # Problème avec les dom. Si je tape 73, j'aurai aussi 973 à cause de la syntaxe
      # de stockage des codes postaux.
      
      var_dateDebut = min(input$date)
      var_dateFin = max(input$date)
      var_dateAbs = input$dateNonRenseignee

      var_dureeMin = input$duree[1]
      var_dureeMax = input$duree[2]

      # Je sélectionne un nomacheteur --> sirenacheteur
      # On ne procède pas en une fois pour capter le cas où un acheteur ou 
      # un titulaires est renseigné avec des noms différents
      var_idacheteur = ''
      if (! is.null(a)){
         requeteA = glue_sql("SELECT DISTINCT *
                              FROM liste_acheteurs 
                              WHERE nomsirenacheteur IN ({acheteurs*});",
                              acheteurs = a,
                              .con = con)
         var_idacheteur = dbGetQuery(con, requeteA)$idacheteur
         }

      
      # Idem titutaires
      var_idtitulaire = ''
      if (!is.null(b)){
         requeteT = glue_sql("SELECT DISTINCT * FROM liste_titulaires
                           WHERE nomsirentitulaire IN ({titulaires*});",
                           titulaires = b,
                           .con = con)
         var_idtitulaire <- dbGetQuery(con, requeteT)$idtitulaire
      }
      
      requete <- glue_sql(
         "SELECT
         c.idcontrat, c.uidcontrat, c.typecontrat,
         c.nature, c.objet, c.codecpv, c.nomcpv, c.procedure,
         c.lieuexectypecode, c.lieuexeccode, c.lieuexecnom, c.lieuexeccodedep,
         c.dureemois, c.datenotification, c.datepublicationdonnees,
         c.montant, c.formeprix
         from contrats c

         INNER JOIN (SELECT * FROM acheteurs WHERE idacheteur IN ({idAcheteurs*})) a
            ON a.uidContrat = c.uidContrat
         INNER JOIN (SELECT * FROM titulaires WHERE idtitulaire IN ({idTitulaires*})) t
            ON t.uidContrat = c.uidContrat

         WHERE typeContrat IN ({typecontrat*})
            AND lieuExecCodeDep LIKE ({typegeo*})
            AND ((dateNotification >= {debut*} AND dateNotification <= {fin*})
               OR (dateSignature >= {debut*} AND dateSignature <= {fin*})
               OR (dateNotification is {dateAbs*} OR dateSignature is {dateAbs*}))
            AND dureemois >= {dureeMin*}
            AND dureemois <= {dureeMax*}
         LIMIT 1200
         ;",
            idAcheteurs = var_idacheteur,
            idTitulaires = var_idtitulaire,
            typecontrat = var_marche,
            typenature = var_nature,
            typecpv = var_cpv,
            typegeo = var_geo,
            debut = var_dateDebut,
            fin = var_dateFin,
            dateAbs = var_dateAbs,
            dureeMin = var_dureeMin,
            dureeMax = var_dureeMax,
            .con = con
            )
      
      # Problème d'encodage
      #AND nomCPV LIKE any ({typecpv*})
      #AND nature LIKE ANY ({typenature*})

      requete = gsub(" WHERE (idacheteur|idtitulaire) IN \\(\\''\\)", '', requete)
      requete = gsub('OR \\(dateNotification .* is FALSE\\)', '', requete)
      requete = gsub('OR \\(dateNotification is TRUE OR dateSignature is TRUE\\)', 
                     'OR \\(dateNotification is NULL OR dateSignature is NULL\\)', requete)
      requete = gsub("AND .* \\((''|NULL)\\)",  '', requete)
      requete = gsub('\n|\t|\\s+', ' ', requete)

      selection <- dbGetQuery(con, requete)

      selection = set_utf8(selection)

      # Faire plus propre à un autre moment
      if (nrow(selection) == 0){
         return(data.frame("Vide" = "Pas de marchés correspondant à ces critères"))
      }
      
      listeuidContrat = unique(selection$uidcontrat)
      ##########################################################################
      # Retraitement des données relatives aux acheteurs et titulaires
      # On refait les requetes initiales car on s'appuie sur les uid de contrat
      requeteA <- glue_sql(
            "SELECT  DISTINCT * 
            FROM acheteurs WHERE uidContrat IN ({uidcontrat*}) ;",
            uidcontrat = listeuidContrat,
            .con = con)
      acheteurParMarche <- dbGetQuery(con, requeteA)
      acheteurParMarche = set_utf8(acheteurParMarche)
      acheteurParMarche$acheteur = paste0(acheteurParMarche$nomacheteur, ' (', acheteurParMarche$idacheteur, ')')
      acheteurParMarche = data.frame(acheteurParMarche[, c('uidcontrat', 'acheteur', 'idacheteur')])
    
      requeteT <- glue_sql(
         "SELECT  DISTINCT *
         FROM titulaires WHERE uidContrat IN ({uidcontrat*}) ;",
         uidcontrat = listeuidContrat,
         .con = con)
      resultatsT <- dbGetQuery(con, requeteT)
      resultatsT = set_utf8(resultatsT)
      resultatsT$codelabeltitulaire = paste0(resultatsT$denominationsocialetitulaire, ' (', resultatsT$idtitulaire, ')')
      titulaireParMarche = resultatsT %>%
         group_by(uidcontrat) %>%
         mutate(titulaire = paste0(codelabeltitulaire, collapse = "<br>"))
      titulaireParMarche = unique(titulaireParMarche)

      selection = merge(acheteurParMarche, selection, by = "uidcontrat", all = TRUE)
      selection = merge(titulaireParMarche[, c('uidcontrat', 'titulaire')], 
                        selection, by = "uidcontrat", all = TRUE)
      selection <<- selection

      #Allègement de la table
      selection$lieuexecnom = paste(selection$lieuexecnom, selection$lieuexeccode, 
                                   sep = "<br>")
      colnames(selection) = gsub('lieuexeccodedep', 'departement', colnames(selection))
      colRetrait = c('uidcontrat', 'idcontrat', 'typecontrat', 'lieuexectypecode', 
                   'lieuexeccode', 'datepublicationdonnees', 'idacheteur', 'idtitulaire')
      selection  = selection[, -which(colnames(selection)%in% colRetrait)]
      
      # Requête géographique
      
      requeteGeo = glue_sql("SELECT acheteurs.*, titulaires.*,
        s1.longitude as long_acheteur, s1.latitude as lat_acheteur,
        s2.longitude as long_titulaire, s2.latitude as lat_titulaire
        FROM acheteurs
        INNER JOIN titulaires
        ON acheteurs.uidcontrat = titulaires.uidcontrat
        INNER JOIN siret_geo s1
        ON acheteurs.idacheteur = s1.siret
        INNER JOIN siret_geo s2
        ON titulaires.idtitulaire = s2.siret
        WHERE acheteurs.uidcontrat IN ({uidcontrat*});",
         uidcontrat = listeuidContrat,
         .con = con)
      selectionGeo <- dbGetQuery(con, requeteGeo)
      
      return(list(selection = selection,
                selectionGeo = selectionGeo
                ))
   })
   
   
   
   ##############################################################################
   ############ FILTRAGE
   
   ## Tables de sortie
  
   output$donnees <- DT::renderDataTable({
      
      datatable(head(unique(filtrerDonnees()$selection),1000),
                colnames = c('Titulaire', 'Acheteur', 'Nature du contrat', 'Objet du contrat',
                'Code activité CPV','Nom activité', 'Type de procédure', 
                "Lieu d'exécution", "Département", "Durée du contrat", "Date de signature", 
                "Montant", "Forme de prix"),
                options = list(scrollX = TRUE, "pageLength" = 10, autoWidth = TRUE,
                               language = list(url = 'French.json'),
                               columnDefs = list(
                                  list(targets=c(0), visible = FALSE),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'nature')), visible=TRUE, width='100'),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'formeprix')), visible=TRUE, width='150'),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'objet')), visible=TRUE, width='350'),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'acheteur')), visible=TRUE, width='200'),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'titulaire')), visible=TRUE, width='250'),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'lieuexecnom')), visible=TRUE, width='100'),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'nomcpv')), visible=TRUE, width='200'),
                                  list(targets=c(which(colnames(filtrerDonnees()$selection) == 'procedure')), visible=TRUE, width='150')
                               )
                ),
                escape = FALSE)
      })
   
   # Carte
   output$map <- renderLeaflet({
    acheteursUniques = unique(filtrerDonnees()$selectionGeo)
    map = leaflet() %>%
      addTiles() %>%  
      setView(lng = 4, lat = 47.5,  zoom = 5)   
    if (length(acheteursUniques)>0){
      map = map %>%
        addCircleMarkers( lng = acheteursUniques$long_acheteur, 
                          lat = acheteursUniques$lat_acheteur, 
                          popup = acheteursUniques$acheteur,
                          layerId = acheteursUniques$idacheteur,
                          group = 'acheteurs',
                          radius = 4, color = "blue", opacity = 1
        )
    }
    return(map)
    
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
    filename = 'Donnees_DECP.xlsx',
    content = function(file) {
      write_xlsx(filtrerDonnees()$selection, 
                 # col_names = c('Titulaire', 'Acheteur', 'Nature du contrat', 'Objet du contrat',
                 #             'Code activité CPV','Nom activité', 'Type de procédure', 
                 #             "Lieu d'exécution", "Département", "Durée du contrat", "Date de signature", 
                 #             "Montant", "Forme de prix"), 
                 file)
    }
  )




}
