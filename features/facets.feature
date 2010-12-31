Feature: Search and browse models by their defined facets
  
  Background:
    Given Sphinx is running
  
  Scenario: Requesting facets
    Given I am searching on developers
    When I am requesting facet results
    Then I should have valid facet results
    And I should have 6 facets
    And I should have the facet State
    And I should have the facet Country
    And I should have the facet Age
    And I should have the facet City
    And I should have the facet Tag Ids
    And I should have the facet Tags
  
  Scenario: Requesting specific facets
    Given I am searching on developers
    When I am requesting facet results
    And I am requesting just the facet State
    Then I should have valid facet results
    And I should have 1 facet
    And I should have the facet State
    When I am requesting just the facets State and Age
    Then I should have valid facet results
    And I should have 2 facet
    And I should have the facet State
    And I should have the facet Age
  
  Scenario: Requesting float facets
    Given I am searching on alphas
    When I am requesting facet results
    Then I should have 1 facet
    And the Cost facet should have a 5.55 key
  
  Scenario: Requesting facet results
    Given I am searching on developers
    When I am requesting facet results
    And I drill down where Country is Australia
    Then I should get 11 results
  
  Scenario: Requesting facet results by multiple facets
    Given I am searching on developers
    When I am requesting facet results
    And I drill down where Country is Australia and Age is 30
    Then I should get 4 results
    
  Scenario: Requesting facets with classes included
    Given I am searching on developers
    When I am requesting facet results
    And I want classes included
    Then I should have valid facet results
    And I should have 7 facets
    And I should have the facet Class
  
  Scenario: Requesting MVA facets
    Given I am searching on developers
    When I am requesting facet results
    And I drill down where tag_ids includes the id of tag Australia
    Then I should get 11 results
    When I am requesting facet results
    And I drill down where tag_ids includes the id of tags Melbourne or Sydney
    Then I should get 5 results
  
  Scenario: Requesting MVA string facets
    Given I am searching on developers
    When I am requesting facet results
    Then the Tags facet should have an "Australia" key
    Then the Tags facet should have an "Melbourne" key
    Then the Tags facet should have an "Victoria" key

  Scenario: Requesting MVA facets from source queries
    Given I am searching on posts
    When I am requesting facet results
    Then the Comment Ids facet should have 9 keys
  
  Scenario: Requesting facets from a subclass
    Given I am searching on animals
    When I am requesting facet results
    And I want classes included
    Then I should have the facet Class
  
  Scenario: Requesting facets with explicit value sources
    Given I am searching on developers
    When I am requesting facet results
    Then the City facet should have a "Melbourne" key
  
