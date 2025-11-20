package com.example.hello.adapter.incoming.rest;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc  // NOTE: Despite the annotation name, this configures a FAKE HTTP client, not a mock
@DisplayName("GET /api/hello - Greeting API")
class HelloControllerIntegrationTest {

    @Autowired
    private MockMvc fakeHttpClient;  // FAKE: MockMvc is a working HTTP test harness, not a mock. All beans are REAL.

    @Test
    @DisplayName("should provide default greeting when no name specified")
    void shouldProvideDefaultGreeting_whenNoNameSpecified() throws Exception {
        // Arrange & Act & Assert
        fakeHttpClient.perform(get("/api/hello"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Hello, World!")));
    }

    @Test
    @DisplayName("should provide personalized greeting for given name")
    void shouldProvidePersonalizedGreeting_forGivenName() throws Exception {
        // Arrange & Act & Assert
        fakeHttpClient.perform(get("/api/hello").param("name", "Alice"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Hello, Alice!")));
    }

    @Test
    @DisplayName("should reject blank name with error message")
    void shouldRejectBlankName_withErrorMessage() throws Exception {
        // Arrange & Act & Assert
        fakeHttpClient.perform(get("/api/hello").param("name", "   "))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(containsString("Name cannot be empty")));
    }
}
