package model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Distance {
    private Long id;
    private Lieu fromLieu;
    private Lieu toLieu;
    private BigDecimal kmDistance;
    private LocalDateTime createdAt;

    public Distance() {}

    public Distance(Lieu fromLieu, Lieu toLieu, BigDecimal kmDistance) {
        this.fromLieu = fromLieu;
        this.toLieu = toLieu;
        this.kmDistance = kmDistance;
    }

    public Distance(Long id, Lieu fromLieu, Lieu toLieu, BigDecimal kmDistance, LocalDateTime createdAt) {
        this.id = id;
        this.fromLieu = fromLieu;
        this.toLieu = toLieu;
        this.kmDistance = kmDistance;
        this.createdAt = createdAt;
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Lieu getFromLieu() {
        return fromLieu;
    }

    public void setFromLieu(Lieu fromLieu) {
        this.fromLieu = fromLieu;
    }

    public Lieu getToLieu() {
        return toLieu;
    }

    public void setToLieu(Lieu toLieu) {
        this.toLieu = toLieu;
    }

    public BigDecimal getKmDistance() {
        return kmDistance;
    }

    public void setKmDistance(BigDecimal kmDistance) {
        this.kmDistance = kmDistance;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Distance{" +
                "id=" + id +
                ", fromLieu=" + fromLieu +
                ", toLieu=" + toLieu +
                ", kmDistance=" + kmDistance +
                ", createdAt=" + createdAt +
                '}';
    }
}
