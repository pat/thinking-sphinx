Feature: Searching via STI model relationships
  In order to be used easy in applications with STI relationships
  Thinking Sphinx
  Should return expected results depending on where in the hierarchy searches are called from.
  
  Scenario: Searching from a parent model
    Given Sphinx is running
    And I am searching on animals
    Then I should get 8 result
  
  Scenario: Searching from a child model
    Given Sphinx is running
    And I am searching on cats
    Then I should get 5 result
