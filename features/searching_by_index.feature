Feature: Searching within a single index
  In order to use Thinking Sphinx's core functionality
  A developer
  Should be able to search on a single index

  Scenario: Searching with alternative index
    Given Sphinx is running
    And I am searching on alphas
    When I order by value
    And I use index alternative_core
    Then I should get 7 results

  Scenario: Searching with default index
    Given Sphinx is running
    And I am searching on alphas
    When I order by value
    And I use index alpha_core
    Then I should get 10 results

  Scenario: Searching without specified index
    Given Sphinx is running
    And I am searching on alphas
    When I order by value
    Then I should get 10 results

  Scenario: Deleting instances from the core index
    Given Sphinx is running
    And I am searching on alphas

    When I create a new alpha named eleven
    And I process the alpha_core index
    And I process the alternative_core index
    And I wait for Sphinx to catch up
    And I clear the connection pool
    And I search for eleven
    Then I should get 1 result

    When I destroy alpha eleven
    And I wait for Sphinx to catch up
    And I search for eleven
    Then I should get 0 results
