# SPRINT 8 - RESULTATS ATTENDUS PAR JOUR (CORRIGE)

## Logique Sprint 8 - RAPPEL

### DEUX TYPES DE FENÊTRES

#### 1. Fenêtre issue d'une ARRIVEE DE RESERVATION
- Créée à partir de la première réservation qui arrive
- Durée: temps_attente (30 min) après la première arrivée
- **Tri DÉCROISSANT** par nb_passagers
- Traiter d'abord la réservation avec le **MAXIMUM** de passagers
- Sélectionner le véhicule avec **CLOSEST FIT** (écart minimum)
- Remplir le véhicule avec **CLOSEST FIT**

**CALCUL DE L'HEURE DE DÉPART:**
```
Par défaut: heure_depart = MAX(arrival_date) dans la fenêtre

CAS: véhicule revenant DANS la fenêtre
  Si heure_retour >= MAX(arrival_date):
    → heure_depart = heure_retour
  Sinon:
    → heure_depart = MAX(arrival_date)

VALIDATION: Un départ est valide UNIQUEMENT si au moins une réservation est assignée
            Sinon, choisir un autre arrival_date valide
```

#### 2. Fenêtre issue d'un RETOUR VEHICULE (véhicule revient non plein)
- Créée quand un véhicule revient de course
- **CLOSEST FIT** directement sur les restes prioritaires et nouvelles arrivées
- Pas de tri DESC préalable

---

## Configuration

| Vehicule | Places | Disponibilite |
|----------|--------|---------------|
| v1 | 10 | Toujours |
| v2 | 10 | Toujours |
| v3 | 12 | Toujours |
| v4 | 8 | A partir de 10:30 |

**Parametres:**
- Vitesse moyenne: 50 km/h
- Temps d'attente (fenetre): 30 min
- CARLTON -> IVATO: 25km = 30min aller, 60min total
- COLBERT -> IVATO: 30km = 36min aller, 72min total

---

## JOUR 1: 27/03/2026 - REGROUPEMENT OPTIMAL

### Reservations

| ID | Client | Passagers | Heure arrivee |
|----|--------|-----------|---------------|
| 1 | J1_r1_9pass | 9 | 08:00 |
| 2 | J1_r2_5pass | 5 | 07:55 |
| 3 | J1_r3_3pass | 3 | 07:50 |
| 4 | J1_r4_2pass | 2 | 07:40 |

**Total: 19 passagers**

### Construction de la Fenetre

```
Première arrivée: r4 à 07:40
Fenêtre: [07:40 - 08:10] (temps_attente = 30 min)

Réservations dans la fenêtre:
- r4(2) arrive 07:40 ✓
- r3(3) arrive 07:50 ✓
- r2(5) arrive 07:55 ✓
- r1(9) arrive 08:00 ✓

MAX(arrival_date) = 08:00
heure_depart = 08:00 (aucun véhicule en cours à cette date)
```

### Logique Appliquee

```
FENÊTRE ARRIVEE RESERVATION [07:40 - 08:10]

ETAPE 0: Tri DÉCROISSANT par passagers
  Ordre de traitement: r1(9) > r2(5) > r3(3) > r4(2)

ETAPE 1: Traiter r1(9 passagers) - LE MAXIMUM
  Sélection véhicule (CLOSEST FIT parmi ceux qui peuvent contenir 9):
    - v1(10): |10-9| = 1 (MINIMUM, diesel prioritaire)
    - v2(10): |10-9| = 1
    - v3(12): |12-9| = 3
  -> v1 choisie (écart=1)
  -> v1 prend r1(9), reste 1 place

  Regroupement v1 (1 place restante) - CLOSEST FIT:
    - r4(2): |1-2| = 1 (MINIMUM)
    - r3(3): |1-3| = 2
    - r2(5): |1-5| = 4
  -> v1 prend 1 de r4 = 10 PLEIN
  -> v1 depart 08:00, retour 09:00

Tri des autres reservations non assigne aprse que la voiture a assigner est pleine 

Reservation restante 
r2(5)
r3(3)
r4(1) -> restant 

Vehicule disponible restant entre : [07:40 - 08:10]
v2(10)
v3(12)

ETAPE 2: Traiter r2(5 passagers) - PROCHAIN MAXIMUM
  Sélection véhicule:
    - v2(10): |10-5| = 5
    - v3(12): |12-5| = 7
  -> v2 choisie (écart=5)
  -> v2 prend r2(5), reste 5 places

  Regroupement v2 (5 places) - CLOSEST FIT:
    - r3(3): |5-3| = 2 (MINIMUM)
    - r4_reste(1): |5-1| = 4
  -> v2 prend r3(3), reste 2 places

  Regroupement v2 (2 places) - CLOSEST FIT:
    - r4_reste(1): |2-1| = 1
  -> v2 prend r4_reste(1), total = 9
  -> v2 depart 08:00, retour 09:00

ETAPE 3: Plus de réservations à traiter
  -> v3, v4 non utilisés
```

