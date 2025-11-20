Feature: Greeting Functionality

  As a user
  I want to get personalized greetings
  So that I can see the full-stack application working

  Scenario: Get personalized greeting with custom name
    Given the application is running
    When I navigate to the home page
    Then I should see the "Hello World Demo" heading
    When I enter "Alice" as the name
    And I click the "Get Greeting" button
    Then I should see the greeting "Hello, Alice! Welcome to the world."

  Scenario: Get greeting with default name
    Given the application is running
    When I navigate to the home page
    Then I should see the "Hello World Demo" heading
    And the name input should contain "World"
    When I click the "Get Greeting" button
    Then I should see the greeting "Hello, World! Welcome to the world."
