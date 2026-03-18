package model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Classe représentant une fenêtre de regroupement.
 * Sprint 5/6 - Developer 1 (ETU003255)
 *
 * Une fenêtre regroupe les réservations dont arrival_date est dans l'intervalle
 * [startTime, startTime + temps_attente]
 *
 * Toutes les réservations d'une même fenêtre partent à la même heure :
 * heureDepart = MAX(arrival_date) de la fenêtre
 */
public class FenetreRegroupement {

    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private List<Reservation> reservations;
    private LocalDateTime heureDepart;

    public FenetreRegroupement(LocalDateTime startTime, LocalDateTime endTime) {
        this.startTime = startTime;
        this.endTime = endTime;
        this.reservations = new ArrayList<>();
    }

    // ============== GETTERS / SETTERS ==============

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }

    public List<Reservation> getReservations() {
        return reservations;
    }

    public void setReservations(List<Reservation> reservations) {
        this.reservations = reservations;
    }

    public LocalDateTime getHeureDepart() {
        return heureDepart;
    }

    public void setHeureDepart(LocalDateTime heureDepart) {
        this.heureDepart = heureDepart;
    }

    // ============== MÉTHODES MÉTIER ==============

    /**
     * Ajoute une réservation à la fenêtre.
     */
    public void addReservation(Reservation reservation) {
        if (reservation != null) {
            this.reservations.add(reservation);
        }
    }

    /**
     * Ajoute plusieurs réservations à la fenêtre.
     */
    public void addAllReservations(List<Reservation> reservations) {
        if (reservations != null) {
            this.reservations.addAll(reservations);
        }
    }

    /**
     * Vérifie si une date est dans la fenêtre [startTime, endTime].
     *
     * @param date La date à vérifier
     * @return true si la date est dans l'intervalle
     */
    public boolean estDansFenetre(LocalDateTime date) {
        if (date == null) {
            return false;
        }
        return !date.isBefore(startTime) && !date.isAfter(endTime);
    }

    /**
     * Calcule l'heure de départ de la fenêtre.
     * L'heure de départ = MAX(arrival_date) des réservations de la fenêtre.
     *
     * @return L'heure de départ calculée
     */
    public LocalDateTime calculerHeureDepart() {
        if (reservations == null || reservations.isEmpty()) {
            return startTime;
        }
        return reservations.stream()
                .map(Reservation::getArrivalDate)
                .filter(d -> d != null)
                .max(LocalDateTime::compareTo)
                .orElse(startTime);
    }

    /**
     * Retourne les réservations triées par nombre de passagers décroissant.
     * Utilisé pour le regroupement optimal (les plus grandes réservations d'abord).
     *
     * @return Liste triée par passagers décroissant
     */
    public List<Reservation> getReservationsTrieesParPassagers() {
        return reservations.stream()
                .sorted(Comparator.comparingInt(Reservation::getPassengerNbr).reversed())
                .collect(Collectors.toList());
    }

    /**
     * Retourne le nombre total de réservations dans la fenêtre.
     */
    public int getNombreReservations() {
        return reservations.size();
    }

    /**
     * Retourne le nombre total de passagers dans la fenêtre.
     */
    public int getTotalPassagers() {
        return reservations.stream()
                .mapToInt(Reservation::getPassengerNbr)
                .sum();
    }

    /**
     * Vérifie si la fenêtre est vide (aucune réservation).
     */
    public boolean isEmpty() {
        return reservations == null || reservations.isEmpty();
    }

    @Override
    public String toString() {
        return "FenetreRegroupement{" +
                "startTime=" + startTime +
                ", endTime=" + endTime +
                ", nbReservations=" + getNombreReservations() +
                ", heureDepart=" + heureDepart +
                '}';
    }
}
