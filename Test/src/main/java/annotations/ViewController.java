package main.java.annotations;

import class_annotations.Controller;
import method_annotations.*; 
import view.ModelView;

@Controller(value = "ViewController")
public class ViewController {

    // public ViewController(){}

    @Route(value = "/view-test")
    public void testVueController () {
        System.out.println("A simple controller view controller");
    }

    @Route("/home")
    public ModelView redirectToHome() {
        ModelView view = new ModelView();
        view.setView("home.jsp");
        view.setData("test", "test");
        
        return view;
    }
    @GetRouteMapping(value = "/server/{id}")
    public ModelView redirectToHomeWithId(int id) {
        ModelView view = new ModelView();
        view.setView("/addServer.jsp");
        view.setData("id", id);
        
        return view;
    }
    @Route("/add_server")
    public ModelView redirectToServer() {
        ModelView view = new ModelView();
        view.setView("addServer.jsp");        
        return view;
    }

}
