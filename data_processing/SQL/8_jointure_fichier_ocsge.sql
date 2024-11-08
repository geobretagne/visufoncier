------------------------------------------------------------
--Jointure avec d'autres tables pour récupérer des données
-----------------------------------------------------------

-- Ce script SQL est conçu pour lier les données de SCOT, EPCI et département
-- dans les tables OCSGE du schéma visufoncier pour divers départements et années.
-- Remplacez '_xx' par le code du département (par exemple, 35, 22, 29) et '_annee' par l'année (par exemple, 2018, 2021).

-- 1. Ajouter la colonne 'nom_epci' pour stocker le nom de l'EPCI
ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN nom_epci VARCHAR;

-- Mettre à jour 'nom_epci' en utilisant la table 'express_epci' pour faire correspondre les siren_epci
UPDATE visufoncier.ocsge_xx_annee_brut
SET nom_epci = ign.express_epci.nom_epci
FROM ign.express_epci
WHERE visufoncier.ocsge_xx_annee_brut.siren_epci = ign.express_epci.code_epci;

-- 2. Ajouter une colonne 'nom_departement' pour indiquer le nom du département
ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN nom_departement VARCHAR;

-- Mettre à jour 'nom_departement' en fonction des deux premiers chiffres de 'insee_com' (à adapter selon le département)
UPDATE visufoncier.ocsge_xx_annee_brut
SET nom_departement = CASE
    WHEN LEFT(insee_com, 2) = '35' THEN 'Ille-et-Vilaine'
    WHEN LEFT(insee_com, 2) = '22' THEN 'Côtes-d''Armor'
    WHEN LEFT(insee_com, 2) = '56' THEN 'Morbihan'
    WHEN LEFT(insee_com, 2) = '29' THEN 'Finistère'
END;

-- 3. Ajouter une colonne 'nom_scot' pour stocker le nom du SCOT
ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN nom_scot VARCHAR(255);

-- Mettre à jour 'nom_scot' en fonction de la correspondance entre 'insee_com' et 'idcom' dans 'ff_obs_artif_conso_com'
UPDATE visufoncier.ocsge_xx_annee_brut v
SET nom_scot = s.scot
FROM visufoncier.ff_obs_artif_conso_com s
WHERE v.insee_com = s.idcom;

-- Rechercher les valeurs distinctes de 'nom_scot' pour vérification
SELECT DISTINCT nom_scot FROM visufoncier.ocsge_xx_annee_brut;

-- Harmoniser les noms de SCOT avec des noms standardisés (à adapter selon le département)
UPDATE visufoncier.ocsge_xx_annee_brut
SET nom_scot = CASE
    WHEN nom_scot = 'SCoT Roi Morvan Communauté - Centre Ouest Bretagne' THEN 'SCOT DU CENTRE OUEST BRETAGNE'
    WHEN nom_scot = 'SCoT de Dinan Agglomération' THEN 'SCOT-AEC DU PAYS DE DINAN'
    WHEN nom_scot = 'SCoT du Pays de Guingamp' THEN 'SCOT DU PAYS DE GUINGAMP'
    WHEN nom_scot = 'SCoT du Trégor' THEN 'SCOT DU TREGOR'
    WHEN nom_scot = 'SCoT des Communautés du Pays de Saint-Malo' THEN 'SCOT DES COMMUNAUTES DU PAYS DE SAINT MALO'
    WHEN nom_scot = 'SCoT Loudeac Communauté Bretagne Centre' THEN 'SCOT LOUDEAC COMMUNAUTE BRETAGNE CENTRE'
    WHEN nom_scot = 'SCoT du Pays de Pontivy' THEN 'SCOT DU PAYS DE PONTIVY'
    WHEN nom_scot = 'SCoT du Pays de Saint-Brieuc' THEN 'SCOT DU PAYS DE SAINT BRIEUC'
    ELSE nom_scot
END;

-- 4. Création d'index pour optimiser les requêtes sur la table
-- Index sur 'nom_commune'
CREATE INDEX IF NOT EXISTS idx_nom_commune
ON visufoncier.ocsge_xx_annee_brut (nom_commune);

-- Index sur 'nom_epci'
CREATE INDEX IF NOT EXISTS idx_nom_epci
ON visufoncier.ocsge_xx_annee_brut (nom_epci);

-- Index sur 'nom_scot'
CREATE INDEX IF NOT EXISTS idx_nom_scot
ON visufoncier.ocsge_xx_annee_brut (nom_scot);

-- Index sur 'insee_com'
CREATE INDEX IF NOT EXISTS idx_insee_com
ON visufoncier.ocsge_xx_annee_brut (insee_com);

-- Index sur 'nom_departement'
CREATE INDEX IF NOT EXISTS idx_nom_departement
ON visufoncier.ocsge_xx_annee_brut (nom_departement);

-- Création d'index génériques pour différentes années et départements.
-- Ces index sont adaptés pour être utilisés avec n'importe quel département et année en utilisant _xx pour le département et _annee pour l'année.

-- Index pour les filtres principaux
CREATE INDEX idx_filtre_xx_annee
ON visufoncier.ocsge_xx_annee_brut (insee_com, nom_commune, nom_epci, nom_scot, nom_departement);

-- Index supplémentaires pour chaque colonne spécifique dans la table


CREATE INDEX idx_millesime_debut_xx_annee ON visufoncier.ocsge_xx_annee_brut (millesime_debut);
CREATE INDEX idx_millesime_fin_xx_annee ON visufoncier.ocsge_xx_annee_brut (millesime_fin);

-- Suppression des lignes où insee_com est NULL ou vide pour chaque table
--Faire une vérification du nombre de ligne en amont

BEGIN;

-- Suppression des lignes pour le département xx et l'année annee
DELETE FROM visufoncier.ocsge_xx_annee_brut
WHERE insee_com IS NULL OR TRIM(insee_com) = '';

COMMIT;

