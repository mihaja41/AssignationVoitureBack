package annotations;

import class_annotations.Controller;
import method_annotations.Route;
import method_annotations.Json;
import method_annotations.PostRouteMapping;
import method_annotations.RequestParam;
import view.ModelView;
import java.util.Map;

@Controller
public class MapTestController {

    @PostRouteMapping(value = "/test-map")
    public ModelView saveUser(
            @RequestParam("name") String nom,
            @RequestParam("qi") int age,
            Map<String, Object> formData                     
    ) {
        System.out.println("=== DONNÉES REÇUES ===");
        System.out.println("Nom : " + nom);
        System.out.println("Âge : " + age);
        System.out.println("TOUT LE FORMULAIRE : " + formData);

        String[] loisirs = (String[]) formData.get("leasures");
        System.out.println("Loisirs sélectionnés : " + java.util.Arrays.toString(loisirs));

        ModelView mv = new ModelView("resultMap.jsp");
        mv.setData("name", nom);
        mv.setData("qi", age);
        mv.setData("formData", formData);
        mv.setData("leasures", loisirs != null ? loisirs : new String[0]);

        return mv;
    }

    @Route("/map-test")
    public ModelView showForm() {
        return new ModelView("MapTest.jsp");
    }
}