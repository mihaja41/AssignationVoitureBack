package model;

/**
 * Représente une portion de réservation reportée à la fenêtre suivante.
 * Sprint 7 - CAS 3 : Passagers non assignables
 *
 * Quand une réservation est partiellement assignée (X passagers dans des véhicules,
 * Y passagers restants car pas de véhicules disponibles), on crée une réservation
 * partielle pour tracker les passagers restants.
 *
 * Exemple :
 *   - Réservation R1 : 12 passagers
 *   - Véhicules disponibles : V1(5) + V2(5) = 10 places total
 *   - Assignés : 10 passagers
 *   - Restants : 2 passagers → ReservationPartielle(R1, 2)
 */
public class ReservationPartielle {
    private Reservation reservationOrigine;
    private int passagersRestants;           // Nombre de passagers NON assignés
    private int passagersTotalOrigine;       // Nombre total dans la réservation d'origine

    /**
     * Constructeur
     * @param reservation Réservation d'origine
     * @param passagersRestants Nombre de passagers non assignés
     */
    public ReservationPartielle(Reservation reservation, int passagersRestants) {
        if (reservation == null) {
            throw new IllegalArgumentException("Réservation d'origine ne peut pas être null");
        }
        if (passagersRestants < 0) {
            throw new IllegalArgumentException("Nombre de passagers restants ne peut pas être négatif");
        }
        if (passagersRestants > reservation.getPassengerNbr()) {
            throw new IllegalArgumentException(
                "Passagers restants (" + passagersRestants + ") > total (" + reservation.getPassengerNbr() + ")");
        }

        this.reservationOrigine = reservation;
        this.passagersRestants = passagersRestants;
        this.passagersTotalOrigine = reservation.getPassengerNbr();
    }

    // ========== Getters & Setters ==========

    public Reservation getReservationOrigine() {
        return reservationOrigine;
    }

    public int getPassagersRestants() {
        return passagersRestants;
    }

    public int getPassagersTotalOrigine() {
        return passagersTotalOrigine;
    }

    /**
     * Retourne le nombre de passagers DÉJÀ assignés dans les fenêtres précédentes.
     */
    public int getPassagersAssignes() {
        return passagersTotalOrigine - passagersRestants;
    }

    /**
     * Vérifie si la réservation est partiellement assignée.
     * @return true si 0 < passagersRestants < total
     */
    public boolean estPartiellementAssignee() {
        return passagersRestants > 0 && passagersRestants < passagersTotalOrigine;
    }

    /**
     * Vérifie si TOUS les passagers sont reportés (aucun assigné).
     * @return true si passagersRestants == total
     */
    public boolean estEntierementReportee() {
        return passagersRestants == passagersTotalOrigine;
    }

    // Compteur pour générer des IDs temporaires uniques (négatifs pour les distinguer)
    private static long tempIdCounter = -1;

    /**
     * Crée une nouvelle Réservation basée sur cette partielle.
     * Utile pour la fenêtre suivante : on accepte les passagers restants
     * comme une nouvelle réservation avec même Date, Lieu, etc.
     *
     * Note: Un ID temporaire négatif est assigné pour éviter les NullPointerException
     * lors des comparaisons d'ID dans le service de planning.
     *
     * @return Nouvelle réservation avec passagersRestants passagers
     */
    public Reservation creerReservationPourFenetresuivante() {
        Reservation res = new Reservation();
        // Assigner un ID temporaire négatif unique pour éviter les NPE
        res.setId(tempIdCounter--);
        res.setCustomerId(reservationOrigine.getCustomerId());
        res.setPassengerNbr(passagersRestants);
        res.setArrivalDate(reservationOrigine.getArrivalDate());
        res.setLieuDepart(reservationOrigine.getLieuDepart());
        res.setLieuDestination(reservationOrigine.getLieuDestination());
        return res;
    }

    @Override
    public String toString() {
        return "ReservationPartielle{" +
                "reservationId=" + reservationOrigine.getId() +
                ", passagersAssignes=" + getPassagersAssignes() +
                ", passagersRestants=" + passagersRestants +
                ", total=" + passagersTotalOrigine +
                '}';
    }
}
