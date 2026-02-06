package  annotations;
import class_annotations.Controller;
import method_annotations.Route; 

@Controller(value = "PersonController")
public class Test3{

    @Route(value = "/add_Test3")
    public void setTest3() { 
        System.out.println("INFO : setTest3 executed\n");

    }
    @Route(value = "/get_Test3")
    public double getTest3() {
        System.out.println("INFO : getTest3 executed.\n");
        return 2.0;
    }
}
