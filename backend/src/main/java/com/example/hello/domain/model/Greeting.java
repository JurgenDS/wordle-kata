package com.example.hello.domain.model;

import lombok.EqualsAndHashCode;
import lombok.NonNull;
import lombok.ToString;

@EqualsAndHashCode
@ToString
public class Greeting {
    private final String message;

    private Greeting(String message) {
        this.message = message;
    }

    public static Greeting of(@NonNull String message) {
        if (message.isBlank()) {
            throw new IllegalArgumentException("Greeting message cannot be blank");
        }
        return new Greeting(message);
    }

    public String getMessage() {
        return message;
    }
}
