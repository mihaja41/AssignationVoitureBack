CREATE TABLE entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    legal_name VARCHAR(255) NOT NULL,
    commercial_name VARCHAR(255),
    tax_id VARCHAR(50) NOT NULL UNIQUE,
    tax_id_type VARCHAR(20) DEFAULT 'SIRET', -- SIRET, VAT, RNC, etc.
    registration_number VARCHAR(50), -- RCS, Registre de commerce
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code CHAR(3) NOT NULL REFERENCES countries(iso_code),
    phone VARCHAR(30),
    email VARCHAR(255),
    website VARCHAR(255),
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    fiscal_regime VARCHAR(50) NOT NULL, -- 'normal', 'simplifié', 'exonéré'
    legal_form VARCHAR(50), -- SA, SAS, SARL, etc.
    share_capital DECIMAL(15,2),
    fiscal_year_start DATE, -- MM-DD (ex: '01-01' pour 1er janvier)
    is_active BOOLEAN DEFAULT TRUE,
    is_headquarter BOOLEAN DEFAULT FALSE,
    parent_entity_id UUID REFERENCES entities(id), -- Si filiale
    logo_url TEXT,
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK (phone ~* '^[+]?[0-9\s\-()]{8,}$')
);

-- Index
CREATE INDEX idx_entities_code ON entities(code);
CREATE INDEX idx_entities_tax_id ON entities(tax_id);
CREATE INDEX idx_entities_country ON entities(country_code);
CREATE INDEX idx_entities_parent ON entities(parent_entity_id);


CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    entity_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    site_type VARCHAR(30) NOT NULL, -- 'siege', 'usine', 'entrepot', 'boutique', 'showroom', 'agence'
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code CHAR(3) NOT NULL REFERENCES countries(iso_code),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(255),
    manager_id UUID REFERENCES users(id), -- Responsable du site
    opening_hours JSONB, -- Horaires d'ouverture au format JSON
    is_active BOOLEAN DEFAULT TRUE,
    is_main_site BOOLEAN DEFAULT FALSE, -- Site principal de l'entité
    has_warehouse BOOLEAN DEFAULT FALSE, -- Possède un dépôt sur place ?
    has_sales_point BOOLEAN DEFAULT FALSE, -- Point de vente ?
    timezone VARCHAR(50) DEFAULT 'UTC',
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Index
CREATE INDEX idx_sites_code ON sites(code);
CREATE INDEX idx_sites_entity ON sites(entity_id);
CREATE INDEX idx_sites_manager ON sites(manager_id);
CREATE INDEX idx_sites_country ON sites(country_code);
CREATE INDEX idx_sites_type ON sites(site_type);


CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    department_type VARCHAR(30) NOT NULL, -- 'achats', 'ventes', 'magasin', 'finance', 'direction', 'rh', 'it'
    entity_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    site_id UUID REFERENCES sites(id), -- Si rattaché à un site spécifique
    parent_department_id UUID REFERENCES departments(id), -- Hiérarchie (sous-direction)
    manager_id UUID REFERENCES users(id), -- Chef de service
    cost_center_code VARCHAR(20), -- Code centre de coût comptable
    budget DECIMAL(15,2),
    budget_fiscal_year INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    is_operational BOOLEAN DEFAULT TRUE, -- Service opérationnel ou support ?
    level INTEGER DEFAULT 1, -- Niveau hiérarchique (1=Direction, 2=Service, 3=Bureau)
    path VARCHAR(500), -- Chemin hiérarchique pour recherche rapide (ex: /1/23/45/)
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_departments_code ON departments(code);
CREATE INDEX idx_departments_entity ON departments(entity_id);
CREATE INDEX idx_departments_site ON departments(site_id);
CREATE INDEX idx_departments_parent ON departments(parent_department_id);
CREATE INDEX idx_departments_manager ON departments(manager_id);
CREATE INDEX idx_departments_type ON departments(department_type);
CREATE INDEX idx_departments_path ON departments(path);

-- Fonction pour mise à jour automatique du path
CREATE OR REPLACE FUNCTION update_department_path()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_department_id IS NULL THEN
        NEW.path := '/' || NEW.id || '/';
    ELSE
        SELECT path INTO NEW.path FROM departments WHERE id = NEW.parent_department_id;
        NEW.path := NEW.path || NEW.id || '/';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_department_path
    BEFORE INSERT OR UPDATE ON departments
    FOR EACH ROW
    EXECUTE FUNCTION update_department_path();



    CREATE TABLE currencies (
    code CHAR(3) PRIMARY KEY, -- ISO 4217: EUR, USD, GBP, etc.
    numeric_code CHAR(3), -- Code numérique ISO
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    symbol_position VARCHAR(10) DEFAULT 'before', -- 'before' ou 'after'
    decimal_places INTEGER DEFAULT 2,
    decimal_separator CHAR(1) DEFAULT '.',
    thousands_separator CHAR(1) DEFAULT ',',
    is_base_currency BOOLEAN DEFAULT FALSE, -- Devise de référence du groupe
    is_active BOOLEAN DEFAULT TRUE,
    is_crypto BOOLEAN DEFAULT FALSE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_currencies_base ON currencies(is_base_currency) WHERE is_base_currency = TRUE;

-- Insertion des devises principales
INSERT INTO currencies (code, numeric_code, name, symbol, symbol_position, decimal_places, is_base_currency) VALUES
('EUR', '978', 'Euro', '€', 'after', 2, TRUE),
('USD', '840', 'US Dollar', '$', 'before', 2, FALSE),
('GBP', '826', 'British Pound', '£', 'before', 2, FALSE),
('CHF', '756', 'Swiss Franc', 'Fr', 'before', 2, FALSE),
('JPY', '392', 'Japanese Yen', '¥', 'before', 0, FALSE),
('CNY', '156', 'Chinese Yuan', '¥', 'before', 2, FALSE),
('CAD', '124', 'Canadian Dollar', 'C$', 'before', 2, FALSE),
('AUD', '036', 'Australian Dollar', 'A$', 'before', 2, FALSE);




CREATE TABLE countries (
    iso_code CHAR(2) PRIMARY KEY, -- ISO 3166-1 alpha-2: FR, US, etc.
    iso3_code CHAR(3), -- ISO 3166-1 alpha-3: FRA, USA
    numeric_code CHAR(3), -- Code numérique ISO 3166-1
    name_fr VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    name_local VARCHAR(100), -- Nom dans la langue locale
    capital VARCHAR(100),
    currency_code CHAR(3) REFERENCES currencies(code),
    phone_prefix VARCHAR(10),
    postal_code_format VARCHAR(100), -- Format regex pour code postal
    is_eu_member BOOLEAN DEFAULT FALSE, -- Membre Union Européenne
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE, -- Pays par défaut (siège social)
    
    -- Pour TVA intracommunautaire
    vat_number_prefix VARCHAR(2), -- FR, DE, etc.
    vat_rate_default DECIMAL(5,2), -- TVA par défaut
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_countries_iso3 ON countries(iso3_code);
CREATE INDEX idx_countries_currency ON countries(currency_code);

-- Insertion des pays principaux
INSERT INTO countries (iso_code, iso3_code, numeric_code, name_fr, name_en, currency_code, phone_prefix, is_eu_member) VALUES
('FR', 'FRA', '250', 'France', 'France', 'EUR', '33', TRUE),
('BE', 'BEL', '056', 'Belgique', 'Belgium', 'EUR', '32', TRUE),
('CH', 'CHE', '756', 'Suisse', 'Switzerland', 'CHF', '41', FALSE),
('LU', 'LUX', '442', 'Luxembourg', 'Luxembourg', 'EUR', '352', TRUE),
('DE', 'DEU', '276', 'Allemagne', 'Germany', 'EUR', '49', TRUE),
('ES', 'ESP', '724', 'Espagne', 'Spain', 'EUR', '34', TRUE),
('IT', 'ITA', '380', 'Italie', 'Italy', 'EUR', '39', TRUE),
('PT', 'PRT', '620', 'Portugal', 'Portugal', 'EUR', '351', TRUE),
('GB', 'GBR', '826', 'Royaume-Uni', 'United Kingdom', 'GBP', '44', FALSE),
('US', 'USA', '840', 'États-Unis', 'United States', 'USD', '1', FALSE),
('CA', 'CAN', '124', 'Canada', 'Canada', 'CAD', '1', FALSE),
('MA', 'MAR', '504', 'Maroc', 'Morocco', 'MAD', '212', FALSE),
('TN', 'TUN', '788', 'Tunisie', 'Tunisia', 'TND', '216', FALSE),
('SN', 'SEN', '686', 'Sénégal', 'Senegal', 'XOF', '221', FALSE),
('CI', 'CIV', '384', 'Côte d''Ivoire', 'Ivory Coast', 'XOF', '225', FALSE);



CREATE TABLE taxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tax_type VARCHAR(30) NOT NULL, -- 'vat' (TVA), 'gst', 'sales_tax', 'excise', 'customs'
    rate DECIMAL(5,2) NOT NULL, -- Pourcentage (ex: 20.00 pour 20%)
    rate_type VARCHAR(20) DEFAULT 'percentage', -- 'percentage', 'fixed_amount'
    country_code CHAR(2) NOT NULL REFERENCES countries(iso_code),
    region VARCHAR(100), -- Si taxe régionale (Québec, Californie, etc.)
    
    -- Catégories de TVA (France)
    vat_category VARCHAR(30), -- 'standard', 'intermediate', 'reduced', 'super_reduced', 'zero', 'exempt'
    is_recoverable BOOLEAN DEFAULT TRUE, -- TVA récupérable ?
    
    -- Validité
    valid_from DATE NOT NULL,
    valid_to DATE, -- NULL si toujours valide
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE, -- Taux par défaut pour le pays
    
    -- Application
    applies_to VARCHAR(20) DEFAULT 'both', -- 'sale', 'purchase', 'both'
    applies_on VARCHAR(20) DEFAULT 'total', -- 'total', 'shipping', 'both'
    
    -- Comptabilité
    accounting_account_code VARCHAR(20), -- Compte comptable (44571, 44566)
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contraintes
    CONSTRAINT valid_rate CHECK (rate >= 0 AND rate <= 100)
);

-- Index
CREATE INDEX idx_taxes_code ON taxes(code);
CREATE INDEX idx_taxes_country ON taxes(country_code);
CREATE INDEX idx_taxes_validity ON taxes(valid_from, valid_to);

-- Insertion des taux de TVA français
INSERT INTO taxes (code, name, rate, country_code, vat_category, is_default, applies_to) VALUES
('FR_TVA_20', 'TVA France 20%', 20.00, 'FR', 'standard', TRUE, 'both'),
('FR_TVA_10', 'TVA France 10%', 10.00, 'FR', 'intermediate', FALSE, 'both'),
('FR_TVA_55', 'TVA France 5.5%', 5.50, 'FR', 'reduced', FALSE, 'both'),
('FR_TVA_21', 'TVA France 2.1%', 2.10, 'FR', 'super_reduced', FALSE, 'both'),
('FR_TVA_0', 'TVA France 0%', 0.00, 'FR', 'zero', FALSE, 'both');

-- Insertion des taux belges
INSERT INTO taxes (code, name, rate, country_code, vat_category, is_default, applies_to) VALUES
('BE_TVA_21', 'TVA Belgique 21%', 21.00, 'BE', 'standard', TRUE, 'both'),
('BE_TVA_12', 'TVA Belgique 12%', 12.00, 'BE', 'intermediate', FALSE, 'both'),
('BE_TVA_6', 'TVA Belgique 6%', 6.00, 'BE', 'reduced', FALSE, 'both');


CREATE TABLE payment_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Type de paiement
    payment_type VARCHAR(30) NOT NULL, -- 'cash', 'transfer', 'check', 'credit_card', 'letter_of_credit'
    
    -- Délai de paiement
    due_days INTEGER, -- Nombre de jours (ex: 30)
    due_day_of_month INTEGER, -- Jour fixe du mois (ex: 15 pour paiement le 15)
    due_end_of_month BOOLEAN DEFAULT FALSE, -- Paiement fin de mois
    due_months_end BOOLEAN DEFAULT FALSE, -- Paiement fin de mois + X mois
    
    -- Escompte
    discount_days INTEGER, -- Jours pour bénéficier de l'escompte
    discount_percentage DECIMAL(5,2), -- % d'escompte
    
    -- Pénalités
    late_penalty_rate DECIMAL(5,2), -- Taux de pénalité annuel
    late_penalty_fixed DECIMAL(15,2), -- Pénalité fixe
    
    -- Conditions particulières
    requires_advance BOOLEAN DEFAULT FALSE, -- Acompte requis ?
    advance_percentage DECIMAL(5,2), -- % d'acompte
    
    -- Séparation des tâches
    requires_approval BOOLEAN DEFAULT FALSE, -- Validation nécessaire ?
    approval_threshold DECIMAL(15,2), -- Seuil pour validation
    
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_payment_terms_code ON payment_terms(code);

-- Insertion des conditions standards
INSERT INTO payment_terms (code, name, payment_type, due_days, is_default) VALUES
('CASH', 'Comptant', 'cash', 0, TRUE),
('NET30', '30 jours net', 'transfer', 30, FALSE),
('NET45', '45 jours net', 'transfer', 45, FALSE),
('NET60', '60 jours net', 'transfer', 60, FALSE),
('EOM30', 'Fin de mois 30 jours', 'transfer', 30, FALSE),
('EOM45', 'Fin de mois 45 jours', 'transfer', 45, FALSE),
('EOM60', 'Fin de mois 60 jours', 'transfer', 60, FALSE);

INSERT INTO payment_terms (code, name, payment_type, due_days, discount_days, discount_percentage) VALUES
('2%10_NET30', '2% escompte 10 jours, net 30', 'transfer', 30, 10, 2.00);


CREATE TABLE delivery_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Type d'Incoterm
    incoterm_type VARCHAR(10) NOT NULL, -- EXW, FCA, FAS, FOB, CFR, CIF, CPT, CIP, DAP, DPU, DDP
    incoterm_version VARCHAR(4) DEFAULT '2020', -- 2010, 2020
    
    -- Responsabilités
    risk_transfer_point TEXT, -- Point de transfert des risques
    cost_transfer_point TEXT, -- Point de transfert des coûts
    
    -- Transport
    transport_responsibility VARCHAR(30), -- 'seller', 'buyer', 'shared'
    insurance_responsibility VARCHAR(30), -- 'seller', 'buyer'
    customs_export_responsibility VARCHAR(30), -- 'seller', 'buyer'
    customs_import_responsibility VARCHAR(30), -- 'seller', 'buyer'
    
    -- Livraison
    delivery_location_type VARCHAR(30), -- 'seller_premises', 'buyer_premises', 'port', 'airport', 'terminal'
    
    -- Délais
    standard_delivery_days INTEGER, -- Délai standard en jours
    
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_delivery_terms_code ON delivery_terms(code);

-- Insertion des Incoterms 2020
INSERT INTO delivery_terms (code, name, incoterm_type, transport_responsibility, customs_export_responsibility, customs_import_responsibility, is_default) VALUES
('EXW', 'Ex Works (Départ usine)', 'EXW', 'buyer', 'buyer', 'buyer', FALSE),
('FCA', 'Free Carrier (Franco transporteur)', 'FCA', 'shared', 'seller', 'buyer', FALSE),
('FAS', 'Free Alongside Ship (Franco long du navire)', 'FAS', 'seller', 'seller', 'buyer', FALSE),
('FOB', 'Free On Board (Franco à bord)', 'FOB', 'seller', 'seller', 'buyer', TRUE),
('CFR', 'Cost and Freight (Coût et fret)', 'CFR', 'seller', 'seller', 'buyer', FALSE),
('CIF', 'Cost, Insurance and Freight', 'CIF', 'seller', 'seller', 'buyer', FALSE),
('CPT', 'Carriage Paid To (Port payé jusqu''à)', 'CPT', 'seller', 'seller', 'buyer', FALSE),
('CIP', 'Carriage and Insurance Paid To', 'CIP', 'seller', 'seller', 'buyer', FALSE),
('DAP', 'Delivered At Place (Rendu au lieu)', 'DAP', 'seller', 'seller', 'seller', FALSE),
('DPU', 'Delivered At Place Unloaded', 'DPU', 'seller', 'seller', 'seller', FALSE),
('DDP', 'Delivered Duty Paid (Rendu droits acquittés)', 'DDP', 'seller', 'seller', 'seller', FALSE);



-- Note: Cette table est créée pour permettre les références dans les champs created_by/updated_by
-- Elle sera détaillée dans la section "Utilisateurs & Sécurité"
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);


CREATE TABLE product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Hiérarchie
    parent_category_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,
    level INTEGER DEFAULT 1,
    path VARCHAR(1000), -- Chemin hiérarchique (ex: /1/23/45/)
    full_path_name TEXT, -- Nom complet (ex: Electronique > Téléphones > Smartphones)
    
    -- Classification
    category_type VARCHAR(30), -- 'marchandise', 'matiere_premiere', 'emballage', 'consommable', 'service', 'immobilisation'
    is_physical BOOLEAN DEFAULT TRUE, -- Produit physique ou service ?
    is_purchased BOOLEAN DEFAULT TRUE, -- Acheté ?
    is_sold BOOLEAN DEFAULT TRUE, -- Vendu ?
    is_stocked BOOLEAN DEFAULT TRUE, -- Stocké ?
    
    -- Comptabilité
    revenue_account_code VARCHAR(20), -- Compte de vente (comptabilité)
    expense_account_code VARCHAR(20), -- Compte d'achat
    inventory_account_code VARCHAR(20), -- Compte de stock
    tax_id UUID REFERENCES taxes(id), -- TVA par défaut pour la catégorie
    
    -- Gestion
    default_uom_id UUID, -- Unité de mesure par défaut (référence circularisée après création)
    default_purchase_uom_id UUID, -- Unité d'achat
    default_sales_uom_id UUID, -- Unité de vente
    min_stock_level DECIMAL(15,3), -- Stock minimum (alerte)
    max_stock_level DECIMAL(15,3), -- Stock maximum
    reorder_point DECIMAL(15,3), -- Point de commande
    
    -- Traçabilité
    requires_lot BOOLEAN DEFAULT FALSE, -- Gestion par lot obligatoire ?
    requires_serial BOOLEAN DEFAULT FALSE, -- Gestion par N° série obligatoire ?
    requires_expiry_date BOOLEAN DEFAULT FALSE, -- Date d'expiration ?
    requires_quality_control BOOLEAN DEFAULT FALSE, -- Contrôle qualité à réception ?
    
    -- Image
    image_url TEXT,
    icon_class VARCHAR(100),
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_product_categories_code ON product_categories(code);
CREATE INDEX idx_product_categories_parent ON product_categories(parent_category_id);
CREATE INDEX idx_product_categories_path ON product_categories(path);
CREATE INDEX idx_product_categories_type ON product_categories(category_type);
CREATE INDEX idx_product_categories_tax ON product_categories(tax_id);

-- Fonction pour mise à jour automatique du path et full_path_name
CREATE OR REPLACE FUNCTION update_category_path()
RETURNS TRIGGER AS $$
DECLARE
    parent_path VARCHAR(1000);
    parent_full_name TEXT;
BEGIN
    IF NEW.parent_category_id IS NULL THEN
        NEW.path := '/' || NEW.id || '/';
        NEW.full_path_name := NEW.name;
        NEW.level := 1;
    ELSE
        SELECT path, full_path_name INTO parent_path, parent_full_name 
        FROM product_categories WHERE id = NEW.parent_category_id;
        NEW.path := parent_path || NEW.id || '/';
        NEW.full_path_name := parent_full_name || ' > ' || NEW.name;
        NEW.level := (SELECT level FROM product_categories WHERE id = NEW.parent_category_id) + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_category_path
    BEFORE INSERT OR UPDATE ON product_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_path();


CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identifiants
    sku VARCHAR(100) NOT NULL UNIQUE, -- Stock Keeping Unit (référence interne)
    code VARCHAR(100) NOT NULL UNIQUE, -- Code article
    ean VARCHAR(13) UNIQUE, -- Code-barres EAN-13
    upc VARCHAR(12) UNIQUE, -- UPC
    isbn VARCHAR(20) UNIQUE, -- ISBN pour livres
    manufacturer_code VARCHAR(100), -- Code fabricant
    supplier_code VARCHAR(100), -- Code fournisseur principal
    
    -- Désignation
    name VARCHAR(500) NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    brand VARCHAR(255),
    model VARCHAR(255),
    
    -- Classification
    category_id UUID NOT NULL REFERENCES product_categories(id),
    product_type VARCHAR(30) NOT NULL DEFAULT 'product', -- 'product', 'service', 'bundle', 'kit', 'digital'
    product_status VARCHAR(30) DEFAULT 'active', -- 'active', 'discontinued', 'in_development', 'obsolete'
    
    -- Unités de mesure (seront mises à jour après création de la table units_of_measure)
    uom_id UUID, -- Unité de base (stock)
    purchase_uom_id UUID, -- Unité d'achat
    sales_uom_id UUID, -- Unité de vente
    weight_uom_id UUID, -- Unité de poids (kg, lb)
    volume_uom_id UUID, -- Unité de volume (m3, L)
    
    -- Caractéristiques physiques
    weight DECIMAL(15,3),
    width DECIMAL(15,3),
    height DECIMAL(15,3),
    length DECIMAL(15,3),
    volume DECIMAL(15,3),
    
    -- Conditionnement
    purchase_pack_quantity DECIMAL(15,3) DEFAULT 1, -- Quantité par colis d'achat
    sales_pack_quantity DECIMAL(15,3) DEFAULT 1, -- Quantité par colis de vente
    is_pack BOOLEAN DEFAULT FALSE, -- Est-ce un pack (assemblage de plusieurs produits) ?
    
    -- Tarifs et coûts
    purchase_price DECIMAL(15,4), -- Prix d'achat standard
    sales_price DECIMAL(15,4), -- Prix de vente standard
    wholesale_price DECIMAL(15,4), -- Prix de gros
    recommended_retail_price DECIMAL(15,4), -- Prix conseillé
    cost_method VARCHAR(20) DEFAULT 'fifo', -- 'fifo', 'cump', 'lifo', 'standard'
    standard_cost DECIMAL(15,4), -- Coût standard (si cost_method = 'standard')
    last_purchase_price DECIMAL(15,4), -- Dernier prix d'achat
    average_cost DECIMAL(15,4), -- Coût moyen (calculé périodiquement)
    
    -- TVA
    purchase_tax_id UUID REFERENCES taxes(id),
    sales_tax_id UUID REFERENCES taxes(id),
    
    -- Stock
    is_stockable BOOLEAN DEFAULT TRUE,
    is_tracked BOOLEAN DEFAULT TRUE, -- Suivi de stock actif ?
    reorder_point DECIMAL(15,3), -- Seuil de réapprovisionnement
    economic_order_quantity DECIMAL(15,3), -- Quantité économique de commande
    safety_stock DECIMAL(15,3), -- Stock de sécurité
    max_stock DECIMAL(15,3), -- Stock maximum
    min_stock DECIMAL(15,3), -- Stock minimum (alerte)
    
    -- Traçabilité
    lot_tracking VARCHAR(20) DEFAULT 'none', -- 'none', 'optional', 'mandatory'
    serial_tracking VARCHAR(20) DEFAULT 'none', -- 'none', 'optional', 'mandatory'
    expiry_tracking BOOLEAN DEFAULT FALSE,
    shelf_life_days INTEGER, -- Durée de vie (jours)
    alert_before_expiry_days INTEGER DEFAULT 30, -- Alerte avant expiration
    
    -- Localisation
    default_warehouse_id UUID, -- Dépôt par défaut (référence à créer)
    default_location_id UUID, -- Emplacement par défaut
    quarantine_on_receipt BOOLEAN DEFAULT FALSE, -- Mise en quarantaine à réception ?
    
    -- Fournisseur principal
    preferred_supplier_id UUID, -- Fournisseur principal (référence à créer)
    
    -- Médias
    main_image_url TEXT,
    additional_images JSONB, -- URLs des images supplémentaires
    technical_sheet_url TEXT,
    msds_url TEXT, -- Fiche de données de sécurité
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    slug VARCHAR(500) UNIQUE, -- URL friendly
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    is_purchasable BOOLEAN DEFAULT TRUE,
    is_sellable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contraintes
    CONSTRAINT valid_price CHECK (purchase_price >= 0 AND sales_price >= 0),
    CONSTRAINT valid_weight CHECK (weight >= 0),
    CONSTRAINT valid_dimensions CHECK (width >= 0 AND height >= 0 AND length >= 0)
);

-- Index
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_ean ON products(ean);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_status ON products(product_status);
CREATE INDEX idx_products_supplier ON products(preferred_supplier_id);
CREATE INDEX idx_products_name ON products(name);
CREATE FULLTEXT INDEX idx_products_search ON products(name, description, sku, code, ean); -- Pour MySQL
-- Pour PostgreSQL, utiliser GIN index avec tsvector

-- Commentaires
COMMENT ON TABLE products IS 'Articles / Produits';
COMMENT ON COLUMN products.sku IS 'Stock Keeping Unit - Référence interne unique';
COMMENT ON COLUMN products.cost_method IS 'Méthode de valorisation: fifo, cump, lifo, standard';


CREATE TABLE product_suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL, -- Référence vers suppliers (table à créer)
    
    -- Références fournisseur
    supplier_product_code VARCHAR(100), -- Code article chez le fournisseur
    supplier_product_name VARCHAR(500), -- Désignation chez le fournisseur
    supplier_barcode VARCHAR(100), -- Code-barres fournisseur
    
    -- Tarification
    purchase_price DECIMAL(15,4) NOT NULL,
    currency_code CHAR(3) REFERENCES currencies(code),
    price_valid_from DATE,
    price_valid_to DATE,
    discount_percentage DECIMAL(5,2) DEFAULT 0, -- Remise négociée
    discount_amount DECIMAL(15,4) DEFAULT 0,
    
    -- Conditions
    payment_term_id UUID REFERENCES payment_terms(id),
    delivery_term_id UUID REFERENCES delivery_terms(id),
    minimum_order_quantity DECIMAL(15,3) DEFAULT 1,
    maximum_order_quantity DECIMAL(15,3),
    economic_order_quantity DECIMAL(15,3),
    lead_time_days INTEGER, -- Délai d'approvisionnement en jours
    reliability_days INTEGER, -- Variabilité du délai (jours de sécurité)
    
    -- Qualité
    quality_rating DECIMAL(2,1), -- Note de 0 à 5
    is_preferred BOOLEAN DEFAULT FALSE, -- Fournisseur préféré ?
    is_approved BOOLEAN DEFAULT TRUE, -- Fournisseur approuvé pour cet article ?
    
    -- Logistique
    incoterm_id UUID REFERENCES delivery_terms(id),
    shipping_cost DECIMAL(15,4),
    shipping_cost_currency CHAR(3) REFERENCES currencies(code),
    
    -- Dates
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE, -- NULL = indéfini
    last_purchase_date DATE,
    last_purchase_price DECIMAL(15,4),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_product_supplier UNIQUE (product_id, supplier_id, effective_from),
    CONSTRAINT valid_dates CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

-- Index
CREATE INDEX idx_product_suppliers_product ON product_suppliers(product_id);
CREATE INDEX idx_product_suppliers_supplier ON product_suppliers(supplier_id);
CREATE INDEX idx_product_suppliers_preferred ON product_suppliers(is_preferred) WHERE is_preferred = TRUE;
CREATE INDEX idx_product_suppliers_validity ON product_suppliers(effective_from, effective_to);


CREATE TABLE product_tariffs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Type de tarif
    tariff_type VARCHAR(30) NOT NULL, -- 'general', 'customer_group', 'customer', 'category', 'promotion'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Liens (selon type)
    customer_id UUID, -- Client spécifique (table à créer)
    customer_group_id UUID, -- Groupe de clients (table à créer)
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    product_category_id UUID REFERENCES product_categories(id) ON DELETE CASCADE,
    
    -- Structure de prix
    price_list_id UUID, -- Liste de prix (si regroupement)
    price DECIMAL(15,4) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    unit_of_measure_id UUID, -- Unité de vente (table à créer)
    
    -- Remises
    discount_type VARCHAR(20), -- 'percentage', 'fixed', 'none'
    discount_value DECIMAL(15,4),
    min_quantity DECIMAL(15,3) DEFAULT 1, -- Quantité minimum pour ce tarif
    max_quantity DECIMAL(15,3), -- Quantité maximum
    
    -- Période de validité
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Priorité (le tarif avec la priorité la plus élevée est appliqué)
    priority INTEGER DEFAULT 0,
    
    -- Conditions
    requires_approval BOOLEAN DEFAULT FALSE, -- Remise exceptionnelle nécessitant validation
    approval_threshold DECIMAL(15,4), -- Seuil de validation
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT valid_dates CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- Index
CREATE INDEX idx_product_tariffs_product ON product_tariffs(product_id);
CREATE INDEX idx_product_tariffs_category ON product_tariffs(product_category_id);
CREATE INDEX idx_product_tariffs_customer ON product_tariffs(customer_id);
CREATE INDEX idx_product_tariffs_group ON product_tariffs(customer_group_id);
CREATE INDEX idx_product_tariffs_validity ON product_tariffs(valid_from, valid_to);
CREATE INDEX idx_product_tariffs_type ON product_tariffs(tariff_type);


CREATE TABLE product_barcodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    
    -- Code-barres
    barcode VARCHAR(100) NOT NULL UNIQUE,
    barcode_type VARCHAR(30) NOT NULL, -- 'EAN13', 'EAN8', 'UPC', 'CODE128', 'QRCODE', 'DATAMATRIX', 'ITF14'
    
    -- Contexte d'utilisation
    usage_context VARCHAR(30) DEFAULT 'all', -- 'all', 'sales', 'purchasing', 'warehouse', 'shipping'
    is_primary BOOLEAN DEFAULT FALSE, -- Code-barres principal ?
    
    -- Conditionnement
    packaging_level VARCHAR(20), -- 'unit', 'inner_pack', 'case', 'pallet'
    quantity DECIMAL(15,3) DEFAULT 1, -- Quantité représentée
    
    -- Unité de mesure associée
    unit_of_measure_id UUID, -- Unité correspondant à ce code-barres
    
    -- Validité
    valid_from DATE,
    valid_to DATE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Métadonnées
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_product_barcodes_product ON product_barcodes(product_id);
CREATE INDEX idx_product_barcodes_barcode ON product_barcodes(barcode);
CREATE INDEX idx_product_barcodes_primary ON product_barcodes(is_primary) WHERE is_primary = TRUE;

-- Commentaires
COMMENT ON TABLE product_barcodes IS 'Codes-barres multiples par produit (différents conditionnements)';



-- Table des définitions d'attributs
CREATE TABLE attribute_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Type d'attribut
    attribute_type VARCHAR(30) NOT NULL, -- 'text', 'number', 'boolean', 'date', 'select', 'multiselect', 'color', 'size'
    data_type VARCHAR(30), -- 'string', 'integer', 'decimal', 'boolean', 'date'
    
    -- Configuration
    is_required BOOLEAN DEFAULT FALSE,
    is_filterable BOOLEAN DEFAULT TRUE, -- Utilisable comme filtre dans les listes
    is_searchable BOOLEAN DEFAULT TRUE, -- Recherchable
    is_comparable BOOLEAN DEFAULT TRUE, -- Comparable entre produits
    is_variant_attribute BOOLEAN DEFAULT FALSE, -- Attribut de variation (décline les variantes)
    
    -- Validation
    validation_rules JSONB, -- Règles de validation (min, max, regex, etc.)
    possible_values JSONB, -- Pour les listes de valeurs prédéfinies
    
    -- Affichage
    display_order INTEGER DEFAULT 0,
    display_in_product BOOLEAN DEFAULT TRUE,
    display_in_list BOOLEAN DEFAULT FALSE,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Table des valeurs d'attributs par produit
