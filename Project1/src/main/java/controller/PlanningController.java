package controller;

import class_annotations.Controller;
import method_annotations.GetRouteMapping;
import method_annotations.PostRouteMapping;
import method_annotations.RequestParam;
import service.PlanningService;
import view.ModelView;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Controller
public class PlanningController {

    private final PlanningService planningService = new PlanningService();

    /**
     * Page 1 : Afficher le formulaire de saisie de date.
     * Le frontend affichera un champ date pour choisir la date de planification.
     */
    @GetRouteMapping(value = "/planning/form")
    public ModelView showDateForm() {
        ModelView mv = new ModelView("/planning/form.jsp");
        return mv;
    }

    /**
     * Page 2 : Générer et afficher le planning pour une date donnée.
     * 
     * Reçoit la date saisie, lance l'algorithme d'attribution,
     * puis retourne un ModelView contenant :
     *   - "planningLines" : liste PlanningDTO des réservations assignées
     *                       (colonnes: Véhicule, Réservation, Lieu, DateHeureDepart, DateHeureRetour)
     *   - "unassignedReservations" : liste PlanningDTO des réservations non assignées
     *   - "selectedDate" : la date saisie (pour affichage)
     */
    @PostRouteMapping(value = "/planning/generate")
    public ModelView generatePlanning(@RequestParam("date") String dateStr) {
        ModelView mv = new ModelView("/planning/result.jsp");

        try {
            // Parser la date saisie (format yyyy-MM-dd depuis un input type="date")
            LocalDate selectedDate = LocalDate.parse(dateStr, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            LocalDateTime dateTime = selectedDate.atStartOfDay();

            // Générer le planning (attribution automatique + résultat)
            PlanningService.PlanningResult result = planningService.genererPlanning(dateTime);

            // Données pour la page planning
            mv.setData("planningLines", result.getPlanningLines());
            mv.setData("unassignedReservations", result.getUnassignedReservations());
            mv.setData("selectedDate", selectedDate.toString());

        } catch (Exception e) {
            mv.setData("error", "Erreur lors de la génération du planning : " + e.getMessage());
        }

        return mv;
    }

    /**
     * Variante GET pour accéder au planning via URL avec paramètre date.
     * Ex: /planning/result?date=2026-03-15
     */
    @GetRouteMapping(value = "/planning/result")
    public ModelView showPlanning(@RequestParam("date") String dateStr) {
        return generatePlanning(dateStr);
    }
}
