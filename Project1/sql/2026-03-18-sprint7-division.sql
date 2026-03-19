-- ================================================================================
-- SPRINT 7 - Division des passagers d'une réservation entre plusieurs véhicules
-- PostgreSQL Migration (corrected)
-- ================================================================================
--
-- Objectif : Permettre la division des passagers d'une même réservation entre
--            plusieurs véhicules lorsqu'aucun véhicule disponible n'a une
--            capacité suffisante.
--
-- ================================================================================

-- ✅ La colonne nb_passagers_assignes existe déjà
-- Vérification : La colonne a déjà été créée, on continue avec les mises à jour

-- Ajouter un commentaire pour clarifier son utilisation (PostgreSQL)
COMMENT ON COLUMN attribution.nb_passagers_assignes IS 'Sprint 7: Nombre de passagers transportés dans CE véhicule (pour supporter la division)';

-- Mettre à jour les données existantes : pour chaque attribution, récupérer le nombre de passagers
-- de la réservation principale (backward compatibility)
UPDATE attribution a
SET nb_passagers_assignes = (
    SELECT r.passenger_nbr
    FROM reservation r
    WHERE r.id = a.reservation_id
)
WHERE a.nb_passagers_assignes IS NULL;

-- Ajouter la contrainte NOT NULL après migration (PostgreSQL)
-- Note: Cette instruction changera la colonne en NOT NULL pour les futures insertions
ALTER TABLE attribution
ALTER COLUMN nb_passagers_assignes SET NOT NULL;

-- ================================================================================
-- Vérification
-- ================================================================================
--
-- SELECT id, vehicule_id, reservation_id, nb_passagers_assignes, statut
-- FROM attribution
-- LIMIT 10;
--
-- ================================================================================