CREATE TABLE product_attribute_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    attribute_id UUID NOT NULL REFERENCES attribute_definitions(id) ON DELETE CASCADE,
    
    -- Valeur (selon le type)
    value_text TEXT,
    value_number DECIMAL(15,4),
    value_boolean BOOLEAN,
    value_date DATE,
    value_datetime TIMESTAMP WITH TIME ZONE,
    value_json JSONB,
    
    -- Pour les valeurs sélectionnées (liste)
    selected_option_id UUID, -- Option sélectionnée
    selected_options JSONB, -- Pour multiselect
    
    -- Contexte
    is_variant_value BOOLEAN DEFAULT FALSE, -- Valeur utilisée pour les variantes
    variant_group_id UUID, -- Groupe de variantes (pour lier les variantes entre elles)
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_product_attribute UNIQUE (product_id, attribute_id)
);

-- Table des options prédéfinies pour les attributs de type select
CREATE TABLE attribute_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attribute_id UUID NOT NULL REFERENCES attribute_definitions(id) ON DELETE CASCADE,
    option_value VARCHAR(255) NOT NULL,
    option_label VARCHAR(255) NOT NULL,
    option_code VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    
    -- Pour attributs hiérarchiques (ex: Catégorie de taille)
    parent_option_id UUID REFERENCES attribute_options(id) ON DELETE SET NULL,
    
    -- Métadonnées supplémentaires
    metadata JSONB,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_attribute_option UNIQUE (attribute_id, option_value)
);

-- Index
CREATE INDEX idx_attr_def_code ON attribute_definitions(code);
CREATE INDEX idx_attr_def_type ON attribute_definitions(attribute_type);
CREATE INDEX idx_attr_values_product ON product_attribute_values(product_id);
CREATE INDEX idx_attr_values_attribute ON product_attribute_values(attribute_id);
CREATE INDEX idx_attr_options_attribute ON attribute_options(attribute_id);




CREATE TABLE units_of_measure (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE, -- 'PC', 'KG', 'M', 'M2', 'M3', 'L', 'PAL'
    name VARCHAR(255) NOT NULL,
    symbol VARCHAR(10), -- 'pièce', 'kg', 'm', 'm²', 'm³', 'L'
    
    -- Type d'unité
    unit_type VARCHAR(30) NOT NULL, -- 'unit' (pièce), 'weight', 'length', 'area', 'volume', 'time', 'packaging'
    
    -- Unité de base (pour conversions)
    is_base_unit BOOLEAN DEFAULT FALSE, -- Unité de référence pour ce type
    base_unit_id UUID REFERENCES units_of_measure(id), -- Pour les unités dérivées
    
    -- Facteur de conversion vers l'unité de base
    conversion_factor DECIMAL(15,6) DEFAULT 1,
    
    -- Précision
    decimal_places INTEGER DEFAULT 0, -- Nombre de décimales autorisé
    rounding_method VARCHAR(20) DEFAULT 'truncate', -- 'truncate', 'round', 'ceil', 'floor'
    
    -- Dimensions (pour unités de type packaging)
    width DECIMAL(15,3), -- en mètres
    height DECIMAL(15,3),
    length DECIMAL(15,3),
    weight DECIMAL(15,3), -- en kg
    volume DECIMAL(15,3), -- en m3
    
    -- Utilisation
    is_purchasing_unit BOOLEAN DEFAULT TRUE, -- Utilisable en achats ?
    is_sales_unit BOOLEAN DEFAULT TRUE, -- Utilisable en ventes ?
    is_stocking_unit BOOLEAN DEFAULT TRUE, -- Utilisable en stock ?
    is_shipping_unit BOOLEAN DEFAULT TRUE, -- Utilisable en expédition ?
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_uom_code ON units_of_measure(code);
CREATE INDEX idx_uom_type ON units_of_measure(unit_type);
CREATE INDEX idx_uom_base ON units_of_measure(base_unit_id);

-- Insertion des unités de base
INSERT INTO units_of_measure (code, name, symbol, unit_type, is_base_unit, decimal_places) VALUES
('PC', 'Pièce', 'pc', 'unit', TRUE, 0),
('KG', 'Kilogramme', 'kg', 'weight', TRUE, 3),
('G', 'Gramme', 'g', 'weight', FALSE, 2),
('T', 'Tonne', 't', 'weight', FALSE, 3),
('M', 'Mètre', 'm', 'length', TRUE, 3),
('CM', 'Centimètre', 'cm', 'length', FALSE, 2),
('M2', 'Mètre carré', 'm²', 'area', TRUE, 2),
('M3', 'Mètre cube', 'm³', 'volume', TRUE, 3),
('L', 'Litre', 'L', 'volume', TRUE, 2),
('ML', 'Millilitre', 'mL', 'volume', FALSE, 2),
('PAL', 'Palette', 'pal', 'packaging', FALSE, 0),
('BOX', 'Carton', 'box', 'packaging', FALSE, 0);

-- Mise à jour des conversions
UPDATE units_of_measure SET base_unit_id = (SELECT id FROM units_of_measure WHERE code = 'KG'), conversion_factor = 0.001 WHERE code = 'G';
UPDATE units_of_measure SET base_unit_id = (SELECT id FROM units_of_measure WHERE code = 'KG'), conversion_factor = 1000 WHERE code = 'T';
UPDATE units_of_measure SET base_unit_id = (SELECT id FROM units_of_measure WHERE code = 'M'), conversion_factor = 0.01 WHERE code = 'CM';
UPDATE units_of_measure SET base_unit_id = (SELECT id FROM units_of_measure WHERE code = 'L'), conversion_factor = 0.001 WHERE code = 'ML';


CREATE TABLE conversion_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Unités source et cible
    from_uom_id UUID NOT NULL REFERENCES units_of_measure(id) ON DELETE CASCADE,
    to_uom_id UUID NOT NULL REFERENCES units_of_measure(id) ON DELETE CASCADE,
    
    -- Facteur de conversion (quantité en unité cible pour 1 unité source)
    conversion_factor DECIMAL(15,6) NOT NULL,
    
    -- Formule inverse (automatique)
    inverse_factor DECIMAL(15,6) GENERATED ALWAYS AS (1 / conversion_factor) STORED,
    
    -- Contexte du produit (NULL = conversion générique)
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    product_category_id UUID REFERENCES product_categories(id) ON DELETE CASCADE,
    
    -- Précision
    rounding_precision INTEGER DEFAULT 2,
    rounding_method VARCHAR(20) DEFAULT 'round',
    
    -- Priorité (plus la priorité est élevée, plus cette conversion est utilisée)
    priority INTEGER DEFAULT 0,
    
    -- Validité
    valid_from DATE,
    valid_to DATE,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT unique_conversion UNIQUE (from_uom_id, to_uom_id, COALESCE(product_id, '00000000-0000-0000-0000-000000000000'), COALESCE(product_category_id, '00000000-0000-0000-0000-000000000000')),
    CONSTRAINT valid_dates CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- Index
CREATE INDEX idx_conversion_from ON conversion_units(from_uom_id);
CREATE INDEX idx_conversion_to ON conversion_units(to_uom_id);
CREATE INDEX idx_conversion_product ON conversion_units(product_id);
CREATE INDEX idx_conversion_category ON conversion_units(product_category_id);

-- Insertion des conversions génériques
INSERT INTO conversion_units (from_uom_id, to_uom_id, conversion_factor) VALUES
-- Poids
((SELECT id FROM units_of_measure WHERE code = 'KG'), (SELECT id FROM units_of_measure WHERE code = 'G'), 1000),
((SELECT id FROM units_of_measure WHERE code = 'KG'), (SELECT id FROM units_of_measure WHERE code = 'T'), 0.001),
-- Longueur
((SELECT id FROM units_of_measure WHERE code = 'M'), (SELECT id FROM units_of_measure WHERE code = 'CM'), 100),
-- Volume
((SELECT id FROM units_of_measure WHERE code = 'L'), (SELECT id FROM units_of_measure WHERE code = 'ML'), 1000),
((SELECT id FROM units_of_measure WHERE code = 'M3'), (SELECT id FROM units_of_measure WHERE code = 'L'), 1000);


CREATE TABLE lots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identifiants
    lot_number VARCHAR(100) NOT NULL UNIQUE,
    internal_reference VARCHAR(100), -- Référence interne
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    
    -- Fournisseur (si lot acheté)
    supplier_id UUID, -- Table suppliers
    supplier_lot_number VARCHAR(100), -- N° de lot fournisseur
    
    -- Dates clés
    manufacturing_date DATE, -- Date de fabrication
    expiry_date DATE, -- Date d'expiration (DLC)
    best_before_date DATE, -- Date limite d'utilisation optimale (DLUO)
    receipt_date DATE, -- Date de réception
    received_from DATE, -- Période de réception (début)
    received_to DATE, -- Période de réception (fin)
    
    -- Caractéristiques
    quantity_initial DECIMAL(15,3) NOT NULL, -- Quantité initiale
    quantity_remaining DECIMAL(15,3) NOT NULL, -- Quantité restante
    uom_id UUID NOT NULL REFERENCES units_of_measure(id), -- Unité
    
    -- Coût
    unit_cost DECIMAL(15,4), -- Coût unitaire d'achat
    total_cost DECIMAL(15,4) GENERATED ALWAYS AS (quantity_initial * unit_cost) STORED,
    currency_code CHAR(3) REFERENCES currencies(code),
    
    -- Statut
    lot_status VARCHAR(30) DEFAULT 'active', -- 'active', 'blocked', 'expired', 'depleted', 'quarantine'
    quality_status VARCHAR(30) DEFAULT 'approved', -- 'pending', 'approved', 'rejected', 'quarantine'
    
    -- Blocages
    is_blocked BOOLEAN DEFAULT FALSE,
    block_reason TEXT,
    blocked_by UUID REFERENCES users(id),
    blocked_at TIMESTAMP WITH TIME ZONE,
    
    -- Traçabilité
    purchase_order_id UUID, -- Commande d'achat associée
    purchase_order_line_id UUID,
    goods_receipt_id UUID, -- Réception associée
    goods_receipt_line_id UUID,
    
    -- Certifications
    certificates JSONB, -- Certificats associés (qualité, origine, etc.)
    laboratory_results JSONB, -- Résultats d'analyses
    
    -- Emplacement
    warehouse_id UUID, -- Dépôt principal
    location_id UUID, -- Emplacement principal
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contraintes
    CONSTRAINT valid_dates CHECK (expiry_date IS NULL OR manufacturing_date IS NULL OR expiry_date >= manufacturing_date),
    CONSTRAINT valid_quantity CHECK (quantity_initial >= 0 AND quantity_remaining >= 0 AND quantity_remaining <= quantity_initial)
);

-- Index
CREATE INDEX idx_lots_number ON lots(lot_number);
CREATE INDEX idx_lots_product ON lots(product_id);
CREATE INDEX idx_lots_supplier ON lots(supplier_id);
CREATE INDEX idx_lots_expiry ON lots(expiry_date) WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_lots_status ON lots(lot_status);
CREATE INDEX idx_lots_quality ON lots(quality_status);
CREATE INDEX idx_lots_location ON lots(warehouse_id, location_id);

-- Fonction pour mise à jour automatique de quantity_remaining basée sur les mouvements
-- (sera implémentée avec les triggers sur stock_movements)


CREATE TABLE serial_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identifiants
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    lot_id UUID REFERENCES lots(id) ON DELETE SET NULL, -- Lot associé (optionnel)
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'in_stock', -- 'in_stock', 'reserved', 'sold', 'returned', 'scrapped', 'blocked', 'in_transit', 'in_repair'
    
    -- Traçabilité
    purchase_order_id UUID, -- Commande d'achat
    purchase_order_line_id UUID,
    goods_receipt_id UUID,
    goods_receipt_line_id UUID,
    sales_order_id UUID, -- Commande client
    sales_order_line_id UUID,
    delivery_note_id UUID, -- Bon de livraison
    delivery_note_line_id UUID,
    customer_id UUID, -- Client final
    supplier_id UUID, -- Fournisseur d'origine
    
    -- Dates
    manufacturing_date DATE,
    purchase_date DATE,
    sale_date DATE,
    warranty_start_date DATE,
    warranty_end_date DATE,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    
    -- Caractéristiques
    firmware_version VARCHAR(50),
    hardware_version VARCHAR(50),
    mac_address VARCHAR(17), -- Pour équipements réseau
    imei VARCHAR(15), -- Pour téléphones
    
    -- Localisation
    current_warehouse_id UUID, -- Dépôt actuel
    current_location_id UUID, -- Emplacement actuel
    current_lot_id UUID REFERENCES lots(id), -- Lot actuel (si reconditionné)
    
    -- Historique
    history JSONB, -- Historique des mouvements
    
    -- Audit
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_serial_numbers_number ON serial_numbers(serial_number);
CREATE INDEX idx_serial_numbers_product ON serial_numbers(product_id);
CREATE INDEX idx_serial_numbers_lot ON serial_numbers(lot_id);
CREATE INDEX idx_serial_numbers_status ON serial_numbers(status);
CREATE INDEX idx_serial_numbers_location ON serial_numbers(current_warehouse_id, current_location_id);
CREATE INDEX idx_serial_numbers_customer ON serial_numbers(customer_id);
CREATE INDEX idx_serial_numbers_sale ON serial_numbers(sale_date) WHERE sale_date IS NOT NULL;
CREATE INDEX idx_serial_numbers_warranty ON serial_numbers(warranty_end_date) WHERE warranty_end_date IS NOT NULL;

-- Table de liaison pour l'historique des mouvements
CREATE TABLE serial_number_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    serial_number_id UUID NOT NULL REFERENCES serial_numbers(id) ON DELETE CASCADE,
    movement_type VARCHAR(30) NOT NULL, -- 'receipt', 'transfer', 'sale', 'return', 'scrap'
    movement_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Documents associés
    document_type VARCHAR(30),
    document_id UUID,
    document_line_id UUID,
    
    -- Localisation
    from_warehouse_id UUID,
    from_location_id UUID,
    to_warehouse_id UUID,
    to_location_id UUID,
    
    -- Utilisateur
    user_id UUID REFERENCES users(id),
    
    -- Métadonnées
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_serial_movements_serial ON serial_number_movements(serial_number_id);
CREATE INDEX idx_serial_movements_date ON serial_number_movements(movement_date);


-- Mise à jour des clés étrangères dans products après création des tables
ALTER TABLE products 
    ADD CONSTRAINT fk_products_uom FOREIGN KEY (uom_id) REFERENCES units_of_measure(id),
    ADD CONSTRAINT fk_products_purchase_uom FOREIGN KEY (purchase_uom_id) REFERENCES units_of_measure(id),
    ADD CONSTRAINT fk_products_sales_uom FOREIGN KEY (sales_uom_id) REFERENCES units_of_measure(id),
    ADD CONSTRAINT fk_products_weight_uom FOREIGN KEY (weight_uom_id) REFERENCES units_of_measure(id),
    ADD CONSTRAINT fk_products_volume_uom FOREIGN KEY (volume_uom_id) REFERENCES units_of_measure(id),
    ADD CONSTRAINT fk_products_default_warehouse FOREIGN KEY (default_warehouse_id) REFERENCES warehouses(id),
    ADD CONSTRAINT fk_products_default_location FOREIGN KEY (default_location_id) REFERENCES locations(id),
    ADD CONSTRAINT fk_products_preferred_supplier FOREIGN KEY (preferred_supplier_id) REFERENCES suppliers(id);

-- Mise à jour des clés étrangères dans product_categories
ALTER TABLE product_categories
    ADD CONSTRAINT fk_categories_uom FOREIGN KEY (default_uom_id) REFERENCES units_of_measure(id),
    ADD CONSTRAINT fk_categories_purchase_uom FOREIGN KEY (default_purchase_uom_id) REFERENCES units_of_measure(id),
    ADD CONSTRAINT fk_categories_sales_uom FOREIGN KEY (default_sales_uom_id) REFERENCES units_of_measure(id);






    CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identifiants
    code VARCHAR(50) NOT NULL UNIQUE,
    legal_name VARCHAR(255) NOT NULL,
    commercial_name VARCHAR(255),
    tax_id VARCHAR(50) UNIQUE, -- SIRET, TVA intracommunautaire
    tax_id_type VARCHAR(20) DEFAULT 'SIRET', -- 'SIRET', 'VAT', 'RNC'
    registration_number VARCHAR(50), -- RCS, Registre de commerce
    
    -- Classification
    supplier_type VARCHAR(30) NOT NULL DEFAULT 'regular', -- 'regular', 'occasional', 'strategic', 'preferred', 'approved'
    supplier_category VARCHAR(50), -- Catégorie d'achat (matières premières, services, etc.)
    industry_sector VARCHAR(100), -- Secteur d'activité
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité légale rattachée
    site_id UUID REFERENCES sites(id), -- ✅ Site rattaché (optionnel)
    
    -- Coordonnées
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL REFERENCES countries(iso_code), -- ✅ Pays
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(255),
    website VARCHAR(255),
    
    -- Communication
    preferred_contact_method VARCHAR(20) DEFAULT 'email', -- 'email', 'phone', 'mail'
    language VARCHAR(10) DEFAULT 'fr', -- Langue de correspondance
    communication_notes TEXT,
    
    -- Financier
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise par défaut
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Conditions paiement par défaut
    delivery_term_id UUID REFERENCES delivery_terms(id), -- ✅ Incoterm par défaut
    bank_account_iban VARCHAR(34),
    bank_account_bic VARCHAR(11),
    bank_name VARCHAR(255),
    payment_method VARCHAR(30), -- 'transfer', 'check', 'letter_of_credit'
    
    -- Fiscal
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA par défaut
    tax_regime VARCHAR(50), -- Régime fiscal applicable
    is_intracommunity BOOLEAN DEFAULT FALSE, -- Échanges intra-UE
    
    -- Commercial
    account_manager_id UUID REFERENCES users(id), -- ✅ Commercial acheteur responsable
    sales_contact_name VARCHAR(255),
    sales_contact_email VARCHAR(255),
    sales_contact_phone VARCHAR(30),
    
    -- Performance
    quality_rating DECIMAL(2,1) DEFAULT 0, -- Note qualité (0-5)
    delivery_rating DECIMAL(2,1) DEFAULT 0, -- Note délais
    price_rating DECIMAL(2,1) DEFAULT 0, -- Note prix
    overall_rating DECIMAL(2,1) GENERATED ALWAYS AS ((quality_rating + delivery_rating + price_rating) / 3) STORED,
    
    -- Statut
    supplier_status VARCHAR(30) DEFAULT 'active', -- 'active', 'inactive', 'blacklisted', 'prospect', 'in_approval'
    approval_date DATE,
    approved_by UUID REFERENCES users(id),
    blacklist_reason TEXT,
    
    -- Dates clés
    first_purchase_date DATE,
    last_purchase_date DATE,
    total_purchases_amount DECIMAL(15,2) DEFAULT 0,
    total_purchases_currency CHAR(3) REFERENCES currencies(code),
    
    -- Certifications
    certifications JSONB, -- ISO 9001, etc.
    documents JSONB, -- URLs des documents (KBIS, assurances)
    
    -- Relations
    parent_supplier_id UUID REFERENCES suppliers(id), -- Si groupe fournisseur
    is_active BOOLEAN DEFAULT TRUE,
    is_preferred BOOLEAN DEFAULT FALSE,
    
    -- Notes
    notes TEXT,
    internal_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK (phone IS NULL OR phone ~* '^[+]?[0-9\s\-()]{8,}$')
);

-- Index
CREATE INDEX idx_suppliers_code ON suppliers(code);
CREATE INDEX idx_suppliers_tax_id ON suppliers(tax_id);
CREATE INDEX idx_suppliers_entity ON suppliers(entity_id);
CREATE INDEX idx_suppliers_country ON suppliers(country_code);
CREATE INDEX idx_suppliers_status ON suppliers(supplier_status);
CREATE INDEX idx_suppliers_rating ON suppliers(overall_rating);
CREATE INDEX idx_suppliers_manager ON suppliers(account_manager_id);
CREATE INDEX idx_suppliers_parent ON suppliers(parent_supplier_id);

-- Commentaires
COMMENT ON TABLE suppliers IS 'Fournisseurs';
COMMENT ON COLUMN suppliers.code IS 'Code fournisseur unique';
COMMENT ON COLUMN suppliers.tax_id IS 'Numéro de TVA intracommunautaire ou SIRET';


CREATE TABLE supplier_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    
    -- Identité
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(255),
    department VARCHAR(100),
    
    -- Rôle chez le fournisseur
    contact_role VARCHAR(50) NOT NULL, -- 'sales', 'technical', 'accounting', 'management', 'logistics'
    is_primary BOOLEAN DEFAULT FALSE, -- Contact principal ?
    
    -- Coordonnées
    email VARCHAR(255),
    phone_direct VARCHAR(30),
    phone_mobile VARCHAR(30),
    fax VARCHAR(30),
    
    -- Communication
    preferred_contact_method VARCHAR(20) DEFAULT 'email',
    language VARCHAR(10) DEFAULT 'fr',
    best_time_to_call TIME,
    
    -- Adresse (si différente du fournisseur)
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    country_code CHAR(2) REFERENCES countries(iso_code), -- ✅ Pays
    
    -- Réseaux sociaux
    linkedin_profile VARCHAR(255),
    
    -- Notes
    notes TEXT,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT unique_supplier_contact_email UNIQUE (supplier_id, email)
);

-- Index
CREATE INDEX idx_supplier_contacts_supplier ON supplier_contacts(supplier_id);
CREATE INDEX idx_supplier_contacts_email ON supplier_contacts(email);
CREATE INDEX idx_supplier_contacts_role ON supplier_contacts(contact_role);
CREATE INDEX idx_supplier_contacts_primary ON supplier_contacts(is_primary) WHERE is_primary = TRUE;



CREATE TABLE supplier_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_number VARCHAR(50) NOT NULL UNIQUE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    
    -- Informations générales
    title VARCHAR(255) NOT NULL,
    description TEXT,
    contract_type VARCHAR(50) NOT NULL, -- 'framework', 'purchase', 'service', 'maintenance', 'nda', 'quality'
    
    -- Dates
    start_date DATE NOT NULL,
    end_date DATE,
    renewal_date DATE,
    is_auto_renew BOOLEAN DEFAULT FALSE,
    renewal_notice_days INTEGER DEFAULT 30, -- Jours de préavis pour non-reconduction
    
    -- Valeurs
    contract_value DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    estimated_annual_value DECIMAL(15,2),
    
    -- Conditions
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Conditions de paiement
    delivery_term_id UUID REFERENCES delivery_terms(id), -- ✅ Conditions de livraison
    
    -- Engagements
    minimum_purchase_quantity DECIMAL(15,3),
    minimum_purchase_amount DECIMAL(15,2),
    volume_discounts JSONB, -- Remises selon volume
    
    -- Documents
    contract_file_url TEXT,
    supporting_documents JSONB,
    
    -- Gestion
    responsible_id UUID REFERENCES users(id), -- ✅ Responsable chez l'acheteur
    supplier_contact_id UUID REFERENCES supplier_contacts(id), -- ✅ Contact fournisseur
    is_exclusive BOOLEAN DEFAULT FALSE, -- Exclusivité ?
    
    -- Statut
    contract_status VARCHAR(30) DEFAULT 'active', -- 'draft', 'active', 'expired', 'terminated', 'renewed'
    termination_reason TEXT,
    terminated_by UUID REFERENCES users(id),
    terminated_at TIMESTAMP WITH TIME ZONE,
    
    -- KPIs
    quality_clauses TEXT,
    penalty_clauses TEXT,
    service_level_agreement TEXT,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contraintes
    CONSTRAINT valid_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Index
CREATE INDEX idx_supplier_contracts_supplier ON supplier_contracts(supplier_id);
CREATE INDEX idx_supplier_contracts_number ON supplier_contracts(contract_number);
CREATE INDEX idx_supplier_contracts_status ON supplier_contracts(contract_status);
CREATE INDEX idx_supplier_contracts_dates ON supplier_contracts(start_date, end_date);
CREATE INDEX idx_supplier_contracts_responsible ON supplier_contracts(responsible_id);

-- Table des articles couverts par le contrat
CREATE TABLE supplier_contract_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES supplier_contracts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE, -- ✅ Produit
    product_category_id UUID REFERENCES product_categories(id), -- ✅ Catégorie (alternative)
    
    -- Conditions spécifiques au produit
    price DECIMAL(15,4),
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    discount_percentage DECIMAL(5,2),
    minimum_quantity DECIMAL(15,3),
    maximum_quantity DECIMAL(15,3),
    
    -- Validité
    valid_from DATE,
    valid_to DATE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    CONSTRAINT unique_contract_product UNIQUE (contract_id, product_id)
);

CREATE INDEX idx_contract_products_contract ON supplier_contract_products(contract_id);
CREATE INDEX idx_contract_products_product ON supplier_contract_products(product_id); 


CREATE TABLE supplier_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    
    -- Évaluation générale
    rating_date DATE NOT NULL DEFAULT CURRENT_DATE,
    rating_period VARCHAR(20) DEFAULT 'monthly', -- 'monthly', 'quarterly', 'yearly', 'ad-hoc'
    overall_score DECIMAL(3,1) NOT NULL CHECK (overall_score BETWEEN 0 AND 5),
    
    -- Critères détaillés (notation sur 5)
    quality_score DECIMAL(3,1) CHECK (quality_score BETWEEN 0 AND 5),
    delivery_score DECIMAL(3,1) CHECK (delivery_score BETWEEN 0 AND 5),
    price_score DECIMAL(3,1) CHECK (price_score BETWEEN 0 AND 5),
    service_score DECIMAL(3,1) CHECK (service_score BETWEEN 0 AND 5),
    responsiveness_score DECIMAL(3,1) CHECK (responsiveness_score BETWEEN 0 AND 5),
    innovation_score DECIMAL(3,1) CHECK (innovation_score BETWEEN 0 AND 5),
    compliance_score DECIMAL(3,1) CHECK (compliance_score BETWEEN 0 AND 5),
    
    -- Évaluateur
    evaluator_id UUID NOT NULL REFERENCES users(id), -- ✅ Utilisateur évaluateur
    department_id UUID REFERENCES departments(id), -- ✅ Département évaluateur
    
    -- Données objectives (basées sur les transactions)
    period_start DATE,
    period_end DATE,
    total_orders_count INTEGER,
    on_time_delivery_count INTEGER,
    on_time_delivery_rate DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN total_orders_count > 0 THEN (on_time_delivery_count * 100.0 / total_orders_count) ELSE 0 END) STORED,
    defective_products_count INTEGER,
    defective_rate DECIMAL(5,2),
    returns_count INTEGER,
    
    -- Commentaires
    strengths TEXT,
    weaknesses TEXT,
    improvement_suggestions TEXT,
    comments TEXT,
    
    -- Décisions
    requires_action_plan BOOLEAN DEFAULT FALSE,
    action_plan_due_date DATE,
    action_plan_completed BOOLEAN DEFAULT FALSE,
    next_review_date DATE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    is_active BOOLEAN DEFAULT TRUE
);

-- Index
CREATE INDEX idx_supplier_ratings_supplier ON supplier_ratings(supplier_id);
CREATE INDEX idx_supplier_ratings_date ON supplier_ratings(rating_date);
CREATE INDEX idx_supplier_ratings_evaluator ON supplier_ratings(evaluator_id);

-- Table des incidents/événements d'évaluation
CREATE TABLE supplier_rating_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    
    -- Type d'événement
    event_type VARCHAR(50) NOT NULL, -- 'late_delivery', 'defective_product', 'price_increase', 'quality_issue', 'communication_issue', 'positive_feedback'
    event_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Références
    purchase_order_id UUID, -- Commande concernée
    goods_receipt_id UUID, -- Réception concernée
    
    -- Détails
    severity VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    description TEXT NOT NULL,
    financial_impact DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Résolution
    resolved BOOLEAN DEFAULT FALSE,
    resolved_date TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id) -- ✅ Utilisateur
);

CREATE INDEX idx_supplier_events_supplier ON supplier_rating_events(supplier_id);
CREATE INDEX idx_supplier_events_type ON supplier_rating_events(event_type);
CREATE INDEX idx_supplier_events_date ON supplier_rating_events(event_date);


CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identifiants
    code VARCHAR(50) NOT NULL UNIQUE,
    legal_name VARCHAR(255) NOT NULL,
    commercial_name VARCHAR(255),
    tax_id VARCHAR(50) UNIQUE, -- TVA intracommunautaire
    tax_id_type VARCHAR(20) DEFAULT 'SIRET',
    registration_number VARCHAR(50), -- RCS
    
    -- Classification
    customer_type VARCHAR(30) NOT NULL DEFAULT 'company', -- 'individual', 'company', 'public', 'association'
    customer_category VARCHAR(50), -- Catégorie client
    customer_segment_id UUID, -- ✅ Segment client (table à venir)
    industry_sector VARCHAR(100),
    
    -- Entités
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité légale qui facture
    site_id UUID REFERENCES sites(id), -- ✅ Site de rattachement
    sales_rep_id UUID REFERENCES users(id), -- ✅ Commercial responsable
    account_manager_id UUID REFERENCES users(id), -- ✅ Gestionnaire de compte
    
    -- Coordonnées principales
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL REFERENCES countries(iso_code), -- ✅ Pays
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(255),
    website VARCHAR(255),
    
    -- Adresse de livraison (si différente)
    delivery_address_line1 VARCHAR(255),
    delivery_address_line2 VARCHAR(255),
    delivery_postal_code VARCHAR(20),
    delivery_city VARCHAR(100),
    delivery_country_code CHAR(2) REFERENCES countries(iso_code),
    
    -- Financier
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise par défaut
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Conditions de paiement
    delivery_term_id UUID REFERENCES delivery_terms(id), -- ✅ Conditions de livraison
    price_list_id UUID, -- ✅ Liste de prix (table à venir)
    
    -- Limites de crédit
    credit_limit DECIMAL(15,2),
    credit_limit_currency CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    credit_balance DECIMAL(15,2) DEFAULT 0,
    credit_status VARCHAR(20) DEFAULT 'good', -- 'good', 'warning', 'blocked', 'overdue'
    credit_notes TEXT,
    
    -- Facturation
    invoice_language VARCHAR(10) DEFAULT 'fr',
    invoice_delivery_method VARCHAR(20) DEFAULT 'email', -- 'email', 'post', 'edi'
    invoice_email VARCHAR(255),
    billing_contact VARCHAR(255),
    
    -- Statistiques
    first_sale_date DATE,
    last_sale_date DATE,
    total_sales_amount DECIMAL(15,2) DEFAULT 0,
    total_sales_currency CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    average_order_value DECIMAL(15,2),
    lifetime_value DECIMAL(15,2),
    
    -- Statut
    customer_status VARCHAR(30) DEFAULT 'active', -- 'active', 'inactive', 'prospect', 'lead', 'blacklisted'
    blacklist_reason TEXT,
    blacklisted_at TIMESTAMP WITH TIME ZONE,
    blacklisted_by UUID REFERENCES users(id),
    
    -- Marketing
    marketing_consent BOOLEAN DEFAULT FALSE,
    consent_date DATE,
    newsletter_subscription BOOLEAN DEFAULT FALSE,
    do_not_disturb BOOLEAN DEFAULT FALSE,
    
    -- Notes
    notes TEXT,
    internal_notes TEXT,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Index
