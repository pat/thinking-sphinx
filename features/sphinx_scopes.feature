Feature: Sphinx Scopes

  Scenario: Single Scope
    Given Sphinx is running
    And I am searching on people
    When I use the with_first_name scope set to "Andrew"
    Then I should get 7 results

  Scenario: Two Field Scopes
    Given Sphinx is running
    And I am searching on people
    When I use the with_first_name scope set to "Andrew"
    And I use the with_last_name scope set to "Byrne"
    Then I should get 1 result

  Scenario: Mixing Filter and Field Scopes
    Given Sphinx is running
    And I am searching on people
    When I use the with_first_name scope set to "Andrew"
    And I use the with_id scope set to 99
    Then I should get 1 result
  
  Scenario: Mixing Field and ID Scopes
    Given Sphinx is running
    And I am searching on people
    When I use the with_first_name scope set to "Andrew"
    And I use the ids_only scope
    Then I should get 7 results
    And I should have an array of integers
  
  Scenario: Non-field/filter Scopes
    Given Sphinx is running
    And I am searching on people
    When I use the ids_only scope
    Then I should have an array of integers
