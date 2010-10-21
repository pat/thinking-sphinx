Feature: Generate excerpts for search results
  
  Scenario: Basic Excerpts Syntax
    Given Sphinx is running
    And I am searching on comments
    And I search for "lorem punto"
    Then the content excerpt of the first result is "de un sitio mientras que mira su diseño. El <span class="match">punto</span> de usar <span class="match">Lorem</span> Ipsum es que tiene una distribución"
  
  Scenario: Integrated Excerpts Syntax
    Given Sphinx is running
    And I am searching on comments
    And I search for "lorem"
    Then calling content on the first result excerpts object should return "de un sitio mientras que mira su diseño. El punto de usar <span class="match">Lorem</span> Ipsum es que tiene una distribución"

  Scenario: Excerpt Options
    Given Sphinx is running
    And I am searching on comments
    And I search for "lorem"
    And I provide excerpt option "before_match" with value "<em>"
    And I provide excerpt option "after_match" with value "</em>"
    Then calling content on the first result excerpts object should return "de un sitio mientras que mira su diseño. El punto de usar <em>Lorem</em> Ipsum es que tiene una distribución"
