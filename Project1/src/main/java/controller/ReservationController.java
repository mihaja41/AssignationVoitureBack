package controller;

import class_annotations.Controller;
import method_annotations.GetRouteMapping;
import method_annotations.Json;
import method_annotations.PostRouteMapping;
import method_annotations.RequestParam;
import repository.HotelRepository;
import repository.ReservationRepository;
import service.ReservationService;
import view.ModelView;
import model.Reservation;
import dto.ReservationDTO;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class ReservationController {

    private final ReservationService reservationService = new ReservationService();
    private final ReservationRepository reservationRepository = new ReservationRepository();
    private final HotelRepository hotelRepository = new HotelRepository();

    /**
     * Afficher le formulaire d'ajout de réservation (Back-office)
     */
    @GetRouteMapping(value = "/reservations/form")
    public ModelView showForm() throws Exception {
        ModelView mv = new ModelView("/reservations/form.jsp");
        mv.setData("hotels", hotelRepository.findAll());
        return mv;
    }

    /**
     * Traiter le formulaire d'ajout (Back-office)
     */
    @PostRouteMapping(value = "/reservations/add")
    public ModelView addReservation(
            @RequestParam("hotelId") Long hotelId,
            @RequestParam("customerId") String customerId,
            @RequestParam("passengerNbr") Integer passengerNbr,
            @RequestParam("arrivalDate") String arrivalDateStr) {

        ModelView mv = new ModelView("/reservations/form.jsp");

        try {
            // Parser la date
            LocalDateTime arrivalDate = LocalDateTime.parse(arrivalDateStr, 
                DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm"));

            // Créer la réservation via le service
            Reservation reservation = reservationService.createReservation(
                hotelId, customerId, passengerNbr, arrivalDate);

            // Message de succès
            mv.setData("success", "✅ Réservation créée avec succès ! (ID: " + reservation.getId() + ")");
            
            // Recharger la liste des hôtels pour le formulaire
            mv.setData("hotels", hotelRepository.findAll());

        } catch (IllegalArgumentException e) {
            mv.setData("error", e.getMessage());
            try {
                mv.setData("hotels", hotelRepository.findAll());
            } catch (Exception ex) {
                mv.setData("error", "Erreur lors du chargement des hôtels");
            }
        } catch (Exception e) {
            mv.setData("error", "Erreur serveur : " + e.getMessage());
            try {
                mv.setData("hotels", hotelRepository.findAll());
            } catch (Exception ex) {
                mv.setData("error", "Erreur lors du chargement des hôtels");
            }
        }

        return mv;
    }
    /**
     * Afficher la liste des réservations (Back-office)
     */
    @GetRouteMapping(value = "/reservations/list")
    public ModelView listReservations() throws Exception {
        ModelView mv = new ModelView("/reservations/list.jsp");
        mv.setData("reservations", reservationRepository.findAll());
        return mv;
    }


    public ReservationDTO toDto(Reservation reservation) {
         ReservationDTO dto = new ReservationDTO();
        dto.setId(reservation.getId());
        dto.setHotelName(reservation.getHotel().getName());
        dto.setCustomerId(reservation.getCustomerId());
        dto.setPassengerNbr(reservation.getPassengerNbr());
        dto.setArrivalDate(reservation.getArrivalDate());
    return dto;
}

public List<ReservationDTO> toDtoList(List<Reservation> reservations) {
    return reservations.stream()
            .map(this::toDto)
            .toList();
}


    /**
     * API : Créer une réservation (JSON pour Front-office Spring Boot)
     */
    @Json
    @PostRouteMapping(value = "/api/reservations")
    public Map<String, Object> createReservationAPI(
            @RequestParam("hotelId") Long hotelId,
            @RequestParam("customerId") String customerId,  // ← Changé de Integer à String
            @RequestParam("passengerNbr") Integer passengerNbr,
            @RequestParam("arrivalDate") String arrivalDateStr) {

        Map<String, Object> response = new HashMap<>();

        try {
            // Parser la date ISO 8601
            LocalDateTime arrivalDate = LocalDateTime.parse(arrivalDateStr);

            // Créer la réservation
            Reservation reservation = reservationService.createReservation(
                hotelId, customerId, passengerNbr, arrivalDate);

            response.put("success", true);
            response.put("reservation", toDto(reservation));
            response.put("message", "Réservation créée avec succès");

        } catch (IllegalArgumentException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Erreur serveur : " + e.getMessage());
        }

        return response;
    }

    /**
     * API : Liste des réservations (JSON pour Front-office)
     */
    @Json
    @GetRouteMapping(value = "/api/reservations")
    public List<ReservationDTO> getReservationsAPI() throws Exception {
        return toDtoList(reservationRepository.findAll());
    }
}