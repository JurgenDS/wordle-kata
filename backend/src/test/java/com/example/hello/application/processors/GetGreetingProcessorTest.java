package com.example.hello.application.processors;

import com.example.hello.application.ports.incoming.GetGreetingCommand;
import com.example.hello.domain.model.Greeting;
import io.vavr.control.Either;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Personalized Greeting Generation")
class GetGreetingProcessorTest {

    private GetGreetingProcessor processor;

    @BeforeEach
    void setUp() {
        processor = new GetGreetingProcessor();
    }

    @Test
    @DisplayName("should generate personalized greeting for valid name")
    void shouldGeneratePersonalizedGreeting_forValidName() {
        // Arrange
        GetGreetingCommand command = new GetGreetingCommand("Alice");

        // Act
        Either<BusinessError, Greeting> result = processor.process(command);

        // Assert
        assertThat(result.isRight()).isTrue();
        assertThat(result.get().getMessage()).isEqualTo("Hello, Alice! Welcome to the world.");
    }

    @Test
    @DisplayName("should reject blank name")
    void shouldRejectBlankName() {
        // Arrange
        GetGreetingCommand command = new GetGreetingCommand("");

        // Act
        Either<BusinessError, Greeting> result = processor.process(command);

        // Assert
        assertThat(result.isLeft()).isTrue();
        assertThat(result.getLeft().message()).isEqualTo("Name cannot be empty");
    }

    @Test
    @DisplayName("should reject whitespace-only name")
    void shouldRejectWhitespaceOnlyName() {
        // Arrange
        GetGreetingCommand command = new GetGreetingCommand("   ");

        // Act
        Either<BusinessError, Greeting> result = processor.process(command);

        // Assert
        assertThat(result.isLeft()).isTrue();
        assertThat(result.getLeft().message()).isEqualTo("Name cannot be empty");
    }
}
