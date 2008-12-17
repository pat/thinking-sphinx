Feature: Keeping Sphinx in line with model changes when requested
  In order to keep indexes as up to date as possible
  Thinking Sphinx
  Should return the expected results depending on whether delta indexes are used
  
  Scenario: Returning instance from old data if there is no delta
    Given Sphinx is running
    And I am searching on alphas
    When I search for two
    Then I should get 1 result
    
    When I change the name of alpha two to twelve
    And I wait for Sphinx to catch up
    And I search for two
    Then I should get 1 result
  
  Scenario: Not returing an instance from old data if there is a delta
    Given Sphinx is running
    And I am searching on betas
    When I search for two
    Then I should get 1 result
  
    When I change the name of beta two to twelve
    And I wait for Sphinx to catch up
    And I search for two
    Then I should get 0 results
  
  Scenario: Returning instance from new data if there is a delta
    Given Sphinx is running
    And I am searching on betas
    When I search for one
    Then I should get 1 result
  
    When I change the name of beta one to eleven
    And I wait for Sphinx to catch up
    And I search for one
    Then I should get 0 results
    
    When I search for eleven
    Then I should get 1 result