CREATE INDEX idx_customers_code ON customers(code);
CREATE INDEX idx_customers_tax_id ON customers(tax_id);
CREATE INDEX idx_customers_entity ON customers(entity_id);
CREATE INDEX idx_customers_country ON customers(country_code);
CREATE INDEX idx_customers_sales_rep ON customers(sales_rep_id);
CREATE INDEX idx_customers_segment ON customers(customer_segment_id);
CREATE INDEX idx_customers_status ON customers(customer_status);
CREATE INDEX idx_customers_credit ON customers(credit_status);


CREATE TABLE customer_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    
    -- Identité
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(255),
    department VARCHAR(100),
    
    -- Rôles
    contact_role VARCHAR(50) NOT NULL, -- 'decision_maker', 'buyer', 'technical', 'accounting', 'logistics', 'management'
    is_primary BOOLEAN DEFAULT FALSE, -- Contact principal ?
    is_billing_contact BOOLEAN DEFAULT FALSE, -- Contact facturation ?
    is_delivery_contact BOOLEAN DEFAULT FALSE, -- Contact livraison ?
    is_technical_contact BOOLEAN DEFAULT FALSE, -- Contact technique ?
    
    -- Coordonnées
    email VARCHAR(255),
    phone_direct VARCHAR(30),
    phone_mobile VARCHAR(30),
    
    -- Communication
    preferred_contact_method VARCHAR(20) DEFAULT 'email',
    language VARCHAR(10) DEFAULT 'fr',
    
    -- Adresse (si différente du client)
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    country_code CHAR(2) REFERENCES countries(iso_code), -- ✅ Pays
    
    -- Réseaux sociaux
    linkedin_profile VARCHAR(255),
    
    -- Authentification (si portail client)
    has_portal_access BOOLEAN DEFAULT FALSE,
    portal_user_id UUID REFERENCES users(id), -- ✅ Lien vers utilisateur si compte portail
    last_login TIMESTAMP WITH TIME ZONE,
    
    -- Préférences
    notification_preferences JSONB, -- Types de notifications souhaitées
    
    -- Notes
    notes TEXT,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT unique_customer_contact_email UNIQUE (customer_id, email)
);

-- Index
CREATE INDEX idx_customer_contacts_customer ON customer_contacts(customer_id);
CREATE INDEX idx_customer_contacts_email ON customer_contacts(email);
CREATE INDEX idx_customer_contacts_role ON customer_contacts(contact_role);
CREATE INDEX idx_customer_contacts_primary ON customer_contacts(is_primary) WHERE is_primary = TRUE;



CREATE TABLE customer_price_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Type de liste
    price_list_type VARCHAR(30) NOT NULL, -- 'standard', 'promotional', 'contract', 'volume', 'seasonal'
    
    -- Période de validité
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Devise
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Application
    applies_to VARCHAR(20) DEFAULT 'all', -- 'all', 'customers', 'segments', 'categories'
    
    -- Priorité (la liste avec la priorité la plus élevée est appliquée)
    priority INTEGER DEFAULT 0,
    
    -- Règle de calcul
    calculation_method VARCHAR(30) DEFAULT 'fixed', -- 'fixed', 'percentage_markup', 'percentage_discount', 'formula'
    base_price_list_id UUID REFERENCES customer_price_lists(id), -- Pour les listes dérivées
    adjustment_percentage DECIMAL(5,2), -- % d'ajustement par rapport à la liste de base
    adjustment_formula TEXT, -- Formule personnalisée
    
    -- Approbation
    requires_approval BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES users(id), -- ✅ Utilisateur
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table des prix par article dans la liste
CREATE TABLE customer_price_list_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    price_list_id UUID NOT NULL REFERENCES customer_price_lists(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE, -- ✅ Produit
    product_category_id UUID REFERENCES product_categories(id) ON DELETE CASCADE, -- ✅ Catégorie (alternative)
    
    -- Prix
    price DECIMAL(15,4) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    unit_of_measure_id UUID REFERENCES units_of_measure(id), -- ✅ Unité de vente
    
    -- Structure de prix par quantité
    min_quantity DECIMAL(15,3) DEFAULT 1,
    max_quantity DECIMAL(15,3),
    
    -- Remises
    discount_type VARCHAR(20), -- 'percentage', 'fixed', 'none'
    discount_value DECIMAL(15,4),
    
    -- Dates spécifiques à l'article
    valid_from DATE,
    valid_to DATE,
    
    -- Priorité
    priority INTEGER DEFAULT 0,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contraintes
    CONSTRAINT valid_product_xor_category CHECK (
        (product_id IS NOT NULL AND product_category_id IS NULL) OR
        (product_id IS NULL AND product_category_id IS NOT NULL)
    )
);

-- Table d'attribution des listes de prix aux clients
CREATE TABLE customer_price_list_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    price_list_id UUID NOT NULL REFERENCES customer_price_lists(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE, -- ✅ Client spécifique
    customer_segment_id UUID REFERENCES customer_segments(id) ON DELETE CASCADE, -- ✅ Segment (table à venir)
    customer_category VARCHAR(50), -- Catégorie de client
    
    -- Priorité d'application
    priority INTEGER DEFAULT 0,
    
    -- Dates d'application
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contraintes
    CONSTRAINT valid_assignment CHECK (
        (customer_id IS NOT NULL AND customer_segment_id IS NULL) OR
        (customer_id IS NULL AND customer_segment_id IS NOT NULL) OR
        (customer_id IS NULL AND customer_segment_id IS NULL AND customer_category IS NOT NULL)
    )
);

-- Index
CREATE INDEX idx_price_lists_code ON customer_price_lists(code);
CREATE INDEX idx_price_lists_validity ON customer_price_lists(valid_from, valid_to);
CREATE INDEX idx_price_list_items_product ON customer_price_list_items(product_id);
CREATE INDEX idx_price_list_items_category ON customer_price_list_items(product_category_id);
CREATE INDEX idx_price_list_assignments_customer ON customer_price_list_assignments(customer_id);
CREATE INDEX idx_price_list_assignments_segment ON customer_price_list_assignments(customer_segment_id);


CREATE TABLE customer_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Type de segmentation
    segment_type VARCHAR(30) NOT NULL, -- 'geographic', 'demographic', 'behavioral', 'value', 'industry', 'custom'
    
    -- Hiérarchie
    parent_segment_id UUID REFERENCES customer_segments(id),
    level INTEGER DEFAULT 1,
    path VARCHAR(1000),
    
    -- Critères de segmentation (pour segmentation dynamique)
    criteria JSONB, -- Critères SQL/JSON pour définir le segment
    
    -- Segmentation statique ou dynamique
    is_dynamic BOOLEAN DEFAULT FALSE, -- FALSE = segment manuel, TRUE = segment basé sur critères
    auto_update BOOLEAN DEFAULT TRUE, -- Mise à jour automatique des membres ?
    
    -- Marketing
    marketing_campaign_allowed BOOLEAN DEFAULT TRUE,
    default_discount_percentage DECIMAL(5,2), -- Remise par défaut pour ce segment
    
    -- Priorité
    priority INTEGER DEFAULT 0,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table de liaison clients-segments (pour segments statiques)
CREATE TABLE customer_segment_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    segment_id UUID NOT NULL REFERENCES customer_segments(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    
    -- Dates d'appartenance
    from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    to_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Raison de l'affectation
    assignment_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur
    
    -- Contrainte d'unicité
    CONSTRAINT unique_customer_segment UNIQUE (segment_id, customer_id, from_date)
);

-- Index
CREATE INDEX idx_customer_segments_code ON customer_segments(code);
CREATE INDEX idx_customer_segments_parent ON customer_segments(parent_segment_id);
CREATE INDEX idx_segment_members_segment ON customer_segment_members(segment_id);
CREATE INDEX idx_segment_members_customer ON customer_segment_members(customer_id);
CREATE INDEX idx_segment_members_active ON customer_segment_members(is_active) WHERE is_active = TRUE;

-- Fonction pour mise à jour du path
CREATE OR REPLACE FUNCTION update_segment_path()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_segment_id IS NULL THEN
        NEW.path := '/' || NEW.id || '/';
        NEW.level := 1;
    ELSE
        SELECT path INTO NEW.path FROM customer_segments WHERE id = NEW.parent_segment_id;
        NEW.path := NEW.path || NEW.id || '/';
        NEW.level := (SELECT level FROM customer_segments WHERE id = NEW.parent_segment_id) + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_segment_path
    BEFORE INSERT OR UPDATE ON customer_segments
    FOR EACH ROW
    EXECUTE FUNCTION update_segment_path(); 



    CREATE TABLE carriers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    
    -- Type de transporteur
    carrier_type VARCHAR(30) NOT NULL, -- 'road', 'air', 'sea', 'rail', 'courier', 'express'
    
    -- Coordonnées
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    country_code CHAR(2) REFERENCES countries(iso_code), -- ✅ Pays
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(255),
    website VARCHAR(255),
    
    -- Contact principal
    contact_name VARCHAR(255),
    contact_phone VARCHAR(30),
    contact_email VARCHAR(255),
    
    -- Services
    services_offered JSONB, -- Liste des services (express, standard, international, etc.)
    delivery_zones JSONB, -- Zones de livraison
    
    -- Tarification
    pricing_model VARCHAR(30) DEFAULT 'weight', -- 'weight', 'volume', 'parcel', 'distance', 'flat'
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    min_charge DECIMAL(15,2),
    rate_per_kg DECIMAL(15,4),
    rate_per_m3 DECIMAL(15,4),
    
    -- Délais
    standard_transit_days INTEGER,
    express_transit_days INTEGER,
    guaranteed_delivery BOOLEAN DEFAULT FALSE,
    
    -- Suivi
    tracking_url_template VARCHAR(500), -- URL avec placeholder pour le N° de suivi
    supports_tracking BOOLEAN DEFAULT TRUE,
    
    -- Intégration
    api_endpoint VARCHAR(500),
    api_key VARCHAR(255),
    api_secret VARCHAR(255),
    
    -- Documents
    requires_shipping_label BOOLEAN DEFAULT TRUE,
    label_format VARCHAR(20), -- 'PDF', 'ZPL', 'EPL'
    
    -- Assurance
    insurance_available BOOLEAN DEFAULT FALSE,
    insurance_rate DECIMAL(5,2), -- % de la valeur
    
    -- Statut
    is_preferred BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur,
    
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Table des services par transporteur
CREATE TABLE carrier_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carrier_id UUID NOT NULL REFERENCES carriers(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Type de service
    service_type VARCHAR(30) NOT NULL, -- 'express', 'standard', 'economy', 'international', 'same_day', 'scheduled'
    
    -- Délais
    transit_days_min INTEGER,
    transit_days_max INTEGER,
    guaranteed BOOLEAN DEFAULT FALSE,
    
    -- Zones
    applicable_zones JSONB,
    
    -- Tarifs
    pricing_rules JSONB,
    
    -- Particularités
    max_weight DECIMAL(15,3),
    max_dimensions JSONB, -- Longueur, largeur, hauteur max
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur,
    
    CONSTRAINT unique_carrier_service UNIQUE (carrier_id, code)
);

-- Table des zones de livraison par transporteur
CREATE TABLE carrier_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carrier_id UUID NOT NULL REFERENCES carriers(id) ON DELETE CASCADE,
    zone_code VARCHAR(50) NOT NULL,
    zone_name VARCHAR(255) NOT NULL,
    
    -- Pays couverts
    countries TEXT[], -- Liste des codes pays ISO
    
    -- Régions (postal codes)
    postal_code_ranges JSONB, -- Ranges de codes postaux
    
    -- Tarifs spécifiques à la zone
    base_rate DECIMAL(15,2),
    rate_per_kg DECIMAL(15,4),
    rate_per_m3 DECIMAL(15,4),
    
    -- Délais
    transit_days INTEGER,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id), -- ✅ Utilisateur
    updated_by UUID REFERENCES users(id), -- ✅ Utilisateur,
    
    CONSTRAINT unique_carrier_zone UNIQUE (carrier_id, zone_code)
);

-- Index
CREATE INDEX idx_carriers_code ON carriers(code);
CREATE INDEX idx_carriers_type ON carriers(carrier_type);
CREATE INDEX idx_carriers_active ON carriers(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_carrier_services_carrier ON carrier_services(carrier_id);
CREATE INDEX idx_carrier_zones_carrier ON carrier_zones(carrier_id);


-- Recréation de la table users (version complète)
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identifiants
    username VARCHAR(50) NOT NULL UNIQUE,
    employee_id VARCHAR(50) UNIQUE, -- Matricule RH
    email VARCHAR(255) NOT NULL UNIQUE,
    
    -- Identité
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(255) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    job_title VARCHAR(255),
    
    -- Authentification
    password_hash VARCHAR(255) NOT NULL,
    password_salt VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP WITH TIME ZONE,
    two_factor_secret VARCHAR(255),
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    
    -- Organisation
    entity_id UUID REFERENCES entities(id), -- ✅ Entité légale principale
    department_id UUID REFERENCES departments(id), -- ✅ Département
    site_id UUID REFERENCES sites(id), -- ✅ Site principal
    manager_id UUID REFERENCES users(id), -- ✅ N+1
    
    -- Coordonnées
    phone_work VARCHAR(30),
    phone_mobile VARCHAR(30),
    phone_personal VARCHAR(30),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    country_code CHAR(2) REFERENCES countries(iso_code), -- ✅ Pays
    
    -- Préférences
    language VARCHAR(10) DEFAULT 'fr',
    date_format VARCHAR(20) DEFAULT 'DD/MM/YYYY',
    time_format VARCHAR(20) DEFAULT 'HH:mm',
    timezone VARCHAR(50) DEFAULT 'Europe/Paris',
    notification_preferences JSONB, -- Préférences de notifications
    dashboard_config JSONB, -- Configuration du tableau de bord
    
    -- Sécurité
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    must_change_password BOOLEAN DEFAULT FALSE,
    password_changed_at TIMESTAMP WITH TIME ZONE,
    
    -- Statut RH
    employment_type VARCHAR(30), -- 'permanent', 'contractor', 'intern', 'temporary'
    hire_date DATE,
    termination_date DATE,
    
    -- Statut compte
    account_status VARCHAR(30) DEFAULT 'active', -- 'active', 'inactive', 'locked', 'suspended', 'terminated'
    is_active BOOLEAN DEFAULT TRUE,
    is_system_account BOOLEAN DEFAULT FALSE, -- Compte technique (API)
    is_service_account BOOLEAN DEFAULT FALSE, -- Compte de service
    
    -- Métadonnées
    avatar_url TEXT,
    signature TEXT, -- Signature électronique
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK (phone_mobile IS NULL OR phone_mobile ~* '^[+]?[0-9\s\-()]{8,}$')
);

-- Index
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_employee ON users(employee_id);
CREATE INDEX idx_users_entity ON users(entity_id);
CREATE INDEX idx_users_department ON users(department_id);
CREATE INDEX idx_users_site ON users(site_id);
CREATE INDEX idx_users_manager ON users(manager_id);
CREATE INDEX idx_users_status ON users(account_status);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = TRUE;

-- Commentaires
COMMENT ON TABLE users IS 'Utilisateurs du système';
COMMENT ON COLUMN users.two_factor_enabled IS 'Authentification à deux facteurs activée';
COMMENT ON COLUMN users.is_system_account IS 'Compte technique pour intégrations API';








CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Type de rôle
    role_type VARCHAR(30) NOT NULL, -- 'system', 'business', 'workflow'
    role_level INTEGER DEFAULT 1, -- Niveau hiérarchique (1=opérateur, 2=superviseur, 3=manager, 4=directeur, 5=admin)
    
    -- Hiérarchie des rôles
    parent_role_id UUID REFERENCES roles(id), -- Héritage de permissions
    is_inheritable BOOLEAN DEFAULT TRUE, -- Les permissions peuvent-elles être héritées ?
    
    -- Périmètre par défaut
    default_scope VARCHAR(30) DEFAULT 'entity', -- 'global', 'entity', 'site', 'department', 'self'
    
    -- Classification par département
    department_type VARCHAR(30), -- 'achats', 'ventes', 'magasin', 'finance', 'direction', 'rh', 'it', 'admin'
    
    -- Métadonnées
    is_system_role BOOLEAN DEFAULT FALSE, -- Rôle système (non modifiable)
    is_default BOOLEAN DEFAULT FALSE, -- Rôle attribué par défaut aux nouveaux utilisateurs
    priority INTEGER DEFAULT 0, -- Priorité en cas de conflit
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Index
CREATE INDEX idx_roles_code ON roles(code);
CREATE INDEX idx_roles_type ON roles(role_type);
CREATE INDEX idx_roles_level ON roles(role_level);
CREATE INDEX idx_roles_department ON roles(department_type);
CREATE INDEX idx_roles_parent ON roles(parent_role_id);

-- Insertion des rôles de base (système)
INSERT INTO roles (code, name, description, role_type, role_level, department_type, is_system_role) VALUES
-- Rôles transverses
('SUPER_ADMIN', 'Super Administrateur', 'Accès complet à toutes les fonctionnalités', 'system', 5, 'admin', TRUE),
('ADMIN', 'Administrateur', 'Administration du système', 'system', 4, 'admin', TRUE),
('AUDITOR', 'Auditeur', 'Accès en lecture seule pour audits', 'system', 3, 'finance', TRUE),

-- Achats
('BUYER', 'Acheteur', 'Gestion des achats et commandes fournisseurs', 'business', 2, 'achats', TRUE),
('BUYER_MANAGER', 'Responsable Achats', 'Supervision des achats, validation des commandes', 'business', 3, 'achats', TRUE),
('PURCHASE_REQUESTER', 'Demandeur', 'Création de demandes dachat', 'business', 1, 'achats', TRUE),
('PURCHASE_APPROVER_N1', 'Approbateur N1', 'Approbation des DA niveau 1', 'workflow', 2, 'achats', TRUE),
('PURCHASE_APPROVER_N2', 'Approbateur N2', 'Approbation des DA niveau 2', 'workflow', 3, 'achats', TRUE),
('PURCHASE_APPROVER_N3', 'Approbateur N3', 'Approbation des DA niveau 3 (direction)', 'workflow', 4, 'direction', TRUE),

-- Ventes
('SALES_REP', 'Commercial', 'Gestion des devis et commandes clients', 'business', 2, 'ventes', TRUE),
('SALES_MANAGER', 'Responsable Commercial', 'Supervision des ventes, validation remises', 'business', 3, 'ventes', TRUE),
('SALES_ADMIN', 'Assistant Commercial', 'Support aux ventes', 'business', 1, 'ventes', TRUE),

-- Magasin / Stock
('WAREHOUSE_RECEIVER', 'Magasinier Réception', 'Gestion des réceptions fournisseurs', 'business', 1, 'magasin', TRUE),
('WAREHOUSE_PICKER', 'Magasinier Préparateur', 'Préparation des commandes', 'business', 1, 'magasin', TRUE),
('WAREHOUSE_MANAGER', 'Chef de Magasin', 'Gestion du dépôt, validation inventaires', 'business', 3, 'magasin', TRUE),
('INVENTORY_CONTROLLER', 'Contrôleur Inventaire', 'Réalisation des inventaires', 'business', 2, 'magasin', TRUE),

-- Finance
('ACCOUNTANT_PAYABLE', 'Comptable Fournisseur', 'Gestion factures fournisseurs', 'business', 2, 'finance', TRUE),
('ACCOUNTANT_RECEIVABLE', 'Comptable Client', 'Gestion factures clients', 'business', 2, 'finance', TRUE),
('FINANCE_CONTROLLER', 'Contrôleur de Gestion', 'Analyse financière, KPI', 'business', 3, 'finance', TRUE),
('CFO', 'Directeur Financier', 'Validation exceptionnelle, clôtures', 'business', 4, 'finance', TRUE),

-- Direction
('CEO', 'Directeur Général', 'Direction générale, signatures légales', 'business', 5, 'direction', TRUE),
('COO', 'Directeur Opérations', 'Supervision des opérations', 'business', 4, 'direction', TRUE),

-- RH
('HR_MANAGER', 'Responsable RH', 'Gestion des utilisateurs, habilitations', 'business', 3, 'rh', TRUE),
('HR_ASSISTANT', 'Assistant RH', 'Support RH', 'business', 2, 'rh', TRUE);

-- Mise à jour des relations parentales
UPDATE roles SET parent_role_id = (SELECT id FROM roles WHERE code = 'BUYER_MANAGER') WHERE code IN ('BUYER', 'PURCHASE_REQUESTER');
UPDATE roles SET parent_role_id = (SELECT id FROM roles WHERE code = 'SALES_MANAGER') WHERE code = 'SALES_REP';
UPDATE roles SET parent_role_id = (SELECT id FROM roles WHERE code = 'WAREHOUSE_MANAGER') WHERE code IN ('WAREHOUSE_RECEIVER', 'WAREHOUSE_PICKER', 'INVENTORY_CONTROLLER');
UPDATE roles SET parent_role_id = (SELECT id FROM roles WHERE code = 'CFO') WHERE code = 'FINANCE_CONTROLLER';
UPDATE roles SET parent_role_id = (SELECT id FROM roles WHERE code = 'CEO') WHERE code IN ('COO', 'CFO');

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Catégorisation
    module VARCHAR(50) NOT NULL, -- 'purchasing', 'sales', 'inventory', 'finance', 'admin', 'reporting'
    resource VARCHAR(100) NOT NULL, -- 'purchase_order', 'sales_order', 'product', 'customer'
    action VARCHAR(50) NOT NULL, -- 'create', 'read', 'update', 'delete', 'approve', 'validate', 'export', 'print'
    
    -- Permission composée
    permission_type VARCHAR(20) DEFAULT 'standard', -- 'standard', 'composite', 'system'
    depends_on UUID[] DEFAULT '{}', -- Liste des permissions requises
    
    -- Périmètre applicable
    applicable_scope VARCHAR(30) DEFAULT 'all', -- 'all', 'entity', 'site', 'department', 'self'
    
    -- Métadonnées
    is_system_permission BOOLEAN DEFAULT FALSE,
    is_risk_sensitive BOOLEAN DEFAULT FALSE, -- Permission sensible (fraude, etc.)
    requires_approval BOOLEAN DEFAULT FALSE, -- Nécessite une double validation
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_permissions_code ON permissions(code);
CREATE INDEX idx_permissions_module ON permissions(module);
CREATE INDEX idx_permissions_resource ON permissions(resource);
CREATE INDEX idx_permissions_action ON permissions(action);

-- Insertion des permissions par module
INSERT INTO permissions (module, resource, action, code, name, is_risk_sensitive) VALUES
-- Achats
('purchasing', 'purchase_request', 'create', 'PR_CREATE', 'Créer demande dachat', FALSE),
('purchasing', 'purchase_request', 'read', 'PR_READ', 'Consulter demande dachat', FALSE),
('purchasing', 'purchase_request', 'update', 'PR_UPDATE', 'Modifier demande dachat', FALSE),
('purchasing', 'purchase_request', 'delete', 'PR_DELETE', 'Supprimer demande dachat', FALSE),
('purchasing', 'purchase_request', 'approve_n1', 'PR_APPROVE_N1', 'Approuver demande N1', FALSE),
('purchasing', 'purchase_request', 'approve_n2', 'PR_APPROVE_N2', 'Approuver demande N2', TRUE),
('purchasing', 'purchase_request', 'approve_n3', 'PR_APPROVE_N3', 'Approuver demande N3', TRUE),
('purchasing', 'purchase_order', 'create', 'PO_CREATE', 'Créer commande fournisseur', FALSE),
('purchasing', 'purchase_order', 'approve', 'PO_APPROVE', 'Approuver commande', TRUE),
('purchasing', 'purchase_order', 'cancel', 'PO_CANCEL', 'Annuler commande', TRUE),
('purchasing', 'supplier', 'manage', 'SUPPLIER_MANAGE', 'Gérer fournisseurs', FALSE),

-- Ventes
('sales', 'sales_quotation', 'create', 'SQ_CREATE', 'Créer devis', FALSE),
('sales', 'sales_quotation', 'approve', 'SQ_APPROVE', 'Approuver devis', FALSE),
('sales', 'sales_order', 'create', 'SO_CREATE', 'Créer commande client', FALSE),
('sales', 'sales_order', 'approve', 'SO_APPROVE', 'Approuver commande', FALSE),
('sales', 'sales_order', 'cancel', 'SO_CANCEL', 'Annuler commande', TRUE),
('sales', 'discount', 'apply', 'DISCOUNT_APPLY', 'Appliquer remise', FALSE),
('sales', 'discount', 'approve_high', 'DISCOUNT_APPROVE_HIGH', 'Approuver remise élevée', TRUE),
('sales', 'customer', 'manage', 'CUSTOMER_MANAGE', 'Gérer clients', FALSE),

-- Stock
('inventory', 'goods_receipt', 'create', 'GR_CREATE', 'Enregistrer réception', FALSE),
('inventory', 'goods_receipt', 'validate', 'GR_VALIDATE', 'Valider réception', FALSE),
('inventory', 'stock_movement', 'create', 'STOCK_MOVE', 'Effectuer mouvement', FALSE),
('inventory', 'stock_transfer', 'approve', 'TRANSFER_APPROVE', 'Approuver transfert', TRUE),
('inventory', 'inventory_count', 'perform', 'INV_COUNT', 'Effectuer comptage', FALSE),
('inventory', 'inventory_adjustment', 'create', 'INV_ADJ_CREATE', 'Créer ajustement', TRUE),
('inventory', 'inventory_adjustment', 'approve', 'INV_ADJ_APPROVE', 'Approuver ajustement', TRUE),

-- Finance
('finance', 'supplier_invoice', 'process', 'SI_PROCESS', 'Traiter facture fournisseur', FALSE),
('finance', 'supplier_invoice', 'validate', 'SI_VALIDATE', 'Valider facture fournisseur', TRUE),
('finance', 'customer_invoice', 'create', 'CI_CREATE', 'Créer facture client', FALSE),
('finance', 'customer_invoice', 'cancel', 'CI_CANCEL', 'Annuler facture client', TRUE),
('finance', 'credit_note', 'create', 'CN_CREATE', 'Créer avoir', TRUE),
('finance', 'payment', 'process', 'PAYMENT_PROCESS', 'Traiter paiement', TRUE),
('finance', 'three_way_match', 'perform', 'THREE_WAY_MATCH', 'Effectuer rapprochement 3-way', FALSE),

-- Reporting
('reporting', 'dashboard', 'view', 'DASH_VIEW', 'Consulter tableau de bord', FALSE),
('reporting', 'report', 'export', 'REPORT_EXPORT', 'Exporter rapport', FALSE),
('reporting', 'kpi', 'view_all', 'KPI_VIEW_ALL', 'Consulter tous les KPI', FALSE),

-- Administration
('admin', 'user', 'manage', 'USER_MANAGE', 'Gérer utilisateurs', TRUE),
('admin', 'role', 'manage', 'ROLE_MANAGE', 'Gérer rôles', TRUE),
('admin', 'permission', 'manage', 'PERM_MANAGE', 'Gérer permissions', TRUE),
('admin', 'audit', 'view', 'AUDIT_VIEW', 'Consulter logs daudit', FALSE),
('admin', 'system', 'configure', 'SYS_CONF', 'Configurer système', TRUE);


CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    
    -- Restrictions supplémentaires
    resource_filter JSONB, -- Filtres spécifiques (ex: {"site_id": ["123", "456"]})
    max_value DECIMAL(15,2), -- Valeur maximale autorisée (montant, remise, etc.)
    
    -- Conditions d'application
    applies_from DATE,
    applies_to DATE,
    
    -- Héritage
    is_inherited BOOLEAN DEFAULT FALSE, -- Permission héritée du rôle parent
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id)
);

-- Index
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);

-- Insertion des permissions par rôle (exemples)
-- Super Admin : toutes les permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE code = 'SUPER_ADMIN'),
    id
FROM permissions;

-- Admin : permissions d'administration
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE code = 'ADMIN'),
    id
FROM permissions 
WHERE module = 'admin';

-- Acheteur
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE code = 'BUYER'),
    id
FROM permissions 
WHERE code IN ('PR_CREATE', 'PR_READ', 'PR_UPDATE', 'PO_CREATE', 'SUPPLIER_MANAGE', 'GR_CREATE');

-- Responsable Achats (hérite + permissions supplémentaires)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE code = 'BUYER_MANAGER'),
    id
FROM permissions 
WHERE code IN ('PR_APPROVE_N1', 'PR_APPROVE_N2', 'PO_APPROVE', 'PO_CANCEL');


CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    
    -- Périmètre d'application du rôle
    scope_type VARCHAR(30) NOT NULL, -- 'global', 'entity', 'site', 'department'
    entity_id UUID REFERENCES entities(id), -- Si scope = 'entity'
    site_id UUID REFERENCES sites(id), -- Si scope = 'site'
    department_id UUID REFERENCES departments(id), -- Si scope = 'department'
    
    -- Validité temporelle
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to IS NULL OR valid_to > CURRENT_TIMESTAMP) STORED,
    
    -- Attribution
    assigned_by UUID REFERENCES users(id),
    assigned_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_user_role UNIQUE (user_id, role_id, COALESCE(entity_id, '00000000-0000-0000-0000-000000000000'), COALESCE(site_id, '00000000-0000-0000-0000-000000000000'), COALESCE(department_id, '00000000-0000-0000-0000-000000000000'), valid_from),
    CONSTRAINT valid_scope CHECK (
        (scope_type = 'global' AND entity_id IS NULL AND site_id IS NULL AND department_id IS NULL) OR
        (scope_type = 'entity' AND entity_id IS NOT NULL AND site_id IS NULL AND department_id IS NULL) OR
        (scope_type = 'site' AND site_id IS NOT NULL AND department_id IS NULL) OR
        (scope_type = 'department' AND department_id IS NOT NULL)
    )
);

-- Index
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);
CREATE INDEX idx_user_roles_entity ON user_roles(entity_id);
CREATE INDEX idx_user_roles_site ON user_roles(site_id);
CREATE INDEX idx_user_roles_department ON user_roles(department_id);
CREATE INDEX idx_user_ros_validity ON user_roles(valid_from, valid_to);
CREATE INDEX idx_user_roles_active ON user_roles(is_active) WHERE is_active = TRUE;



CREATE TABLE user_site_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    
    -- Type d'accès
    access_level VARCHAR(30) NOT NULL DEFAULT 'read', -- 'read', 'write', 'admin', 'none'
    
    -- Périmètre fonctionnel
    module_restrictions JSONB, -- Restrictions par module pour ce site
    
    -- Validité
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to IS NULL OR valid_to > CURRENT_TIMESTAMP) STORED,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_user_site UNIQUE (user_id, site_id, valid_from)
);

-- Index
CREATE INDEX idx_user_site_user ON user_site_restrictions(user_id);
CREATE INDEX idx_user_site_site ON user_site_restrictions(site_id);
CREATE INDEX idx_user_site_validity ON user_site_restrictions(valid_from, valid_to);
CREATE INDEX idx_user_site_active ON user_site_restrictions(is_active) WHERE is_active = TRUE;