### Resultat Attendu Jour 1

| Vehicule | Reservations | Passagers | Depart | Retour |
|----------|--------------|-----------|--------|--------|
| v1 | r1(9) + r4(1) | 10 | 08:00 | 09:00 |
| v2 | r2(5) + r3(3) + r4(1) | 9 | 08:00 | 09:00 |
| v3 | - | 0 | - | - |
| v4 | - | 0 | - | - |

**Verification:** 9+1 + 5+3+1 = 19 passagers (tous assignes)

**Points cles:**
- r1 traitee EN PREMIER car 9 = maximum (tri DESC)
- r4 choisie pour regroupement car écart=1 (CLOSEST FIT)

-------------------------------------------------------------

Reste vehicule :
v3(12)
v4(8) 

Reste reservation :
aucun



---

## JOUR 2: 28/03/2026 - DIVISION OPTIMALE

### Reservations

| ID | Client | Passagers | Heure arrivee |
|----|--------|-----------|---------------|
| 5 | J2_r1_20pass | 20 | 09:00 |

### Logique DIVISION

```
09:00 - r1(20 pass) arrive:

ETAPE 1: Une seule réservation, pas de tri nécessaire
  Sélection véhicule (CLOSEST FIT parmi TOUS car aucun ne peut contenir 20):
    - v1(10): |10-20| = 10
    - v2(10): |10-20| = 10
    - v3(12): |12-20| = 8 (MINIMUM)
  -> v3 choisie
  -> v3 prend 12 passagers, reste 8

ETAPE 2 (Division): 8 passagers restants
  Véhicules disponibles: v1, v2, v4(non dispo avant 10:30)
  CLOSEST FIT:
    - v1(10): |10-8| = 2 (MINIMUM, égalité avec v2)
    - v2(10): |10-8| = 2
  -> v1 choisie d'abord min > le moins de trajet ;nb de trajet realiser > (diesel prioritaire ou aléatoire)
  -> v1 prend 8 passagers
  -> TOUS assignés
```

### Resultat Attendu Jour 2

| Vehicule | Reservation | Passagers | Depart | Retour |
|----------|-------------|-----------|--------|--------|
| v3 | r1 (partie 1) | 12 | 09:00 | 10:00 |
| v1 | r1 (partie 2) | 8 | 09:00 | 10:00 |

**Verification:** 12 + 8 = 20 passagers (tous assignes)

**Points cles:**
- v3(12) choisie car écart=8 < écart v1/v2=10 (CLOSEST FIT pour division)

---

## JOUR 3: 29/03/2026 - RETOUR VEHICULE + FENETRE D'ATTENTE

### Reservations

| ID | Client | Passagers | Heure arrivee | Note |
|----|--------|-----------|---------------|------|
| 6 | J3_r1_10pass_MATIN | 10 | 07:00 | |
| 7 | J3_r2_10pass_MATIN | 10 | 07:00 | |
| 8 | J3_r3_12pass_MATIN | 12 | 07:00 | |
| 9 | J3_r4_9pass_RESTE | 9 | 07:30 | RESTE |
| 10 | J3_r5_5pass_RESTE | 5 | 07:45 | RESTE |
| 11 | J3_r6_7pass | 7 | 08:15 | Fenetre |
| 12 | J3_r7_8pass | 8 | 08:20 | Fenetre |

### Logique

