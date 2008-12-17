Feature: Keeping AR::Base.find arguments in search calls
  To keep things as streamlined as possible
  Thinking Sphinx
  Should respect particular arguments to AR::Base.find calls
  
  Scenario: Respecting the include option
    Given Sphinx is running
    And I am searching on posts
    Then I should get 1 result
    
    When I get the first comment
    And I track queries
    And I compare comments
    Then I should have 1 query
    
    When I include comments
    Then I should get 1 result
    When I track queries
    And I compare comments
    Then I should have 0 queries
  
  Scenario: Respecting the include option without using a specific model
    Given Sphinx is running
    And I search for "Hello World"
    Then I should get 1 result

    When I get the first comment
    And I track queries
    And I compare comments
    Then I should have 1 query

    When I include comments
    Then I should get 1 result
    When I track queries
    And I compare comments
    Then I should have 0 queries
  
  Scenario: Respecting the select option
    Given Sphinx is running
    And I am searching on posts
    Then I should get 1 result
    And I should not get an error accessing the subject
    
    When I select only content
    Then I should get 1 result
    And I should get an error accessing the subject
  
  Scenario: Respecting the select option without using a specific model
    Given Sphinx is running
    When I search for "Hello World"
    Then I should get 1 result
    And I should not get an error accessing the subject

    When I select only content
    Then I should get 1 result
    And I should get an error accessing the subject