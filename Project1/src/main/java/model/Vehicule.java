package model;

import java.time.LocalTime;

/**
 * Modèle représentant un véhicule de la flotte.
 *  sprint 7 : Ajout de l'heure de disponibilité quotidienne.
 */
public class Vehicule {
    private Long id;
    private String reference;
    private Integer nbPlace;
    private TypeCarburant typeCarburant;

    //  sprint 7 : Heure à partir de laquelle le véhicule est disponible chaque jour
    private LocalTime heureDisponibleDebut;

    public Vehicule() {}

    public Vehicule(String reference, Integer nbPlace, TypeCarburant typeCarburant) {
        this.reference = reference;
        this.nbPlace = nbPlace;
        this.typeCarburant = typeCarburant;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getReference() {
        return reference;
    }

    public void setReference(String reference) {
        this.reference = reference;
    }

    public Integer getNbPlace() {
        return nbPlace;
    }

    public void setNbPlace(Integer nbPlace) {
        this.nbPlace = nbPlace;
    }

    public TypeCarburant getTypeCarburant() {
        return typeCarburant;
    }

    public void setTypeCarburant(TypeCarburant typeCarburant) {
        this.typeCarburant = typeCarburant;
    }

    //  sprint 7 : Getters/Setters pour heure de disponibilité
    public LocalTime getHeureDisponibleDebut() {
        return heureDisponibleDebut;
    }

    public void setHeureDisponibleDebut(LocalTime heureDisponibleDebut) {
        this.heureDisponibleDebut = heureDisponibleDebut;
    }

    /**
     *  sprint 7 : Vérifie si le véhicule est disponible à une heure donnée.
     * @param heureDemandee L'heure à laquelle on veut utiliser le véhicule
     * @return true si le véhicule est disponible (heure >= heureDisponibleDebut)
     */
    public boolean estDisponibleAHeure(LocalTime heureDemandee) {
        if (heureDisponibleDebut == null) {
            return true; // Pas de restriction = toujours disponible
        }
        if (heureDemandee == null) {
            return true;
        }
        return !heureDemandee.isBefore(heureDisponibleDebut);
    }
}
