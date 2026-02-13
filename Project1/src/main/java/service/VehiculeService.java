package service;

import model.Vehicule;
import model.TypeCarburant;
import repository.VehiculeRepository;

import java.sql.SQLException;
import java.util.List;

public class VehiculeService {

    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();

    /**
     * Créer un véhicule avec validation métier
     */
    public Vehicule createVehicule(String reference, Integer nbPlace, String typeCarburant) 
            throws SQLException, IllegalArgumentException {

        // Validation 1 : Référence obligatoire
        if (reference == null || reference.trim().isEmpty()) {
            throw new IllegalArgumentException("La référence du véhicule est obligatoire");
        }

        // Validation 2 : Vérifier que la référence n'existe pas déjà
        Vehicule existing = vehiculeRepository.findByReference(reference.trim());
        if (existing != null) {
            throw new IllegalArgumentException("Un véhicule avec la référence '" + reference + "' existe déjà");
        }

        // Validation 3 : Nombre de places obligatoire et positif
        if (nbPlace == null || nbPlace <= 0) {
            throw new IllegalArgumentException("Le nombre de places doit être supérieur à 0");
        }

        // Validation 4 : Type de carburant obligatoire et valide
        if (typeCarburant == null || typeCarburant.trim().isEmpty()) {
            throw new IllegalArgumentException("Le type de carburant est obligatoire");
        }

        TypeCarburant carburant;
        try {
            carburant = TypeCarburant.valueOf(typeCarburant.trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Type de carburant invalide. Les valeurs acceptées sont : D, Es, H, El");
        }

        // Créer et sauvegarder le véhicule
        Vehicule vehicule = new Vehicule(reference.trim(), nbPlace, carburant);
        return vehiculeRepository.save(vehicule);
    }

    /**
     * Obtenir tous les véhicules
     */
    public List<Vehicule> getAllVehicules() throws SQLException {
        return vehiculeRepository.findAll();
    }

    /**
     * Obtenir un véhicule par ID
     */
    public Vehicule getVehiculeById(Long id) throws SQLException, IllegalArgumentException {
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("L'ID du véhicule n'est pas valide");
        }

        Vehicule vehicule = vehiculeRepository.findById(id);
        if (vehicule == null) {
            throw new IllegalArgumentException("Aucun véhicule trouvé avec l'ID " + id);
        }

        return vehicule;
    }

    /**
     * Mettre à jour un véhicule avec validation
     */
    public Vehicule updateVehicule(Long id, String reference, Integer nbPlace, String typeCarburant) 
            throws SQLException, IllegalArgumentException {

        // Validation 0 : ID doit être valide
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("L'ID du véhicule n'est pas valide");
        }

        // Vérifier que le véhicule existe
        Vehicule vehicule = vehiculeRepository.findById(id);
        if (vehicule == null) {
            throw new IllegalArgumentException("Aucun véhicule trouvé avec l'ID " + id);
        }

        // Validation 1 : Référence obligatoire
        if (reference == null || reference.trim().isEmpty()) {
            throw new IllegalArgumentException("La référence du véhicule est obligatoire");
        }

        // Validation 2 : Si la référence a changé, vérifier qu'elle n'existe pas ailleurs
        if (!vehicule.getReference().equals(reference.trim())) {
            Vehicule existing = vehiculeRepository.findByReference(reference.trim());
            if (existing != null) {
                throw new IllegalArgumentException("Un véhicule avec la référence '" + reference + "' existe déjà");
            }
        }

        // Validation 3 : Nombre de places obligatoire et positif
        if (nbPlace == null || nbPlace <= 0) {
            throw new IllegalArgumentException("Le nombre de places doit être supérieur à 0");
        }

        // Validation 4 : Type de carburant obligatoire et valide
        if (typeCarburant == null || typeCarburant.trim().isEmpty()) {
            throw new IllegalArgumentException("Le type de carburant est obligatoire");
        }

        TypeCarburant carburant;
        try {
            carburant = TypeCarburant.valueOf(typeCarburant.trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Type de carburant invalide. Les valeurs acceptées sont : D, Es, H, El");
        }

        // Mettre à jour le véhicule
        vehicule.setReference(reference.trim());
        vehicule.setNbPlace(nbPlace);
        vehicule.setTypeCarburant(carburant);

        return vehiculeRepository.update(vehicule);
    }

    /**
     * Supprimer un véhicule
     */
    public void deleteVehicule(Long id) throws SQLException, IllegalArgumentException {
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("L'ID du véhicule n'est pas valide");
        }

        Vehicule vehicule = vehiculeRepository.findById(id);
        if (vehicule == null) {
            throw new IllegalArgumentException("Aucun véhicule trouvé avec l'ID " + id);
        }

        vehiculeRepository.delete(id);
    }
}
