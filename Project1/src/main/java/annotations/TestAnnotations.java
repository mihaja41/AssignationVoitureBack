package  annotations;
import class_annotations.Controller;
import method_annotations.Route; 

@Controller(value = "TestController")
public class TestAnnotations {

    @Route(value = "/test")
    public void testMethod() { 
        System.out.println("Annotation test method executed.\n");

    }
}
