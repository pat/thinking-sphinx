Feature: Search and browse across models by their defined facets

Scenario: Requesting facets across multiple models
  Given Sphinx is running
  When I am requesting facet results with classes included
  Then I should have valid facet results
  And I should have 7 facets
  And I should have the facet Class
  And it should have a "Person" key
  And I should have the facet Gender
  And it should have a "female" key
  And I should have the facet Country
  And I should have the facet category_name
  And it should have a "hello" key with 2 hits
  
