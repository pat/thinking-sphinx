Feature: Delayed Delta Indexing
  In order to have delta indexing on frequently-updated sites
  Developers
  Should be able to create their own handlers for delta indexing
  
  Scenario: I specify a valid handler for delta indexing
    Given Sphinx is running
    When I change the name of extensible beta one to eleven
    Then the generic delta handler should handle the delta indexing