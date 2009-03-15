Feature: Search and browse across models by their defined facets

  Scenario: Requesting facets across multiple models
    Given Sphinx is running
    When I am requesting facet results with classes included
    Then I should have valid facet results
    And I should have 8 facets
    And I should have the facet Class
    And the Class facet should have a "Person" key
    And I should have the facet Gender
    And the Gender facet should have a "female" key
    And I should have the facet Country
    And I should have the facet Category Name
    And the Category Name facet should have a "hello" key with 10 hits
