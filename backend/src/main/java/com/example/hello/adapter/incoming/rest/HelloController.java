package com.example.hello.adapter.incoming.rest;

import com.example.hello.application.ports.incoming.GetGreetingCommand;
import com.example.hello.application.processors.GetGreetingProcessor;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/hello")
@AllArgsConstructor
public class HelloController {

    private final GetGreetingProcessor getGreetingProcessor;

    @GetMapping
    public ResponseEntity<GreetingDto> getGreeting(
            @RequestParam(name = "name", defaultValue = "World") String name) {

        return getGreetingProcessor.process(new GetGreetingCommand(name))
                .map(greeting -> ResponseEntity.ok(new GreetingDto(greeting.getMessage())))
                .getOrElseGet(error -> ResponseEntity.badRequest()
                        .body(new GreetingDto(error.message())));
    }

    public record GreetingDto(String message) {
    }
}
