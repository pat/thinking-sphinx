Feature: Searching on a single model
  In order to use search models with non-integer primary keys
  A developer
  Should be able to search on a single model
  
  Scenario: Searching using a basic query
    Given Sphinx is running
    And I am searching on robots
    When I search for Sizzle
    Then I should get 2 results
  
  Scenario: Searching using another basic query
    Given Sphinx is running
    And I am searching on robots
    When I search for fritz
    Then I should get 1 result