CREATE TABLE user_warehouse_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL, -- Référence à la table warehouses (à créer)
    
    -- Type d'accès
    access_level VARCHAR(30) NOT NULL DEFAULT 'read', -- 'read', 'write', 'admin', 'none'
    
    -- Opérations autorisées
    allowed_operations JSONB, -- ['receive', 'pick', 'move', 'count', 'adjust']
    
    -- Restrictions sur les emplacements
    location_restrictions JSONB, -- Zones/emplacements autorisés
    
    -- Validité
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to IS NULL OR valid_to > CURRENT_TIMESTAMP) STORED,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_user_warehouse UNIQUE (user_id, warehouse_id, valid_from)
);

-- Index
CREATE INDEX idx_user_warehouse_user ON user_warehouse_restrictions(user_id);
CREATE INDEX idx_user_warehouse_warehouse ON user_warehouse_restrictions(warehouse_id);
CREATE INDEX idx_user_warehouse_validity ON user_warehouse_restrictions(valid_from, valid_to);
CREATE INDEX idx_user_warehouse_active ON user_warehouse_restrictions(is_active) WHERE is_active = TRUE;



CREATE TABLE user_product_category_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES product_categories(id) ON DELETE CASCADE,
    
    -- Type d'accès
    access_level VARCHAR(30) NOT NULL DEFAULT 'read', -- 'read', 'write', 'admin', 'none'
    
    -- Opérations autorisées sur ces catégories
    allowed_operations JSONB, -- ['view', 'purchase', 'sell', 'price_modify']
    
    -- Restrictions supplémentaires
    max_purchase_price DECIMAL(15,2), -- Prix d'achat maximum autorisé
    max_sales_discount DECIMAL(5,2), -- Remise maximum autorisée (%)
    
    -- Validité
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to IS NULL OR valid_to > CURRENT_TIMESTAMP) STORED,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_user_category UNIQUE (user_id, category_id, valid_from)
);

-- Index
CREATE INDEX idx_user_category_user ON user_product_category_restrictions(user_id);
CREATE INDEX idx_user_category_category ON user_product_category_restrictions(category_id);
CREATE INDEX idx_user_category_validity ON user_product_category_restrictions(valid_from, valid_to);
CREATE INDEX idx_user_category_active ON user_product_category_restrictions(is_active) WHERE is_active = TRUE;



CREATE TABLE approval_thresholds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Contexte
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    approval_type VARCHAR(50) NOT NULL, -- 'purchase_request', 'purchase_order', 'sales_discount', 'credit_note', 'stock_adjustment'
    
    -- Périmètre d'application
    entity_id UUID REFERENCES entities(id), -- NULL = toutes entités
    site_id UUID REFERENCES sites(id), -- NULL = tous sites
    department_id UUID REFERENCES departments(id), -- NULL = tous départements
    
    -- Critères de seuil
    threshold_type VARCHAR(30) NOT NULL, -- 'amount', 'percentage', 'quantity', 'duration'
    min_value DECIMAL(15,2), -- Seuil minimum
    max_value DECIMAL(15,2), -- Seuil maximum
    currency_code CHAR(3) REFERENCES currencies(code), -- Devise si threshold_type = 'amount'
    
    -- Conditions supplémentaires
    conditions JSONB, -- Conditions supplémentaires (catégorie, fournisseur, etc.)
    
    -- Hiérarchie
    level INTEGER NOT NULL, -- Niveau d'approbation (1,2,3)
    requires_second_approval BOOLEAN DEFAULT FALSE, -- Double validation requise ?
    second_approval_role_id UUID REFERENCES roles(id), -- Rôle pour seconde validation
    
    -- Validité
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to IS NULL OR valid_to >= CURRENT_DATE) STORED,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_approval_threshold UNIQUE (role_id, approval_type, level, COALESCE(entity_id, '00000000-0000-0000-0000-000000000000'), COALESCE(site_id, '00000000-0000-0000-0000-000000000000'))
);

-- Index
CREATE INDEX idx_approval_thresholds_role ON approval_thresholds(role_id);
CREATE INDEX idx_approval_thresholds_type ON approval_thresholds(approval_type);
CREATE INDEX idx_approval_thresholds_entity ON approval_thresholds(entity_id);
CREATE INDEX idx_approval_thresholds_validity ON approval_thresholds(valid_from, valid_to);

-- Insertion des seuils par défaut
INSERT INTO approval_thresholds (role_id, approval_type, level, min_value, max_value, currency_code) VALUES
-- Demandes d'achat
((SELECT id FROM roles WHERE code = 'PURCHASE_APPROVER_N1'), 'purchase_request', 1, 0, 5000, 'EUR'),
((SELECT id FROM roles WHERE code = 'PURCHASE_APPROVER_N2'), 'purchase_request', 2, 5000, 50000, 'EUR'),
((SELECT id FROM roles WHERE code = 'PURCHASE_APPROVER_N3'), 'purchase_request', 3, 50000, 1000000, 'EUR'),
((SELECT id FROM roles WHERE code = 'CFO'), 'purchase_request', 4, 1000000, NULL, 'EUR'),

-- Remises commerciales
((SELECT id FROM roles WHERE code = 'SALES_REP'), 'sales_discount', 1, 0, 5, NULL), -- 0-5%
((SELECT id FROM roles WHERE code = 'SALES_MANAGER'), 'sales_discount', 2, 5, 15, NULL), -- 5-15%
((SELECT id FROM roles WHERE code = 'COO'), 'sales_discount', 3, 15, 30, NULL), -- 15-30%
((SELECT id FROM roles WHERE code = 'CEO'), 'sales_discount', 4, 30, 100, NULL); -- >30%


CREATE TABLE temporary_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Utilisateur concerné
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    granted_by UUID NOT NULL REFERENCES users(id),
    
    -- Accès accordé
    access_type VARCHAR(50) NOT NULL, -- 'role', 'permission', 'site', 'warehouse'
    role_id UUID REFERENCES roles(id), -- Si access_type = 'role'
    permission_id UUID REFERENCES permissions(id), -- Si access_type = 'permission'
    site_id UUID REFERENCES sites(id), -- Si access_type = 'site'
    warehouse_id UUID, -- Si access_type = 'warehouse'
    
    -- Périmètre additionnel
    scope_json JSONB, -- Périmètre supplémentaire
    
    -- Durée
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_hours INTEGER GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (valid_to - valid_from))/3600) STORED,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to > CURRENT_TIMESTAMP) STORED,
    
    -- Justification
    reason TEXT NOT NULL,
    justification_document TEXT, -- URL du document justificatif
    
    -- Notification
    notified BOOLEAN DEFAULT FALSE,
    notified_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES users(id),
    revoke_reason TEXT,
    
    -- Contrainte
    CONSTRAINT valid_dates CHECK (valid_to > valid_from)
);

-- Index
CREATE INDEX idx_temp_access_user ON temporary_access(user_id);
CREATE INDEX idx_temp_access_granted ON temporary_access(granted_by);
CREATE INDEX idx_temp_access_validity ON temporary_access(valid_from, valid_to);
CREATE INDEX idx_temp_access_active ON temporary_access(is_active) WHERE is_active = TRUE;

-- Table d'historique des accès temporaires utilisés
CREATE TABLE temporary_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    temporary_access_id UUID NOT NULL REFERENCES temporary_access(id) ON DELETE CASCADE,
    accessed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resource_type VARCHAR(100),
    resource_id UUID,
    action_performed VARCHAR(50),
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX idx_temp_logs_access ON temporary_access_logs(temporary_access_id);
CREATE INDEX idx_temp_logs_accessed ON temporary_access_logs(accessed_at);


CREATE TABLE delegations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Délégant (celui qui délègue)
    delegator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Délégué (celui qui reçoit la délégation)
    delegate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Type de délégation
    delegation_type VARCHAR(30) NOT NULL, -- 'full', 'role_based', 'permission_based', 'document_based'
    
    -- Périmètre de la délégation
    scope_type VARCHAR(30) NOT NULL, -- 'global', 'entity', 'site', 'department', 'specific'
    entity_id UUID REFERENCES entities(id),
    site_id UUID REFERENCES sites(id),
    department_id UUID REFERENCES departments(id),
    
    -- Délégation de rôles spécifiques
    role_ids UUID[], -- Liste des rôles délégués
    
    -- Délégation de permissions spécifiques
    permission_ids UUID[], -- Liste des permissions déléguées
    
    -- Limitations
    max_amount DECIMAL(15,2), -- Montant maximum autorisé
    currency_code CHAR(3) REFERENCES currencies(code),
    document_types VARCHAR(50)[], -- Types de documents concernés
    
    -- Période
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_to TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to > CURRENT_TIMESTAMP AND valid_from <= CURRENT_TIMESTAMP) STORED,
    
    -- Motif
    reason TEXT NOT NULL,
    reference_document TEXT, -- URL du document de délégation (signé)
    
    -- Révocation
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES users(id),
    revoke_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contraintes
    CONSTRAINT valid_dates CHECK (valid_to > valid_from),
    CONSTRAINT different_users CHECK (delegator_id != delegate_id)
);

-- Index
CREATE INDEX idx_delegations_delegator ON delegations(delegator_id);
CREATE INDEX idx_delegations_delegate ON delegations(delegate_id);
CREATE INDEX idx_delegations_validity ON delegations(valid_from, valid_to);
CREATE INDEX idx_delegations_active ON delegations(is_active) WHERE is_active = TRUE AND is_revoked = FALSE;

-- Table des actions réalisées sous délégation
CREATE TABLE delegation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delegation_id UUID NOT NULL REFERENCES delegations(id) ON DELETE CASCADE,
    
    -- Action réalisée
    action_type VARCHAR(50) NOT NULL,
    document_type VARCHAR(50),
    document_id UUID,
    document_number VARCHAR(100),
    
    -- Valeurs
    amount DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code),
    
    -- Timestamps
    action_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Résultat
    action_status VARCHAR(30) DEFAULT 'completed', -- 'completed', 'rejected', 'cancelled'
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_delegation_actions_delegation ON delegation_actions(delegation_id);
CREATE INDEX idx_delegation_actions_document ON delegation_actions(document_type, document_id);
CREATE INDEX idx_delegation_actions_at ON delegation_actions(action_at);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Qui
    user_id UUID REFERENCES users(id),
    user_name VARCHAR(255), -- Copie du nom pour historique
    user_role VARCHAR(50), -- Rôle au moment de l'action
    ip_address INET,
    user_agent TEXT,
    
    -- Quand
    action_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Quoi
    action_type VARCHAR(50) NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE', 'VIEW', 'EXPORT', 'APPROVE', 'REJECT'
    module VARCHAR(50) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    resource_code VARCHAR(100), -- Code/Numéro du document
    
    -- Détails
    old_values JSONB, -- Anciennes valeurs (avant modification)
    new_values JSONB, -- Nouvelles valeurs (après modification)
    changes JSONB, -- Résumé des modifications
    
    -- Contexte
    entity_id UUID REFERENCES entities(id),
    site_id UUID REFERENCES sites(id),
    department_id UUID REFERENCES departments(id),
    
    -- Métadonnées
    session_id VARCHAR(100),
    request_id VARCHAR(100),
    api_endpoint VARCHAR(500),
    
    -- Signature (pour non-répudiation)
    hash_signature VARCHAR(255), -- Hash SHA-256 de l'enregistrement
    previous_log_id UUID REFERENCES audit_logs(id), -- Chaînage pour intégrité
    
    -- Created_at déjà présent comme action_time
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index pour recherche rapide
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_time ON audit_logs(action_time);
CREATE INDEX idx_audit_type ON audit_logs(action_type);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_module ON audit_logs(module);
CREATE INDEX idx_audit_entity ON audit_logs(entity_id);
CREATE INDEX idx_audit_site ON audit_logs(site_id);
CREATE INDEX idx_audit_search ON audit_logs USING gin (to_tsvector('french', COALESCE(resource_code, '') || ' ' || COALESCE(old_values::text, '') || ' ' || COALESCE(new_values::text, '')));

-- Partitionnement par mois (optionnel)
-- CREATE TABLE audit_logs_2024_01 PARTITION OF audit_logs FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Fonction pour créer une signature hachée
CREATE OR REPLACE FUNCTION generate_audit_hash()
RETURNS TRIGGER AS $$
BEGIN
    NEW.hash_signature = encode(
        sha256(
            NEW.id::text || 
            NEW.user_id::text || 
            NEW.action_time::text || 
            NEW.action_type || 
            NEW.resource_type || 
            NEW.resource_id::text || 
            COALESCE(NEW.old_values::text, '') || 
            COALESCE(NEW.new_values::text, '') || 
            COALESCE(NEW.previous_log_id::text, '')
        ),
        'hex'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_hash
    BEFORE INSERT ON audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION generate_audit_hash();





CREATE TABLE purchase_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    request_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    request_date DATE NOT NULL DEFAULT CURRENT_DATE,
    required_date DATE, -- Date souhaitée
    expected_date DATE, -- Date prévisionnelle
    
    -- Demandeur
    requester_id UUID NOT NULL REFERENCES users(id), -- ✅ Utilisateur demandeur
    requester_name VARCHAR(255), -- Copie pour historique
    department_id UUID REFERENCES departments(id), -- ✅ Service demandeur
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité
    site_id UUID REFERENCES sites(id), -- ✅ Site
    
    -- Description
    title VARCHAR(500) NOT NULL,
    description TEXT,
    justification TEXT,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'submitted', 'pending_approval', 'approved', 'rejected', 'cancelled', 'ordered'
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    
    -- Budget
    budget_code VARCHAR(100), -- Code centre de coût
    budget_check_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'verified', 'insufficient', 'exempt'
    estimated_total DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Approbations
    current_approval_level INTEGER DEFAULT 0,
    max_approval_level INTEGER,
    approved_amount DECIMAL(15,2),
    
    -- Transformation
    converted_to_po BOOLEAN DEFAULT FALSE,
    purchase_order_id UUID, -- Sera mis à jour après création
    
    -- Classification
    purchase_type VARCHAR(30) DEFAULT 'standard', -- 'standard', 'urgent', 'framework', 'repeat'
    expense_type VARCHAR(30), -- 'operational', 'investment', 'stock', 'service'
    
    -- Validation workflow
    submitted_at TIMESTAMP WITH TIME ZONE,
    submitted_by UUID REFERENCES users(id),
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Index
CREATE INDEX idx_pr_number ON purchase_requests(request_number);
CREATE INDEX idx_pr_requester ON purchase_requests(requester_id);
CREATE INDEX idx_pr_department ON purchase_requests(department_id);
CREATE INDEX idx_pr_entity ON purchase_requests(entity_id);
CREATE INDEX idx_pr_site ON purchase_requests(site_id);
CREATE INDEX idx_pr_status ON purchase_requests(status);
CREATE INDEX idx_pr_dates ON purchase_requests(request_date, required_date);
CREATE INDEX idx_pr_budget ON purchase_requests(budget_code);


CREATE TABLE purchase_request_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_request_id UUID NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Article
    product_id UUID REFERENCES products(id), -- ✅ Produit (si connu)
    product_category_id UUID REFERENCES product_categories(id), -- ✅ Catégorie (si produit non référencé)
    product_description TEXT NOT NULL, -- Description libre
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    estimated_unit_price DECIMAL(15,4),
    estimated_total DECIMAL(15,4) GENERATED ALWAYS AS (quantity * estimated_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2), -- Taux au moment de la demande
    
    -- Dates souhaitées
    required_date DATE,
    
    -- Comptabilité
    account_code VARCHAR(20), -- Code comptable
    budget_code VARCHAR(100),
    
    -- Statut
    status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'ordered'
    rejection_reason TEXT,
    
    -- Suivi
    ordered_quantity DECIMAL(15,3) DEFAULT 0,
    received_quantity DECIMAL(15,3) DEFAULT 0,
    
    -- Références
    asset_id UUID, -- Si achat d'immobilisation
    project_id UUID, -- Si projet spécifique
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contraintes
    CONSTRAINT valid_product_xor_category CHECK (
        (product_id IS NOT NULL AND product_category_id IS NULL) OR
        (product_id IS NULL AND product_category_id IS NOT NULL) OR
        (product_id IS NULL AND product_category_id IS NULL)
    )
);

-- Index
CREATE INDEX idx_pr_lines_request ON purchase_request_lines(purchase_request_id);
CREATE INDEX idx_pr_lines_product ON purchase_request_lines(product_id);
CREATE INDEX idx_pr_lines_category ON purchase_request_lines(product_category_id);



CREATE TABLE purchase_request_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_request_id UUID NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
    
    -- Niveau d'approbation
    approval_level INTEGER NOT NULL, -- 1, 2, 3
    approval_type VARCHAR(30) NOT NULL, -- 'budget', 'technical', 'hierarchical', 'legal'
    
    -- Approbateur
    approver_id UUID NOT NULL REFERENCES users(id), -- ✅ Approbateur
    approver_role VARCHAR(50), -- Rôle au moment de l'approbation
    
    -- Décision
    decision VARCHAR(20) NOT NULL, -- 'approved', 'rejected', 'pending', 'escalated'
    decision_date TIMESTAMP WITH TIME ZONE,
    comments TEXT,
    
    -- Seuil appliqué
    threshold_amount DECIMAL(15,2),
    threshold_currency CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Notification
    notified_at TIMESTAMP WITH TIME ZONE,
    reminded_at TIMESTAMP WITH TIME ZONE,
    reminder_count INTEGER DEFAULT 0,
    
    -- Délégation
    delegated_from_id UUID REFERENCES users(id), -- Si approbation par délégation
    delegation_id UUID, -- Référence à la délégation utilisée
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_request_level UNIQUE (purchase_request_id, approval_level)
);

-- Index
CREATE INDEX idx_pr_approvals_request ON purchase_request_approvals(purchase_request_id);
CREATE INDEX idx_pr_approvals_approver ON purchase_request_approvals(approver_id);
CREATE INDEX idx_pr_approvals_status ON purchase_request_approvals(decision);
CREATE INDEX idx_pr_approvals_pending ON purchase_request_approvals(decision_date) WHERE decision = 'pending';



CREATE TABLE budget_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Document source
    source_type VARCHAR(30) NOT NULL, -- 'purchase_request', 'purchase_order'
    source_id UUID NOT NULL,
    source_line_id UUID,
    
    -- Budget
    budget_code VARCHAR(100) NOT NULL,
    budget_period VARCHAR(20), -- '2024', '2024-Q1', '2024-01'
    
    -- Montants
    requested_amount DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Disponibilité
    available_budget DECIMAL(15,2),
    committed_budget DECIMAL(15,2),
    consumed_budget DECIMAL(15,2),
    remaining_budget DECIMAL(15,2),
    
    -- Résultat
    check_status VARCHAR(20) NOT NULL, -- 'sufficient', 'insufficient', 'warning', 'exempt'
    warning_threshold DECIMAL(5,2), -- % seuil d'alerte
    warning_triggered BOOLEAN DEFAULT FALSE,
    
    -- Validation
    validated_by UUID REFERENCES users(id), -- ✅ Contrôleur budgétaire
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Contournement
    override_required BOOLEAN DEFAULT FALSE,
    override_approved BOOLEAN DEFAULT FALSE,
    override_approved_by UUID REFERENCES users(id),
    override_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_budget_checks_source ON budget_checks(source_type, source_id);
CREATE INDEX idx_budget_checks_code ON budget_checks(budget_code);
CREATE INDEX idx_budget_checks_status ON budget_checks(check_status);



CREATE TABLE purchase_quotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Références
    quotation_number VARCHAR(50) NOT NULL,
    supplier_id UUID NOT NULL REFERENCES suppliers(id), -- ✅ Fournisseur
    supplier_quotation_number VARCHAR(100), -- Référence fournisseur
    
    -- Lien avec demande
    purchase_request_id UUID REFERENCES purchase_requests(id),
    
    -- Dates
    quotation_date DATE NOT NULL,
    validity_date DATE, -- Date de validité de l'offre
    expected_delivery_date DATE,
    
    -- Montants
    total_excl_tax DECIMAL(15,2),
    total_tax DECIMAL(15,2),
    total_incl_tax DECIMAL(15,2),
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Conditions
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Conditions de paiement
    delivery_term_id UUID REFERENCES delivery_terms(id), -- ✅ Incoterm
    delivery_terms_text TEXT,
    
    -- Statut
    status VARCHAR(30) DEFAULT 'received', -- 'received', 'accepted', 'rejected', 'expired'
    is_selected BOOLEAN DEFAULT FALSE, -- Offre retenue ?
    selection_reason TEXT,
    
    -- Documents
    document_url TEXT,
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT unique_supplier_quotation UNIQUE (supplier_id, supplier_quotation_number)
);

-- Lignes de devis
CREATE TABLE purchase_quotation_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_quotation_id UUID NOT NULL REFERENCES purchase_quotations(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Article
    product_id UUID REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    supplier_product_code VARCHAR(100),
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Prix
    unit_price DECIMAL(15,4) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,4) DEFAULT 0,
    net_unit_price DECIMAL(15,4) GENERATED ALWAYS AS (unit_price * (1 - discount_percentage/100) - discount_amount) STORED,
    line_total DECIMAL(15,4) GENERATED ALWAYS AS (quantity * net_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2),
    
    -- Lien avec ligne de demande
    purchase_request_line_id UUID REFERENCES purchase_request_lines(id),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_pq_supplier ON purchase_quotations(supplier_id);
CREATE INDEX idx_pq_request ON purchase_quotations(purchase_request_id);
CREATE INDEX idx_pq_status ON purchase_quotations(status);
CREATE INDEX idx_pq_lines_quotation ON purchase_quotation_lines(purchase_quotation_id);
CREATE INDEX idx_pq_lines_product ON purchase_quotation_lines(product_id);


CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    po_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_date DATE, -- Date de livraison prévue
    confirmation_date DATE,
    
    -- Fournisseur
    supplier_id UUID NOT NULL REFERENCES suppliers(id), -- ✅ Fournisseur
    supplier_name VARCHAR(255), -- Copie pour historique
    supplier_address TEXT,
    supplier_contact_id UUID REFERENCES supplier_contacts(id), -- ✅ Contact
    
    -- Entités
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité acheteuse
    site_id UUID REFERENCES sites(id), -- ✅ Site de livraison
    department_id UUID REFERENCES departments(id), -- ✅ Service acheteur
    
    -- Acheteur
    buyer_id UUID NOT NULL REFERENCES users(id), -- ✅ Acheteur responsable
    
    -- Références
    purchase_request_id UUID REFERENCES purchase_requests(id), -- DA source
    quotation_id UUID REFERENCES purchase_quotations(id), -- Devis retenu
    
    -- Montants
    total_excl_tax DECIMAL(15,2),
    total_tax DECIMAL(15,2),
    total_incl_tax DECIMAL(15,2),
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Conditions
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Paiement
    delivery_term_id UUID REFERENCES delivery_terms(id), -- ✅ Livraison
    incoterm_location VARCHAR(255), -- Lieu de l'incoterm
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'pending_approval', 'approved', 'sent', 'confirmed', 'partially_received', 'fully_received', 'cancelled', 'closed'
    approval_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    
    -- Suivi
    sent_at TIMESTAMP WITH TIME ZONE,
    sent_by UUID REFERENCES users(id),
    supplier_confirmation VARCHAR(100),
    supplier_order_number VARCHAR(100), -- Référence commande fournisseur
    
    -- Livraison
    delivery_address TEXT,
    delivery_instructions TEXT,
    
    -- Facturation
    billing_address TEXT,
    
    -- Documents
    document_url TEXT, -- PDF de la commande
    notes TEXT,
    internal_notes TEXT,
    
    -- Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_po_number ON purchase_orders(po_number);
CREATE INDEX idx_po_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_po_entity ON purchase_orders(entity_id);
CREATE INDEX idx_po_site ON purchase_orders(site_id);
CREATE INDEX idx_po_buyer ON purchase_orders(buyer_id);
CREATE INDEX idx_po_status ON purchase_orders(status);
CREATE INDEX idx_po_dates ON purchase_orders(order_date, expected_date);



CREATE TABLE purchase_order_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Article
    product_id UUID REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    supplier_product_code VARCHAR(100),
    
    -- Quantités
    quantity_ordered DECIMAL(15,3) NOT NULL,
    quantity_received DECIMAL(15,3) DEFAULT 0,
    quantity_invoiced DECIMAL(15,3) DEFAULT 0,
    quantity_remaining DECIMAL(15,3) GENERATED ALWAYS AS (quantity_ordered - quantity_received) STORED,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Prix
    unit_price DECIMAL(15,4) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,4) DEFAULT 0,
    net_unit_price DECIMAL(15,4) GENERATED ALWAYS AS (unit_price * (1 - discount_percentage/100) - discount_amount) STORED,
    line_total DECIMAL(15,4) GENERATED ALWAYS AS (quantity_ordered * net_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2),
    
    -- Dates
    requested_date DATE,
    promised_date DATE,
    received_date DATE,
    
    -- Lien avec demande
    purchase_request_line_id UUID REFERENCES purchase_request_lines(id),
    quotation_line_id UUID REFERENCES purchase_quotation_lines(id),
    
    -- Lots
    lot_number VARCHAR(100), -- N° de lot si connu
    expiry_date DATE, -- Date d'expiration
    
    -- Réception partielle autorisée
    partial_reception_allowed BOOLEAN DEFAULT TRUE,
    
    -- Statut
    status VARCHAR(30) DEFAULT 'ordered', -- 'ordered', 'partially_received', 'fully_received', 'cancelled'
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT check_quantity CHECK (quantity_ordered >= 0 AND quantity_received <= quantity_ordered)
);

-- Index
CREATE INDEX idx_po_lines_order ON purchase_order_lines(purchase_order_id);
CREATE INDEX idx_po_lines_product ON purchase_order_lines(product_id);
CREATE INDEX idx_po_lines_request ON purchase_order_lines(purchase_request_line_id);
CREATE INDEX idx_po_lines_status ON purchase_order_lines(status);



CREATE TABLE purchase_order_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    
    -- Niveau d'approbation
    approval_level INTEGER NOT NULL,
    approval_type VARCHAR(30) NOT NULL, -- 'budget', 'hierarchical', 'legal'
    
    -- Approbateur
    approver_id UUID NOT NULL REFERENCES users(id), -- ✅ Approbateur
    approver_role VARCHAR(50),
    
    -- Décision
    decision VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    decision_date TIMESTAMP WITH TIME ZONE,
    comments TEXT,
    
    -- Seuil
    order_amount DECIMAL(15,2),
    threshold_amount DECIMAL(15,2),
    threshold_exceeded BOOLEAN GENERATED ALWAYS AS (order_amount > threshold_amount) STORED,
    
    -- Délégation
    delegated_from_id UUID REFERENCES users(id),
    
    -- Notification
    notified_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    CONSTRAINT unique_po_level UNIQUE (purchase_order_id, approval_level)
);

-- Index
CREATE INDEX idx_po_approvals_order ON purchase_order_approvals(purchase_order_id);
CREATE INDEX idx_po_approvals_approver ON purchase_order_approvals(approver_id);
CREATE INDEX idx_po_approvals_status ON purchase_order_approvals(decision);



CREATE TABLE goods_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    receipt_date DATE NOT NULL DEFAULT CURRENT_DATE,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Commande associée
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id),
    
    -- Fournisseur
    supplier_id UUID NOT NULL REFERENCES suppliers(id), -- ✅ Fournisseur
    supplier_name VARCHAR(255),
    
    -- Dépôt de réception
    warehouse_id UUID NOT NULL, -- ✅ Dépôt (table à créer)
    location_id UUID, -- ✅ Emplacement de déchargement
    
    -- Documents fournisseur
    delivery_note_number VARCHAR(100), -- N° BL fournisseur
    delivery_note_date DATE,
    carrier_name VARCHAR(255),
    tracking_number VARCHAR(100),
    
    -- Réceptionnaire
    receiver_id UUID NOT NULL REFERENCES users(id), -- ✅ Magasinier
    checker_id UUID REFERENCES users(id), -- ✅ Contrôleur (si double contrôle)
    
    -- Contrôle qualité
    quality_control_required BOOLEAN DEFAULT FALSE,
    quality_control_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'passed', 'failed', 'partial'
    quality_control_date TIMESTAMP WITH TIME ZONE,
    quality_controlled_by UUID REFERENCES users(id),
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'completed', 'cancelled', 'partially_controlled'
    
    -- Réception partielle
    is_partial BOOLEAN DEFAULT FALSE,
    
    -- Notes
    notes TEXT,
    internal_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_gr_number ON goods_receipts(receipt_number);
CREATE INDEX idx_gr_po ON goods_receipts(purchase_order_id);
CREATE INDEX idx_gr_supplier ON goods_receipts(supplier_id);
CREATE INDEX idx_gr_warehouse ON goods_receipts(warehouse_id);
CREATE INDEX idx_gr_date ON goods_receipts(receipt_date);
CREATE INDEX idx_gr_status ON goods_receipts(status);


CREATE TABLE goods_receipt_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goods_receipt_id UUID NOT NULL REFERENCES goods_receipts(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Lien avec commande
    purchase_order_line_id UUID NOT NULL REFERENCES purchase_order_lines(id),
    
    -- Article
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    product_description TEXT,
    
    -- Quantités
    quantity_expected DECIMAL(15,3) NOT NULL,
    quantity_received DECIMAL(15,3) NOT NULL,
    quantity_accepted DECIMAL(15,3),
    quantity_rejected DECIMAL(15,3) DEFAULT 0,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Lots / traçabilité
    lot_id UUID REFERENCES lots(id), -- ✅ Lot créé
    lot_number VARCHAR(100), -- N° de lot fournisseur
    serial_numbers TEXT[], -- Liste des N° de série
    manufacturing_date DATE,
    expiry_date DATE,
    
    -- Contrôle qualité
    quality_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'quarantine'
    quality_notes TEXT,
    defect_reason TEXT,
    
    -- Écarts
    discrepancy_quantity DECIMAL(15,3) GENERATED ALWAYS AS (quantity_expected - quantity_received) STORED,
    discrepancy_reason VARCHAR(50), -- 'over_delivery', 'under_delivery', 'damaged', 'wrong_product'
    
    -- Emplacement
    destination_location_id UUID, -- ✅ Emplacement de stockage
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT check_quantities CHECK (
        quantity_received >= 0 AND 
        quantity_accepted <= quantity_received AND
        quantity_rejected <= quantity_received
    )
);

-- Index
CREATE INDEX idx_gr_lines_receipt ON goods_receipt_lines(goods_receipt_id);
CREATE INDEX idx_gr_lines_po_line ON goods_receipt_lines(purchase_order_line_id);
CREATE INDEX idx_gr_lines_product ON goods_receipt_lines(product_id);
CREATE INDEX idx_gr_lines_lot ON goods_receipt_lines(lot_id);
CREATE INDEX idx_gr_lines_location ON goods_receipt_lines(destination_location_id);



