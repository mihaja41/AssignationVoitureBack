package main.java.class_object;

public class Employe {
    private int id;
    private String name;
    private String email;
    private Departement departement;

    public Employe(){}

    public Employe(int id, String name,  String email, Departement departement) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.departement = departement;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public Departement getDepartement() { return departement; }
    public void setDepartement(Departement departement) { this.departement = departement; }
}
