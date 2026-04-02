-- ================================================================================
-- FIX: Ajouter les colonnes manquantes a la table parameters
-- ================================================================================
-- Erreur: column "created_at" does not exist
-- ================================================================================

-- Verifier si les colonnes existent, sinon les ajouter

-- Ajouter created_at si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'parameters' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE parameters ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();
        RAISE NOTICE 'Colonne created_at ajoutee';
    ELSE
        RAISE NOTICE 'Colonne created_at existe deja';
    END IF;
END $$;

-- Ajouter updated_at si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'parameters' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE parameters ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
        RAISE NOTICE 'Colonne updated_at ajoutee';
    ELSE
        RAISE NOTICE 'Colonne updated_at existe deja';
    END IF;
END $$;

-- Verification
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'parameters';

-- Afficher les donnees
SELECT * FROM parameters;
