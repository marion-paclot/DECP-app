# DECP-app

Depuis octobre 2018, les acheteurs publics ont l'obligation de publier les données relatives à leurs marchés de plus de 25.000€ au format "DECP" (données essentielles des marchés publics). 

Ce format prévoit un nombre restreint d'informations (peu nombreuses en comparaison des avis d'attribution du BOAMP) mais la couverture des marchés étant plus grande, cette source de données nous semble intéressante pour les acteurs des marchés publics.



Etapes de travail : 
- Création d'une base données (ok, sur serveur 2)
- Téléchargement des données disponibles (agrégat réalisé par Colin --> à faire) au format xml. Idéalement, juste de l'incrément. (ok)
- Parsing des xml pour création de 3 (actuellements) tables : Contrats, acheteurs, titulaires, qui sont sauvées en csv (ok). Manquent les modifications et les données de fonctionnement de la concession.
- Retour au bash, import dans la base de données (ok)
- Nécessité de charger la base sirene / siret la plus récente pour retraiter les noms des acheteurs et titulaires pour fournir un nom récent et homogène. Ainsi si une boite change de nom, on retrouvera son historique. (ok)
- Géolocalisation à l'adresse des établissements pour carto (ok)
- App Shiny pour visualiser les données. (structure avancée, besoin d'avis pour faire une travail utile)

