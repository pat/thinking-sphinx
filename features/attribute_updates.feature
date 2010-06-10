Feature: Update attributes directly to Sphinx
  In order for updates to be more seamless
  The plugin
  Should update Sphinx's attributes where possible
  
  Scenario: Updating attributes in Sphinx without delta indexes
    Given Sphinx is running
    And I am searching on alphas
    When I filter by 3 on value
    Then I should get 1 result
    
    When I change the value of alpha four to 13
    And I wait for Sphinx to catch up
    And I filter by 13 on value
    And I use index alpha_core
    Then I should get 1 result
    When I use index alternative_core
    Then I should get 1 result
    
    When I change the value of alpha four to 4
    And I wait for Sphinx to catch up
    And I filter by 13 on value
    And I use index alpha_core
    Then I should get 0 results
    When I use index alternative_core
    Then I should get 0 result

  Scenario: Updating attributes in Sphinx with delta indexes
    Given Sphinx is running
    And I am searching on betas
    When I filter by 8 on value
    Then I should get 1 result
    
    When I change the value of beta eight to 18
    And I wait for Sphinx to catch up
    And I filter by 18 on value
    Then I should get 1 result
    
    When I search for the document id of beta eight in the beta_delta index
    Then it should not exist
  
  Scenario: Updating attributes in a delta index
    Given Sphinx is running
    And I am searching on betas
    
    When I change the name of beta nine to nineteen
    And I change the value of beta nineteen to 19
    And I wait for Sphinx to catch up
    
    When I filter by 19 on value
    And I use index beta_delta
    Then I should get 1 result
  
  Scenario: Updating boolean attribute in Sphinx
    Given Sphinx is running
    And I am searching on alphas
    When I filter by active alphas
    Then I should get 10 results
    
    When I flag alpha five as inactive
    And I wait for Sphinx to catch up
    And I filter by active alphas
    Then I should get 9 results