```
FENÊTRE 1 [07:00 - 07:30]

Tri DESC: r3(12) > r1(10) = r2(10) > r4(9) > r5(5)

ETAPE 1: Traiter r3(12) - MAXIMUM
  Véhicules: v1(10), v2(10), v3(12), v4(non dispo)
  Seul v3 peut contenir 12:
    - v3(12): |12-12| = 0 (PARFAIT)
  -> v3 prend r3(12) = PLEIN
  -> v3 depart 07:00, retour 08:00 (arrondi ~08:12 pour COLBERT)

ETAPE 2: Traiter r1(10) ou r2(10)
  Ici , comme pour ces 2 cas v1 et v2 qui ont les memes ecart, on va prendre le vehicule qui serait le plus proche si plusieurs c est alors on va respecter les criteres de selections de vehicule : moin de trajet si plusoeurs en les meme aussi > diesel > aleatoire
  CLOSEST FIT: v1(10) ou v2(10), écart=0
  -> v1 prend r1(10) = PLEIN
  -> v1 depart 07:00, retour 08:00

ETAPE 3: Traiter r2(10)
  -> v2 prend r2(10) = PLEIN
  -> v2 depart 07:00, retour 08:00

RESTES NON ASSIGNÉS: r4(9), r5(5)

#### ici de modification a faire comme r4 et r5 sont encore des reservations non assigne (pas les restes mais fraichement encore non assigne), on ne peut plus assigne r4 car il est arrivee dans a 7:30 et que la fenetre est entre [07:00 - 07:30], du coup a on va passer au prochaines arrivees de vehicule ou au prochaine reservation non assignee 
Du coup comme r5 arrive a 07:45 alors on va creer une fenetre issue de cette reservation 
    [07:45 - 08:15] -> Du coup il faut que nous traitons tous les reservatuibs non assignee avant ou entre ces  intervalles 
    Reservations :
        r4 (9) reservation non assignee avant fenetre (priorite) 
        r5 (5)
        r6 (7) 
    Vehicule dispo :
        v3 (12) 


*A commencer par reservation non assignee avant fenetre (si >= 2 alors les trier desc et commencer par max) 
r4 (9) -> v3(12) (seul vehicule dispo entre fenetre )
v3 (3) -> restant (a trouver une reservation a assigner) 
Reservation restant : Si plus aucune reservation non assignees avant fenetre, trouver d'autres reservations le plus proches de place restant au vehicule (s il y a egalite entre ecart, on cheche toujours a remplir le vehicule par exemple si le vehicule est 5 et il y a 6 passager et un autre 4 alors on prendra le 6)
r6 (7) -> |3-7|= 4
r5 (5) -> |3-5| = 2 -> le plus proche 

r5(seulement 3 assigne dans v3) a assigne dans v3 => PLEINE 
r5(2) -> restant non assigne
v3 parte a 07:45 


Reservation restant non assignee : 
-----------------------------
r5(2) -> restant non assigne

----------------------------------------------------------------------------------------------------------
A 08:00 , v1,v2,v3 retourne 

=> Nouvelles regles a corriger, pour chaque vehicule , a partir de son heure de disponibilite (soit heure_disponible_debut soit heure_retour),si le vehicule est rempli par des reservations directement au moment (date_heure) de son retour alors le vehicule partira a ce date_heure (attribution.date_depart = date_heure_retour ou date_disponible_debut du vehicule) et aucune fenetre de groupement n'est creer mais  si le vehicule n'est pas encore pleine apres assignation au meme moment de son date_heure de disponibilite alors une fenetre de groupement est creer (toujours creer la fenetre s'il existe des places restantes pour le vehicules), Durant cela, on traite les assignement  de la meme maniere que le traitement que l on fait pour les traitements entre les fenetre creer a partir d une reservation : 
    Trier reservations par ordre decroissante (prendre le max)
    Trouver le vehicule a l'assigner ou le nb de place est le plus proche de nombre de passager (si passager = 6 et v1 = 5 et v2 = 7 alors on prendra le 7)
    Si vehicule.nb_place < reservation1.nb_passager 
        Trouver de vehicule a assigner le reste de reservation1 non assigne car notre but s'est d'assignees aux personnes de cette reservation de vehicules et ainsi de suite jusqu a ce que tout les reservation1 sont assigne ou le reste de reservation1 non assigne ne peut plus etre assigner a aucun vehicule (plus aucun vehicule dispo) 
    Si vehicule.nb_place > reservation1.nb_passager 
        Trouver des reservations a assigner dans cette vehicules ou la reservation.nb_passager le plus proche du reste de place de vehicule a assigner  
            Si vehicule.nb_place restant < reservation2.nb_passager 
            => on continue jusqu a ce que le vehicule soit rempli ou plus aucune reservation ne peut plus etre assigne aux vehicule 
            Si vehicule.nb_place restant > reservation2.nb_passager 
            => on s'arrete la puis lors du suivant  traitement de prochain reservation , la reservation2 apparaitra aussi mais avec le nb de passager restant => En gros , elle apparaisse egalement aussi dans la liste des reservations a faire une trie desc s'il en reste encore 
=> Rappel : Si un groupement de fenetre a ete necessaire  , les traitements des assignations des reservations restent les memes que les fenetre issue de reservation, Il parte tous a la meme date_heure de depart ou la date heure de depart de tous les vehicules contenant des reservations assigne serait la derniere date d'arrivee d' une reservation qui a ete assigne a un vehicule (et non le max(Arrival_date ) alors que les reservations dedans ne sont pas assigne a un vehicule ) ou cette date de depart prendra la date_heure de retour d un vehicule, si un vehicule retournee entre cette fenetre a ete assigne a de reservations et que date_heure retour du vehicule est > au max(arrival_date) 
Du coup tous les vehicules partirons a ce meme date_heure de depart



Dans notre test de simulation , v1(10) Diesel,v2(10) Essence,v3(12) Diesel retourne a 08:00 
=> existe t il des reservations non assignees avant ? 
=> r5(2 restant ) => Trouver le vehicule le plus proche nombre de place 
=> v1 = |10 - 2| = 8 
=> v2 = |10 - 2| = 8
=> en cas d'egalite (faire le tri comme d'habitude :moins de trajet > diesel > aleatoire) => supposons que d'apres les calculs des trajet faits, les 2 vehicule ont aussi fait les memes nombre de trajet alors on prendra celui en diesel => v1
=> r5 assigne a v1 -> v1 (8) place restant 
=> comme on vient de traiter la reservation suite a un retour de vehicule et on constate que le vehicule n'est pas immediatement pleine (il existe des place restant ), alors une fenetre de regroupemeent est creer a partir de son date_retour 
    Donc une petite rappel, apres le retour ou la disponibilite d'un ou plusieurs vehicules a une date_heure donnee , on verifie toujours s'il existe des reservations non assignees avant cette date_heure de retour 
        S'il existe 
            Trier d'abord les reservations non assigne par nb_place(restant ou non assignee) par ordre descendant 
            On prendra le max 
            Trouver parmi les vehicule retourner avec la meme date_heure 
            celui qui a le nombre de place le plus proche pour assignee cette reservation 
            Si reservation.nb_place >= vehicule.nb_place 
                Alors la vehicule parte immediatement a son date_heure de retour ou date_disponibilite_debut et ne creer aucune fenetre de regroupement 
            Si reservation.nb_place < vehicule.nb_place 
                S'il existe d'autres reservations non assignee avant cette date heure de retour ou de debut de disponibilite de vehicule alors  on continuerais a trouver des reesrvations le plus proche de nombre de place restant pour le vehicule tant qu'il n'est pas plein 
                    Si il n'y a plus de reservation non assignee avant sa disponiblite ou retour et que le vehicule n'est pas encore plein alors on creer une fenetre de regroupement a partir de son date_heure de disponibilite ou de retour 
                    Du coup si a l'interieur de cette fenetre des vehicules ont ete redisponible (retournee ou commence a etre dispo) il serais tous traite comme dans le traitement dans la fenetre de regroupement creer a partir du date heure de redisponibilite du vehicule 
                        Commencer par remplir le reste de la place de vehicule qui n'a pas encore ete pleine et qui a provoque la creation de cette fenetre de groupement 
                            Puis apres si elle est pleine , c'est a dire  vehicule.place_restant <= reservation.nb_passager 
                            Alors Si vehicule.place_restant < reservation3.nb_passager (il reste des division de passager non assignees pour la reservation3 ) 
                            alors on refait le tri par ordre decroissante des reservations non encore assignee avec les restantes aussi (le reste de reservation3 est aussi trie la dedans) 
                            Trouver les max et lui trouver le vehicule le plus proche de son nb_passager et ainsi de suite 

                    Si le vehicule est pleine alors il parte a ce date_heure_retour ou date_heure_disponible_debut 
            Si reservation.nb_place >= vehicule.nb_place 
                Alors le vehicule parte sans provoquer une fenetre de regroupement



entre [08:00 - 08:30]
=> Trouver des reservations pour pouvoir remplir v1 mais avec le nb_passager le plus proche , rappel toujours,reste non assignee avant fenetre priorite  mais comme il n ' y a plus de non assignee avant fenetre alors nous attaquerons pour ceux qui sont dans la fenetre 
    (arrivee en 08:15) r8 |8-8| = 0 => le plus proche 
    (arrivee en 08:20) r6 |8-7| = 1 
r8 assigne a v1 (pleine) 
Vehicule dispo restant entre ces intervalles
    v2 (10)
    v3 (12)
=> Trouver les autres reservations non encore assigne 
=> Trier par ordre decroissante 
il ne reste plus que r6(7) entre cette intervalle alors , trouvons les vehicules le plus proche de cela 
=> r6 assigne a v2 
v2 (3 restant) -> Trouver d'autres reservations non assignees pour remplir cela 
Comme il n'y a plus de reservations, donc du coup 
v1 et v2 parte a 08:20 
v3 ne parte pas car elle n'a pas ete assigne a au moins une reservation 
Mais cependant pour les prochain reservation , v3 serais dans la liste des vehicules dispo 

Supposons qu'a 10:30 une reservation r7 avec 8 passager est arrivee 
Je suppose qu aucun des vehicules (v1 et v2) n'ont pas encore pu retourner a l aeroport (juste pour hypothese mais en realite la date_heure_retour serais calculer a partir des distances, vitesse moyenne comme deja present dans les fonctions du projet) 
Du coup ici , nous avons 2 cas double, on a v4 qui commence a etre disponible en debut de cette heure(mais cela est aussi valable pour le cas ou par exemple la date_heure retour de v4 est aussi a ce moment, soit heure debut disponible soit date_heure_retour) et on a aussi une reservation qui arrive a r7 
Que va t on faire ? => on va d'abord chercher si avant la fenetre, des reservations sont encore non assignees
[
    S il existe alors on trouve le max de personne d eux et a l'assignee aux vehicules avec le plus proche nombre de place, cas 1 : si c'est le vehicule qui est retourne au debut de fenetre est celui qui convient et que le vehicule est directement remplit par la reservation alors il parte de suite, si c'est l'autre vehicule v3 toujours dispo precedemment alors on va traiter la reservation arrivee comme le traitement des reservations arrivee a une date_heure donnees existant(creer la fenetre de regroupement a partir de cette reservation , etc)
]
Cas particuliere
Comme les 2 sont arrivees en meme temps et que aucune reservation non assigne avant la fenetre n a ete trouvee , lequel choisir de faire un traitement en premier?
= >Le vehicule retourne qui pourait soit partir directement a ce meme temps soit generer une fenetre de regroupement ou 
=> La reservation sur quoi nous devons toujours creer une fenetre de regroupement a partir de cela
Ici, aucun reservation non assignee avant 10:30 n'est trouvee, alors comme nous avons aussi v4 arrivee au meme moment, que la reservation, Nous choisissant d'abord parmis les vehicule dispo , celle qui est le plus proche de cette reservation arrivee au terme de nombre de place , ici v4 = 8 place et r7 = 8 passager alors , le vehicule est rempli et parte a 10h:30 
Si v4 = 13 alors r7 va choisir v3 (12 places) => du coup la on choisi de traiter la reservation a partir d'une fenetre de regroupement creer par cette reservation (ou v4 est aussi une voiture candidat dans cette fenetre) => donc [10:30 - 11:00] 
[
    en gros, le traitement reste toujours les memes mais il  nous faudrait juste verifier si le vehicule est rempli par les reservations <= a son date_heure_retour ou date_heure_debut_disponibilite 
    Si oui alors il parte directement sans declancher une fenetre de regroupement
]
il reste 4 places pour v3 apres assignation 
Chercher s il y a d autres reservations arrive entre cette fenetre pour remplir le vehicules
Reste des reservations entre cette fenetre 
r8 : 7 passager 10:40
r10 : 5 passager 10:41
Vehicule v9 (8 place) dispo a 10:42

donc r10 choisi pour remplir le reste de v3, 
v3 pleine, r10 (1 ) restant 
Puis retrier les reservations 
r8(7)
r10(1)

Vehicule dispo : 
v4 (13 places) 
v9 (8 place)

Trouver un vehicule a r8 ,=> v9 en respectant les regles de selections 
v9 (1 restant ) 
Trouver reservation le plus proche 
r10 
Du coup v9 rempli 
Trouver d autres reservation restant => plus aucun 
donc les vehicule, v3 et v9 partent a 10:42 (car c est l heure de retour de v9 > a max(arrival date des reervation : 10:41) et dans l intervalle du fenetre) 
v4 ne partent pas car il n a pas eu de reservation a assigne donc il serais toujours dispo pour les prochaines reservations 

