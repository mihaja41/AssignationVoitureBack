// package com.gestion.assignationvoiture;

// import org.apache.catalina.startup.Tomcat;
// import java.io.File;

// public class Application {

//     public static void main(String[] args) throws Exception {

//         Tomcat tomcat = new Tomcat();

//         int port = Integer.parseInt(
//             System.getenv().getOrDefault("PORT", "8080")
//         );
//         tomcat.setPort(port);

//         tomcat.getConnector();

//         // IMPORTANT : ressources web
//         File webappDir = new File("src/main/resources");
//         tomcat.addWebapp("", webappDir.getAbsolutePath());

//         tomcat.start();
//         tomcat.getServer().await();
//     }
// }
