-- Script SQL pour créer la table attribution
-- Sprint 5/6 - Developer 2 (ETU003283)
--
-- Cette table enregistre toutes les assignations de véhicules aux réservations

CREATE TABLE IF NOT EXISTS attribution (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL REFERENCES reservation(id),
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id),
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'ASSIGNE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour optimiser les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_attribution_reservation ON attribution(reservation_id);
CREATE INDEX IF NOT EXISTS idx_attribution_vehicule ON attribution(vehicule_id);
CREATE INDEX IF NOT EXISTS idx_attribution_date_depart ON attribution(date_heure_depart);
CREATE INDEX IF NOT EXISTS idx_attribution_date_retour ON attribution(date_heure_retour);

-- Commentaires sur les colonnes
COMMENT ON TABLE attribution IS 'Table des attributions de véhicules aux réservations';
COMMENT ON COLUMN attribution.reservation_id IS 'Référence vers la réservation';
COMMENT ON COLUMN attribution.vehicule_id IS 'Référence vers le véhicule assigné';
COMMENT ON COLUMN attribution.date_heure_depart IS 'Date et heure de départ du véhicule';
COMMENT ON COLUMN attribution.date_heure_retour IS 'Date et heure de retour du véhicule à l''aéroport';
COMMENT ON COLUMN attribution.statut IS 'Statut de l''attribution (ASSIGNE, TERMINE, ANNULE)';
