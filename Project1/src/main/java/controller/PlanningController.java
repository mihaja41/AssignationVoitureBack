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
     */
    @GetRouteMapping(value = "/planning/form")
    public ModelView showDateForm() {
        ModelView mv = new ModelView("/planning/form.jsp");
        return mv;
    }

    /**
     * Page 2 : Générer et afficher le planning pour une date donnée.
     * 
     * Retourne un ModelView contenant :
     *   - "attributions" : liste des Attribution assignées (véhicule + réservation + horaires calculés)
     *   - "reservationsNonAssignees" : liste des Reservation sans véhicule
     *   - "selectedDate" : la date saisie
     */
    @PostRouteMapping(value = "/planning/generate")
    public ModelView generatePlanning(@RequestParam("date") String dateStr) {
        ModelView mv = new ModelView("/planning/result.jsp");

        try {
            LocalDate selectedDate = LocalDate.parse(dateStr, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            LocalDateTime dateTime = selectedDate.atStartOfDay();

            PlanningService.PlanningResult result = planningService.genererPlanning(dateTime);

            mv.setData("attributions", result.getAttributions());
            mv.setData("reservationsNonAssignees", result.getReservationsNonAssignees());
            mv.setData("selectedDate", selectedDate.toString());

        } catch (Exception e) {
            mv.setData("error", "Erreur lors de la génération du planning : " + e.getMessage());
            e.printStackTrace();
        }

        return mv;
    }

    /**
     * Variante GET pour accéder au planning via URL avec paramètre date.
     */
    @GetRouteMapping(value = "/planning/result")
    public ModelView showPlanning(@RequestParam("date") String dateStr) {
        return generatePlanning(dateStr);
    }
}
