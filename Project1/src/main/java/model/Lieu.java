package model;

import java.time.LocalDateTime;

public class Lieu {
    private Long id;
    private String code;
    private String libelle;
    private LocalDateTime createdAt;

    public Lieu() {}

    public Lieu(String code, String libelle) {
        this.code = code;
        this.libelle = libelle;
    }

    public Lieu(Long id, String code, String libelle, LocalDateTime createdAt) {
        this.id = id;
        this.code = code;
        this.libelle = libelle;
        this.createdAt = createdAt;
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getLibelle() {
        return libelle;
    }

    public void setLibelle(String libelle) {
        this.libelle = libelle;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Lieu{" +
                "id=" + id +
                ", code='" + code + '\'' +
                ", libelle='" + libelle + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
}
