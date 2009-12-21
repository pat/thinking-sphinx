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
  
  Scenario: Not returning an instance from old data if there is a delta
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
  
  Scenario: Returning new records if there's a delta
    Given Sphinx is running
    And I am searching on betas
    When I search for fifteen
    Then I should get 0 results
    
    When I create a new beta named fifteen
    And I wait for Sphinx to catch up
    And I search for fifteen
    Then I should get 1 result
  
  Scenario: Avoiding delta updates if there hasn't been changes
    Given Sphinx is running
    And I am searching on betas
    When I search for five
    Then I should get 1 result
    
    When I change the name of beta five to five
    And I wait for Sphinx to catch up
    And I search for five
    Then I should get 1 result
    
    When I search for the document id of beta five in the beta_core index
    Then it should exist if using Rails 2.1 or newer
    When I search for the document id of beta five in the beta_delta index
    Then it should not exist if using Rails 2.1 or newer
  
  Scenario: Handling edits with a delta when Sphinx isn't running
    Given Sphinx is running
    And I am searching on betas
    When I stop Sphinx
    And I change the name of beta six to sixteen
    And I start Sphinx
    And I search for sixteen
    Then I should get 1 result
  
  Scenario: Handling edits when updates are disabled
    Given Sphinx is running
    And updates are disabled
    And I am searching on betas
    
    When I search for seven
    Then I should get 1 result
    
    When I change the name of beta seven to seventeen
    And I wait for Sphinx to catch up
    And I search for seven
    Then I should get 1 result
    
    When I search for seventeen
    Then I should get 0 results
