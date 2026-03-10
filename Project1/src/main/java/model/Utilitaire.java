package model;

public class Utilitaire {
    
public int getValueInitial(String initial) {
    if (initial.equalsIgnoreCase("a")) return 0;
    if (initial.equalsIgnoreCase("b")) return 1;
    if (initial.equalsIgnoreCase("c")) return 2;
    if (initial.equalsIgnoreCase("d")) return 3;
    if (initial.equalsIgnoreCase("e")) return 4;
    if (initial.equalsIgnoreCase("f")) return 5;
    if (initial.equalsIgnoreCase("g")) return 6;
    if (initial.equalsIgnoreCase("h")) return 7;
    if (initial.equalsIgnoreCase("i")) return 8;
    if (initial.equalsIgnoreCase("j")) return 9;
    if (initial.equalsIgnoreCase("k")) return 10;
    if (initial.equalsIgnoreCase("l")) return 11;
    if (initial.equalsIgnoreCase("m")) return 12;
    if (initial.equalsIgnoreCase("n")) return 13;
    if (initial.equalsIgnoreCase("o")) return 14;
    if (initial.equalsIgnoreCase("p")) return 15;
    if (initial.equalsIgnoreCase("q")) return 16;
    if (initial.equalsIgnoreCase("r")) return 17;
    if (initial.equalsIgnoreCase("s")) return 18;
    if (initial.equalsIgnoreCase("t")) return 19;
    if (initial.equalsIgnoreCase("u")) return 20;
    if (initial.equalsIgnoreCase("v")) return 21;
    if (initial.equalsIgnoreCase("w")) return 22;
    if (initial.equalsIgnoreCase("x")) return 23;
    if (initial.equalsIgnoreCase("y")) return 24;
    if (initial.equalsIgnoreCase("z")) return 25;
    return -1; // si valeur invalide
}

}