CREATE TABLE supplier_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Références
    invoice_number VARCHAR(100) NOT NULL,
    supplier_id UUID NOT NULL REFERENCES suppliers(id), -- ✅ Fournisseur
    supplier_invoice_number VARCHAR(100) NOT NULL, -- N° facture fournisseur
    
    -- Dates
    invoice_date DATE NOT NULL,
    received_date DATE NOT NULL,
    due_date DATE NOT NULL,
    
    -- Entités
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité destinataire
    department_id UUID REFERENCES departments(id), -- ✅ Service
    
    -- Montants
    total_excl_tax DECIMAL(15,2) NOT NULL,
    total_tax DECIMAL(15,2) NOT NULL,
    total_incl_tax DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Taux de change (si devise étrangère)
    exchange_rate DECIMAL(15,6) DEFAULT 1,
    base_currency_total DECIMAL(15,2) GENERATED ALWAYS AS (total_incl_tax * exchange_rate) STORED,
    
    -- Taxes
    tax_summary JSONB, -- Récapitulatif par taux de TVA
    
    -- Références documents
    purchase_order_id UUID REFERENCES purchase_orders(id),
    goods_receipt_id UUID REFERENCES goods_receipts(id),
    
    -- Paiement
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Conditions de paiement
    payment_status VARCHAR(30) DEFAULT 'unpaid', -- 'unpaid', 'partial', 'paid', 'overdue', 'disputed'
    payment_due_status VARCHAR(20) GENERATED ALWAYS AS 
        (CASE WHEN due_date < CURRENT_DATE AND payment_status != 'paid' THEN 'overdue' ELSE 'current' END) STORED,
    
    -- Rapprochement
    matching_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'matched', 'partial', 'mismatch', 'blocked'
    matching_date TIMESTAMP WITH TIME ZONE,
    
    -- Statut comptable
    accounting_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'booked', 'verified', 'cancelled'
    accounting_date DATE,
    accounting_period VARCHAR(10), -- Période comptable (MM-YYYY)
    
    -- Documents
    invoice_file_url TEXT,
    ocr_data JSONB, -- Données issues de l'OCR
    
    -- Litiges
    is_disputed BOOLEAN DEFAULT FALSE,
    dispute_id UUID,
    
    -- Notes
    notes TEXT,
    internal_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT,
    
    -- Contrainte d'unicité
    CONSTRAINT unique_supplier_invoice UNIQUE (supplier_id, supplier_invoice_number)
);

-- Index
CREATE INDEX idx_si_supplier ON supplier_invoices(supplier_id);
CREATE INDEX idx_si_number ON supplier_invoices(supplier_invoice_number);
CREATE INDEX idx_si_entity ON supplier_invoices(entity_id);
CREATE INDEX idx_si_dates ON supplier_invoices(invoice_date, due_date);
CREATE INDEX idx_si_po ON supplier_invoices(purchase_order_id);
CREATE INDEX idx_si_payment_status ON supplier_invoices(payment_status);
CREATE INDEX idx_si_matching_status ON supplier_invoices(matching_status);


CREATE TABLE supplier_invoice_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_invoice_id UUID NOT NULL REFERENCES supplier_invoices(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Lien avec réception/commande
    goods_receipt_line_id UUID REFERENCES goods_receipt_lines(id),
    purchase_order_line_id UUID REFERENCES purchase_order_lines(id),
    
    -- Article
    product_id UUID REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Prix
    unit_price DECIMAL(15,4) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,4) DEFAULT 0,
    net_unit_price DECIMAL(15,4) GENERATED ALWAYS AS (unit_price * (1 - discount_percentage/100) - discount_amount) STORED,
    line_total_excl_tax DECIMAL(15,4) GENERATED ALWAYS AS (quantity * net_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2),
    tax_amount DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax * tax_rate/100) STORED,
    line_total_incl_tax DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax + tax_amount) STORED,
    
    -- Écarts éventuels
    price_discrepancy DECIMAL(15,4),
    quantity_discrepancy DECIMAL(15,3),
    discrepancy_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_si_lines_invoice ON supplier_invoice_lines(supplier_invoice_id);
CREATE INDEX idx_si_lines_po_line ON supplier_invoice_lines(purchase_order_line_id);
CREATE INDEX idx_si_lines_gr_line ON supplier_invoice_lines(goods_receipt_line_id);
CREATE INDEX idx_si_lines_product ON supplier_invoice_lines(product_id);



CREATE TABLE supplier_invoice_matching (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Documents à rapprocher
    supplier_invoice_id UUID NOT NULL REFERENCES supplier_invoices(id) ON DELETE CASCADE,
    supplier_invoice_line_id UUID REFERENCES supplier_invoice_lines(id),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id),
    purchase_order_line_id UUID REFERENCES purchase_order_lines(id),
    goods_receipt_id UUID REFERENCES goods_receipts(id),
    goods_receipt_line_id UUID REFERENCES goods_receipt_lines(id),
    
    -- Type de rapprochement
    match_type VARCHAR(30) NOT NULL, -- '2_way' (BC-Facture), '3_way' (BC-Réception-Facture)
    
    -- Comparaison des quantités
    po_quantity DECIMAL(15,3),
    gr_quantity DECIMAL(15,3),
    invoice_quantity DECIMAL(15,3),
    quantity_match BOOLEAN GENERATED ALWAYS AS (
        ABS(COALESCE(po_quantity, 0) - COALESCE(invoice_quantity, 0)) < 0.001 AND
        (match_type = '2_way' OR ABS(COALESCE(gr_quantity, 0) - COALESCE(invoice_quantity, 0)) < 0.001)
    ) STORED,
    quantity_discrepancy DECIMAL(15,3) GENERATED ALWAYS AS (
        invoice_quantity - COALESCE(gr_quantity, po_quantity, 0)
    ) STORED,
    
    -- Comparaison des prix
    po_unit_price DECIMAL(15,4),
    invoice_unit_price DECIMAL(15,4),
    price_match BOOLEAN GENERATED ALWAYS AS (
        ABS(COALESCE(po_unit_price, 0) - COALESCE(invoice_unit_price, 0)) < 0.01
    ) STORED,
    price_discrepancy DECIMAL(15,4) GENERATED ALWAYS AS (
        invoice_unit_price - po_unit_price
    ) STORED,
    
    -- Résultat
    match_status VARCHAR(30) NOT NULL, -- 'matched', 'quantity_mismatch', 'price_mismatch', 'both_mismatch', 'pending'
    discrepancy_amount DECIMAL(15,2),
    discrepancy_percentage DECIMAL(5,2),
    
    -- Traitement
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    resolution_type VARCHAR(30), -- 'accept', 'reject', 'adjust', 'credit_note'
    resolution_notes TEXT,
    
    -- Blocage
    is_blocked BOOLEAN DEFAULT FALSE,
    blocked_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_sim_invoice ON supplier_invoice_matching(supplier_invoice_id);
CREATE INDEX idx_sim_po ON supplier_invoice_matching(purchase_order_id);
CREATE INDEX idx_sim_gr ON supplier_invoice_matching(goods_receipt_id);
CREATE INDEX idx_sim_status ON supplier_invoice_matching(match_status);
CREATE INDEX idx_sim_blocked ON supplier_invoice_matching(is_blocked) WHERE is_blocked = TRUE;


CREATE TABLE supplier_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Références
    payment_number VARCHAR(50) NOT NULL UNIQUE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id), -- ✅ Fournisseur
    
    -- Dates
    payment_date DATE NOT NULL,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Montant
    amount DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Mode de paiement
    payment_method VARCHAR(30) NOT NULL, -- 'bank_transfer', 'check', 'cash', 'credit_card', 'letter_of_credit'
    payment_reference VARCHAR(100), -- Référence virement, n° chèque
    
    -- Comptes bancaires
    from_bank_account VARCHAR(50), -- Compte émetteur
    to_bank_account VARCHAR(50), -- Compte destinataire (IBAN fournisseur)
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'pending', -- 'pending', 'initiated', 'processed', 'confirmed', 'failed', 'cancelled'
    
    -- Validation
    validated_by UUID REFERENCES users(id), -- ✅ Validateur
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Rapprochement bancaire
    reconciled BOOLEAN DEFAULT FALSE,
    reconciled_at TIMESTAMP WITH TIME ZONE,
    bank_statement_reference VARCHAR(100),
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_sp_supplier ON supplier_payments(supplier_id);
CREATE INDEX idx_sp_date ON supplier_payments(payment_date);
CREATE INDEX idx_sp_status ON supplier_payments(status);
CREATE INDEX idx_sp_reference ON supplier_payments(payment_reference);


CREATE TABLE supplier_payment_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES supplier_payments(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES supplier_invoices(id) ON DELETE CASCADE,
    
    -- Montant alloué
    allocated_amount DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Montant restant sur la facture
    invoice_total DECIMAL(15,2),
    invoice_paid_amount DECIMAL(15,2),
    invoice_remaining DECIMAL(15,2) GENERATED ALWAYS AS (invoice_total - invoice_paid_amount) STORED,
    
    -- Rapprochement
    is_full_payment BOOLEAN GENERATED ALWAYS AS (ABS(allocated_amount - invoice_remaining) < 0.01) STORED,
    
    -- Date d'allocation
    allocation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT positive_allocation CHECK (allocated_amount > 0)
);

-- Index
CREATE INDEX idx_spa_payment ON supplier_payment_allocations(payment_id);
CREATE INDEX idx_spa_invoice ON supplier_payment_allocations(invoice_id);




CREATE TABLE purchase_disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Référence
    dispute_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Documents concernés
    dispute_type VARCHAR(30) NOT NULL, -- 'invoice', 'delivery', 'quality', 'price', 'delay'
    source_type VARCHAR(30) NOT NULL, -- 'purchase_order', 'goods_receipt', 'supplier_invoice'
    source_id UUID NOT NULL,
    
    -- Fournisseur
    supplier_id UUID NOT NULL REFERENCES suppliers(id), -- ✅ Fournisseur
    
    -- Créateur
    created_by_id UUID NOT NULL REFERENCES users(id), -- ✅ Créateur
    
    -- Dates
    dispute_date DATE NOT NULL DEFAULT CURRENT_DATE,
    resolution_deadline DATE,
    
    -- Description
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    
    -- Montant litigieux
    disputed_amount DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Pièces jointes
    attachments JSONB,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'open', -- 'open', 'in_progress', 'resolved', 'cancelled', 'escalated'
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    
    -- Résolution
    resolution_type VARCHAR(30), -- 'credit_note', 'replacement', 'refund', 'acceptance', 'cancellation'
    resolution_date DATE,
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT,
    approved_amount DECIMAL(15,2),
    
    -- Suivi
    assigned_to UUID REFERENCES users(id), -- ✅ Responsable du traitement
    last_contact_date DATE,
    next_action_date DATE,
    
    -- Historique des échanges
    communication_log JSONB,
    
    -- Escalade
    escalated_to UUID REFERENCES users(id),
    escalated_at TIMESTAMP WITH TIME ZONE,
    escalation_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id),
    closed_at TIMESTAMP WITH TIME ZONE,
    closed_by UUID REFERENCES users(id)
);

-- Lignes de litige (détail par produit)
CREATE TABLE purchase_dispute_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id UUID NOT NULL REFERENCES purchase_disputes(id) ON DELETE CASCADE,
    
    -- Références
    purchase_order_line_id UUID REFERENCES purchase_order_lines(id),
    goods_receipt_line_id UUID REFERENCES goods_receipt_lines(id),
    supplier_invoice_line_id UUID REFERENCES supplier_invoice_lines(id),
    
    -- Produit
    product_id UUID REFERENCES products(id),
    product_description TEXT,
    
    -- Quantités
    quantity_disputed DECIMAL(15,3),
    unit_id UUID REFERENCES units_of_measure(id),
    
    -- Montant
    unit_price DECIMAL(15,4),
    line_amount DECIMAL(15,4),
    
    -- Motif
    reason_code VARCHAR(50), -- 'wrong_quantity', 'wrong_price', 'damaged', 'late_delivery', 'wrong_product'
    reason_details TEXT,
    
    -- Résolution
    resolution_quantity DECIMAL(15,3),
    resolution_amount DECIMAL(15,4),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_disputes_supplier ON purchase_disputes(supplier_id);
CREATE INDEX idx_disputes_status ON purchase_disputes(status);
CREATE INDEX idx_disputes_source ON purchase_disputes(source_type, source_id);
CREATE INDEX idx_disputes_assigned ON purchase_disputes(assigned_to);
CREATE INDEX idx_dispute_lines_dispute ON purchase_dispute_lines(dispute_id);



---- vente 


CREATE TABLE sales_quotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    quotation_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    quotation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    validity_date DATE NOT NULL, -- Date de validité du devis
    expected_delivery_date DATE,
    
    -- Client
    customer_id UUID NOT NULL REFERENCES customers(id), -- ✅ Client
    customer_name VARCHAR(255), -- Copie pour historique
    customer_address TEXT,
    customer_contact_id UUID REFERENCES customer_contacts(id), -- ✅ Contact
    
    -- Entités
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité émettrice
    site_id UUID REFERENCES sites(id), -- ✅ Site de livraison
    department_id UUID REFERENCES departments(id), -- ✅ Service commercial
    
    -- Commercial
    sales_rep_id UUID NOT NULL REFERENCES users(id), -- ✅ Commercial
    sales_team VARCHAR(100),
    
    -- Montants
    total_excl_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_incl_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Conditions
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Paiement
    delivery_term_id UUID REFERENCES delivery_terms(id), -- ✅ Livraison
    incoterm_location VARCHAR(255),
    
    -- Remises globales
    global_discount_percentage DECIMAL(5,2) DEFAULT 0,
    global_discount_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'sent', 'accepted', 'rejected', 'expired', 'cancelled', 'converted'
    
    -- Transformation
    converted_to_order BOOLEAN DEFAULT FALSE,
    sales_order_id UUID,
    conversion_date TIMESTAMP WITH TIME ZONE,
    
    -- Envoi
    sent_at TIMESTAMP WITH TIME ZONE,
    sent_by UUID REFERENCES users(id),
    sent_to_email VARCHAR(255),
    
    -- Acceptation
    accepted_at TIMESTAMP WITH TIME ZONE,
    accepted_by VARCHAR(255), -- Nom du signataire client
    acceptance_notes TEXT,
    
    -- Impression
    print_count INTEGER DEFAULT 0,
    last_printed_at TIMESTAMP WITH TIME ZONE,
    
    -- Documents
    document_url TEXT,
    notes TEXT,
    internal_notes TEXT,
    
    -- Validation (si remise > plafond)
    requires_approval BOOLEAN DEFAULT FALSE,
    approval_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_sq_number ON sales_quotations(quotation_number);
CREATE INDEX idx_sq_customer ON sales_quotations(customer_id);
CREATE INDEX idx_sq_sales_rep ON sales_quotations(sales_rep_id);
CREATE INDEX idx_sq_entity ON sales_quotations(entity_id);
CREATE INDEX idx_sq_dates ON sales_quotations(quotation_date, validity_date);
CREATE INDEX idx_sq_status ON sales_quotations(status);


CREATE TABLE sales_quotation_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sales_quotation_id UUID NOT NULL REFERENCES sales_quotations(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Article
    product_id UUID REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Prix
    unit_price DECIMAL(15,4) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,4) DEFAULT 0,
    net_unit_price DECIMAL(15,4) GENERATED ALWAYS AS (unit_price * (1 - discount_percentage/100) - discount_amount) STORED,
    line_total_excl_tax DECIMAL(15,4) GENERATED ALWAYS AS (quantity * net_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2),
    tax_amount DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax * tax_rate/100) STORED,
    line_total_incl_tax DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax + tax_amount) STORED,
    
    -- Dates souhaitées
    requested_date DATE,
    
    -- Commentaires
    line_notes TEXT,
    
    -- Lien avec tarif appliqué
    price_list_id UUID REFERENCES customer_price_lists(id),
    price_list_item_id UUID,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_sq_lines_quotation ON sales_quotation_lines(sales_quotation_id);
CREATE INDEX idx_sq_lines_product ON sales_quotation_lines(product_id);


CREATE TABLE sales_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    order_number VARCHAR(50) NOT NULL UNIQUE,
    customer_order_number VARCHAR(100), -- Référence commande client
    
    -- Dates
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    confirmation_date DATE,
    requested_delivery_date DATE,
    promised_delivery_date DATE,
    
    -- Client
    customer_id UUID NOT NULL REFERENCES customers(id), -- ✅ Client
    customer_name VARCHAR(255),
    customer_address TEXT,
    customer_contact_id UUID REFERENCES customer_contacts(id), -- ✅ Contact
    
    -- Livraison (si différente)
    delivery_address TEXT,
    delivery_contact_name VARCHAR(255),
    delivery_contact_phone VARCHAR(30),
    
    -- Facturation
    billing_address TEXT,
    billing_contact_name VARCHAR(255),
    
    -- Entités
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité émettrice
    site_id UUID REFERENCES sites(id), -- ✅ Site de livraison
    department_id UUID REFERENCES departments(id), -- ✅ Service commercial
    
    -- Commercial
    sales_rep_id UUID NOT NULL REFERENCES users(id), -- ✅ Commercial
    sales_team VARCHAR(100),
    
    -- Montants
    total_excl_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_incl_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Conditions
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Paiement
    delivery_term_id UUID REFERENCES delivery_terms(id), -- ✅ Livraison
    incoterm_location VARCHAR(255),
    
    -- Remises globales
    global_discount_percentage DECIMAL(5,2) DEFAULT 0,
    global_discount_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Origine
    source_type VARCHAR(30), -- 'quotation', 'direct', 'ecommerce', 'import'
    source_id UUID, -- ID du devis si conversion
    source_reference VARCHAR(100), -- Référence externe
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'pending_approval', 'approved', 'confirmed', 'processing', 'partially_delivered', 'fully_delivered', 'invoiced', 'cancelled', 'closed'
    delivery_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'partial', 'complete'
    invoice_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'partial', 'complete'
    payment_status VARCHAR(30) DEFAULT 'unpaid', -- 'unpaid', 'partial', 'paid'
    
    -- Stock
    reservation_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'partial', 'complete'
    
    -- Validation (remises)
    requires_approval BOOLEAN DEFAULT FALSE,
    approval_status VARCHAR(20) DEFAULT 'pending',
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    
    -- Suivi
    notes TEXT,
    internal_notes TEXT,
    customer_notes TEXT,
    
    -- Documents
    document_url TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    confirmed_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_so_number ON sales_orders(order_number);
CREATE INDEX idx_so_customer ON sales_orders(customer_id);
CREATE INDEX idx_so_sales_rep ON sales_orders(sales_rep_id);
CREATE INDEX idx_so_entity ON sales_orders(entity_id);
CREATE INDEX idx_so_status ON sales_orders(status);
CREATE INDEX idx_so_dates ON sales_orders(order_date, requested_delivery_date);
CREATE INDEX idx_so_source ON sales_orders(source_type, source_id);



CREATE TABLE sales_order_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Article
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    
    -- Quantités
    quantity_ordered DECIMAL(15,3) NOT NULL,
    quantity_reserved DECIMAL(15,3) DEFAULT 0,
    quantity_picked DECIMAL(15,3) DEFAULT 0,
    quantity_delivered DECIMAL(15,3) DEFAULT 0,
    quantity_invoiced DECIMAL(15,3) DEFAULT 0,
    quantity_backordered DECIMAL(15,3) GENERATED ALWAYS AS (quantity_ordered - quantity_delivered) STORED,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Prix
    unit_price DECIMAL(15,4) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,4) DEFAULT 0,
    net_unit_price DECIMAL(15,4) GENERATED ALWAYS AS (unit_price * (1 - discount_percentage/100) - discount_amount) STORED,
    line_total_excl_tax DECIMAL(15,4) GENERATED ALWAYS AS (quantity_ordered * net_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2),
    tax_amount DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax * tax_rate/100) STORED,
    line_total_incl_tax DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax + tax_amount) STORED,
    
    -- Dates
    requested_date DATE,
    promised_date DATE,
    delivered_date DATE,
    
    -- Lien avec devis
    quotation_id UUID REFERENCES sales_quotations(id),
    quotation_line_id UUID REFERENCES sales_quotation_lines(id),
    
    -- Gestion de stock
    reservation_method VARCHAR(30) DEFAULT 'automatic', -- 'automatic', 'manual', 'none'
    allocation_rule VARCHAR(30) DEFAULT 'fifo', -- 'fifo', 'fefo', 'manual'
    
    -- Lots spécifiques (si réservation manuelle)
    lot_id UUID REFERENCES lots(id),
    serial_numbers TEXT[],
    
    -- Statut ligne
    status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'reserved', 'picked', 'delivered', 'invoiced', 'cancelled'
    
    -- Notes
    line_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT,
    
    -- Contrainte
    CONSTRAINT check_quantities CHECK (
        quantity_ordered >= 0 AND
        quantity_reserved <= quantity_ordered AND
        quantity_picked <= quantity_ordered AND
        quantity_delivered <= quantity_ordered
    )
);

-- Index
CREATE INDEX idx_so_lines_order ON sales_order_lines(sales_order_id);
CREATE INDEX idx_so_lines_product ON sales_order_lines(product_id);
CREATE INDEX idx_so_lines_lot ON sales_order_lines(lot_id);
CREATE INDEX idx_so_lines_status ON sales_order_lines(status);



CREATE TABLE sales_order_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
    
    -- Type d'approbation
    approval_type VARCHAR(30) NOT NULL, -- 'discount', 'credit_limit', 'special_price', 'bulk_order'
    
    -- Valeurs
    requested_value DECIMAL(15,2),
    threshold_value DECIMAL(15,2),
    discount_percentage DECIMAL(5,2),
    order_total DECIMAL(15,2),
    
    -- Approbateur
    approver_id UUID NOT NULL REFERENCES users(id), -- ✅ Approbateur
    approver_role VARCHAR(50),
    
    -- Décision
    decision VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    decision_date TIMESTAMP WITH TIME ZONE,
    comments TEXT,
    
    -- Délégation
    delegated_from_id UUID REFERENCES users(id),
    
    -- Notification
    notified_at TIMESTAMP WITH TIME ZONE,
    reminded_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    CONSTRAINT unique_so_approval_type UNIQUE (sales_order_id, approval_type)
);

-- Index
CREATE INDEX idx_so_approvals_order ON sales_order_approvals(sales_order_id);
CREATE INDEX idx_so_approvals_approver ON sales_order_approvals(approver_id);
CREATE INDEX idx_so_approvals_status ON sales_order_approvals(decision);



CREATE TABLE order_reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Lien avec commande
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id),
    sales_order_line_id UUID NOT NULL REFERENCES sales_order_lines(id),
    
    -- Stock réservé
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    lot_id UUID REFERENCES lots(id), -- ✅ Lot (si tracé)
    warehouse_id UUID NOT NULL, -- ✅ Dépôt
    location_id UUID, -- ✅ Emplacement
    
    -- Quantités
    quantity_reserved DECIMAL(15,3) NOT NULL,
    quantity_picked DECIMAL(15,3) DEFAULT 0,
    quantity_cancelled DECIMAL(15,3) DEFAULT 0,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Dates
    reservation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiration_date TIMESTAMP WITH TIME ZONE, -- Date d'expiration de la réservation
    
    -- Méthode d'allocation
    allocation_method VARCHAR(30) DEFAULT 'fifo', -- 'fifo', 'fefo', 'manual'
    allocation_rule_applied TEXT, -- Règle appliquée
    
    -- Statut
    status VARCHAR(30) DEFAULT 'active', -- 'active', 'picked', 'cancelled', 'expired'
    
    -- Picking associé
    picking_list_line_id UUID, -- Sera mis à jour
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT,
    
    -- Contrainte
    CONSTRAINT check_quantity CHECK (quantity_reserved >= 0)
);

-- Index
CREATE INDEX idx_reservations_order ON order_reservations(sales_order_id, sales_order_line_id);
CREATE INDEX idx_reservations_product ON order_reservations(product_id);
CREATE INDEX idx_reservations_lot ON order_reservations(lot_id);
CREATE INDEX idx_reservations_warehouse ON order_reservations(warehouse_id);
CREATE INDEX idx_reservations_status ON order_reservations(status);
CREATE INDEX idx_reservations_expiry ON order_reservations(expiration_date) WHERE status = 'active';



CREATE TABLE delivery_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    delivery_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    delivery_date DATE NOT NULL DEFAULT CURRENT_DATE,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    shipping_date DATE,
    
    -- Commande associée
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id),
    
    -- Client
    customer_id UUID NOT NULL REFERENCES customers(id), -- ✅ Client
    customer_name VARCHAR(255),
    delivery_address TEXT,
    contact_name VARCHAR(255),
    contact_phone VARCHAR(30),
    
    -- Dépôt d'expédition
    warehouse_id UUID NOT NULL, -- ✅ Dépôt expéditeur
    location_id UUID, -- ✅ Emplacement de sortie
    
    -- Transport
    carrier_id UUID, -- ✅ Transporteur (table carriers)
    carrier_name VARCHAR(255),
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(100),
    shipping_cost DECIMAL(15,2),
    
    -- Documents
    delivery_note_file_url TEXT,
    packing_list_url TEXT,
    labels_url TEXT,
    
    -- Signature
    receiver_name VARCHAR(255),
    receiver_signature TEXT, -- Signature électronique ou image
    reception_date TIMESTAMP WITH TIME ZONE,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'prepared', 'shipped', 'delivered', 'partially_delivered', 'cancelled'
    
    -- Préparateur
    prepared_by UUID REFERENCES users(id), -- ✅ Préparateur
    prepared_at TIMESTAMP WITH TIME ZONE,
    checked_by UUID REFERENCES users(id), -- ✅ Vérificateur
    checked_at TIMESTAMP WITH TIME ZONE,
    shipped_by UUID REFERENCES users(id), -- ✅ Expéditeur
    shipped_at TIMESTAMP WITH TIME ZONE,
    
    -- Facturation
    invoiced BOOLEAN DEFAULT FALSE,
    invoice_id UUID,
    
    -- Notes
    notes TEXT,
    delivery_instructions TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_dn_number ON delivery_notes(delivery_number);
CREATE INDEX idx_dn_order ON delivery_notes(sales_order_id);
CREATE INDEX idx_dn_customer ON delivery_notes(customer_id);
CREATE INDEX idx_dn_warehouse ON delivery_notes(warehouse_id);
CREATE INDEX idx_dn_status ON delivery_notes(status);
CREATE INDEX idx_dn_dates ON delivery_notes(delivery_date, shipping_date);



CREATE TABLE delivery_note_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_note_id UUID NOT NULL REFERENCES delivery_notes(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Lien avec commande
    sales_order_id UUID NOT NULL,
    sales_order_line_id UUID NOT NULL REFERENCES sales_order_lines(id),
    
    -- Article
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    product_description TEXT,
    
    -- Quantités
    quantity_ordered DECIMAL(15,3),
    quantity_delivered DECIMAL(15,3) NOT NULL,
    quantity_backordered DECIMAL(15,3) GENERATED ALWAYS AS (quantity_ordered - quantity_delivered) STORED,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Lots / traçabilité
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    lot_number VARCHAR(100),
    serial_numbers TEXT[], -- Liste des N° de série livrés
    
    -- Emplacement de prélèvement
    picked_from_location_id UUID, -- ✅ Emplacement de prélèvement
    
    -- Prix (pour information)
    unit_price DECIMAL(15,4),
    line_total DECIMAL(15,4),
    
    -- Statut
    status VARCHAR(30) DEFAULT 'delivered', -- 'delivered', 'backordered', 'cancelled'
    
    -- Contrôle
    quality_check_passed BOOLEAN DEFAULT TRUE,
    quality_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_dn_lines_delivery ON delivery_note_lines(delivery_note_id);
CREATE INDEX idx_dn_lines_order_line ON delivery_note_lines(sales_order_line_id);
CREATE INDEX idx_dn_lines_product ON delivery_note_lines(product_id);
CREATE INDEX idx_dn_lines_lot ON delivery_note_lines(lot_id);


CREATE TABLE picking_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    picking_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    picking_date DATE,
    
    -- Commandes incluses
    sales_order_ids UUID[], -- Liste des commandes à préparer
    delivery_note_ids UUID[], -- Liste des BL associés
    
    -- Dépôt
    warehouse_id UUID NOT NULL, -- ✅ Dépôt
    zone_id UUID, -- Zone de picking
    
    -- Préparateur(s)
    picker_id UUID REFERENCES users(id), -- ✅ Préparateur principal
    picker_name VARCHAR(255),
    assistant_id UUID REFERENCES users(id), -- ✅ Assistant
    
    -- Vérificateur
    checker_id UUID REFERENCES users(id), -- ✅ Vérificateur
    
    -- Type de picking
    picking_type VARCHAR(30) DEFAULT 'order', -- 'order', 'batch', 'wave', 'zone'
    priority VARCHAR(20) DEFAULT 'normal', -- 'high', 'normal', 'low'
    
    -- Statistiques
    total_lines INTEGER DEFAULT 0,
    total_items DECIMAL(15,3) DEFAULT 0,
    total_pallets INTEGER DEFAULT 0,
    total_volume DECIMAL(15,3),
    total_weight DECIMAL(15,3),
    
    -- Chronométrage
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (completed_at - started_at))/60
    ) STORED,
    
    -- Équipement
    equipment_used JSONB, -- Liste des équipements utilisés
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'pending', -- 'pending', 'in_progress', 'paused', 'completed', 'verified', 'cancelled'
    
    -- Résultat
    accuracy_rate DECIMAL(5,2), -- Taux de précision (après vérification)
    incidents TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    completed_by UUID REFERENCES users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_pl_number ON picking_lists(picking_number);
CREATE INDEX idx_pl_warehouse ON picking_lists(warehouse_id);
CREATE INDEX idx_pl_picker ON picking_lists(picker_id);
CREATE INDEX idx_pl_status ON picking_lists(status);
CREATE INDEX idx_pl_dates ON picking_lists(picking_date, created_at);




