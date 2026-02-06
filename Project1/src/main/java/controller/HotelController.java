package controller;

import class_annotations.Controller;
import method_annotations.GetRouteMapping;
import method_annotations.Json;
import repository.HotelRepository;
import model.Hotel;

import java.util.List;

@Controller
public class HotelController {

    private final HotelRepository hotelRepository = new HotelRepository();

    /**
     * API : Liste des hôtels (pour le front-office)
     */
    @Json
    @GetRouteMapping(value = "/api/hotels")
    public List<Hotel> getHotels() throws Exception {
        return hotelRepository.findAll();
    }
}