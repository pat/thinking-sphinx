Feature: Search and browse models by their defined facets
  
  Scenario: Test
    Given Sphinx is running
    And I am searching on developers
    When I am requesting facet results
    Then I should see facet results