CREATE TABLE picking_list_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    picking_list_id UUID NOT NULL REFERENCES picking_lists(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Lien avec commande
    sales_order_id UUID NOT NULL,
    sales_order_line_id UUID NOT NULL REFERENCES sales_order_lines(id),
    delivery_note_line_id UUID REFERENCES delivery_note_lines(id),
    
    -- Réservation associée
    reservation_id UUID REFERENCES order_reservations(id),
    
    -- Article
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    product_description TEXT,
    barcode VARCHAR(100),
    
    -- Quantités
    quantity_to_pick DECIMAL(15,3) NOT NULL,
    quantity_picked DECIMAL(15,3) DEFAULT 0,
    quantity_remaining DECIMAL(15,3) GENERATED ALWAYS AS (quantity_to_pick - quantity_picked) STORED,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Emplacements
    from_location_id UUID NOT NULL, -- ✅ Emplacement source
    to_location_id UUID, -- ✅ Emplacement de regroupement
    
    -- Lots
    lot_id UUID REFERENCES lots(id), -- ✅ Lot à prélever
    lot_number VARCHAR(100),
    serial_numbers TEXT[], -- N° de série à prélever
    
    -- Statut
    status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'picked', 'verified', 'issue'
    
    -- Picking effectif
    picked_at TIMESTAMP WITH TIME ZONE,
    picked_by UUID REFERENCES users(id),
    picked_quantity DECIMAL(15,3),
    picked_location_id UUID, -- Emplacement réel de prélèvement
    
    -- Vérification
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    verified_quantity DECIMAL(15,3),
    verification_notes TEXT,
    
    -- Anomalie
    is_anomaly BOOLEAN DEFAULT FALSE,
    anomaly_type VARCHAR(50), -- 'wrong_product', 'wrong_quantity', 'wrong_location', 'damaged'
    anomaly_description TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_pl_lines_picking ON picking_list_lines(picking_list_id);
CREATE INDEX idx_pl_lines_order ON picking_list_lines(sales_order_id, sales_order_line_id);
CREATE INDEX idx_pl_lines_product ON picking_list_lines(product_id);
CREATE INDEX idx_pl_lines_location ON picking_list_lines(from_location_id);
CREATE INDEX idx_pl_lines_lot ON picking_list_lines(lot_id);
CREATE INDEX idx_pl_lines_status ON picking_list_lines(status);



CREATE TABLE picking_validation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Session de scan
    session_id UUID NOT NULL,
    device_id VARCHAR(100), -- Identifiant du terminal
    device_type VARCHAR(50), -- 'mobile', 'scanner', 'tablet'
    
    -- Utilisateur
    user_id UUID NOT NULL REFERENCES users(id), -- ✅ Opérateur
    scanned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Élément scanné
    scan_type VARCHAR(30) NOT NULL, -- 'product', 'location', 'lot', 'serial', 'picking_line', 'delivery'
    scan_value VARCHAR(255) NOT NULL, -- Code-barres scanné
    
    -- Contexte
    picking_list_id UUID REFERENCES picking_lists(id),
    picking_list_line_id UUID REFERENCES picking_list_lines(id),
    
    -- Résultat du scan
    expected_value VARCHAR(255), -- Valeur attendue
    is_valid BOOLEAN NOT NULL,
    validation_message TEXT,
    
    -- Données associées
    product_id UUID REFERENCES products(id),
    lot_id UUID REFERENCES lots(id),
    serial_number_id UUID REFERENCES serial_numbers(id),
    location_id UUID, -- ✅ Emplacement
    
    -- Quantité (si applicable)
    quantity DECIMAL(15,3),
    unit_id UUID REFERENCES units_of_measure(id),
    
    -- Coordonnées GPS (optionnel)
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    
    -- Image (optionnel)
    photo_url TEXT,
    
    -- Métadonnées
    metadata JSONB, -- Infos supplémentaires
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_pv_session ON picking_validation(session_id);
CREATE INDEX idx_pv_user ON picking_validation(user_id);
CREATE INDEX idx_pv_time ON picking_validation(scanned_at);
CREATE INDEX idx_pv_picking ON picking_validation(picking_list_id, picking_list_line_id);
CREATE INDEX idx_pv_scan ON picking_validation(scan_type, scan_value);
CREATE INDEX idx_pv_valid ON picking_validation(is_valid);

-- Table des sessions de validation
CREATE TABLE picking_validation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    picking_list_id UUID REFERENCES picking_lists(id),
    
    -- Statistiques
    total_scans INTEGER DEFAULT 0,
    valid_scans INTEGER DEFAULT 0,
    invalid_scans INTEGER DEFAULT 0,
    
    -- Statut
    status VARCHAR(30) DEFAULT 'active', -- 'active', 'completed', 'aborted'
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pvs_user ON picking_validation_sessions(user_id);
CREATE INDEX idx_pvs_status ON picking_validation_sessions(status);




CREATE TABLE customer_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Références
    invoice_type VARCHAR(30) NOT NULL DEFAULT 'invoice', -- 'invoice', 'credit_note', 'debit_note', 'proforma'
    
    -- Dates
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Client
    customer_id UUID NOT NULL REFERENCES customers(id), -- ✅ Client
    customer_name VARCHAR(255),
    customer_address TEXT,
    customer_tax_id VARCHAR(50),
    
    -- Entités
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité émettrice
    site_id UUID REFERENCES sites(id), -- ✅ Site
    
    -- Commercial
    sales_rep_id UUID REFERENCES users(id), -- ✅ Commercial
    
    -- Montants
    total_excl_tax DECIMAL(15,2) NOT NULL,
    total_tax DECIMAL(15,2) NOT NULL,
    total_incl_tax DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    amount_paid DECIMAL(15,2) DEFAULT 0,
    amount_due DECIMAL(15,2) GENERATED ALWAYS AS (total_incl_tax - amount_paid) STORED,
    
    -- Taxes
    tax_summary JSONB, -- Récapitulatif par taux
    
    -- Documents source
    source_type VARCHAR(30), -- 'sales_order', 'delivery_note'
    source_ids UUID[], -- Liste des IDs sources
    
    -- Conditions
    payment_term_id UUID REFERENCES payment_terms(id), -- ✅ Paiement
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'sent', 'paid', 'partial', 'overdue', 'cancelled', 'credit_note'
    payment_status VARCHAR(30) GENERATED ALWAYS AS (
        CASE 
            WHEN amount_paid <= 0 THEN 'unpaid'
            WHEN amount_paid < total_incl_tax THEN 'partial'
            WHEN amount_paid >= total_incl_tax THEN 'paid'
        END
    ) STORED,
    
    -- Envoi
    sent_at TIMESTAMP WITH TIME ZONE,
    sent_by UUID REFERENCES users(id),
    sent_to_email VARCHAR(255),
    
    -- Rapprochement
    reconciled BOOLEAN DEFAULT FALSE,
    reconciled_at TIMESTAMP WITH TIME ZONE,
    
    -- Documents
    invoice_file_url TEXT,
    pdf_generated BOOLEAN DEFAULT FALSE,
    
    -- Comptabilité
    accounting_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'booked', 'exported'
    accounting_period VARCHAR(10),
    accounting_journal VARCHAR(20),
    
    -- Notes
    notes TEXT,
    internal_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_ci_number ON customer_invoices(invoice_number);
CREATE INDEX idx_ci_customer ON customer_invoices(customer_id);
CREATE INDEX idx_ci_entity ON customer_invoices(entity_id);
CREATE INDEX idx_ci_dates ON customer_invoices(invoice_date, due_date);
CREATE INDEX idx_ci_status ON customer_invoices(status);
CREATE INDEX idx_ci_payment_status ON customer_invoices(payment_status);



CREATE TABLE customer_invoice_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_invoice_id UUID NOT NULL REFERENCES customer_invoices(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Lien avec documents source
    sales_order_id UUID,
    sales_order_line_id UUID REFERENCES sales_order_lines(id),
    delivery_note_id UUID,
    delivery_note_line_id UUID REFERENCES delivery_note_lines(id),
    
    -- Article
    product_id UUID REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Prix
    unit_price DECIMAL(15,4) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,4) DEFAULT 0,
    net_unit_price DECIMAL(15,4) GENERATED ALWAYS AS (unit_price * (1 - discount_percentage/100) - discount_amount) STORED,
    line_total_excl_tax DECIMAL(15,4) GENERATED ALWAYS AS (quantity * net_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2),
    tax_amount DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax * tax_rate/100) STORED,
    line_total_incl_tax DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax + tax_amount) STORED,
    
    -- Comptabilité
    account_code VARCHAR(20), -- Compte comptable
    
    -- Notes
    line_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_ci_lines_invoice ON customer_invoice_lines(customer_invoice_id);
CREATE INDEX idx_ci_lines_order ON customer_invoice_lines(sales_order_id, sales_order_line_id);
CREATE INDEX idx_ci_lines_delivery ON customer_invoice_lines(delivery_note_id, delivery_note_line_id);
CREATE INDEX idx_ci_lines_product ON customer_invoice_lines(product_id);




CREATE TABLE credit_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    credit_note_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Références
    invoice_id UUID NOT NULL REFERENCES customer_invoices(id), -- ✅ Facture d'origine
    invoice_number VARCHAR(50), -- Copie pour historique
    
    -- Dates
    credit_note_date DATE NOT NULL DEFAULT CURRENT_DATE,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Client
    customer_id UUID NOT NULL REFERENCES customers(id), -- ✅ Client
    customer_name VARCHAR(255),
    
    -- Entités
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité
    
    -- Montants
    total_excl_tax DECIMAL(15,2) NOT NULL,
    total_tax DECIMAL(15,2) NOT NULL,
    total_incl_tax DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Type d'avoir
    credit_type VARCHAR(30) NOT NULL, -- 'return', 'price_adjustment', 'commercial', 'cancellation'
    
    -- Motif
    reason_code VARCHAR(50), -- 'damaged', 'wrong_product', 'price_error', 'customer_complaint', 'other'
    reason_description TEXT NOT NULL,
    
    -- Retour marchandise associé
    return_id UUID, -- Si retour physique
    
    -- Approbation
    requires_approval BOOLEAN DEFAULT TRUE,
    approved_by UUID REFERENCES users(id), -- ✅ Approbateur
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'approved', 'sent', 'applied', 'cancelled'
    
    -- Application
    applied_to_invoice BOOLEAN DEFAULT FALSE,
    applied_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Documents
    document_url TEXT,
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_cn_number ON credit_notes(credit_note_number);
CREATE INDEX idx_cn_invoice ON credit_notes(invoice_id);
CREATE INDEX idx_cn_customer ON credit_notes(customer_id);
CREATE INDEX idx_cn_status ON credit_notes(status);


CREATE TABLE credit_note_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    credit_note_id UUID NOT NULL REFERENCES credit_notes(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Lien avec facture d'origine
    invoice_line_id UUID REFERENCES customer_invoice_lines(id),
    
    -- Article
    product_id UUID REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Prix
    unit_price DECIMAL(15,4) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,4) DEFAULT 0,
    net_unit_price DECIMAL(15,4) GENERATED ALWAYS AS (unit_price * (1 - discount_percentage/100) - discount_amount) STORED,
    line_total_excl_tax DECIMAL(15,4) GENERATED ALWAYS AS (quantity * net_unit_price) STORED,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id), -- ✅ TVA
    tax_rate DECIMAL(5,2),
    tax_amount DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax * tax_rate/100) STORED,
    line_total_incl_tax DECIMAL(15,4) GENERATED ALWAYS AS (line_total_excl_tax + tax_amount) STORED,
    
    -- Retour physique
    returned_quantity DECIMAL(15,3),
    return_condition VARCHAR(50), -- 'new', 'damaged', 'destroyed'
    
    -- Notes
    line_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_cn_lines_credit ON credit_note_lines(credit_note_id);
CREATE INDEX idx_cn_lines_invoice ON credit_note_lines(invoice_line_id);
CREATE INDEX idx_cn_lines_product ON credit_note_lines(product_id);


CREATE TABLE customer_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Références
    payment_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id UUID NOT NULL REFERENCES customers(id), -- ✅ Client
    
    -- Dates
    payment_date DATE NOT NULL,
    receipt_date DATE NOT NULL,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Montant
    amount DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Mode de paiement
    payment_method VARCHAR(30) NOT NULL, -- 'bank_transfer', 'check', 'cash', 'credit_card', 'paypal', 'wire'
    payment_reference VARCHAR(100), -- Référence virement, n° chèque
    transaction_id VARCHAR(100), -- ID de transaction externe
    
    -- Comptes bancaires
    bank_account VARCHAR(50), -- Compte destinataire
    bank_name VARCHAR(255),
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'pending', -- 'pending', 'confirmed', 'reconciled', 'failed', 'cancelled'
    
    -- Validation
    validated_by UUID REFERENCES users(id), -- ✅ Validateur
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Rapprochement bancaire
    reconciled BOOLEAN DEFAULT FALSE,
    reconciled_at TIMESTAMP WITH TIME ZONE,
    bank_statement_reference VARCHAR(100),
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_cp_customer ON customer_payments(customer_id);
CREATE INDEX idx_cp_number ON customer_payments(payment_number);
CREATE INDEX idx_cp_date ON customer_payments(payment_date);
CREATE INDEX idx_cp_status ON customer_payments(status);
CREATE INDEX idx_cp_reference ON customer_payments(payment_reference);



CREATE TABLE customer_payment_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES customer_payments(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES customer_invoices(id) ON DELETE CASCADE,
    
    -- Montant alloué
    allocated_amount DECIMAL(15,2) NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code), -- ✅ Devise
    
    -- Montants de la facture
    invoice_total DECIMAL(15,2),
    invoice_paid_amount DECIMAL(15,2),
    invoice_remaining DECIMAL(15,2) GENERATED ALWAYS AS (invoice_total - invoice_paid_amount) STORED,
    
    -- Rapprochement
    is_full_payment BOOLEAN GENERATED ALWAYS AS (ABS(allocated_amount - invoice_remaining) < 0.01) STORED,
    
    -- Date d'allocation
    allocation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Utilisateur
    allocated_by UUID REFERENCES users(id),
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT positive_allocation CHECK (allocated_amount > 0)
);

-- Index
CREATE INDEX idx_cpa_payment ON customer_payment_allocations(payment_id);
CREATE INDEX idx_cpa_invoice ON customer_payment_allocations(invoice_id);
CREATE INDEX idx_cpa_allocation_date ON customer_payment_allocations(allocation_date);





-- Dépôts / Entrepôts
CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Site rattaché
    site_id UUID NOT NULL REFERENCES sites(id), -- ✅ Site
    entity_id UUID NOT NULL REFERENCES entities(id), -- ✅ Entité
    
    -- Type de dépôt
    warehouse_type VARCHAR(30) NOT NULL, -- 'principal', 'transfert', 'quarantaine', 'rebut', 'consignation'
    
    -- Adresse
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    country_code CHAR(2) REFERENCES countries(iso_code), -- ✅ Pays
    
    -- Responsable
    manager_id UUID REFERENCES users(id), -- ✅ Responsable
    
    -- Caractéristiques
    total_area DECIMAL(15,2), -- Surface totale en m²
    storage_area DECIMAL(15,2), -- Surface de stockage
    height_limit DECIMAL(10,2), -- Hauteur sous plafond
    temperature_min DECIMAL(5,2), -- Température minimale
    temperature_max DECIMAL(5,2), -- Température maximale
    humidity_min DECIMAL(5,2), -- Humidité minimale
    humidity_max DECIMAL(5,2), -- Humidité maximale
    
    -- Configuration
    allow_negative_stock BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Emplacements (zones, allées, racks, casiers)
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    
    -- Codes
    code VARCHAR(100) NOT NULL,
    barcode VARCHAR(100) UNIQUE, -- Code-barres de l'emplacement
    
    -- Hiérarchie
    parent_location_id UUID REFERENCES locations(id),
    location_path VARCHAR(500), -- Chemin complet (ex: /A/01/12/)
    location_level INTEGER DEFAULT 1, -- Niveau dans la hiérarchie
    
    -- Type d'emplacement
    location_type VARCHAR(30) NOT NULL, -- 'zone', 'aisle', 'rack', 'shelf', 'bin', 'bulk', 'dock'
    storage_type VARCHAR(30), -- 'pallet', 'case', 'piece', 'bulk', 'hazardous', 'cold', 'quarantine'
    
    -- Dimensions et capacité
    width DECIMAL(10,2), -- Largeur (cm)
    depth DECIMAL(10,2), -- Profondeur (cm)
    height DECIMAL(10,2), -- Hauteur (cm)
    max_weight DECIMAL(10,2), -- Poids maximum (kg)
    max_volume DECIMAL(10,2), -- Volume maximum (m³)
    max_pallets INTEGER, -- Nombre max de palettes
    max_quantity DECIMAL(15,3), -- Quantité max (selon unité)
    
    -- Coordonnées (pour système de guidage)
    coordinate_x INTEGER,
    coordinate_y INTEGER,
    coordinate_z INTEGER,
    zone_code VARCHAR(50), -- Code de zone (ex: A, B, C)
    aisle_code VARCHAR(50), -- Code d'allée
    rack_code VARCHAR(50), -- Code de rack
    shelf_code VARCHAR(50), -- Code d'étagère
    bin_code VARCHAR(50), -- Code de casier
    
    -- Statut
    is_active BOOLEAN DEFAULT TRUE,
    is_reserved BOOLEAN DEFAULT FALSE, -- Emplacement réservé (produit spécifique)
    reserved_product_id UUID REFERENCES products(id), -- ✅ Produit réservé
    is_occupied BOOLEAN DEFAULT FALSE,
    is_blocked BOOLEAN DEFAULT FALSE,
    blocked_reason TEXT,
    
    -- Caractéristiques
    has_rack BOOLEAN DEFAULT TRUE,
    has_light BOOLEAN DEFAULT FALSE,
    has_pick_face BOOLEAN DEFAULT FALSE, -- Face de picking
    is_pickable BOOLEAN DEFAULT TRUE,
    is_receivable BOOLEAN DEFAULT TRUE,
    is_shippable BOOLEAN DEFAULT TRUE,
    
    -- Sécurité
    requires_equipment BOOLEAN DEFAULT FALSE, -- Équipement nécessaire
    safety_stock DECIMAL(15,3), -- Stock de sécurité pour cet emplacement
    
    -- Métadonnées
    last_counted_at TIMESTAMP WITH TIME ZONE, -- Dernier inventaire
    last_moved_at TIMESTAMP WITH TIME ZONE, -- Dernier mouvement
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité
    CONSTRAINT unique_location_code UNIQUE (warehouse_id, code)
);

-- Index pour locations
CREATE INDEX idx_locations_warehouse ON locations(warehouse_id);
CREATE INDEX idx_locations_parent ON locations(parent_location_id);
CREATE INDEX idx_locations_code ON locations(code);
CREATE INDEX idx_locations_barcode ON locations(barcode);
CREATE INDEX idx_locations_path ON locations(location_path);
CREATE INDEX idx_locations_type ON locations(location_type);
CREATE INDEX idx_locations_active ON locations(is_active) WHERE is_active = TRUE;

-- Fonction pour mise à jour du path hiérarchique
CREATE OR REPLACE FUNCTION update_location_path()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_location_id IS NULL THEN
        NEW.location_path := '/' || NEW.code || '/';
        NEW.location_level := 1;
    ELSE
        SELECT location_path INTO NEW.location_path 
        FROM locations WHERE id = NEW.parent_location_id;
        NEW.location_path := NEW.location_path || NEW.code || '/';
        NEW.location_level := (SELECT location_level FROM locations WHERE id = NEW.parent_location_id) + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_location_path
    BEFORE INSERT OR UPDATE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION update_location_path();


CREATE TABLE stock_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Clé unique du stock
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    location_id UUID REFERENCES locations(id), -- ✅ Emplacement (NULL si stock global dépôt)
    
    -- Lot (si tracé)
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    serial_number_id UUID REFERENCES serial_numbers(id), -- ✅ N° série (si unitaire)
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL DEFAULT 0,
    quantity_reserved DECIMAL(15,3) NOT NULL DEFAULT 0,
    quantity_available DECIMAL(15,3) GENERATED ALWAYS AS (quantity - quantity_reserved) STORED,
    quantity_quarantine DECIMAL(15,3) DEFAULT 0,
    quantity_blocked DECIMAL(15,3) DEFAULT 0,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Valorisation
    unit_cost DECIMAL(15,4), -- Coût unitaire actuel
    total_value DECIMAL(15,4) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Dates
    last_movement_at TIMESTAMP WITH TIME ZONE, -- Dernier mouvement
    last_counted_at TIMESTAMP WITH TIME ZONE, -- Dernier comptage
    first_reception_at TIMESTAMP WITH TIME ZONE, -- Première réception
    expiry_date DATE, -- Date d'expiration (si lot)
    
    -- Statut
    stock_status VARCHAR(30) DEFAULT 'active', -- 'active', 'expired', 'blocked', 'quarantine'
    
    -- Alertes
    below_min_threshold BOOLEAN DEFAULT FALSE,
    above_max_threshold BOOLEAN DEFAULT FALSE,
    near_expiry BOOLEAN DEFAULT FALSE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte d'unicité (un seul enregistrement par combinaison)
    CONSTRAINT unique_stock_level UNIQUE (product_id, warehouse_id, COALESCE(location_id, '00000000-0000-0000-0000-000000000000'), COALESCE(lot_id, '00000000-0000-0000-0000-000000000000'), COALESCE(serial_number_id, '00000000-0000-0000-0000-000000000000'))
);

-- Index
CREATE INDEX idx_stock_levels_product ON stock_levels(product_id);
CREATE INDEX idx_stock_levels_warehouse ON stock_levels(warehouse_id);
CREATE INDEX idx_stock_levels_location ON stock_levels(location_id);
CREATE INDEX idx_stock_levels_lot ON stock_levels(lot_id);
CREATE INDEX idx_stock_levels_serial ON stock_levels(serial_number_id);
CREATE INDEX idx_stock_levels_status ON stock_levels(stock_status);
CREATE INDEX idx_stock_levels_expiry ON stock_levels(expiry_date) WHERE expiry_date IS NOT NULL;


CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    movement_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Type de mouvement
    movement_type VARCHAR(30) NOT NULL, -- 'receipt', 'delivery', 'transfer', 'adjustment', 'return', 'scrap', 'consumption'
    movement_reason VARCHAR(50), -- 'purchase', 'sale', 'internal', 'damage', 'expiry', 'count_correction'
    
    -- Dates
    movement_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Date comptable
    
    -- Produit
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    lot_id UUID REFERENCES lots(id), -- ✅ Lot (si tracé)
    serial_number_id UUID REFERENCES serial_numbers(id), -- ✅ N° série (si unitaire)
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    quantity_delta INTEGER GENERATED ALWAYS AS (CASE WHEN movement_type IN ('receipt', 'return', 'adjustment_positive') THEN 1 ELSE -1 END) STORED,
    
    -- Emplacements
    from_warehouse_id UUID REFERENCES warehouses(id), -- ✅ Dépôt source
    from_location_id UUID REFERENCES locations(id), -- ✅ Emplacement source
    to_warehouse_id UUID REFERENCES warehouses(id), -- ✅ Dépôt destination
    to_location_id UUID REFERENCES locations(id), -- ✅ Emplacement destination
    
    -- Valeur
    unit_cost DECIMAL(15,4), -- Coût unitaire au moment du mouvement
    total_cost DECIMAL(15,4) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Documents source
    source_type VARCHAR(30), -- 'purchase_order', 'goods_receipt', 'sales_order', 'delivery_note', 'stock_transfer', 'stock_adjustment'
    source_id UUID,
    source_line_id UUID,
    source_reference VARCHAR(100), -- Référence document (N° BL, N° commande)
    
    -- Utilisateur
    user_id UUID NOT NULL REFERENCES users(id), -- ✅ Opérateur
    user_name VARCHAR(255), -- Copie pour historique
    
    -- Contrôle
    is_automated BOOLEAN DEFAULT FALSE, -- Mouvement automatique (système)
    is_validated BOOLEAN DEFAULT TRUE,
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by UUID REFERENCES users(id),
    
    -- Notes
    notes TEXT,
    
    -- Audit (traçabilité)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_stock_movements_number ON stock_movements(movement_number);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_lot ON stock_movements(lot_id);
CREATE INDEX idx_stock_movements_serial ON stock_movements(serial_number_id);
CREATE INDEX idx_stock_movements_date ON stock_movements(movement_date);
CREATE INDEX idx_stock_movements_type ON stock_movements(movement_type);
CREATE INDEX idx_stock_movements_source ON stock_movements(source_type, source_id);
CREATE INDEX idx_stock_movements_user ON stock_movements(user_id);
CREATE INDEX idx_stock_movements_from ON stock_movements(from_warehouse_id, from_location_id);
CREATE INDEX idx_stock_movements_to ON stock_movements(to_warehouse_id, to_location_id);

-- Fonction de mise à jour automatique des stock_levels
CREATE OR REPLACE FUNCTION update_stock_levels_from_movement()
RETURNS TRIGGER AS $$
BEGIN
    -- Mouvement de sortie (décrémentation)
    IF NEW.from_warehouse_id IS NOT NULL THEN
        UPDATE stock_levels 
        SET quantity = quantity - NEW.quantity,
            last_movement_at = NEW.movement_date
        WHERE product_id = NEW.product_id 
          AND warehouse_id = NEW.from_warehouse_id
          AND (location_id = NEW.from_location_id OR (location_id IS NULL AND NEW.from_location_id IS NULL))
          AND (lot_id = NEW.lot_id OR (lot_id IS NULL AND NEW.lot_id IS NULL))
          AND (serial_number_id = NEW.serial_number_id OR (serial_number_id IS NULL AND NEW.serial_number_id IS NULL));
          
        -- Si pas de ligne existante, créer une ligne négative (stock négatif autorisé selon config)
        IF NOT FOUND AND (SELECT allow_negative_stock FROM warehouses WHERE id = NEW.from_warehouse_id) THEN
            INSERT INTO stock_levels (product_id, warehouse_id, location_id, lot_id, serial_number_id, quantity, unit_id, unit_cost)
            VALUES (NEW.product_id, NEW.from_warehouse_id, NEW.from_location_id, NEW.lot_id, NEW.serial_number_id, -NEW.quantity, NEW.unit_id, NEW.unit_cost);
        END IF;
    END IF;
    
    -- Mouvement d'entrée (incrémentation)
    IF NEW.to_warehouse_id IS NOT NULL THEN
        INSERT INTO stock_levels (product_id, warehouse_id, location_id, lot_id, serial_number_id, quantity, unit_id, unit_cost, last_movement_at)
        VALUES (NEW.product_id, NEW.to_warehouse_id, NEW.to_location_id, NEW.lot_id, NEW.serial_number_id, NEW.quantity, NEW.unit_id, NEW.unit_cost, NEW.movement_date)
        ON CONFLICT (product_id, warehouse_id, location_id, lot_id, serial_number_id) 
        DO UPDATE SET 
            quantity = stock_levels.quantity + EXCLUDED.quantity,
            unit_cost = EXCLUDED.unit_cost, -- À affiner selon méthode valorisation
            last_movement_at = EXCLUDED.last_movement_at;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_levels
    AFTER INSERT ON stock_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_levels_from_movement();



    CREATE TABLE stock_reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Référence commande
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id),
    sales_order_line_id UUID NOT NULL REFERENCES sales_order_lines(id),
    
    -- Produit réservé
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    lot_id UUID REFERENCES lots(id), -- ✅ Lot (si tracé)
    serial_number_id UUID REFERENCES serial_numbers(id), -- ✅ N° série (si unitaire)
    
    -- Dépôt / Emplacement
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    location_id UUID REFERENCES locations(id), -- ✅ Emplacement (optionnel)
    
    -- Quantités
    quantity_reserved DECIMAL(15,3) NOT NULL,
    quantity_picked DECIMAL(15,3) DEFAULT 0,
    quantity_cancelled DECIMAL(15,3) DEFAULT 0,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Dates
    reservation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiration_date TIMESTAMP WITH TIME ZONE, -- Date d'expiration de la réservation
    
    -- Méthode d'allocation
    allocation_method VARCHAR(30) DEFAULT 'fifo', -- 'fifo', 'fefo', 'manual'
    allocation_rule_applied TEXT, -- Règle appliquée
    
    -- Statut
    status VARCHAR(30) DEFAULT 'active', -- 'active', 'picked', 'cancelled', 'expired'
    
    -- Lien avec picking
    picking_list_line_id UUID REFERENCES picking_list_lines(id),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT,
    
    -- Contrainte
    CONSTRAINT positive_reservation CHECK (quantity_reserved > 0)
);

-- Index
CREATE INDEX idx_stock_reservations_order ON stock_reservations(sales_order_id, sales_order_line_id);
CREATE INDEX idx_stock_reservations_product ON stock_reservations(product_id);
CREATE INDEX idx_stock_reservations_lot ON stock_reservations(lot_id);
CREATE INDEX idx_stock_reservations_warehouse ON stock_reservations(warehouse_id);
CREATE INDEX idx_stock_reservations_status ON stock_reservations(status);
CREATE INDEX idx_stock_reservations_expiry ON stock_reservations(expiration_date) WHERE status = 'active';





CREATE TABLE stock_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    transfer_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    transfer_date DATE NOT NULL DEFAULT CURRENT_DATE,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expected_arrival_date DATE,
    completed_date DATE,
    
    -- Dépôts
    from_warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt source
    to_warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt destination
    
    -- Responsables
    requested_by UUID NOT NULL REFERENCES users(id), -- ✅ Demandeur
    approved_by UUID REFERENCES users(id), -- ✅ Approbateur
    sent_by UUID REFERENCES users(id), -- ✅ Expéditeur
    received_by UUID REFERENCES users(id), -- ✅ Réceptionnaire
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'pending_approval', 'approved', 'preparing', 'shipped', 'received', 'completed', 'cancelled'
    
    -- Transport
    carrier_id UUID, -- ✅ Transporteur (table carriers)
    tracking_number VARCHAR(100),
    shipping_cost DECIMAL(15,2),
    
    -- Documents
    transfer_document_url TEXT,
    notes TEXT,
    
    -- Validation
    requires_approval BOOLEAN DEFAULT TRUE,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_st_transfer_number ON stock_transfers(transfer_number);
CREATE INDEX idx_st_from_warehouse ON stock_transfers(from_warehouse_id);
CREATE INDEX idx_st_to_warehouse ON stock_transfers(to_warehouse_id);
CREATE INDEX idx_st_status ON stock_transfers(status);
CREATE INDEX idx_st_dates ON stock_transfers(transfer_date, expected_arrival_date);



