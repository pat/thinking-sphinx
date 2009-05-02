Feature: Update attributes directly to Sphinx
  In order for updates to be more seamless
  The plugin
  Should update Sphinx's attributes where possible
  
  Scenario: Updating attributes in Sphinx without delta indexes
    Given Sphinx is running
    And I am searching on alphas
    When I filter by 3 on value
    Then I should get 1 result
    
    When I change the value of alpha two to 13
    And I wait for Sphinx to catch up    
    And I filter by 13 on value
    Then I should get 1 result
    
    When I change the value of alpha two to 3
    And I wait for Sphinx to catch up    
    And I filter by 13 on value
    Then I should get 0 results

  Scenario: Updating attributes in Sphinx with delta indexes
    Given Sphinx is running
    And I am searching on betas
    When I filter by 8 on value
    Then I should get 1 result
    
    When I change the value of beta eight to 18
    And I filter by 18 on value
    Then I should get 1 result
    
    When I search for the document id of beta eight in the beta_delta index
    Then it should not exist