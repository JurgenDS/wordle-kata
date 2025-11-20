package com.example.hello.domain.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("Greeting Message Validation")
class GreetingTest {

    @Test
    @DisplayName("should accept and store valid message")
    void shouldAcceptAndStoreValidMessage() {
        // Arrange
        String message = "Hello, World!";

        // Act
        Greeting greeting = Greeting.of(message);

        // Assert
        assertThat(greeting.getMessage()).isEqualTo(message);
    }

    @Test
    @DisplayName("should reject blank message")
    void shouldRejectBlankMessage() {
        // Arrange
        String blankMessage = "";

        // Act & Assert
        assertThatThrownBy(() -> Greeting.of(blankMessage))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Greeting message cannot be blank");
    }

    @Test
    @DisplayName("should reject null message")
    void shouldRejectNullMessage() {
        // Act & Assert
        assertThatThrownBy(() -> Greeting.of(null))
                .isInstanceOf(NullPointerException.class);
    }
}
