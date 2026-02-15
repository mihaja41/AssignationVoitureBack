package controller;

import class_annotations.Controller;
import method_annotations.GetRouteMapping;
import method_annotations.Json;
import repository.HotelRepository;
import service.TokenService ; 
import model.Hotel;
import model.Token;
import dto.TokenDTO ; 

import java.util.List;

@Controller
public class HotelController {

    private final HotelRepository hotelRepository = new HotelRepository();
    private final TokenService   token = new TokenService() ; 

    /**
     * API : Liste des hôtels (pour le front-office)
     */
    @Json
    @GetRouteMapping(value = "/api/hotels")
    public List<Hotel> getHotels() throws Exception {
        return hotelRepository.findAll();
    }
    /**
     * API : Liste des hôtels (pour le front-office)
     */
    @Json
    @GetRouteMapping(value = "/token")
    public TokenDTO  getToken() throws Exception {
        Token tokenEntity = token.generateAndSaveToken() ;

        return new TokenDTO(
            tokenEntity.getTokenName(),
            tokenEntity.getExpireDate().toString()
        );

    }

}