-- Création de la base SIRENE

DROP TABLE IF EXISTS sirene ;

CREATE TABLE public.sirene
(
	siren CHARACTER VARYING,
	statutDiffusionUniteLegale CHARACTER VARYING,
	unitePurgeeUniteLegale CHARACTER VARYING,
	dateCreationUniteLegale CHARACTER VARYING,
	sigleUniteLegale CHARACTER VARYING,
	sexeUniteLegale CHARACTER VARYING,
	prenom1UniteLegale CHARACTER VARYING,
	prenom2UniteLegale CHARACTER VARYING,
	prenom3UniteLegale CHARACTER VARYING,
	prenom4UniteLegale CHARACTER VARYING,
	prenomUsuelUniteLegale CHARACTER VARYING,
	pseudonymeUniteLegale CHARACTER VARYING,
	identifiantAssociationUniteLegale CHARACTER VARYING,
	trancheEffectifsUniteLegale CHARACTER VARYING,
	anneeEffectifsUniteLegale CHARACTER VARYING,
	dateDernierTraitementUniteLegale CHARACTER VARYING,
	nombrePeriodesUniteLegale CHARACTER VARYING,
	categorieEntreprise CHARACTER VARYING,
	anneeCategorieEntreprise CHARACTER VARYING,
	dateDebut CHARACTER VARYING,
	etatAdministratifUniteLegale CHARACTER VARYING,
	nomUniteLegale CHARACTER VARYING,
	nomUsageUniteLegale CHARACTER VARYING,
	denominationUniteLegale CHARACTER VARYING,
	denominationUsuelle1UniteLegale CHARACTER VARYING,
	denominationUsuelle2UniteLegale CHARACTER VARYING,
	denominationUsuelle3UniteLegale CHARACTER VARYING,
	categorieJuridiqueUniteLegale CHARACTER VARYING,
	activitePrincipaleUniteLegale CHARACTER VARYING,
	nomenclatureActivitePrincipaleUniteLegale CHARACTER VARYING,
	nicSiegeUniteLegale CHARACTER VARYING,
	economieSocialeSolidaireUniteLegale CHARACTER VARYING,
	caractereEmployeurUniteLegale  CHARACTER VARYING
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;


--DROP TABLE if EXISTS sirene_decp ;
-- CREATE TABLE sirene_decp AS
-- SELECT siren, denominationUnique FROM sirene s
-- LEFT JOIN 
	-- (SELECT DISTINCT sirenacheteur FROM acheteurs) a
-- ON s.siren = a.sirenacheteur
-- WHERE a.sirenacheteur IS NOT NULL;





