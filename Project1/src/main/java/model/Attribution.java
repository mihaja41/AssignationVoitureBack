package model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Représente une attribution de véhicule à une ou plusieurs réservations regroupées (résultat du planning).
 *
 * Sprint 7 : Support de la division des passagers d'une même réservation entre plusieurs véhicules.
 *   Une réservation peut être DIVISÉE entre plusieurs véhicules.
 *   Chaque attribution indique combien de passagers sont transportés dans CE véhicule.
 *
 * Sprint 5/6 : Maintenant enregistré en base de données dans la table attribution.
 *
 * Sprint 4 – Regroupement :
 *   Un même véhicule peut transporter plusieurs réservations si :
 *     - même date et heure de départ
 *     - même lieu de départ (aéroport)
 *     - total passagers <= nb_places du véhicule
 *
 * Calcul des horaires :
 *   - dateHeureDepart = reservation.arrivalDate
 *   - duree = distanceAllerRetour / vitesseMoyenne
 *   - dateHeureRetour = dateHeureDepart + duree
 */
public class Attribution {
    private Long id;  // ID en base de données (Sprint 5/6)
    private Vehicule vehicule;
    private Reservation reservation;                         // réservation principale (backward compat)
    private List<Reservation> reservations = new ArrayList<>();  // toutes les réservations regroupées
    private LocalDateTime dateHeureDepart;
    private LocalDateTime dateHeureRetour;
    private BigDecimal distanceKm;            // distance aller simple (calculée depuis table distance)
    private BigDecimal distanceAllerRetourKm;  // distance aller-retour (= distanceKm × 2)
    private String statut;                     // "ASSIGNE"
    private Integer nbPassagersAssignes;       // Sprint 7 : nombre de passagers transportés dans CE véhicule

    private List<TrajetCar> detailTraject = new ArrayList<>(); 

    public Attribution() {}

    // ========== Regroupement ==========

    /**
     * Ajouter une réservation au regroupement de ce véhicule.
     */
    public void addReservation(Reservation r) {
        this.reservations.add(r);
    }

    /**
     * Retourne toutes les réservations regroupées dans ce véhicule.
     */
    public List<Reservation> getReservations() {
        return reservations;
    }

    public List<TrajetCar> getDetailTraject() {
        return detailTraject;
    }

    public void setDetailTraject(List<TrajetCar> detailTraject) {
        this.detailTraject = detailTraject;
    }
    

    /**
     * Nombre total de passagers dans ce véhicule.
     * Sprint 7 : Si nbPassagersAssignes est défini, le retourner (division support).
     * Sinon, retourner la somme de toutes les réservations regroupées.
     */
    public int getTotalPassengers() {
        if (nbPassagersAssignes != null) {
            return nbPassagersAssignes;
        }
        return reservations.stream().mapToInt(Reservation::getPassengerNbr).sum();
    }

    /**
     * Nombre de places restantes dans le véhicule après regroupement.
     */
    public int getPlacesRestantes() {
        if (vehicule == null) return 0;
        return vehicule.getNbPlace() - getTotalPassengers();
    }

    // ========== Getters & Setters ==========

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Vehicule getVehicule() {
        return vehicule;
    }

    public void setVehicule(Vehicule vehicule) {
        this.vehicule = vehicule;
    }

    /**
     * Retourne la réservation principale (la première assignée).
     * Conservé pour compatibilité avec l'existant.
     */
    public Reservation getReservation() {
        return reservation;
    }

    public void setReservation(Reservation reservation) {
        this.reservation = reservation;
    }

    public LocalDateTime getDateHeureDepart() {
        return dateHeureDepart;
    }

    public void setDateHeureDepart(LocalDateTime dateHeureDepart) {
        this.dateHeureDepart = dateHeureDepart;
    }

    public LocalDateTime getDateHeureRetour() {
        return dateHeureRetour;
    }

    public void setDateHeureRetour(LocalDateTime dateHeureRetour) {
        this.dateHeureRetour = dateHeureRetour;
    }

    public BigDecimal getDistanceKm() {
        return distanceKm;
    }

    public void setDistanceKm(BigDecimal distanceKm) {
        this.distanceKm = distanceKm;
    }

    public BigDecimal getDistanceAllerRetourKm() {
        return distanceAllerRetourKm;
    }

    public void setDistanceAllerRetourKm(BigDecimal distanceAllerRetourKm) {
        this.distanceAllerRetourKm = distanceAllerRetourKm;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }

    public Integer getNbPassagersAssignes() {
        return nbPassagersAssignes;
    }

    public void setNbPassagersAssignes(Integer nbPassagersAssignes) {
        this.nbPassagersAssignes = nbPassagersAssignes;
    }
}
