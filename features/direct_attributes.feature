Feature: Direct Attributes
  In order to avoid unnecessary SQL queries
  I want to access attribute values from Sphinx's response
  
  Scenario: Accessing attribute values directly
    Given Sphinx is running
    And I am searching on posts
    When I search
    Then the first result should have a comments count of 9

  
