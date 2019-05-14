# DECP-app

Etapes de travail : 
- Création d'une base données (ok, sur serveur perso Digital Océan)
- Téléchargement des données disponibles (agrégat réalisé par Colin --> à faire) au format xml. Idéalement, juste de l'incrément. Sinon j'ai un code qui tourne (uniquement files.data.gouv et aife)
- Parsing des xml pour création de 3 (actuellements) tables : Contrats, acheteurs, titulaires, qui sont sauvées en csv (ok). Manquent les modifications et les données de fonctionnement de la concession.
- Retour au bash, import dans la base de données (ok)

- Nécessité de charger la base sirene / siret la plus récente pour retraiter les noms des acheteurs et titulaires pour fournir un nom récent et homogène. Ainsi si une boite change de nom, on retrouvera son historique.
- App Shiny pour visualiser les données. (bien avancée mais pas touché depuis 2 mois)

Dans les urgences : 
- Gérer la base sirene pour le renommage de acheteurs et titulaires
- Interfacer la bd avec le site shiny
- Prendre en compte les remarques du groupe DECP
