Feature: Search and browse models by their defined facets
  
  Scenario: Requesting facets
    Given Sphinx is running
    And I am searching on developers
    When I am requesting facet results
    Then I should have valid facet results
    And I should have 4 facets
    And I should have the facet State
    And I should have the facet Country
    And I should have the facet Age
    And I should have the facet City
  
  Scenario: Requesting facet results
    Given Sphinx is running
    And I am searching on developers
    When I am requesting facet results
    And I drill down where Country is Australia
    Then I should get 11 results
  
  Scenario: Requesting facet results by multiple facets
    Given Sphinx is running
    And I am searching on developers
    When I am requesting facet results
    And I drill down where Country is Australia and Age is 30
    Then I should get 4 results
    
  Scenario: Requesting facets with classes included
    Given Sphinx is running
    And I am searching on developers
    When I am requesting facet results with classes included
    Then I should have valid facet results
    And I should have 5 facets
    And I should have the facet Class
