Feature: Datetime Delta Indexing
  In order to have delta indexing on frequently-updated sites
  Developers
  Should be able to use an existing datetime column to track changes
  
  Scenario: Delta Index should not fire automatically
    Given Sphinx is running
    And I am searching on thetas
    When I search for one
    Then I should get 1 result
  
    When I change the name of theta one to eleven
    And I wait for Sphinx to catch up
    And I search for one
    Then I should get 1 result
    
    When I search for eleven
    Then I should get 0 results
  
  Scenario: Delta Index should fire when jobs are run
    Given Sphinx is running
    And I am searching on thetas
    When I search for one
    Then I should get 1 result
  
    When I change the name of theta two to twelve
    And I wait for Sphinx to catch up
    And I search for twelve
    Then I should get 0 results
    
    When I index the theta datetime delta
    And I wait for Sphinx to catch up
    And I search for twelve
    Then I should get 1 result
    
    When I search for two
    Then I should get 0 results
  
  Scenario: New records should be merged into the core index
    Given Sphinx is running
    And I am searching on thetas
    When I search for thirteen
    Then I should get 0 results
    
    When I create a new theta named thirteen
    And I search for thirteen
    Then I should get 0 results
    
    When I index the theta datetime delta
    And I wait for Sphinx to catch up
    And I search for thirteen
    Then I should get 1 result
    
    When I search for the specific id of 107 in the theta_core index
    Then it should exist