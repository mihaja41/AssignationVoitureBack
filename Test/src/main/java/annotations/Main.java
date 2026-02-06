package main.java.annotations;

import java.io.File;
import java.lang.reflect.Method;
import java.net.URL;
import java.util.*;
import method_annotations.Route;
import class_annotations.Controller;

public class Main {
    
    public static void main(String[] args) throws Exception {

        String basePackage = detectScanPackage();
        
        System.out.println("Scanning: " + basePackage);
        
        Map<String, List<String>> routesMap = new HashMap<>();
        
        List<Class<?>> classes = getClasses(basePackage);
        System.out.println("Classes found: " + classes.size() + "\n");
        
        for (Class<?> clazz : classes) {
            if (clazz.isAnnotationPresent(Controller.class)) {
                System.out.println("Controller: " + clazz.getSimpleName());
                
                for (Method method : clazz.getDeclaredMethods()) {
                    if (method.isAnnotationPresent(Route.class)) {
                        Route route = method.getAnnotation(Route.class);
                        String url = route.value();
                        
                        System.out.println("  => " + url + " => " + method.getName() + "()");
                        
                        routesMap.computeIfAbsent(url, k -> new ArrayList<>())
                                 .add(clazz.getSimpleName() + "." + method.getName());
                    }
                }
                System.out.println();
            }
        }
        
        System.out.println("ROUTE MAPPING");
        
        if (routesMap.isEmpty()) {
            System.out.println("No routes found!");
        } else {
            routesMap.forEach((url, methods) -> 
                System.out.println(url + " => " + methods)
            );
        }
    }

    private static String detectScanPackage() {
        String currentPackage = Main.class.getPackage().getName();
        
        // Prendre uniquement le PREMIER niveau (racine)
        String[] parts = currentPackage.split("\\.");
        
        if (parts.length > 0) {
            return parts[0];
        }
        
        return currentPackage;
    }
    
    private static List<Class<?>> getClasses(String packageName) throws Exception {
        List<Class<?>> classes = new ArrayList<>();
        String path = packageName.replace('.', '/');
        
        ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
        Enumeration<URL> resources = classLoader.getResources(path);
        
        if (!resources.hasMoreElements()) {
            System.err.println("Package not found: " + packageName);
            return classes;
        }
        
        while (resources.hasMoreElements()) {
            URL resource = resources.nextElement();
            File directory = new File(resource.getFile());
            
            if (directory.exists() && directory.isDirectory()) {
                scanDirectory(directory, packageName, classes);
            }
        }
        
        return classes;
    }
  
    private static void scanDirectory(File dir, String packageName, List<Class<?>> classes) {
        File[] files = dir.listFiles();
        if (files == null) return;
        
        for (File file : files) {
            String fileName = file.getName();
            
            if (file.isDirectory()) {
                // RECURSION : Scanner tous les sous-packages
                String subPackage = packageName + "." + fileName;
                scanDirectory(file, subPackage, classes);
            } 
            else if (fileName.endsWith(".class") && !fileName.contains("$")) {
                // Charger la classe (ignorer les inner classes)
                String className = packageName + "." + fileName.replace(".class", "");
                
                try {
                    Class<?> clazz = Class.forName(className);
                    classes.add(clazz);
                } catch (ClassNotFoundException | NoClassDefFoundError e) {
                    // Ignorer les classes non chargeables
                }
            }
        }
    }
}

