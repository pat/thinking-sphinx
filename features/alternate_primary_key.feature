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
  
  Scenario: Deleting an instance
    Given Sphinx is running
    And I am searching on robots
    When I search for Expendable
    Then I should get 1 result
    
    When I destroy robot Expendable
    And I wait for Sphinx to catch up
    And I search for three
    Then I should get 0 results
