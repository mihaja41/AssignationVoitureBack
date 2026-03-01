package dto;

public class VehiculeDTO {
    private Long id;
    private String reference;
    private Integer nbPlace;
    private String typeCarburant;

    public VehiculeDTO() {}

    public VehiculeDTO(Long id, String reference, Integer nbPlace, String typeCarburant) {
        this.id = id;
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

    public String getTypeCarburant() {
        return typeCarburant;
    }

    public void setTypeCarburant(String typeCarburant) {
        this.typeCarburant = typeCarburant;
    }
}
