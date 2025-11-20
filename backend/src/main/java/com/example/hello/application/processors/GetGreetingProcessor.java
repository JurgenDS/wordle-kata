package com.example.hello.application.processors;

import com.example.hello.application.CommandProcessor;
import com.example.hello.application.ports.incoming.GetGreetingCommand;
import com.example.hello.domain.model.Greeting;
import io.vavr.control.Either;
import org.springframework.stereotype.Component;

@Component
public class GetGreetingProcessor implements CommandProcessor<GetGreetingCommand, Either<BusinessError, Greeting>> {

    @Override
    public Either<BusinessError, Greeting> process(GetGreetingCommand command) {
        if (command.name().isBlank()) {
            return Either.left(new BusinessError("Name cannot be empty"));
        }

        String message = String.format("Hello, %s! Welcome to the world.", command.name());
        return Either.right(Greeting.of(message));
    }
}
