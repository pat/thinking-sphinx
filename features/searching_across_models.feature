Feature: Searching across multiple model
  In order to use Thinking Sphinx's core functionality
  A developer
  Should be able to search on multiple models
  
  Scenario: Retrieving total result count
    Given Sphinx is running
    When I search for James
    And I am retrieving the result count
    Then I should get a value of 6
  
  Scenario: Confirming existance of a document id in a given index
    Given Sphinx is running
    When I search for the document id of alpha one in the alpha_core index
    Then it should exist
  
  Scenario: Retrieving results from multiple models
    Given Sphinx is running
    When I search for ten
    Then I should get 4 results
