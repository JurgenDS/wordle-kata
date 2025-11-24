package com.example.hello.adapter;

import com.example.hello.application.processors.GetGreetingProcessor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for application layer components.
 * This configuration ensures that the application layer remains
 * framework-agnostic by manually wiring beans instead of using
 * framework annotations in the application layer.
 */
@Configuration
public class ApplicationConfiguration {

    @Bean
    public GetGreetingProcessor getGreetingProcessor() {
        return new GetGreetingProcessor();
    }
}
