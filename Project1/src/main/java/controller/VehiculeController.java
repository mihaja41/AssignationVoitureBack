package controller;

import class_annotations.Controller;
import method_annotations.GetRouteMapping;
import method_annotations.Json;
import method_annotations.PostRouteMapping;
import method_annotations.RequestParam;
import service.VehiculeService;
import repository.VehiculeRepository;
import view.ModelView;
import model.Vehicule;
import dto.VehiculeDTO;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class VehiculeController {

    private final VehiculeService vehiculeService = new VehiculeService();
    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();

    /**
     * Afficher le formulaire d'ajout de véhicule (Back-office)
     */
    @GetRouteMapping(value = "/vehicules/form")
    public ModelView showForm() {
        ModelView mv = new ModelView("/vehicules/form.jsp");
        return mv;
    }

    /**
     * Traiter le formulaire d'ajout (Back-office)
     */
    @PostRouteMapping(value = "/vehicules/add")
    public ModelView addVehicule(
            @RequestParam("reference") String reference,
            @RequestParam("nbPlace") Integer nbPlace,
            @RequestParam("typeCarburant") String typeCarburant) {

        ModelView mv = new ModelView("/vehicules/form.jsp");

        try {
            Vehicule vehicule = vehiculeService.createVehicule(reference, nbPlace, typeCarburant);
            mv.setData("success", "Véhicule créé avec succès ! (ID: " + vehicule.getId() + ")");

        } catch (IllegalArgumentException e) {
            mv.setData("error", e.getMessage());
        } catch (Exception e) {
            mv.setData("error", "Erreur serveur : " + e.getMessage());
        }

        return mv;
    }

    /**
     * Afficher la liste des véhicules (Back-office)
     */
    @GetRouteMapping(value = "/vehicules/list")
    public ModelView listVehicules() throws Exception {
        ModelView mv = new ModelView("/vehicules/list.jsp");
        mv.setData("vehicules", vehiculeRepository.findAll());
        return mv;
    }

    /**
     * Afficher le formulaire de modification (Back-office)
     */
    @GetRouteMapping(value = "/vehicules/edit")
    public ModelView showEditForm(@RequestParam("id") Long id) throws Exception {
        ModelView mv = new ModelView("/vehicules/edit.jsp");

        try {
            Vehicule vehicule = vehiculeService.getVehiculeById(id);
            mv.setData("vehicule", vehicule);
        } catch (IllegalArgumentException e) {
            mv.setData("error", e.getMessage());
        } catch (Exception e) {
            mv.setData("error", "Erreur serveur : " + e.getMessage());
        }

        return mv;
    }

    /**
     * Traiter la mise à jour d'un véhicule (Back-office)
     */
    @PostRouteMapping(value = "/vehicules/update")
    public ModelView updateVehicule(
            @RequestParam("id") Long id,
            @RequestParam("reference") String reference,
            @RequestParam("nbPlace") Integer nbPlace,
            @RequestParam("typeCarburant") String typeCarburant) {

        ModelView mv = new ModelView("/vehicules/list.jsp");

        try {
            vehiculeService.updateVehicule(id, reference, nbPlace, typeCarburant);
            mv.setData("success", "Véhicule mis à jour avec succès !");
            mv.setData("vehicules", vehiculeRepository.findAll());

        } catch (IllegalArgumentException e) {
            mv.setData("error", e.getMessage());
            try {
                mv.setData("vehicules", vehiculeRepository.findAll());
            } catch (Exception ex) {
                mv.setData("error", "Erreur lors du chargement des véhicules");
            }
        } catch (Exception e) {
            mv.setData("error", "Erreur serveur : " + e.getMessage());
            try {
                mv.setData("vehicules", vehiculeRepository.findAll());
            } catch (Exception ex) {
                mv.setData("error", "Erreur lors du chargement des véhicules");
            }
        }

        return mv;
    }

    /**
     * Traiter la suppression d'un véhicule (Back-office)
     */
    @PostRouteMapping(value = "/vehicules/delete")
    public ModelView deleteVehicule(@RequestParam("id") Long id) throws Exception {
        ModelView mv = new ModelView("/vehicules/list.jsp");

        try {
            vehiculeService.deleteVehicule(id);
            mv.setData("success", "Véhicule supprimé avec succès !");
            mv.setData("vehicules", vehiculeRepository.findAll());

        } catch (IllegalArgumentException e) {
            mv.setData("error", e.getMessage());
            mv.setData("vehicules", vehiculeRepository.findAll());
        } catch (Exception e) {
            mv.setData("error", "Erreur serveur : " + e.getMessage());
            mv.setData("vehicules", vehiculeRepository.findAll());
        }

        return mv;
    }

    // ============================================
    // API JSON ENDPOINTS
    // ============================================

    @Json
    @PostRouteMapping(value = "/api/vehicules")
    public Map<String, Object> createVehiculeAPI(
            @RequestParam("reference") String reference,
            @RequestParam("nbPlace") Integer nbPlace,
            @RequestParam("typeCarburant") String typeCarburant) {

        Map<String, Object> response = new HashMap<>();

        try {
            Vehicule vehicule = vehiculeService.createVehicule(reference, nbPlace, typeCarburant);
            response.put("success", true);
            response.put("vehicule", toDto(vehicule));
            response.put("message", "Véhicule créé avec succès");

        } catch (IllegalArgumentException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Erreur serveur : " + e.getMessage());
        }

        return response;
    }

    @Json
    @GetRouteMapping(value = "/api/vehicules")
    public Map<String, Object> getVehiculesAPI() {
        Map<String, Object> response = new HashMap<>();

        try {
            List<Vehicule> vehicules = vehiculeService.getAllVehicules();
            response.put("success", true);
            response.put("vehicules", toDtoList(vehicules));
            response.put("count", vehicules.size());

        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Erreur serveur : " + e.getMessage());
        }

        return response;
    }

    @Json
    @GetRouteMapping(value = "/api/vehicules/:id")
    public Map<String, Object> getVehiculeAPI(@RequestParam("id") Long id) {
        Map<String, Object> response = new HashMap<>();

        try {
            Vehicule vehicule = vehiculeService.getVehiculeById(id);
            response.put("success", true);
            response.put("vehicule", toDto(vehicule));

        } catch (IllegalArgumentException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Erreur serveur : " + e.getMessage());
        }

        return response;
    }

    @Json
    @PostRouteMapping(value = "/api/vehicules/:id")
    public Map<String, Object> updateVehiculeAPI(
            @RequestParam("id") Long id,
            @RequestParam("reference") String reference,
            @RequestParam("nbPlace") Integer nbPlace,
            @RequestParam("typeCarburant") String typeCarburant) {

        Map<String, Object> response = new HashMap<>();

        try {
            vehiculeService.updateVehicule(id, reference, nbPlace, typeCarburant);
            Vehicule vehicule = vehiculeService.getVehiculeById(id);
            response.put("success", true);
            response.put("vehicule", toDto(vehicule));
            response.put("message", "Véhicule mis à jour avec succès");

        } catch (IllegalArgumentException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Erreur serveur : " + e.getMessage());
        }

        return response;
    }

    @Json
    @PostRouteMapping(value = "/api/vehicules/:id/delete")
    public Map<String, Object> deleteVehiculeAPI(@RequestParam("id") Long id) {
        Map<String, Object> response = new HashMap<>();

        try {
            vehiculeService.deleteVehicule(id);
            response.put("success", true);
            response.put("message", "Véhicule supprimé avec succès");

        } catch (IllegalArgumentException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Erreur serveur : " + e.getMessage());
        }

        return response;
    }

    // ============================================
    // HELPER METHODS
    // ============================================

    public VehiculeDTO toDto(Vehicule vehicule) {
        VehiculeDTO dto = new VehiculeDTO();
        dto.setId(vehicule.getId());
        dto.setReference(vehicule.getReference());
        dto.setNbPlace(vehicule.getNbPlace());
        dto.setTypeCarburant(vehicule.getTypeCarburant().name());
        return dto;
    }

    public List<VehiculeDTO> toDtoList(List<Vehicule> vehicules) {
        return vehicules.stream()
                .map(this::toDto)
                .toList();
    }
}
