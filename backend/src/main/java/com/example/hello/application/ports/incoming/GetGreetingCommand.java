package com.example.hello.application.ports.incoming;

import lombok.NonNull;

public record GetGreetingCommand(@NonNull String name) {
}
