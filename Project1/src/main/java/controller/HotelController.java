package controller;

import class_annotations.Controller;
import method_annotations.GetRouteMapping;
import method_annotations.Json;
import repository.LieuRepository;
import service.TokenService ; 
import model.Lieu;
import model.Token;
import dto.TokenDTO ; 

import java.util.List;

@Controller
public class HotelController {

    private final LieuRepository lieuRepository = new LieuRepository();
    private final TokenService   token = new TokenService() ; 

    /**
     * API : Liste des lieux (pour le front-office)
     * URL conservée /api/hotels pour compatibilité avec l'autre repo frontend
     */
    @Json
    @GetRouteMapping(value = "/api/hotels")
    public List<Lieu> getHotels() throws Exception {
        return lieuRepository.findAll();
    }
    /**
     * API : Génération de token (pour le front-office)
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