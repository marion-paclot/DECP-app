-- Création de la base de données et peuplement

DROP TABLE IF EXISTS contrats;
DROP TABLE IF EXISTS acheteurs ;
DROP TABLE IF EXISTS titulaires ;

CREATE TABLE public.contrats
(
	idContrat CHARACTER VARYING, 
	uidContrat CHARACTER VARYING, 
	typeContrat CHARACTER VARYING, 
	nature CHARACTER VARYING, 
	objet CHARACTER VARYING, 
	codeCPV CHARACTER VARYING, 
	nomCPV CHARACTER VARYING,
	procedure CHARACTER VARYING, 
	lieuExecTypeCode CHARACTER VARYING, 
	lieuExecCode CHARACTER VARYING, 
	lieuExecNom CHARACTER VARYING,
	lieuExecCodeDep CHARACTER VARYING,
	dureeMois INTEGER, 
	dateNotification DATE, 
	datePublicationDonnees DATE, 
	montant DECIMAL(15,2), 
	formePrix CHARACTER VARYING, 
	dateSignature DATE, 
	dateDebutExecution DATE, 
	valeurGlobale DECIMAL(15,2), 
	montantSubventionPublique DECIMAL(15,2)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;
CREATE INDEX idx_typeContrat ON contrats(typeContrat) ;
CREATE INDEX idx_natureContrat ON contrats(nature) ;
CREATE INDEX idx_codeCPV ON contrats(codeCPV) ;
CREATE INDEX idx_nomCPV ON contrats(nomCPV) ;
CREATE INDEX idx_procedure ON contrats(procedure) ;
CREATE INDEX idx_lieuExecCodeDep ON contrats(lieuExecCodeDep) ;
CREATE INDEX idx_dureeMois ON contrats(dureeMois) ;
CREATE INDEX idx_dateNotification ON contrats(dateNotification) ;
CREATE INDEX idx_formePrix ON contrats(formePrix) ;
CREATE INDEX idx_dateDebutExecution ON contrats(dateDebutExecution) ;


CREATE TABLE public.acheteurs
(
	idContrat CHARACTER VARYING, 
	uidContrat CHARACTER VARYING, 
	idAcheteur CHARACTER VARYING, 
	nomAcheteur CHARACTER VARYING
	--,
	--sirenAcheteur CHARACTER VARYING,
	--nomSirenAcheteur CHARACTER VARYING
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;
--CREATE INDEX idx_nomAcheteur ON acheteurs(sirenAcheteur) ;
--CREATE INDEX idx_sirenAcheteur ON acheteurs(nomSirenAcheteur) ;


CREATE TABLE public.titulaires
(
	idContrat CHARACTER VARYING, 
	uidContrat CHARACTER VARYING, 
	typeIdentifiant CHARACTER VARYING, 
	idTitulaire CHARACTER VARYING,
	denominationSocialeTitulaire CHARACTER VARYING
	--,
	--sirenTitulaire CHARACTER VARYING,
	--nomSirenTitulaire CHARACTER VARYING
)

WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;
--CREATE INDEX idx_nomTitulaire ON titulaires(nomSirenTitulaire) ;
--CREATE INDEX idx_sirenTitulaire ON titulaires(sirenTitulaire) ;

	

