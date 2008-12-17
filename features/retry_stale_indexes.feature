Feature: Manually updating Sphinx indexes to handle uncaught deletions
  In order to keep indexes as up to date as possible
  Thinking Sphinx
  Should automatically update the indexes and retry the search if it gets a nil result
  
  Scenario: Changing retry_stale settings
    Given Sphinx is running
    And I am searching on gammas
    Then I should not get 0 results
    
    When I set retry stale to false
    And I set per page to 1
    And I order by "sphinx_internal_id ASC"
    And I destroy gamma one without callbacks
    Then I should get a single result of nil
    
    When I set retry stale to 1
    Then I should get a single gamma result with a name of two
    
    When I destroy gamma two without callbacks
    Then I should get a single result of nil
    
    When I set retry stale to true
    Then I should get a single gamma result with a name of three
