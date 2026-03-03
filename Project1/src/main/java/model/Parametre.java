package model;

import java.time.LocalDateTime;

/**
 * Paramètres de configuration pour le calcul des trajets.
 * Clés attendues :
 *   - "vitesse_moyenne" : vitesse moyenne en km/h (ex: "30")
 *   - "temps_attente"   : temps d'attente en minutes (ex: "30")
 */
public class Parametre {
    private Long id;
    private String key;
    private String value;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Parametre() {}

    public Parametre(String key, String value) {
        this.key = key;
        this.value = value;
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    /**
     * Retourne la valeur en double (utile pour vitesse_moyenne et temps_attente).
     */
    public double getValueAsDouble() {
        return Double.parseDouble(value);
    }
}
