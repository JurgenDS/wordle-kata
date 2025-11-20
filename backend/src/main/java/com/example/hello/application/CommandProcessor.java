package com.example.hello.application;

public interface CommandProcessor<COMMAND, RESULT> {
    RESULT process(COMMAND command);
}
