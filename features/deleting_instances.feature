Feature: Keeping Sphinx in line with deleted model instances
  In order to avoid deleted items being returned by Sphinx
  Thinking Sphinx
  Should keep deleted items out of search results

  Scenario: Deleting instances from the core index
    Given Sphinx is running
    And I am searching on betas
    When I search for three
    Then I should get 1 result

    When I destroy beta three
    And I wait for Sphinx to catch up
    And I search for three
    Then I should get 0 results

  Scenario: Deleting subclasses when the parent class is indexed
    Given Sphinx is running
    And I am searching on cats
    When I search for moggy
    Then I should get 1 result

    When I destroy cat moggy
    And I wait for Sphinx to catch up
    And I search for moggy
    Then I should get 0 results

  Scenario: Deleting created instances from the delta index
    Given Sphinx is running
    And I am searching on betas
    When I create a new beta named eleven
    And I wait for Sphinx to catch up
    And I clear the connection pool
    And I search for eleven
    Then I should get 1 result

    When I destroy beta eleven
    And I wait for Sphinx to catch up
    And I search for eleven
    Then I should get 0 results

  Scenario: Deleting edited instances from the delta index
    Given Sphinx is running
    And I am searching on betas
    When I change the name of beta four to fourteen
    And I wait for Sphinx to catch up
    And I clear the connection pool
    And I search for fourteen
    Then I should get 1 result

    When I destroy beta fourteen
    And I wait for Sphinx to catch up
    And I search for fourteen
    Then I should get 0 results

  Scenario: Deleting created instances from the delta index when deltas are disabled
    Given Sphinx is running
    And I am searching on betas
    When I create a new beta named thirteen
    And I wait for Sphinx to catch up
    And I clear the connection pool
    And I search for thirteen
    Then I should get 1 result

    And I disable delta updates
    And I destroy beta thirteen
    And I wait for Sphinx to catch up
    And I enable delta updates
    And I search for thirteen
    Then I should get 0 results
