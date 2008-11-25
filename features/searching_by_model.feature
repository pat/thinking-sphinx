Feature: Searching on a single model
  In order to use Thinking Sphinx's core functionality
  A developer
  Should be able to search on a single model
  
  Scenario: Searching using a basic query
    Given Sphinx is running
    And I am searching on people
    When I search for James
    Then I should get 3 results
  
  Scenario: Searching on a specific field
    Given Sphinx is running
    And I am searching on people
    When I search for James on first_name
    Then I should get 2 results
  
  Scenario: Searching on multiple fields
    Given Sphinx is running
    And I am searching on people
    When I search for James on first_name
    And I search for Chamberlain on last_name
    Then I should get 1 result
  
  Scenario: Searching with a filter
    Given Sphinx is running
    And I am searching on alphas
    When I filter by 1 on value
    Then I should get 1 result
  
  Scenario: Searching with multiple filters
    Given Sphinx is running
    And I am searching on boxes
    When I filter by 2 on width
    And I filter by 2 on length
    Then I should get 1 result
  
  Scenario: Searching with ordering by attribute
    Given Sphinx is running
    And I am searching on alphas
    When I order by value
    Then I should get 10 results
    And the value of each result should indicate order
  
  Scenario: Searching with ordering on a sortable field
    Given Sphinx is running
    And I am searching on people
    And I order by first_name
    Then I should get 20 results
    And the first_name of each result should indicate order
  