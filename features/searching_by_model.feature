Feature: Searching on a single model
  In order to use Thinking Sphinx's core functionality
  A developer
  Should be able to search on a single model
  
  Scenario: Searching using a basic query
    Given Sphinx is running
    And I am searching on people
    When I search for James
    Then I should get 3 results
  
  Scenario: Searching on a specific field
    Given Sphinx is running
    And I am searching on people
    When I search for James on first_name
    Then I should get 2 results
  
  Scenario: Searching on multiple fields
    Given Sphinx is running
    And I am searching on people
    When I search for James on first_name
    And I search for Chamberlain on last_name
    Then I should get 1 result

  Scenario: Searching on association content
	  Given Sphinx is running
	  And I am searching on posts
	
	  When I search for "Waffles"
	  Then I should get 1 result

	  When I search for "Turtle"
	  Then I should get 1 result
  
  Scenario: Searching with a filter
    Given Sphinx is running
    And I am searching on alphas
    When I filter by 1 on value
    Then I should get 1 result
  
  Scenario: Searching with multiple filters
    Given Sphinx is running
    And I am searching on boxes
    When I filter by 2 on width
    And I filter by 2 on length
    Then I should get 1 result
  
  Scenario: Searching with a ranged time filter
    Given Sphinx is running
    And I am searching on people
    When I filter by birthday between 1975 and 1976
    Then I should get 16 results
    
  Scenario: Searching to filter multiple values on an MVA
    Given Sphinx is running
    And I am searching on boxes
    When I filter by 11 and 12 on dimensions
    Then I should get 2 results
    When I clear existing filters
    And I filter by both 11 and 12 on dimensions
    Then I should get 1 result
  
  Scenario: Searching by NULL/0 values in MVAs
    Given Sphinx is running
    And I am searching on boxes
    When I filter by 0 on dimensions
    Then I should get 1 result
    
    Given Sphinx is running
    And I am searching on developers
    When I clear existing filters
    And I filter by 0 on tag_ids
    Then I should get 1 result
  
  Scenario: Searching on a MVA configured as ranged_query
    Given Sphinx is running
    And I am searching on posts
    When I filter by 1 on comment_ids
    Then I should get 1 result
    When I clear existing filters
    And I filter by both 1 and 2 on comment_ids
    Then I should get 1 results
    When I clear existing filters
    And I filter by 10 on comment_ids
    Then I should get 0 results
  
  Scenario: Searching with ordering by attribute
    Given Sphinx is running
    And I am searching on alphas
    When I order by value
    Then I should get 10 results
    And the value of each result should indicate order
  
  Scenario: Searching with ordering on a sortable field
    Given Sphinx is running
    And I am searching on people
    And I order by first_name
    Then I should get 20 results
    And the first_name of each result should indicate order
  
  Scenario: Intepreting Sphinx Internal Identifiers
    Given Sphinx is running
    And I am searching on people
    Then I should get 20 results
    And each result id should match the corresponding sphinx internal id
  
  Scenario: Retrieving weightings
    Given Sphinx is running
    And I am searching on people
    When I search for "Ellie Ford"
    And I set match mode to any
    Then I can iterate by result and weighting
  
  Scenario: Retrieving group counts
    Given Sphinx is running
    And I am searching on people
    When I group results by the birthday attribute
    Then I can iterate by result and count
  
  Scenario: Retrieving group values
    Given Sphinx is running
    And I am searching on people
    When I group results by the birthday attribute
    Then I can iterate by result and group
  
  Scenario: Retrieving both group values and counts
    Given Sphinx is running
    And I am searching on people
    When I group results by the birthday attribute
    Then I can iterate by result and group and count
  
  Scenario: Searching for ids
    Given Sphinx is running
    And I am searching on people
    When I search for Ellie
    And I am searching for ids
    Then I should have an array of integers
  
  Scenario: Search results should match Sphinx's order
    Given Sphinx is running
    And I am searching on people
    When I search for Ellie
    And I order by "sphinx_internal_id DESC"
    Then searching for ids should match the record ids of the normal search results
  
  Scenario: Retrieving total result count when total is less than a page
    Given Sphinx is running
    And I am searching on people
    When I search for James
    And I am retrieving the result count
    Then I should get a value of 3

  Scenario: Retrieving total result count for more than a page
    Given Sphinx is running
    And I am searching on people
    When I am retrieving the result count
    Then I should get a value of 1000
  
  Scenario: Searching with Unicode Characters
    Given Sphinx is running
    And I am searching on people
    When I search for "José* "
    Then I should get 1 result

  Scenario: Searching by fields from HABTM joins
    Given Sphinx is running
    And I am searching on posts
    When I search for "Shakespeare"
    Then I should get 1 result
