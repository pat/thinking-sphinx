Feature: Checking whether Sphinx is running or not
  In order to avoid unnecessary errors
  Thinking Sphinx
  Should be able to determine whether Sphinx is running or not
  
  Scenario: Checking Sphinx's status
    Given Sphinx is running
    Then Sphinx should be running
    
    When I stop Sphinx
    And I wait for Sphinx to catch up
    Then Sphinx should not be running
    
    When I start Sphinx
    And I wait for Sphinx to catch up
    Then Sphinx should be running
    
    Given Sphinx is running
    When I kill the Sphinx process
    And I wait for Sphinx to catch up
    Then Sphinx should not be running