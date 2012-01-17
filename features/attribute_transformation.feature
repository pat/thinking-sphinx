Feature: Handle not-quite-supported column types as attributes
  In order for Thinking Sphinx to be more understanding with model structures
  The plugin
  Should be able to use translatable columns as attributes

  Scenario: Decimals as floats
    Given Sphinx is running
    And I am searching on alphas
    When I filter between 1.0 and 3.0 on cost
    Then I should get 2 results

  Scenario: Dates as Datetimes
    Given Sphinx is running
    And I am searching on alphas
    When I filter between 2 and 4 days ago on created_on by date
    Then I should get 2 results

  Scenario: Timestamps as Datetimes
    Given Sphinx is running
    And I am searching on alphas
    When I filter between 2 and 4 days ago on created_at
    Then I should get 2 results