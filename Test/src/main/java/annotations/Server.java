package main.java.annotations;

import class_annotations.Controller;
import method_annotations.Route; 

@Controller
public class Server {

    private int server_id;
    private String server_ip;

    public Server(int id,String server_ip) {
        this.server_id=id;
        this.server_ip=server_ip;
    }

    public int getIdMap() { return this.server_id; }
    public void setIdMap(int id) { this.server_id = id;}
    public String getMap() {return this.server_ip;}
    public void setMap() {this.server_ip = server_ip;}
}
