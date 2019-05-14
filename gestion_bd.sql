# 

# Création d'un dossier dédié
cd /
cd srv/
mkdir decp
cd decp
mkdir data
cd data

# Création de la base de données

# Chargement des données
wget -r -np -nH --cut-dirs 5 --reject-regex "index" "http://files.data.gouv.fr/decp/"
