Feature: Delayed Delta Indexing
  In order to have delta indexing on frequently-updated sites
  Developers
  Should be able to use delayed_job to handle delta indexes to lower system load
  
  Scenario: Delta Index should not fire automatically
    Given Sphinx is running
    And I am searching on delayed betas
    When I search for one
    Then I should get 1 result
  
    When I change the name of delayed beta one to eleven
    And I wait for Sphinx to catch up
    And I search for one
    Then I should get 1 result
    
    When I search for eleven
    Then I should get 0 results
  
  Scenario: Delta Index should fire when jobs are run
    Given Sphinx is running
    And I am searching on delayed betas
    When I search for one
    Then I should get 1 result
  
    When I change the name of delayed beta two to twelve
    And I wait for Sphinx to catch up
    And I search for twelve
    Then I should get 0 results
    
    When I run the delayed jobs
    And I wait for Sphinx to catch up
    And I search for twelve
    Then I should get 1 result
    
    When I search for two
    Then I should get 0 results