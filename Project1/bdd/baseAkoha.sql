

-- Atody 1 lasa lot vao2 
-- soit atody amidy , soit atody lasa lot vao2 


-- manome sakafo 1g / tete / jour
-- recencer atody na lot x 
-- mijery situation am date iray (situation selon date x) anaty lot x , nbr poulet , achat , sakafo (lany sakony reto zay ) , maty (par lot) , poids moyen poulet , prix de vente , nbr atody , prix atody , benefice , etc.
--  condition  si issue_transformation_id existe alors le prix d'achat est egal = 0
-- Tsisy rehefa foy ilay atody achat = 0 
-- nbr atody miena rehefa misy fohy ny atody 
-- atody avy amina lot , par pondeson isanandro dia par lot foana 
--- Affichage mamadika lot atody ho lasa akoha 
-- mampiditra atody fotsny am lot 1 fa ampina date fotsny 


create table race_poulet (
    id int primary key,
    name varchar(255) not null,  --- Berger Allemend, Leghorn, etc.
    poids_s0 decimal(10,2) not null, --- Poids en moyenne initial du poulet

    aliment_donne varchar(255) not null, --- Aliment donne au poulet => maizena, soja, etc.
    pu_sakafo_par_gramme decimal(10,2) not null, --- Prix de la nourriture par gramme

    pv_par_gramme decimal(10,2) not null, --- Prix de la nourriture par gramme
    pv_atody decimal(10,2) not null, --- Prix atody

    temps_incubation int not null, --- Temps d'incubation en jours
    description text
);

create table lot_poulet (
    id int primary key,
    code varchar(255) unique not null ,
    id_race int not null references race_poulet(id),
    age_semaines int not null, --- Age du poulet en semaine pour cette alimentation
    nombre_poulets int not null,
    date_entree_lot TIMESTAMP NOT NULL default CURRENT_TIMESTAMP, --- Date d'entrée du lot de poulet dans la ferme
    description text
);

---  Evolution du poids du poulet en fonction de son alimentation dans un intervalle de temps (semaine) donne 
--   Parametre de poids obtenue : poids du poulet a la fin de l'intervalle de temps (semaine) pour une alimentation donnee
CREATE TABLE alimentation (
    id int primary key,
    code varchar(255) unique not null ,
    id_race int not null references race_poulet(id),

    interval_min int not null, --- Intervalle de temps minimum (en semaine) pour cette alimentation
    interval_max int not null, --- Intervalle de temps maximum (en semaine) pour cette alimentation

    alimentation_donne decimal(10,2) not null, --- en gramme /tete Poids de la nourriture donnee au poulet pour cette semaine

    poids_obtenue decimal(10,2) not null, --- Poids obtenu du poulet pour cette semaine
    date_entree_lot TIMESTAMP NOT NULL default CURRENT_TIMESTAMP, --- Date d'entrée du lot de poulet dans l'alimentation
    description text
);

-- s0 r1 - 150
-- s1 r1 - 60 poids + skf 30g 
-- s2 r1 - 40 poids + skf 60g
-- 240

 
create table type_produit  (
    id int primary key,
    code varchar(255) unique not null , -- AKOHA / ATODY
    name varchar(255) not null, --- Type de MATIERE PREMIERE HOE atody , akoha 
    description text
);
 
create table type_transaction (
    id int primary key,
    code varchar(255) unique not null , -- IN / OUT
    name varchar(255) not null, --- Type de transaction ( entre  , sortie )
    description text
);

create table type_mouvement  (
    id int primary key,
    name varchar(255) not null, --- Type de transaction (  Cassure , mort , maladie , vol , lamokany , transformation  , transformationPoussin, vente  etc.)
    type_produit_id int REFERENCES type_produit(id) ,  -- AKOHA / ATODY  
    id_type_transaction int not null references type_transaction(id),
    description text
);

-- compted , not_compted 
create table status_mouvement  (
    id int primary key,
    status_name varchar(255) not null,  
    description text
);

CREATE table mouvement_produit (
    id int primary key,
    id_lot int not null references lot_poulet(id),     -- LOT-001
    type_produit_id int REFERENCES type_produit(id) ,  -- AKOHA / ATODY  
    id_type_mouvement int not null references type_mouvement(id),
    nombre_atody int not null, --- Nombre d'atody produits par le lot de poulet
    date_mouvement TIMESTAMP NOT NULL default CURRENT_TIMESTAMP, --- Date de mvt des atody
    description text
);

CREATE table transformation_atody  (
    id int primary key,
    id_mouvement int REFERENCES mouvement_atody_lot(id) , 
    nombre_atody int not null, --- Nombre d'atody  incube
    date_mouvement TIMESTAMP NOT NULL default CURRENT_TIMESTAMP, --- Date debut incubation
    date_mouvement TIMESTAMP NOT NULL default CURRENT_TIMESTAMP, --- Date fin incubation 
    description text
);
---  generer mouvment 
CREATE table detail_transformation_atody  (
    id int primary key,
    id_transormation int REFERENCES transformation_atody(id) ,  
    id_type_mouvement int not null references type_mouvement(id), --- perte lamokany ve sa transformationPoussin
    nombre_atody int not null, --- Nombre d'atody produits par le lot de poulet
    date_transformation TIMESTAMP NOT NULL default CURRENT_TIMESTAMP  --- Date fin incubation 
);

   
alter table  lot_poulet  add column  issue_id int REFERENCES transformation_atody(id)    ; 










CREATE table atody_lot (
    id int primary key,
    id_lot int not null references lot_poulet(id),
    nombre_atody int not null, --- Nombre d'atody produits par le lot de poulet
    prix_atody decimal(10,2) not null, --- Prix de vente des atody
    date_production TIMESTAMP NOT NULL default CURRENT_TIMESTAMP, --- Date de production des atody
    description text
);
