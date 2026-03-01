-- SPRINT 3 - Migration : Hotel → Lieu & Planification Véhicules
-- PostgreSQL Version
-- Date: 2026-03-01

-- ==========================================
-- MIGRATION : Remplacement hotel par lieu
-- ==========================================

-- 1. Ajouter lieu_depart_id à reservation (si pas encore fait)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='lieu_depart_id'
    ) THEN
        ALTER TABLE reservation ADD COLUMN lieu_depart_id BIGINT REFERENCES lieu(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Si hotel_id existe encore, migrer les données vers lieu_depart_id
-- (Nécessite que les lieux correspondants existent déjà dans la table lieu)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='hotel_id'
    ) THEN
        -- Migrer : on suppose que les hôtels ont été ajoutés dans lieu avec les mêmes IDs
        UPDATE reservation r SET lieu_depart_id = r.hotel_id WHERE lieu_depart_id IS NULL;
        -- Supprimer la colonne hotel_id
        ALTER TABLE reservation DROP COLUMN IF EXISTS hotel_id;
    END IF;
END $$;

-- 3. Supprimer l'ancienne table hotel
DROP TABLE IF EXISTS hotel CASCADE;

-- ==========================================
-- CRÉATION TABLES - SPRINT 3
-- ==========================================

-- Table LIEU (lieux : hôtels, aéroports, villes)
CREATE TABLE IF NOT EXISTS lieu (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table DISTANCE (distances entre lieux)
CREATE TABLE IF NOT EXISTS distance (
    id BIGSERIAL PRIMARY KEY,
    from_lieu_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    to_lieu_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    km_distance NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_distance_pair UNIQUE (from_lieu_id, to_lieu_id)
);

-- ==========================================
-- MODIFICATION TABLE RESERVATION
-- ==========================================

-- Ajout colonnes manquantes à la table reservation
DO $$
BEGIN
    -- Ajout lieu_destination_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='lieu_destination_id'
    ) THEN
        ALTER TABLE reservation ADD COLUMN lieu_destination_id BIGINT REFERENCES lieu(id) ON DELETE SET NULL;
    END IF;
    
    -- Ajout vehicule_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='vehicule_id'
    ) THEN
        ALTER TABLE reservation ADD COLUMN vehicule_id BIGINT REFERENCES vehicule(id) ON DELETE SET NULL;
    END IF;
    
    -- Ajout statut
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='statut'
    ) THEN
        ALTER TABLE reservation ADD COLUMN statut VARCHAR(50) DEFAULT 'NON_ASSIGNE';
    END IF;
    
    -- Ajout heure_depart
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='heure_depart'
    ) THEN
        ALTER TABLE reservation ADD COLUMN heure_depart TIMESTAMP;
    END IF;
    
    -- Ajout heure_arrivee
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='heure_arrivee'
    ) THEN
        ALTER TABLE reservation ADD COLUMN heure_arrivee TIMESTAMP;
    END IF;
    
    -- Ajout heure_retour
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='reservation' AND column_name='heure_retour'
    ) THEN
        ALTER TABLE reservation ADD COLUMN heure_retour TIMESTAMP;
    END IF;
END $$;

-- ==========================================
-- CRÉATION INDEX POUR OPTIMISATION
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_reservation_statut ON reservation(statut);
CREATE INDEX IF NOT EXISTS idx_reservation_heure_depart ON reservation(heure_depart);
CREATE INDEX IF NOT EXISTS idx_reservation_vehicule_id ON reservation(vehicule_id);
CREATE INDEX IF NOT EXISTS idx_reservation_lieu_destination ON reservation(lieu_destination_id);
CREATE INDEX IF NOT EXISTS idx_reservation_lieu_depart ON reservation(lieu_depart_id);
CREATE INDEX IF NOT EXISTS idx_lieu_code ON lieu(code);
CREATE INDEX IF NOT EXISTS idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);

-- ==========================================
-- DONNÉES DE TEST - SPRINT 3
-- ==========================================

-- Insertion des lieux (hôtels + destinations)
INSERT INTO lieu (code, libelle) VALUES
('COLBERT', 'Hotel Colbert, Antananarivo'),
('CARLTON', 'Hotel Carlton, Antananarivo'),
('IBIS', 'Hotel Ibis, Antananarivo'),
('IVATO', 'Ivato Airport, Antananarivo'),
('NOSY_BE', 'Nosy Be Airport'),
('SAINTE_MARIE', 'Sainte-Marie Airport'),
('ANTALAHA', 'Antalaha Airport'),
('SAMBAVA', 'Sambava Airport')
ON CONFLICT (code) DO NOTHING;

-- Insertion des distances
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 4, 35.50),   -- Colbert -> Ivato
(4, 1, 35.50),   -- Ivato -> Colbert
(1, 5, 250.00),  -- Colbert -> Nosy Be
(5, 1, 250.00),  -- Nosy Be -> Colbert
(1, 6, 180.00),  -- Colbert -> Sainte-Marie
(6, 1, 180.00),  -- Sainte-Marie -> Colbert
(4, 5, 285.00),  -- Ivato -> Nosy Be
(5, 4, 285.00),  -- Nosy Be -> Ivato
(4, 6, 200.00),  -- Ivato -> Sainte-Marie
(6, 4, 200.00)   -- Sainte-Marie -> Ivato
ON CONFLICT (from_lieu_id, to_lieu_id) DO NOTHING;

-- Insertion des véhicules de test
INSERT INTO vehicule (reference, nb_place, type_carburant) VALUES
('AV-001', 4, 'D'),
('AV-002', 4, 'Es'),
('AV-003', 7, 'D'),
('AV-004', 5, 'El'),
('AV-005', 8, 'D')
ON CONFLICT DO NOTHING;

-- ==========================================
-- VÉRIFICATION DONNÉES
-- ==========================================

-- SELECT COUNT(*) as total_lieux FROM lieu;
-- SELECT COUNT(*) as total_distances FROM distance;
-- SELECT COUNT(*) as total_vehicules FROM vehicule;
-- SELECT COUNT(*) as total_reservations FROM reservation WHERE statut = 'NON_ASSIGNE';
