package main.java.annotations;

import java.sql.Date;

import class_annotations.Controller;
import method_annotations.*;
import view.ModelView;

@Controller
public class ServerController {

    // public ViewController(){}

    @Route(value = "/servers/get/{id}") 
    public String get(int id) {
        Server a = new Server(id, "127.0.0.1");
        return "ID : "+id;
    }
    @Route(value = "/servers/{ip}") 
    public String getIp(String ip) {
        Server a = new Server(1, ip);
        return "IP : "+ip;
    }

    // @GetRouteMapping(value = "/add") 
    // public String addServer(String name, @RequestParam("number") double isa) {
    //     return "server: "+name+" successfully added whith GET method";
    // }

    @Json
    @PostRouteMapping(value = "/add") 
    public String addPostServer(String name, @RequestParam("number") double isa) {
        return "server: "+name+" successfully added whith POST method";
    }

    @Route(value = "/pass") 
    public Date passAllRoutes(Date date) {
        return date;
    }

    @Route("/add-server")
    public ModelView showForm() {
        return new ModelView("addServer.jsp");
    }

}