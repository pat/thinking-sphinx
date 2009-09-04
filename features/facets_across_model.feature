Feature: Search and browse across models by their defined facets

  Scenario: Requesting facets across multiple models
    Given Sphinx is running
    When I am requesting facet results
    And I want all possible attributes
    Then I should have valid facet results
    And I should have 10 facets
    And I should have the facet Class
    And the Class facet should have a "Person" key
    And I should have the facet Gender
    And the Gender facet should have a "female" key
    And I should have the facet Country
    And I should have the facet Category Name
    And the Category Name facet should have a "hello" key with 10 hits
  
  Scenario: Requesting facets across models without class results
    Given Sphinx is running
    When I am requesting facet results
    And I want all possible attributes
    And I don't want classes included
    Then I should have 9 facets
    And I should not have the facet Class
  
  Scenario: Requesting facets common to all indexed models
    Given Sphinx is running
    When I am requesting facet results
    Then I should have the facet Class
    And I should have 1 facet
