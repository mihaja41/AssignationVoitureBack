package dto;

public class TokenDTO {

    private String token;
    private String expireDate;

    public TokenDTO(String token, String expireDate) {
        this.token = token;
        this.expireDate = expireDate;
    }

    public String getToken() {
        return token;
    }

    public String getExpireDate() {
        return expireDate;
    }
}
