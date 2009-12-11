Feature: Abstract inheritance
  In order to use Thinking Sphinx in complex situations
  As a developer
  I want to define indexes on subclasses of abstract models

  Scenario: Searching on subclasses of abstract models
    Given Sphinx is running
    And I am searching on music
    When I search
    Then I should get 3 results
