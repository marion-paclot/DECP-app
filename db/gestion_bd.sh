# Tout ce qu'il faut charger avant
# Prérequis : Python3, R, R shiny, PostgresQL

apt-get install libssl-dev
apt-get install gunzip
apt install csvkit

# sudo apt-get install libpq-dev
# apt install jupyter
# pip install Flask-SQLAlchemy

# pip3 install pandas
# pip3 install requests
# pip3 install SQLAlchemy
# pip3 install psycopg2
# pip3 install psycopg2-binary




# Se mettre dans le dossier DECP
cd /

#########################################################
# Création de la base de données -- à faire une fois
sudo -u postgres psql -c "DROP DATABASE IF EXISTS decp;"
sudo -u postgres psql -c "CREATE DATABASE decp;"
sudo -u postgres psql -c "ALTER DATABASE decp SET datestyle TO ""ISO, DMY"";"
sudo -u postgres psql -d decp -f "db/create_table.sql"



#########################################################
# A faire une fois par mois, le 1er ou le 2

# Chargement de la base siren pour normaliser les noms
# Voir si on allège comme pour le siret_geo ci-dessous
wget --cut-dirs 5 "http://files.data.gouv.fr/insee-sirene/StockUniteLegale_utf8.zip"
find . -name '*.zip' -exec unzip '{}' \;
#rm "StockUniteLegale_utf8.zip"

# Eventuellement, alléger et utiliser la syntaxe du siret_geo voir ci-dessous
sudo -u postgres psql -d decp -c "DROP TABLE IF EXISTS sirene;"
sudo -u postgres psql -d decp -f "db/create_sirene.sql"
sudo -u postgres psql -d decp -c "COPY sirene FROM '/srv/shiny-server/DECP/StockUniteLegale_utf8.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER, encoding 'UTF8') ;"

# Colonnes à garder : nomUniteLegale, nomUsageUniteLegale, prenomUsuelUniteLegale, denominationUniteLegale, siren
sudo -u postgres psql -d decp -c "ALTER TABLE sirene
		ADD COLUMN denominationUnique CHARACTER VARYING ; 
		UPDATE public.sirene
		SET denominationUnique = (
			CASE
				WHEN nomUniteLegale IS NOT NULL THEN nomUniteLegale ||' ' || prenomUsuelUniteLegale
				WHEN nomUsageUniteLegale IS NOT NULL THEN nomUsageUniteLegale || '' || prenomUsuelUniteLegale
			ELSE
				denominationUniteLegale
			END);"
sudo -u postgres psql -d decp -c "CREATE INDEX idx_denominationUnique on sirene(denominationUnique);"
sudo -u postgres psql -d decp -c "CREATE INDEX idx_siren ON sirene(siren) ;"

#rm "StockUniteLegale_utf8.csv"


# Chargement du siret géolocalisé depuis le site de Christian Quest. 
# Ligne gunzip très longue (environ 5 minutes)
# 1) Chargement du fichier complet 2) Subset 3) Création de la table et peuplement 5) Suppression des fichiers source
wget --cut-dirs 5 "http://data.cquest.org/geo_sirene/v2019/last/StockEtablissement_utf8_geo.csv.gz"
gunzip -c StockEtablissement_utf8_geo.csv.gz | csvcut -c siret,longitude,latitude > siret_lon_lat.csv

sudo -u postgres psql -d decp -c "DROP TABLE IF EXISTS siret_geo;"
sudo -u postgres psql -d decp -c "CREATE TABLE siret_geo (siret CHARACTER VARYING, longitude DECIMAL(10,2), latitude DECIMAL(10,2));"
sudo -u postgres psql -d decp -c "COPY siret_geo FROM '/srv/shiny-server/DECP/siret_lon_lat.csv' WITH (FORMAT CSV, DELIMITER ',', NULL '', HEADER, encoding 'UTF8', FORCE_NULL(siret, longitude, latitude));"
sudo -u postgres psql -d decp -c "CREATE INDEX idx_siret ON siret_geo(siret) ;"
rm "StockEtablissement_utf8_geo.csv.gz"
#rm "siret_lon_lat.csv"



#########################################################
# Création d'un dossier, chargement des données brutes, traitement des infos
# Attention, si on prend tout le stock, penser à vider la base et recommencer tout.
mkdir data
wget --cut-dirs 5 --output-document="data/decp.xml" "https://www.data.gouv.fr/fr/datasets/r/17046b18-8921-486a-bc31-c9196d5c3e9c" 

# Conversion du ipynb to py
jupyter nbconvert --to script *.ipynb
python ParseRawData.py
#rm -r data


# 3) Charger les données + réindexation + création de la liste des titulaires et acheteurs
sudo -u postgres psql decp -c "COPY contrats FROM '/srv/shiny-server/DECP/Contrats.csv' WITH (FORMAT CSV, DELIMITER '|', NULL '', HEADER, encoding 'UTF8', FORCE_NULL(typeContrat, nature, objet, codeCPV, procedure, lieuExecTypeCode, lieuExecCode, lieuExecNom,dureeMois, dateNotification, datePublicationDonnees, montant, formePrix, dateSignature, dateDebutExecution, valeurGlobale, montantSubventionPublique)) ;"
sudo -u postgres psql -d decp -c "COPY acheteurs FROM '/srv/shiny-server/DECP/Acheteurs.csv' WITH (FORMAT CSV, DELIMITER '|', NULL '', HEADER, encoding 'UTF8', FORCE_NULL(idAcheteur, nomAcheteur)) ;"
sudo -u postgres psql -d decp -c "COPY titulaires FROM '/srv/shiny-server/DECP/Titulaires.csv' WITH (FORMAT CSV, DELIMITER '|', NULL '', HEADER, encoding 'UTF8', FORCE_NULL(typeIdentifiant, idTitulaire, denominationSocialeTitulaire)) ;"

sudo -u postgres psql -d decp -c "REINDEX TABLE contrats; REINDEX TABLE acheteurs; REINDEX TABLE titulaires;"
sudo -u postgres psql -d decp -c "DROP TABLE IF EXISTS liste_titulaires;
	CREATE TABLE liste_titulaires AS (
	SELECT DISTINCT titulaires.denominationSocialeTitulaire, titulaires.idTitulaire idTitulaire,
					sirene.denominationunique nomSirenTitulaire, sirene.siren sirenTitulaire
	FROM titulaires
	LEFT JOIN sirene sirene
	ON substr(titulaires.idTitulaire, 1, 9) = sirene.siren);
	CREATE INDEX idx_sirenT ON liste_titulaires(sirenTitulaire) ; "
sudo -u postgres psql -d decp -c "DROP TABLE IF EXISTS liste_acheteurs;
	CREATE TABLE liste_acheteurs AS (
	SELECT DISTINCT acheteurs.nomAcheteur, acheteurs.idAcheteur idAcheteur,
					sirene.denominationunique nomSirenAcheteur, sirene.siren sirenAcheteur
	FROM acheteurs
	LEFT JOIN sirene sirene
	ON substr(acheteurs.idAcheteur,1,9) = sirene.siren);
	CREATE INDEX idx_sirenA ON liste_acheteurs(sirenAcheteur) ; "


rm -rf Contrats.csv
rm -rf Acheteurs.csv
rm -rf Titulaires.csv
			