CREATE TABLE stock_transfer_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_transfer_id UUID NOT NULL REFERENCES stock_transfers(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Produit
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    product_description TEXT,
    
    -- Lots
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    lot_number VARCHAR(100),
    serial_numbers TEXT[], -- Liste des N° de série
    
    -- Quantités
    quantity_requested DECIMAL(15,3) NOT NULL,
    quantity_prepared DECIMAL(15,3) DEFAULT 0,
    quantity_shipped DECIMAL(15,3) DEFAULT 0,
    quantity_received DECIMAL(15,3) DEFAULT 0,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Emplacements
    from_location_id UUID REFERENCES locations(id), -- ✅ Emplacement source
    to_location_id UUID REFERENCES locations(id), -- ✅ Emplacement destination (prévisionnel)
    
    -- Statut
    status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'prepared', 'shipped', 'received', 'cancelled'
    
    -- Valeur
    unit_cost DECIMAL(15,4),
    line_value DECIMAL(15,4) GENERATED ALWAYS AS (quantity_shipped * unit_cost) STORED,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_st_lines_transfer ON stock_transfer_lines(stock_transfer_id);
CREATE INDEX idx_st_lines_product ON stock_transfer_lines(product_id);
CREATE INDEX idx_st_lines_lot ON stock_transfer_lines(lot_id);


CREATE TABLE stock_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    adjustment_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    adjustment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Type d'ajustement
    adjustment_type VARCHAR(30) NOT NULL, -- 'inventory_gap', 'damage', 'loss', 'theft', 'expiry', 'quality', 'correction'
    
    -- Dépôt
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    
    -- Responsables
    requested_by UUID NOT NULL REFERENCES users(id), -- ✅ Demandeur
    approved_by UUID REFERENCES users(id), -- ✅ Approbateur (si ajustement sensible)
    performed_by UUID REFERENCES users(id), -- ✅ Opérateur
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'pending_approval', 'approved', 'rejected', 'completed', 'cancelled'
    
    -- Sensibilité
    is_sensitive BOOLEAN DEFAULT FALSE, -- Ajustement sensible (montant élevé)
    sensitivity_reason TEXT,
    
    -- Période comptable
    accounting_period VARCHAR(10),
    
    -- Notes
    reason TEXT NOT NULL,
    description TEXT,
    internal_notes TEXT,
    
    -- Validation
    requires_approval BOOLEAN DEFAULT TRUE,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_sa_number ON stock_adjustments(adjustment_number);
CREATE INDEX idx_sa_warehouse ON stock_adjustments(warehouse_id);
CREATE INDEX idx_sa_status ON stock_adjustments(status);
CREATE INDEX idx_sa_type ON stock_adjustments(adjustment_type);
CREATE INDEX idx_sa_date ON stock_adjustments(adjustment_date);





CREATE TABLE stock_adjustment_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_adjustment_id UUID NOT NULL REFERENCES stock_adjustments(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Produit
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    product_description TEXT,
    
    -- Lot (si tracé)
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    lot_number VARCHAR(100),
    serial_number_id UUID REFERENCES serial_numbers(id), -- ✅ N° série
    
    -- Emplacement
    location_id UUID REFERENCES locations(id), -- ✅ Emplacement
    
    -- Quantités
    quantity_before DECIMAL(15,3) NOT NULL, -- Quantité théorique avant ajustement
    quantity_after DECIMAL(15,3) NOT NULL, -- Quantité réelle après ajustement
    quantity_adjustment DECIMAL(15,3) GENERATED ALWAYS AS (quantity_after - quantity_before) STORED,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Valeur
    unit_cost DECIMAL(15,4), -- Coût unitaire
    adjustment_value DECIMAL(15,4) GENERATED ALWAYS AS (quantity_adjustment * unit_cost) STORED,
    
    -- Motif détaillé
    reason_code VARCHAR(50), -- 'damage', 'loss', 'expiry', 'count_error', 'system_error'
    reason_details TEXT,
    
    -- Contrôle qualité (si applicable)
    quality_status VARCHAR(30), -- 'good', 'damaged', 'expired', 'quarantine'
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_sa_lines_adjustment ON stock_adjustment_lines(stock_adjustment_id);
CREATE INDEX idx_sa_lines_product ON stock_adjustment_lines(product_id);
CREATE INDEX idx_sa_lines_lot ON stock_adjustment_lines(lot_id);
CREATE INDEX idx_sa_lines_location ON stock_adjustment_lines(location_id);



CREATE TABLE stock_adjustment_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_adjustment_id UUID NOT NULL REFERENCES stock_adjustments(id) ON DELETE CASCADE,
    
    -- Niveaux d'approbation
    approval_level INTEGER NOT NULL, -- 1, 2, 3
    
    -- Valeurs
    adjustment_total DECIMAL(15,2),
    threshold_amount DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Approbateur
    approver_id UUID NOT NULL REFERENCES users(id), -- ✅ Approbateur
    approver_role VARCHAR(50),
    
    -- Décision
    decision VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    decision_date TIMESTAMP WITH TIME ZONE,
    comments TEXT,
    
    -- Délégation
    delegated_from_id UUID REFERENCES users(id),
    
    -- Notification
    notified_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Contrainte
    CONSTRAINT unique_adjustment_level UNIQUE (stock_adjustment_id, approval_level)
);

-- Index
CREATE INDEX idx_sa_approvals_adjustment ON stock_adjustment_approvals(stock_adjustment_id);
CREATE INDEX idx_sa_approvals_approver ON stock_adjustment_approvals(approver_id);
CREATE INDEX idx_sa_approvals_status ON stock_adjustment_approvals(decision);


CREATE TABLE inventory_counts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    count_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    count_date DATE NOT NULL,
    scheduled_date DATE,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Type d'inventaire
    count_type VARCHAR(30) NOT NULL, -- 'annual', 'cyclic', 'rotation', 'spot', 'audit'
    count_method VARCHAR(30) DEFAULT 'physical', -- 'physical', 'blind', 'double'
    
    -- Périmètre
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    zone_id UUID REFERENCES locations(id), -- ✅ Zone spécifique (optionnel)
    
    -- Responsables
    count_manager_id UUID NOT NULL REFERENCES users(id), -- ✅ Responsable inventaire
    count_team JSONB, -- Liste des compteurs
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'planned', -- 'planned', 'in_progress', 'paused', 'completed', 'validated', 'cancelled'
    
    -- Statistiques
    total_locations INTEGER DEFAULT 0,
    counted_locations INTEGER DEFAULT 0,
    total_products INTEGER DEFAULT 0,
    counted_products INTEGER DEFAULT 0,
    discrepancy_count INTEGER DEFAULT 0,
    discrepancy_percentage DECIMAL(5,2),
    
    -- Dates clés
    started_at TIMESTAMP WITH TIME ZONE,
    paused_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Validation
    validated_by UUID REFERENCES users(id), -- ✅ Validateur
    validation_notes TEXT,
    
    -- Notes
    instructions TEXT,
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_ic_number ON inventory_counts(count_number);
CREATE INDEX idx_ic_warehouse ON inventory_counts(warehouse_id);
CREATE INDEX idx_ic_status ON inventory_counts(status);
CREATE INDEX idx_ic_dates ON inventory_counts(count_date, scheduled_date);



CREATE TABLE inventory_count_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_count_id UUID NOT NULL REFERENCES inventory_counts(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Emplacement compté
    location_id UUID NOT NULL REFERENCES locations(id), -- ✅ Emplacement
    
    -- Produit attendu (si connu)
    product_id UUID REFERENCES products(id), -- ✅ Produit
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    expected_quantity DECIMAL(15,3), -- Quantité théorique (si connue)
    
    -- Comptage
    counted_by UUID REFERENCES users(id), -- ✅ Compteur
    counted_at TIMESTAMP WITH TIME ZONE,
    counted_quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Second comptage (pour double comptage)
    second_counted_by UUID REFERENCES users(id),
    second_counted_at TIMESTAMP WITH TIME ZONE,
    second_counted_quantity DECIMAL(15,3),
    
    -- Écart
    theoretical_quantity DECIMAL(15,3),
    discrepancy_quantity DECIMAL(15,3) GENERATED ALWAYS AS (counted_quantity - theoretical_quantity) STORED,
    discrepancy_percentage DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN theoretical_quantity > 0 THEN (counted_quantity - theoretical_quantity) * 100.0 / theoretical_quantity ELSE 0 END) STORED,
    
    -- Statut de la ligne
    status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'counted', 'verified', 'discrepancy', 'resolved'
    
    -- Produit réellement trouvé (si différent)
    actual_product_id UUID REFERENCES products(id),
    actual_lot_id UUID REFERENCES lots(id),
    actual_product_description TEXT,
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_ic_lines_count ON inventory_count_lines(inventory_count_id);
CREATE INDEX idx_ic_lines_location ON inventory_count_lines(location_id);
CREATE INDEX idx_ic_lines_product ON inventory_count_lines(product_id);
CREATE INDEX idx_ic_lines_status ON inventory_count_lines(status);
CREATE INDEX idx_ic_lines_discrepancy ON inventory_count_lines(discrepancy_quantity) WHERE discrepancy_quantity != 0;


CREATE TABLE inventory_count_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_count_id UUID NOT NULL REFERENCES inventory_counts(id) ON DELETE CASCADE,
    inventory_count_line_id UUID NOT NULL REFERENCES inventory_count_lines(id) ON DELETE CASCADE,
    
    -- Validateur
    validator_id UUID NOT NULL REFERENCES users(id), -- ✅ Validateur
    validation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Type de validation
    validation_type VARCHAR(30) NOT NULL, -- 'spot_check', 'full_validation', 'supervisor', 'manager'
    
    -- Décision
    validation_status VARCHAR(30) NOT NULL, -- 'approved', 'rejected', 'recount_required'
    
    -- Vérification (recomptage)
    verified_quantity DECIMAL(15,3),
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Écart constaté
    discrepancy_confirmed BOOLEAN,
    final_discrepancy DECIMAL(15,3),
    
    -- Action corrective
    correction_action VARCHAR(50), -- 'adjust_stock', 'ignore', 'investigate', 'recount'
    adjustment_created BOOLEAN DEFAULT FALSE,
    adjustment_id UUID REFERENCES stock_adjustments(id), -- ✅ Ajustement créé
    
    -- Notes
    comments TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_icv_count ON inventory_count_validations(inventory_count_id);
CREATE INDEX idx_icv_line ON inventory_count_validations(inventory_count_line_id);
CREATE INDEX idx_icv_validator ON inventory_count_validations(validator_id);




CREATE TABLE inventory_gaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Référence
    gap_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Lien avec inventaire
    inventory_count_id UUID REFERENCES inventory_counts(id),
    inventory_count_line_id UUID REFERENCES inventory_count_lines(id),
    
    -- Produit
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    location_id UUID REFERENCES locations(id), -- ✅ Emplacement
    
    -- Quantités
    theoretical_quantity DECIMAL(15,3) NOT NULL,
    counted_quantity DECIMAL(15,3) NOT NULL,
    gap_quantity DECIMAL(15,3) GENERATED ALWAYS AS (counted_quantity - theoretical_quantity) STORED,
    gap_absolute DECIMAL(15,3) GENERATED ALWAYS AS (ABS(counted_quantity - theoretical_quantity)) STORED,
    gap_percentage DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN theoretical_quantity > 0 THEN (counted_quantity - theoretical_quantity) * 100.0 / theoretical_quantity ELSE 0 END) STORED,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Valeur
    unit_cost DECIMAL(15,4),
    gap_value DECIMAL(15,4) GENERATED ALWAYS AS (gap_quantity * unit_cost) STORED,
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    
    -- Gravité
    severity VARCHAR(30) GENERATED ALWAYS AS (
        CASE 
            WHEN ABS(gap_quantity) < 1 THEN 'minor'
            WHEN ABS(gap_quantity) < 10 THEN 'moderate'
            WHEN ABS(gap_quantity) < 100 THEN 'significant'
            ELSE 'critical'
        END
    ) STORED,
    
    -- Analyse
    gap_reason VARCHAR(50), -- 'counting_error', 'system_error', 'loss', 'theft', 'damage', 'misplacement', 'unknown'
    gap_analysis TEXT,
    
    -- Action corrective
    correction_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'investigating', 'corrected', 'accepted'
    correction_action VARCHAR(100),
    correction_date DATE,
    corrected_by UUID REFERENCES users(id),
    adjustment_id UUID REFERENCES stock_adjustments(id), -- ✅ Ajustement lié
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_ig_product ON inventory_gaps(product_id);
CREATE INDEX idx_ig_warehouse ON inventory_gaps(warehouse_id);
CREATE INDEX idx_ig_severity ON inventory_gaps(severity);
CREATE INDEX idx_ig_status ON inventory_gaps(correction_status);


CREATE TABLE lot_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Lot
    lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE, -- ✅ Lot
    lot_number VARCHAR(100) NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    
    -- Événement
    event_type VARCHAR(30) NOT NULL, -- 'receipt', 'transfer', 'sale', 'return', 'adjustment', 'expiry', 'quality'
    event_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Documents source
    source_type VARCHAR(30) NOT NULL, -- 'purchase_order', 'goods_receipt', 'sales_order', 'delivery_note', 'stock_transfer', 'stock_adjustment'
    source_id UUID NOT NULL,
    source_line_id UUID,
    source_reference VARCHAR(100), -- N° document
    
    -- Mouvement
    from_warehouse_id UUID REFERENCES warehouses(id),
    from_location_id UUID REFERENCES locations(id),
    to_warehouse_id UUID REFERENCES warehouses(id),
    to_location_id UUID REFERENCES locations(id),
    
    -- Quantité
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id),
    
    -- Utilisateur
    user_id UUID NOT NULL REFERENCES users(id), -- ✅ Opérateur
    
    -- Statut du lot après événement
    lot_status VARCHAR(30), -- 'active', 'partial', 'depleted', 'blocked', 'expired'
    quantity_remaining DECIMAL(15,3), -- Quantité restante après événement
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_lt_lot ON lot_tracking(lot_id);
CREATE INDEX idx_lt_product ON lot_tracking(product_id);
CREATE INDEX idx_lt_event ON lot_tracking(event_type, event_date);
CREATE INDEX idx_lt_source ON lot_tracking(source_type, source_id);


CREATE TABLE lot_expiry_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Lot concerné
    lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE, -- ✅ Lot
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    lot_number VARCHAR(100) NOT NULL,
    
    -- Dates
    manufacturing_date DATE,
    expiry_date DATE NOT NULL,
    best_before_date DATE, -- DLUO
    alert_date DATE NOT NULL, -- Date à laquelle l'alerte a été générée
    
    -- Stock
    current_quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    
    -- Seuils d'alerte
    alert_threshold_days INTEGER NOT NULL, -- Nombre de jours avant expiration
    days_until_expiry INTEGER GENERATED ALWAYS AS (expiry_date - CURRENT_DATE) STORED,
    alert_level VARCHAR(20) GENERATED ALWAYS AS (
        CASE 
            WHEN expiry_date - CURRENT_DATE <= 0 THEN 'expired'
            WHEN expiry_date - CURRENT_DATE <= 7 THEN 'critical'
            WHEN expiry_date - CURRENT_DATE <= 30 THEN 'warning'
            ELSE 'info'
        END
    ) STORED,
    
    -- Statut
    status VARCHAR(30) DEFAULT 'active', -- 'active', 'acknowledged', 'resolved', 'ignored'
    
    -- Actions
    recommended_action VARCHAR(100), -- 'use_first', 'discount', 'donate', 'dispose'
    action_taken VARCHAR(100),
    action_date DATE,
    action_by UUID REFERENCES users(id),
    
    -- Notification
    notified_users JSONB, -- Liste des utilisateurs notifiés
    last_notified_at TIMESTAMP WITH TIME ZONE,
    notification_count INTEGER DEFAULT 0,
    
    -- Résolution
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_lea_lot ON lot_expiry_alerts(lot_id);
CREATE INDEX idx_lea_expiry ON lot_expiry_alerts(expiry_date);
CREATE INDEX idx_lea_level ON lot_expiry_alerts(alert_level);
CREATE INDEX idx_lea_status ON lot_expiry_alerts(status);




CREATE TABLE quality_controls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    control_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Référence
    source_type VARCHAR(30) NOT NULL, -- 'goods_receipt', 'stock_transfer', 'return'
    source_id UUID NOT NULL,
    source_line_id UUID,
    
    -- Produit contrôlé
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    lot_number VARCHAR(100),
    serial_number_id UUID REFERENCES serial_numbers(id), -- ✅ N° série
    
    -- Quantité
    quantity_controlled DECIMAL(15,3) NOT NULL,
    quantity_accepted DECIMAL(15,3),
    quantity_rejected DECIMAL(15,3),
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Dates
    control_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sampling_date DATE,
    
    -- Contrôleur
    controller_id UUID NOT NULL REFERENCES users(id), -- ✅ Contrôleur
    supervisor_id UUID REFERENCES users(id), -- ✅ Superviseur
    
    -- Type de contrôle
    control_type VARCHAR(30) NOT NULL, -- 'visual', 'dimensional', 'weight', 'chemical', 'microbiological', 'functional'
    control_plan VARCHAR(100), -- Plan de contrôle appliqué
    sampling_plan VARCHAR(100), -- Plan d'échantillonnage
    
    -- Résultats
    result VARCHAR(30) NOT NULL, -- 'conform', 'non_conform', 'partial', 'pending'
    conformity_rate DECIMAL(5,2),
    
    -- Critères
    criteria_results JSONB, -- Résultats par critère
    
    -- Décision
    decision VARCHAR(30), -- 'accept', 'reject', 'quarantine', 'rework', 'scrap'
    decision_date TIMESTAMP WITH TIME ZONE,
    decision_by UUID REFERENCES users(id),
    
    -- Non-conformité
    non_conformity_code VARCHAR(50),
    non_conformity_description TEXT,
    
    -- Actions
    corrective_action TEXT,
    preventive_action TEXT,
    action_due_date DATE,
    action_responsible UUID REFERENCES users(id),
    
    -- Documents
    control_report_url TEXT,
    attachments JSONB,
    
    -- Statut
    status VARCHAR(30) DEFAULT 'draft', -- 'draft', 'in_progress', 'completed', 'approved', 'cancelled'
    
    -- Audit
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_qc_number ON quality_controls(control_number);
CREATE INDEX idx_qc_source ON quality_controls(source_type, source_id);
CREATE INDEX idx_qc_product ON quality_controls(product_id);
CREATE INDEX idx_qc_lot ON quality_controls(lot_id);
CREATE INDEX idx_qc_result ON quality_controls(result);




CREATE TABLE blocked_stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Référence
    block_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Stock concerné
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    serial_number_id UUID REFERENCES serial_numbers(id), -- ✅ N° série
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    location_id UUID REFERENCES locations(id), -- ✅ Emplacement
    
    -- Quantité
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Dates
    block_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expected_unblock_date DATE,
    unblock_date TIMESTAMP WITH TIME ZONE,
    
    -- Motif
    block_reason VARCHAR(50) NOT NULL, -- 'quality', 'expiry', 'damage', 'recall', 'litigation', 'audit'
    block_reason_text TEXT NOT NULL,
    block_source VARCHAR(50), -- 'quality_control', 'customer_return', 'supplier_dispute', 'inventory'
    source_id UUID, -- ID de la source (qualité, retour, etc.)
    
    -- Responsable
    blocked_by UUID NOT NULL REFERENCES users(id), -- ✅ Opérateur
    unblocked_by UUID REFERENCES users(id),
    
    -- Niveau de risque
    risk_level VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    
    -- Décision finale
    final_decision VARCHAR(30), -- 'destroy', 'return_supplier', 'rework', 'release', 'donate'
    decision_date DATE,
    decision_by UUID REFERENCES users(id),
    
    -- Coût
    estimated_loss DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code),
    
    -- Statut
    status VARCHAR(30) DEFAULT 'blocked', -- 'blocked', 'pending_decision', 'processing', 'unblocked', 'destroyed'
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_bs_product ON blocked_stock(product_id);
CREATE INDEX idx_bs_lot ON blocked_stock(lot_id);
CREATE INDEX idx_bs_warehouse ON blocked_stock(warehouse_id);
CREATE INDEX idx_bs_status ON blocked_stock(status);
CREATE INDEX idx_bs_reason ON blocked_stock(block_reason);



CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    shipment_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    shipment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    estimated_departure TIMESTAMP WITH TIME ZONE,
    estimated_arrival TIMESTAMP WITH TIME ZONE,
    actual_departure TIMESTAMP WITH TIME ZONE,
    actual_arrival TIMESTAMP WITH TIME ZONE,
    
    -- Type d'expédition
    shipment_type VARCHAR(30) NOT NULL, -- 'outbound' (client), 'inbound' (fournisseur), 'transfer' (inter-dépôt)
    shipment_mode VARCHAR(30), -- 'standard', 'express', 'urgent', 'scheduled'
    
    -- Documents source
    source_type VARCHAR(30), -- 'sales_order', 'delivery_note', 'purchase_order', 'stock_transfer'
    source_ids UUID[], -- Liste des IDs sources (plusieurs BL possible)
    
    -- Expéditeur
    from_warehouse_id UUID REFERENCES warehouses(id), -- ✅ Dépôt expéditeur
    from_address TEXT,
    from_contact_name VARCHAR(255),
    from_contact_phone VARCHAR(30),
    
    -- Destinataire
    to_customer_id UUID REFERENCES customers(id), -- ✅ Client (si outbound)
    to_supplier_id UUID REFERENCES suppliers(id), -- ✅ Fournisseur (si retour)
    to_warehouse_id UUID REFERENCES warehouses(id), -- ✅ Dépôt destination (si transfert)
    to_address TEXT NOT NULL,
    to_contact_name VARCHAR(255),
    to_contact_phone VARCHAR(30),
    to_contact_email VARCHAR(255),
    
    -- Transport
    carrier_id UUID REFERENCES carriers(id), -- ✅ Transporteur
    carrier_service_id UUID REFERENCES carrier_services(id), -- ✅ Service transporteur
    carrier_name VARCHAR(255), -- Copie pour historique
    shipping_method VARCHAR(100),
    incoterm_id UUID REFERENCES delivery_terms(id), -- ✅ Incoterm
    incoterm_location VARCHAR(255),
    
    -- Suivi
    tracking_number VARCHAR(100),
    tracking_url VARCHAR(500),
    
    -- Colisage
    total_packages INTEGER,
    total_pallets INTEGER,
    total_weight DECIMAL(15,3),
    weight_unit VARCHAR(10) DEFAULT 'kg',
    total_volume DECIMAL(15,3),
    volume_unit VARCHAR(10) DEFAULT 'm3',
    
    -- Valeur déclarée
    declared_value DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code), -- ✅ Devise
    insurance_amount DECIMAL(15,2),
    
    -- Coûts
    shipping_cost DECIMAL(15,2),
    fuel_surcharge DECIMAL(15,2),
    handling_cost DECIMAL(15,2),
    total_cost DECIMAL(15,2) GENERATED ALWAYS AS (COALESCE(shipping_cost,0) + COALESCE(fuel_surcharge,0) + COALESCE(handling_cost,0)) STORED,
    cost_currency CHAR(3) REFERENCES currencies(code),
    
    -- Documents
    shipping_labels_url TEXT,
    packing_list_url TEXT,
    customs_documents_url TEXT,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'ready', 'picked_up', 'in_transit', 'delivered', 'delayed', 'exception', 'cancelled'
    
    -- Validation
    validated_by UUID REFERENCES users(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Signature
    receiver_name VARCHAR(255),
    receiver_signature TEXT,
    delivery_photo_url TEXT,
    
    -- Notes
    special_instructions TEXT,
    internal_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_shipments_number ON shipments(shipment_number);
CREATE INDEX idx_shipments_date ON shipments(shipment_date);
CREATE INDEX idx_shipments_carrier ON shipments(carrier_id);
CREATE INDEX idx_shipments_customer ON shipments(to_customer_id);
CREATE INDEX idx_shipments_status ON shipments(status);
CREATE INDEX idx_shipments_tracking ON shipments(tracking_number);
CREATE INDEX idx_shipments_source ON shipments(source_type, source_ids);

-- Commentaires
COMMENT ON TABLE shipments IS 'Expéditions (sortantes et entrantes)';

CREATE TABLE shipment_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Lien avec documents source
    source_type VARCHAR(30), -- 'delivery_note', 'sales_order', 'purchase_order'
    source_id UUID,
    source_line_id UUID,
    
    -- Article
    product_id UUID NOT NULL REFERENCES products(id), -- ✅ Produit
    product_description TEXT NOT NULL,
    barcode VARCHAR(100),
    
    -- Lots / traçabilité
    lot_id UUID REFERENCES lots(id), -- ✅ Lot
    lot_number VARCHAR(100),
    serial_numbers TEXT[], -- Liste des N° de série
    
    -- Quantités
    quantity_shipped DECIMAL(15,3) NOT NULL,
    quantity_delivered DECIMAL(15,3) DEFAULT 0,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id), -- ✅ Unité
    
    -- Colisage
    package_type VARCHAR(50), -- 'carton', 'palette', 'caisse', 'fardeau'
    package_barcode VARCHAR(100),
    package_dimensions JSONB, -- Dimensions du colis
    
    -- Poids / Volume
    weight DECIMAL(15,3),
    volume DECIMAL(15,3),
    
    -- Valeur
    unit_price DECIMAL(15,4),
    line_value DECIMAL(15,4) GENERATED ALWAYS AS (quantity_shipped * unit_price) STORED,
    
    -- Statut
    status VARCHAR(30) DEFAULT 'shipped', -- 'shipped', 'delivered', 'damaged', 'lost'
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_shipment_lines_shipment ON shipment_lines(shipment_id);
CREATE INDEX idx_shipment_lines_product ON shipment_lines(product_id);
CREATE INDEX idx_shipment_lines_lot ON shipment_lines(lot_id);
CREATE INDEX idx_shipment_lines_source ON shipment_lines(source_type, source_id);



CREATE TABLE shipment_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    
    -- Événement
    event_code VARCHAR(50) NOT NULL, -- 'PICKUP', 'DEPART', 'ARRIVAL', 'OUT_FOR_DELIVERY', 'DELIVERED', 'EXCEPTION'
    event_name VARCHAR(255) NOT NULL,
    event_description TEXT,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Localisation
    location_name VARCHAR(255),
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    
    -- Source (automatique ou manuel)
    source VARCHAR(30) DEFAULT 'manual', -- 'manual', 'api_carrier', 'scan', 'system'
    
    -- Statut détaillé
    status_detail VARCHAR(50),
    is_delivery_event BOOLEAN DEFAULT FALSE,
    is_exception BOOLEAN DEFAULT FALSE,
    
    -- Signataire (si livraison)
    receiver_name VARCHAR(255),
    receiver_signature TEXT,
    delivery_photo_url TEXT,
    
    -- Commentaires
    comments TEXT,
    
    -- Métadonnées
    metadata JSONB,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_shipment_tracking_shipment ON shipment_tracking(shipment_id);
CREATE INDEX idx_shipment_tracking_date ON shipment_tracking(event_date);
CREATE INDEX idx_shipment_tracking_code ON shipment_tracking(event_code);

-- Table pour intégration API transporteurs
CREATE TABLE carrier_api_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carrier_id UUID REFERENCES carriers(id),
    shipment_id UUID REFERENCES shipments(id),
    tracking_number VARCHAR(100),
    
    -- Requête
    api_endpoint VARCHAR(500),
    request_payload JSONB,
    request_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Réponse
    response_status INTEGER,
    response_payload JSONB,
    response_time TIMESTAMP WITH TIME ZONE,
    
    -- Statut
    success BOOLEAN,
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_carrier_api_shipment ON carrier_api_logs(shipment_id);
CREATE INDEX idx_carrier_api_tracking ON carrier_api_logs(tracking_number);




CREATE TABLE receiving_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    schedule_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    scheduled_date DATE NOT NULL,
    scheduled_time TIME, -- Heure prévue
    expected_arrival TIMESTAMP WITH TIME ZONE,
    confirmed_arrival TIMESTAMP WITH TIME ZONE,
    
    -- Fournisseur
    supplier_id UUID REFERENCES suppliers(id), -- ✅ Fournisseur
    supplier_name VARCHAR(255),
    
    -- Commande associée
    purchase_order_id UUID REFERENCES purchase_orders(id), -- ✅ Commande
    po_number VARCHAR(50),
    
    -- Dépôt
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    dock_id UUID, -- Référence à la table docks (créée ci-dessous)
    
    -- Réceptionnaire prévu
    expected_receiver_id UUID REFERENCES users(id), -- ✅ Réceptionnaire
    actual_receiver_id UUID REFERENCES users(id),
    
    -- Informations logistiques
    carrier_name VARCHAR(255),
    truck_number VARCHAR(50),
    trailer_number VARCHAR(50),
    driver_name VARCHAR(255),
    driver_phone VARCHAR(30),
    
    -- Documents
    advance_shipping_notice_url TEXT, -- ASN
    delivery_note_url TEXT,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'scheduled', -- 'scheduled', 'confirmed', 'in_progress', 'completed', 'delayed', 'cancelled'
    
    -- Délais
    estimated_unload_time INTEGER, -- Temps estimé de déchargement (minutes)
    actual_unload_time INTEGER,
    
    -- Notes
    special_instructions TEXT,
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_rs_date ON receiving_schedules(scheduled_date);
CREATE INDEX idx_rs_supplier ON receiving_schedules(supplier_id);
CREATE INDEX idx_rs_po ON receiving_schedules(purchase_order_id);
CREATE INDEX idx_rs_warehouse ON receiving_schedules(warehouse_id);
CREATE INDEX idx_rs_status ON receiving_schedules(status);




-- Docks / Quais
CREATE TABLE docks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255),
    
    -- Type de quai
    dock_type VARCHAR(30) NOT NULL, -- 'receiving', 'shipping', 'both'
    dock_size VARCHAR(30), -- 'small', 'medium', 'large', 'truck', 'container'
    
    -- Équipements
    has_leveler BOOLEAN DEFAULT TRUE, -- Pont niveau
    has_shelter BOOLEAN DEFAULT TRUE, -- Sas
    has_scale BOOLEAN DEFAULT FALSE, -- Pont bascule
    has_crane BOOLEAN DEFAULT FALSE, -- Grue
    has_refrigeration BOOLEAN DEFAULT FALSE, -- Quai frigorifique
    
    -- Caractéristiques
    max_height DECIMAL(10,2), -- Hauteur max (m)
    max_weight DECIMAL(10,2), -- Poids max (tonnes)
    max_length DECIMAL(10,2), -- Longueur max (m)
    
    -- Disponibilité
    is_active BOOLEAN DEFAULT TRUE,
    is_available BOOLEAN DEFAULT TRUE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    CONSTRAINT unique_dock_code UNIQUE (warehouse_id, code)
);

-- Planning des quais
CREATE TABLE dock_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dock_id UUID NOT NULL REFERENCES docks(id) ON DELETE CASCADE,
    
    -- Période
    schedule_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    -- Opération associée
    operation_type VARCHAR(30) NOT NULL, -- 'receiving', 'shipping', 'transfer'
    operation_id UUID, -- ID de l'opération (receiving_schedule, shipment)
    operation_reference VARCHAR(100), -- N° de référence
    
    -- Utilisateur
    assigned_to UUID REFERENCES users(id), -- Opérateur assigné
    
    -- Statut
    status VARCHAR(30) DEFAULT 'scheduled', -- 'scheduled', 'in_progress', 'completed', 'cancelled', 'delayed'
    
    -- Réalisation
    actual_start TIMESTAMP WITH TIME ZONE,
    actual_end TIMESTAMP WITH TIME ZONE,
    
    -- Véhicule
    vehicle_plate VARCHAR(50),
    vehicle_type VARCHAR(50),
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT
);

-- Index
CREATE INDEX idx_dock_schedules_dock ON dock_schedules(dock_id);
CREATE INDEX idx_dock_schedules_date ON dock_schedules(schedule_date);
CREATE INDEX idx_dock_schedules_status ON dock_schedules(status);
CREATE INDEX idx_dock_schedules_operation ON dock_schedules(operation_type, operation_id);

CREATE TABLE picking_rounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    round_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dates
    round_date DATE NOT NULL DEFAULT CURRENT_DATE,
    creation_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    
    -- Dépôt
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    zone_id UUID REFERENCES locations(id), -- ✅ Zone concernée
    
    -- Type de tournée
    round_type VARCHAR(30) NOT NULL, -- 'order' (par commande), 'batch' (par lot), 'wave' (vague), 'zone' (par zone)
    priority VARCHAR(20) DEFAULT 'normal', -- 'high', 'normal', 'low'
    
    -- Préparateurs
    picker_id UUID REFERENCES users(id), -- ✅ Préparateur principal
    picker_ids UUID[], -- Liste des préparateurs (pour tournée en équipe)
    team_leader_id UUID REFERENCES users(id), -- ✅ Chef d'équipe
    
    -- Équipement
    equipment_used JSONB, -- Liste des équipements (chariots, scanners)
    
    -- Statistiques
    total_picking_lists INTEGER DEFAULT 0,
    total_lines INTEGER DEFAULT 0,
    total_items DECIMAL(15,3) DEFAULT 0,
    total_distance INTEGER, -- Distance parcourue (mètres)
    total_steps INTEGER, -- Nombre de pas
    
    -- Performance
    expected_duration INTEGER, -- Durée estimée (minutes)
    actual_duration INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (COALESCE(end_time, CURRENT_TIMESTAMP) - start_time))/60
    ) STORED,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'planned', -- 'planned', 'in_progress', 'paused', 'completed', 'cancelled'
    
    -- Validation
    validated_by UUID REFERENCES users(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Notes
    notes TEXT,
    incidents TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id)
);

-- Table de liaison entre tournées et listes de préparation
CREATE TABLE picking_round_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    picking_round_id UUID NOT NULL REFERENCES picking_rounds(id) ON DELETE CASCADE,
    picking_list_id UUID NOT NULL REFERENCES picking_lists(id) ON DELETE CASCADE,
    
    -- Ordre de traitement
    sequence_number INTEGER NOT NULL,
    
    -- Statut dans la tournée
    status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'skipped'
    
    -- Chronométrage
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_round_list UNIQUE (picking_round_id, picking_list_id)
);

-- Index
CREATE INDEX idx_pr_rounds_warehouse ON picking_rounds(warehouse_id);
CREATE INDEX idx_pr_rounds_picker ON picking_rounds(picker_id);
CREATE INDEX idx_pr_rounds_date ON picking_rounds(round_date);
CREATE INDEX idx_pr_rounds_status ON picking_rounds(status);
CREATE INDEX idx_pr_lists_round ON picking_round_lists(picking_round_id);
CREATE INDEX idx_pr_lists_list ON picking_round_lists(picking_list_id);


