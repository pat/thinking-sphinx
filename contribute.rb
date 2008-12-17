#!/usr/bin/env ruby

module ContributeHelper; end

class Contribute
  include ContributeHelper

  def show
    show_welcome_screen
    
    (
      check_for_mysql_gem            &&
      create_database_yaml           &&
      check_mysql_gem_is_working     &&
      create_test_database
    ) || exit(1)
    
    show_done_screen
  end

private
WELCOME_SCREEN = <<-EO_WELCOME
  <banner>Thinking Sphinx Contribution</banner>

Thanks for contributing to Thinking Sphinx.

In this script we'll help you get started contributing to Thinking Sphinx
EO_WELCOME

  def show_welcome_screen
    colour_puts WELCOME_SCREEN
  end

  def show_done_screen
    puts "done!"
  end

  # check / install mysql gem
  def check_for_mysql_gem
    puts "check_for_mysql_gem"
    true
  end

  def check_mysql_gem_is_working
    puts "check_mysql_gem_is_working"
    false
  end

  # create database.yml
  def create_database_yaml
    puts "create_database_yaml"
    false
  end

  # create test db
  def create_test_database
    puts "create_test_database"
    false
  end
end

module ContributeHelper
  DEFAULT_TERMINAL_COLORS = "\e[0m\e[37m\e[40m"
  def subs_colour(data)

  	data = data.gsub(%r{<b>(.*?)</b>}m, "\e[1m\\1#{DEFAULT_TERMINAL_COLORS}")
  	data.gsub!(%r{<red>(.*?)</red>}m, "\e[1m\e[31m\\1#{DEFAULT_TERMINAL_COLORS}")
  	data.gsub!(%r{<green>(.*?)</green>}m, "\e[1m\e[32m\\1#{DEFAULT_TERMINAL_COLORS}")
  	data.gsub!(%r{<yellow>(.*?)</yellow>}m, "\e[1m\e[33m\\1#{DEFAULT_TERMINAL_COLORS}")
  	data.gsub!(%r{<banner>(.*?)</banner>}m, "\e[33m\e[44m\e[1m\\1#{DEFAULT_TERMINAL_COLORS}")
  	
  	return data
  end
  
  def colour_puts(text)
    puts subs_colour(text)
  end
end

Contribute.new.show