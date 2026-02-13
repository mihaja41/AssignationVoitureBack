package model;

public class Vehicule {
    private Long id;
    private String reference;
    private Integer nbPlace;
    private TypeCarburant typeCarburant;

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
}