CREATE TABLE picking_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Date de mesure
    performance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Utilisateur
    user_id UUID NOT NULL REFERENCES users(id), -- ✅ Opérateur
    user_name VARCHAR(255),
    
    -- Dépôt
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- ✅ Dépôt
    zone_id UUID REFERENCES locations(id), -- ✅ Zone (optionnel)
    
    -- Période
    shift VARCHAR(30), -- 'morning', 'afternoon', 'night'
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (end_time - start_time))/60
    ) STORED,
    
    -- Statistiques globales
    total_picking_lists INTEGER DEFAULT 0,
    total_lines_picked INTEGER DEFAULT 0,
    total_items_picked DECIMAL(15,3) DEFAULT 0,
    total_distance INTEGER DEFAULT 0, -- Distance parcourue (mètres)
    
    -- Statistiques par type
    lines_by_zone JSONB, -- Lignes par zone
    items_by_product_category JSONB, -- Articles par catégorie
    
    -- Indicateurs de performance
    lines_per_hour DECIMAL(10,2) GENERATED ALWAYS AS 
        (CASE WHEN duration_minutes > 0 THEN total_lines_picked * 60.0 / duration_minutes ELSE 0 END) STORED,
    items_per_hour DECIMAL(10,2) GENERATED ALWAYS AS 
        (CASE WHEN duration_minutes > 0 THEN total_items_picked * 60.0 / duration_minutes ELSE 0 END) STORED,
    time_per_line DECIMAL(10,2) GENERATED ALWAYS AS 
        (CASE WHEN total_lines_picked > 0 THEN duration_minutes * 60.0 / total_lines_picked ELSE 0 END) STORED,
    
    -- Qualité
    error_count INTEGER DEFAULT 0,
    error_rate DECIMAL(5,4) GENERATED ALWAYS AS 
        (CASE WHEN total_lines_picked > 0 THEN error_count::DECIMAL / total_lines_picked ELSE 0 END) STORED,
    rework_count INTEGER DEFAULT 0,
    
    -- Tournées effectuées
    picking_round_ids UUID[], -- Liste des tournées
    
    -- Comparaison objectifs
    target_lines_per_hour DECIMAL(10,2),
    target_achievement DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN target_lines_per_hour > 0 THEN (lines_per_hour / target_lines_per_hour) * 100 ELSE NULL END) STORED,
    
    -- Métadonnées
    weather_conditions VARCHAR(100), -- Conditions météo (si entrepôt extérieur)
    congestion_level VARCHAR(20), -- Niveau de congestion ('low', 'medium', 'high')
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_pp_user ON picking_performance(user_id);
CREATE INDEX idx_pp_warehouse ON picking_performance(warehouse_id);
CREATE INDEX idx_pp_date ON picking_performance(performance_date);
CREATE INDEX idx_pp_shift ON picking_performance(shift);

-- Table des détails de performance (par commande/liste)
CREATE TABLE picking_performance_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    performance_id UUID NOT NULL REFERENCES picking_performance(id) ON DELETE CASCADE,
    
    -- Référence
    picking_list_id UUID REFERENCES picking_lists(id),
    sales_order_id UUID REFERENCES sales_orders(id),
    
    -- Chronométrage
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (completed_at - started_at))
    ) STORED,
    
    -- Statistiques
    lines_count INTEGER,
    items_count INTEGER,
    
    -- Distance
    estimated_distance INTEGER, -- Distance estimée
    actual_distance INTEGER, -- Distance réelle (si tracké)
    
    -- Difficulté
    complexity_score INTEGER, -- Score de complexité (1-10)
    
    -- Problèmes
    had_issues BOOLEAN DEFAULT FALSE,
    issues TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ppd_performance ON picking_performance_details(performance_id);
CREATE INDEX idx_ppd_list ON picking_performance_details(picking_list_id);




CREATE TABLE cost_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Code méthode
    code VARCHAR(20) NOT NULL UNIQUE, -- 'FIFO', 'LIFO', 'CUMP', 'STANDARD', 'ACTUAL'
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Type de méthode
    method_type VARCHAR(30) NOT NULL, -- 'inventory', 'accounting'
    
    -- Règles de calcul
    calculation_rule TEXT, -- Description de la règle
    formula TEXT, -- Formule de calcul
    
    -- Paramètres
    requires_periodic_calculation BOOLEAN DEFAULT FALSE, -- Nécessite calcul périodique
    calculation_frequency VARCHAR(20), -- 'daily', 'weekly', 'monthly', 'yearly'
    
    -- Période de validité
    valid_from DATE,
    valid_to DATE,
    
    -- Configuration par défaut
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_system BOOLEAN DEFAULT FALSE, -- Méthode système (non modifiable)
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Insertion des méthodes standards
INSERT INTO cost_methods (code, name, description, method_type, is_system, is_default) VALUES
('FIFO', 'First In First Out', 'Les premiers articles entrés sont les premiers sortis', 'inventory', TRUE, TRUE),
('LIFO', 'Last In First Out', 'Les derniers articles entrés sont les premiers sortis', 'inventory', TRUE, FALSE),
('CUMP', 'Coût Unitaire Moyen Pondéré', 'Moyenne pondérée des coûts d''achat', 'inventory', TRUE, FALSE),
('STANDARD', 'Coût Standard', 'Coût prédéfini, révisé périodiquement', 'inventory', TRUE, FALSE),
('ACTUAL', 'Coût Réel', 'Coût réel d''acquisition', 'inventory', TRUE, FALSE);

-- Table de liaison produit-méthode (si méthode spécifique par produit)
CREATE TABLE product_cost_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    cost_method_id UUID NOT NULL REFERENCES cost_methods(id),
    
    -- Période d'application
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,
    is_active BOOLEAN GENERATED ALWAYS AS (valid_to IS NULL OR valid_to >= CURRENT_DATE) STORED,
    
    -- Paramètres spécifiques
    parameters JSONB, -- Paramètres supplémentaires
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id),
    
    CONSTRAINT unique_product_cost_method UNIQUE (product_id, valid_from)
);

CREATE INDEX idx_product_cost_methods_product ON product_cost_methods(product_id);



CREATE TABLE cost_layers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Produit
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    
    -- Lot (si tracé)
    lot_id UUID REFERENCES lots(id),
    
    -- Dépôt
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    
    -- Couche
    layer_number VARCHAR(50), -- Numéro de couche
    layer_date DATE NOT NULL, -- Date de création de la couche
    
    -- Quantité
    quantity_initial DECIMAL(15,3) NOT NULL,
    quantity_remaining DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id),
    
    -- Coût
    unit_cost DECIMAL(15,4) NOT NULL,
    total_cost DECIMAL(15,4) GENERATED ALWAYS AS (quantity_remaining * unit_cost) STORED,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    
    -- Document source
    source_type VARCHAR(30) NOT NULL, -- 'purchase_order', 'goods_receipt', 'supplier_invoice', 'adjustment'
    source_id UUID NOT NULL,
    source_line_id UUID,
    source_date DATE,
    source_reference VARCHAR(100), -- N° document
    
    -- Dates
    receipt_date DATE, -- Date d'entrée en stock
    expiry_date DATE, -- Date d'expiration (pour FIFO périssable)
    
    -- Statut
    status VARCHAR(30) DEFAULT 'active', -- 'active', 'partial', 'depleted', 'frozen'
    
    -- Valorisation
    is_frozen BOOLEAN DEFAULT FALSE, -- Gelé par clôture
    frozen_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_cost_layers_product ON cost_layers(product_id);
CREATE INDEX idx_cost_layers_warehouse ON cost_layers(warehouse_id);
CREATE INDEX idx_cost_layers_lot ON cost_layers(lot_id);
CREATE INDEX idx_cost_layers_date ON cost_layers(layer_date);
CREATE INDEX idx_cost_layers_status ON cost_layers(status);
CREATE INDEX idx_cost_layers_source ON cost_layers(source_type, source_id);

-- Table de suivi des sorties de couches (consommation FIFO)
CREATE TABLE cost_layer_consumption (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cost_layer_id UUID NOT NULL REFERENCES cost_layers(id) ON DELETE CASCADE,
    
    -- Document de sortie
    source_type VARCHAR(30) NOT NULL, -- 'sales_order', 'stock_movement', 'adjustment'
    source_id UUID NOT NULL,
    source_line_id UUID,
    source_date DATE NOT NULL,
    
    -- Quantité consommée
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL REFERENCES units_of_measure(id),
    
    -- Valeur
    unit_cost DECIMAL(15,4) NOT NULL,
    total_cost DECIMAL(15,4) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    
    -- Ordre de consommation
    consumption_order INTEGER, -- Ordre dans la séquence FIFO
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_cost_layer_cons_layer ON cost_layer_consumption(cost_layer_id);
CREATE INDEX idx_cost_layer_cons_source ON cost_layer_consumption(source_type, source_id);



CREATE TABLE average_costs (    
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Produit
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    
    -- Période
    calculation_date DATE NOT NULL,
    period_type VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'yearly'
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Dépôt (NULL = tous dépôts confondus)
    warehouse_id UUID REFERENCES warehouses(id),
    
    -- Calcul
    opening_quantity DECIMAL(15,3) DEFAULT 0,
    opening_value DECIMAL(15,4) DEFAULT 0,
    opening_unit_cost DECIMAL(15,4) GENERATED ALWAYS AS 
        (CASE WHEN opening_quantity > 0 THEN opening_value / opening_quantity ELSE 0 END) STORED,
    
    -- Entrées de la période
    incoming_quantity DECIMAL(15,3) DEFAULT 0,
    incoming_value DECIMAL(15,4) DEFAULT 0,
    incoming_unit_cost DECIMAL(15,4) GENERATED ALWAYS AS 
        (CASE WHEN incoming_quantity > 0 THEN incoming_value / incoming_quantity ELSE 0 END) STORED,
    
    -- Sorties de la période
    outgoing_quantity DECIMAL(15,3) DEFAULT 0,
    outgoing_value DECIMAL(15,4) DEFAULT 0,
    
    -- Stock final
    closing_quantity DECIMAL(15,3) GENERATED ALWAYS AS (opening_quantity + incoming_quantity - outgoing_quantity) STORED,
    closing_value DECIMAL(15,4) GENERATED ALWAYS AS (opening_value + incoming_value - outgoing_value) STORED,
    
    -- Coût moyen pondéré
    weighted_average_cost DECIMAL(15,4) GENERATED ALWAYS AS 
        (CASE WHEN closing_quantity > 0 THEN closing_value / closing_quantity ELSE 
         CASE WHEN opening_quantity > 0 THEN opening_value / opening_quantity ELSE 0 END END) STORED,
    
    -- Devise
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    
    -- Statut
    is_final BOOLEAN DEFAULT FALSE, -- Calcul finalisé (après clôture)
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    CONSTRAINT unique_product_period UNIQUE (product_id, warehouse_id, period_type, period_start)
);

-- Index
CREATE INDEX idx_avg_costs_product ON average_costs(product_id);
CREATE INDEX idx_avg_costs_warehouse ON average_costs(warehouse_id);
CREATE INDEX idx_avg_costs_period ON average_costs(period_start, period_end); 




CREATE TABLE period_closings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Période comptable
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL CHECK (period_month BETWEEN 1 AND 12),
    period_code VARCHAR(10) GENERATED ALWAYS AS (period_year || '-' || LPAD(period_month::TEXT, 2, '0')) STORED UNIQUE,
    
    -- Dates
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    closing_date TIMESTAMP WITH TIME ZONE,
    
    -- Entité
    entity_id UUID NOT NULL REFERENCES entities(id),
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'open', -- 'open', 'closing', 'closed', 'reopened'
    
    -- Responsables
    closed_by UUID REFERENCES users(id),
    reopened_by UUID REFERENCES users(id),
    
    -- Vérifications
    inventory_verified BOOLEAN DEFAULT FALSE,
    bank_reconciled BOOLEAN DEFAULT FALSE,
    invoices_verified BOOLEAN DEFAULT FALSE,
    
    -- Totaux de contrôle
    total_assets DECIMAL(15,2),
    total_liabilities DECIMAL(15,2),
    total_equity DECIMAL(15,2),
    currency_code CHAR(3) REFERENCES currencies(code),
    
    -- Notes
    closing_notes TEXT,
    reopening_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_period_closings_entity ON period_closings(entity_id);
CREATE INDEX idx_period_closings_status ON period_closings(status);
CREATE INDEX idx_period_closings_date ON period_closings(period_start, period_end);

-- Table des vérifications de clôture
CREATE TABLE closing_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    period_closing_id UUID NOT NULL REFERENCES period_closings(id) ON DELETE CASCADE,
    
    -- Type de vérification
    check_type VARCHAR(50) NOT NULL, -- 'inventory_value', 'supplier_invoices', 'customer_invoices', 'bank_balance', 'cash_balance'
    check_name VARCHAR(255) NOT NULL,
    
    -- Résultat
    expected_value DECIMAL(15,2),
    actual_value DECIMAL(15,2),
    difference DECIMAL(15,2) GENERATED ALWAYS AS (actual_value - expected_value) STORED,
    is_valid BOOLEAN GENERATED ALWAYS AS (ABS(difference) < 0.01) STORED,
    
    -- Statut
    status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'passed', 'failed', 'ignored'
    
    -- Validation
    checked_by UUID REFERENCES users(id),
    checked_at TIMESTAMP WITH TIME ZONE,
    comments TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_closing_checks_period ON closing_checks(period_closing_id);


CREATE TABLE closing_freeze_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Période concernée
    period_closing_id UUID NOT NULL REFERENCES period_closings(id) ON DELETE CASCADE,
    
    -- Type de gel
    freeze_type VARCHAR(30) NOT NULL, -- 'inventory', 'accounting', 'full'
    
    -- Périmètre
    entity_id UUID REFERENCES entities(id),
    warehouse_id UUID REFERENCES warehouses(id),
    
    -- Dates
    freeze_start TIMESTAMP WITH TIME ZONE NOT NULL,
    freeze_end TIMESTAMP WITH TIME ZONE,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'active', -- 'active', 'expired', 'cancelled'
    
    -- Éléments gelés
    frozen_tables TEXT[], -- Liste des tables gelées
    frozen_period_start DATE NOT NULL, -- Début période gelée
    frozen_period_end DATE NOT NULL, -- Fin période gelée
    
    -- Utilisateurs autorisés à déroger
    authorized_users UUID[], -- Liste des users autorisés à passer outre
    
    -- Justification
    reason TEXT NOT NULL,
    
    -- Levée du gel
    unfrozen_at TIMESTAMP WITH TIME ZONE,
    unfrozen_by UUID REFERENCES users(id),
    unfrozen_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_freeze_period ON closing_freeze_logs(period_closing_id);
CREATE INDEX idx_freeze_status ON closing_freeze_logs(status);
CREATE INDEX idx_freeze_dates ON closing_freeze_logs(freeze_start, freeze_end);

-- Table des tentatives de mouvement pendant gel
CREATE TABLE freeze_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    freeze_log_id UUID NOT NULL REFERENCES closing_freeze_logs(id) ON DELETE CASCADE,
    
    -- Utilisateur
    user_id UUID NOT NULL REFERENCES users(id),
    attempted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Mouvement tenté
    movement_type VARCHAR(50),
    movement_data JSONB,
    
    -- Blocage
    blocked BOOLEAN DEFAULT TRUE,
    bypass_authorized BOOLEAN DEFAULT FALSE,
    authorized_by UUID REFERENCES users(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_freeze_violations_freeze ON freeze_violations(freeze_log_id);
CREATE INDEX idx_freeze_violations_user ON freeze_violations(user_id);


CREATE TABLE inventory_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Date de valorisation
    valuation_date DATE NOT NULL,
    
    -- Période
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL,
    
    -- Entité
    entity_id UUID NOT NULL REFERENCES entities(id),
    
    -- Dépôt (optionnel)
    warehouse_id UUID REFERENCES warehouses(id),
    
    -- Produit (optionnel - pour valorisation détaillée)
    product_id UUID REFERENCES products(id),
    product_category_id UUID REFERENCES product_categories(id),
    
    -- Méthode de valorisation
    cost_method_id UUID NOT NULL REFERENCES cost_methods(id),
    
    -- Quantités
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID REFERENCES units_of_measure(id),
    
    -- Valeurs
    unit_cost DECIMAL(15,4) NOT NULL,
    total_value DECIMAL(15,4) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    
    -- Décomposition
    value_by_layer JSONB, -- Valeur par couche FIFO
    
    -- Statut
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Comparaison avec période précédente
    previous_value DECIMAL(15,4),
    variation DECIMAL(15,4) GENERATED ALWAYS AS (total_value - previous_value) STORED,
    variation_percentage DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN previous_value > 0 THEN (total_value - previous_value) * 100.0 / previous_value ELSE 0 END) STORED,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_inventory_values_date ON inventory_values(valuation_date);
CREATE INDEX idx_inventory_values_entity ON inventory_values(entity_id);
CREATE INDEX idx_inventory_values_warehouse ON inventory_values(warehouse_id);
CREATE INDEX idx_inventory_values_product ON inventory_values(product_id);
CREATE INDEX idx_inventory_values_category ON inventory_values(product_category_id);
CREATE INDEX idx_inventory_values_method ON inventory_values(cost_method_id);

-- Vue consolidée pour reporting
CREATE VIEW inventory_value_summary AS
SELECT 
    valuation_date,
    entity_id,
    COALESCE(warehouse_id, '00000000-0000-0000-0000-000000000000') as warehouse_id,
    SUM(quantity) as total_quantity,
    SUM(total_value) as total_value,
    currency_code
FROM inventory_values
GROUP BY valuation_date, entity_id, warehouse_id, currency_code;



CREATE TABLE valuation_variations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Périodes comparées
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Entité
    entity_id UUID NOT NULL REFERENCES entities(id),
    
    -- Produit
    product_id UUID REFERENCES products(id),
    product_category_id UUID REFERENCES product_categories(id),
    
    -- Type d'écart
    variation_type VARCHAR(30) NOT NULL, -- 'price', 'quantity', 'mix', 'exchange_rate'
    
    -- Valeurs
    opening_value DECIMAL(15,4) NOT NULL,
    closing_value DECIMAL(15,4) NOT NULL,
    variation_amount DECIMAL(15,4) GENERATED ALWAYS AS (closing_value - opening_value) STORED,
    variation_percentage DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN opening_value > 0 THEN (closing_value - opening_value) * 100.0 / opening_value ELSE 0 END) STORED,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    
    -- Décomposition
    price_effect DECIMAL(15,4), -- Effet prix
    quantity_effect DECIMAL(15,4), -- Effet quantité
    mix_effect DECIMAL(15,4), -- Effet mix
    exchange_rate_effect DECIMAL(15,4), -- Effet taux de change
    
    -- Analyse
    analysis TEXT,
    recommendations TEXT,
    
    -- Validation
    validated_by UUID REFERENCES users(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_val_var_period ON valuation_variations(period_start, period_end);
CREATE INDEX idx_val_var_entity ON valuation_variations(entity_id);
CREATE INDEX idx_val_var_product ON valuation_variations(product_id);
CREATE INDEX idx_val_var_category ON valuation_variations(product_category_id);

-- Table des causes d'écarts
CREATE TABLE variation_causes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    valuation_variation_id UUID NOT NULL REFERENCES valuation_variations(id) ON DELETE CASCADE,
    
    cause_type VARCHAR(50) NOT NULL, -- 'purchase_price_change', 'exchange_rate', 'supplier_change', 'promotion', 'error'
    cause_description TEXT NOT NULL,
    
    -- Impact
    impact_amount DECIMAL(15,4),
    impact_percentage DECIMAL(5,2),
    
    -- Événement associé
    source_type VARCHAR(30),
    source_id UUID,
    source_reference VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_var_causes_variation ON variation_causes(valuation_variation_id);



CREATE TABLE margin_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Période
    analysis_date DATE NOT NULL,
    period_type VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Périmètre
    entity_id UUID NOT NULL REFERENCES entities(id),
    site_id UUID REFERENCES sites(id),
    department_id UUID REFERENCES departments(id),
    
    -- Produit
    product_id UUID REFERENCES products(id),
    product_category_id UUID REFERENCES product_categories(id),
    
    -- Client
    customer_id UUID REFERENCES customers(id),
    customer_segment_id UUID,
    
    -- Ventes
    sales_quantity DECIMAL(15,3),
    sales_value DECIMAL(15,4) NOT NULL,
    sales_currency CHAR(3) NOT NULL REFERENCES currencies(code),
    
    -- Coûts
    cost_of_goods_sold DECIMAL(15,4) NOT NULL, -- Coût des marchandises vendues
    cost_currency CHAR(3) REFERENCES currencies(code),
    
    -- Marges
    gross_margin DECIMAL(15,4) GENERATED ALWAYS AS (sales_value - cost_of_goods_sold) STORED,
    gross_margin_percentage DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN sales_value > 0 THEN (sales_value - cost_of_goods_sold) * 100.0 / sales_value ELSE 0 END) STORED,
    
    -- Autres coûts
    shipping_cost DECIMAL(15,4),
    discount_amount DECIMAL(15,4),
    commission_amount DECIMAL(15,4),
    
    -- Marge nette
    net_margin DECIMAL(15,4) GENERATED ALWAYS AS 
        (gross_margin - COALESCE(shipping_cost,0) - COALESCE(discount_amount,0) - COALESCE(commission_amount,0)) STORED,
    net_margin_percentage DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN sales_value > 0 THEN net_margin * 100.0 / sales_value ELSE 0 END) STORED,
    
    -- Comparaison
    target_margin DECIMAL(5,2),
    margin_vs_target DECIMAL(5,2) GENERATED ALWAYS AS (gross_margin_percentage - target_margin) STORED,
    
    -- Analyse
    analysis_notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_margin_period ON margin_analyses(period_start, period_end);
CREATE INDEX idx_margin_entity ON margin_analyses(entity_id);
CREATE INDEX idx_margin_product ON margin_analyses(product_id);
CREATE INDEX idx_margin_category ON margin_analyses(product_category_id);
CREATE INDEX idx_margin_customer ON margin_analyses(customer_id);

-- Vue synthétique des marges
CREATE VIEW margin_dashboard AS
SELECT 
    period_start,
    period_end,
    entity_id,
    product_category_id,
    SUM(sales_value) as total_sales,
    SUM(cost_of_goods_sold) as total_cogs,
    SUM(gross_margin) as total_margin,
    AVG(gross_margin_percentage) as avg_margin_percentage
FROM margin_analyses
GROUP BY period_start, period_end, entity_id, product_category_id;




CREATE TABLE accounting_journals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Code journal
    journal_code VARCHAR(10) NOT NULL UNIQUE,
    journal_name VARCHAR(255) NOT NULL,
    journal_type VARCHAR(30) NOT NULL, -- 'sales', 'purchases', 'bank', 'cash', 'general', 'inventory'
    
    -- Entité
    entity_id UUID NOT NULL REFERENCES entities(id),
    
    -- Période en cours
    current_period DATE,
    
    -- Numérotation
    last_entry_number INTEGER DEFAULT 0,
    entry_number_prefix VARCHAR(10),
    entry_number_suffix VARCHAR(10),
    
    -- Configuration
    is_auto_reverse BOOLEAN DEFAULT FALSE, -- Auto inversion
    requires_approval BOOLEAN DEFAULT FALSE,
    
    -- Comptes par défaut
    default_debit_account VARCHAR(20),
    default_credit_account VARCHAR(20),
    
    -- Statut
    is_active BOOLEAN DEFAULT TRUE,
    is_locked BOOLEAN DEFAULT FALSE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Insertion des journaux standards
INSERT INTO accounting_journals (journal_code, journal_name, journal_type, entity_id) 
SELECT 'VTE', 'Journal des Ventes', 'sales', id FROM entities;

INSERT INTO accounting_journals (journal_code, journal_name, journal_type, entity_id) 
SELECT 'ACH', 'Journal des Achats', 'purchases', id FROM entities;

INSERT INTO accounting_journals (journal_code, journal_name, journal_type, entity_id) 
SELECT 'BQ', 'Journal de Banque', 'bank', id FROM entities;

INSERT INTO accounting_journals (journal_code, journal_name, journal_type, entity_id) 
SELECT 'OD', 'Journal des Opérations Diverses', 'general', id FROM entities;

INSERT INTO accounting_journals (journal_code, journal_name, journal_type, entity_id) 
SELECT 'STK', 'Journal des Stocks', 'inventory', id FROM entities;




CREATE TABLE accounting_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numéro unique
    entry_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Journal
    journal_id UUID NOT NULL REFERENCES accounting_journals(id),
    
    -- Dates
    entry_date DATE NOT NULL,
    value_date DATE NOT NULL, -- Date de valeur
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Période comptable
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL,
    
    -- Entité
    entity_id UUID NOT NULL REFERENCES entities(id),
    
    -- Référence
    reference VARCHAR(100), -- Référence externe
    description TEXT NOT NULL,
    
    -- Documents source
    source_type VARCHAR(30), -- 'customer_invoice', 'supplier_invoice', 'payment', 'credit_note', 'inventory_adjustment'
    source_id UUID,
    source_reference VARCHAR(100),
    
    -- Montant
    total_debit DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_credit DECIMAL(15,2) NOT NULL DEFAULT 0,
    is_balanced BOOLEAN GENERATED ALWAYS AS (total_debit = total_credit) STORED,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    
    -- Taux de change
    exchange_rate DECIMAL(15,6) DEFAULT 1,
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'posted', 'approved', 'reversed', 'cancelled'
    
    -- Validation
    posted_by UUID REFERENCES users(id),
    posted_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Contre-passation
    reversed_by UUID REFERENCES users(id),
    reversed_at TIMESTAMP WITH TIME ZONE,
    reverse_reason TEXT,
    original_entry_id UUID REFERENCES accounting_entries(id),
    
    -- Audit
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Lignes d'écriture comptable
CREATE TABLE accounting_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    accounting_entry_id UUID NOT NULL REFERENCES accounting_entries(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    
    -- Compte comptable
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(255),
    
    -- Sens
    debit DECIMAL(15,2) DEFAULT 0,
    credit DECIMAL(15,2) DEFAULT 0,
    
    -- Libellé
    label TEXT NOT NULL,
    
    -- Analytique
    analytical_code VARCHAR(50), -- Code analytique
    department_id UUID REFERENCES departments(id),
    project_code VARCHAR(50),
    
    -- Pièce justificative
    supporting_document TEXT,
    
    -- Taxes
    tax_id UUID REFERENCES taxes(id),
    tax_base DECIMAL(15,2),
    tax_amount DECIMAL(15,2),
    
    -- Échéance
    due_date DATE,
    
    -- Lettrage
    reconciliation_status VARCHAR(20) DEFAULT 'unreconciled', -- 'unreconciled', 'partial', 'reconciled'
    reconciliation_id UUID, -- ID de lettrage
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    CONSTRAINT check_debit_credit CHECK (debit >= 0 AND credit >= 0),
    CONSTRAINT check_debit_xor_credit CHECK ((debit > 0 AND credit = 0) OR (credit > 0 AND debit = 0))
);

-- Index
CREATE INDEX idx_acc_entries_number ON accounting_entries(entry_number);
CREATE INDEX idx_acc_entries_journal ON accounting_entries(journal_id);
CREATE INDEX idx_acc_entries_date ON accounting_entries(entry_date);
CREATE INDEX idx_acc_entries_period ON accounting_entries(period_year, period_month);
CREATE INDEX idx_acc_entries_source ON accounting_entries(source_type, source_id);
CREATE INDEX idx_acc_entries_status ON accounting_entries(status);
CREATE INDEX idx_acc_lines_entry ON accounting_entry_lines(accounting_entry_id);
CREATE INDEX idx_acc_lines_account ON accounting_entry_lines(account_code);
CREATE INDEX idx_acc_lines_reconciliation ON accounting_entry_lines(reconciliation_id);



CREATE TABLE reconciliation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Rapprochement
    reconciliation_number VARCHAR(50) NOT NULL UNIQUE,
    reconciliation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Type
    reconciliation_type VARCHAR(30) NOT NULL, -- 'bank', 'account', 'intercompany', 'inventory'
    
    -- Période
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Entité
    entity_id UUID NOT NULL REFERENCES entities(id),
    
    -- Compte
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(255),
    
    -- Soldes
    opening_balance DECIMAL(15,2) NOT NULL,
    closing_balance DECIMAL(15,2) NOT NULL,
    reconciled_balance DECIMAL(15,2) NOT NULL,
    difference DECIMAL(15,2) GENERATED ALWAYS AS (closing_balance - reconciled_balance) STORED,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(code),
    
    -- Statut
    status VARCHAR(30) NOT NULL DEFAULT 'in_progress', -- 'in_progress', 'completed', 'verified', 'discrepancy'
    
    -- Responsables
    reconciled_by UUID NOT NULL REFERENCES users(id),
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Écarts
    discrepancy_reason TEXT,
    adjustment_required BOOLEAN DEFAULT FALSE,
    adjustment_entry_id UUID REFERENCES accounting_entries(id),
    
    -- Pièces jointes
    supporting_documents JSONB,
    
    -- Notes
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Lignes de rapprochement
CREATE TABLE reconciliation_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reconciliation_log_id UUID NOT NULL REFERENCES reconciliation_logs(id) ON DELETE CASCADE,
    
    -- Ligne comptable
    accounting_entry_id UUID REFERENCES accounting_entries(id),
    accounting_entry_line_id UUID REFERENCES accounting_entry_lines(id),
    
    -- Date
    transaction_date DATE NOT NULL,
    value_date DATE,
    
    -- Référence
    reference VARCHAR(100),
    description TEXT,
    
    -- Montants
    amount DECIMAL(15,2) NOT NULL,
    reconciled_amount DECIMAL(15,2) DEFAULT 0,
    difference DECIMAL(15,2) GENERATED ALWAYS AS (amount - reconciled_amount) STORED,
    
    -- Statut
    is_reconciled BOOLEAN DEFAULT FALSE,
    reconciliation_date TIMESTAMP WITH TIME ZONE,
    
    -- Écart
    discrepancy_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index
CREATE INDEX idx_recon_logs_number ON reconciliation_logs(reconciliation_number);
CREATE INDEX idx_recon_logs_entity ON reconciliation_logs(entity_id);
CREATE INDEX idx_recon_logs_period ON reconciliation_logs(period_start, period_end);
CREATE INDEX idx_recon_logs_status ON reconciliation_logs(status);
CREATE INDEX idx_recon_lines_log ON reconciliation_lines(reconciliation_log_id);
CREATE INDEX idx_recon_lines_entry ON reconciliation_lines(accounting_entry_id, accounting_entry_line_id);

-- Table de rapprochement bancaire
CREATE TABLE bank_reconciliation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reconciliation_log_id UUID NOT NULL REFERENCES reconciliation_logs(id) ON DELETE CASCADE,
    
    -- Relevé bancaire
    bank_statement_id VARCHAR(100),
    bank_statement_date DATE,
    bank_account VARCHAR(50),
    
    -- Soldes bancaires
    bank_opening_balance DECIMAL(15,2) NOT NULL,
    bank_closing_balance DECIMAL(15,2) NOT NULL,
    bank_currency CHAR(3) REFERENCES currencies(code),
    
    -- Écritures non rapprochées
    outstanding_deposits DECIMAL(15,2) DEFAULT 0,
    outstanding_withdrawals DECIMAL(15,2) DEFAULT 0,
    
    -- Frais bancaires
    bank_fees DECIMAL(15,2) DEFAULT 0,
    bank_interest DECIMAL(15,2) DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);



