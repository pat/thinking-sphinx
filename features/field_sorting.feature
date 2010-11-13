Feature: Field Sorting
  In order to sort by strings
  As a developer
  I want to enable sorting by existing fields
  
  Background:
    Given Sphinx is running
    And I am searching on people
    
  Scenario: Searching with ordering on a sortable field
    When I order by first_name
    Then I should get 20 results
    And the first_name of each result should indicate order
  
  Scenario: Sort on a case insensitive sortable field
    When I order by last_name
    Then the first result's "last_name" should be "abbott"
  
