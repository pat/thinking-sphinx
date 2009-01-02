Feature: Searching across multiple model
  In order to use Thinking Sphinx's core functionality
  A developer
  Should be able to search on multiple models
  
  Scenario: Retrieving total result count
    Given Sphinx is running
    When I search for James
    And I am retrieving the result count
    Then I should get a value of 3
  
  Scenario: Confirming existance of a document id in a given index
    Given Sphinx is running
    When I search for the specific id of 46 in the person_core index
    Then it should exist
  
  Scenario: Unsuccessfully confirming existance of a document id in a given index
    Given Sphinx is running
    When I search for the specific id of 47 in the person_core index
    Then it should not exist