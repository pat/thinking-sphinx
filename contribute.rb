#!/usr/bin/env ruby

require 'rubygems'
module ContributeHelper; end

class Contribute
  include ContributeHelper
  
  def dependencies
    [
      Dependencies::Sphinx,
      Dependencies::Mysql,
      Dependencies::Ginger
    ]
  end

  def show
    show_welcome_screen
    
    (
      check_for_dependencies         &&
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
  
  def check_for_dependencies
    colour_puts "<banner>Checking for required software</banner>"
    puts
    
    all_found = true
    
    dependencies.each do |klass|
      dep = klass.new
      print " * #{dep.name}... "
      dep.check!
      
      if dep.found?
        if dep.location
          colour_puts "<green>found at #{dep.location}</green>"
        else
          colour_puts "<green>found</green>"
        end
      else
        all_found &= false
        colour_puts "<red>not found</red>"
      end
    end
    
    puts
    
    all_found
  end

  def check_mysql_is_working
    colour_puts "<banner>check mysql gem is working</banner>"
    false
  end

  # create database.yml
  def create_database_yaml
    colour_puts "<banner>creating database yaml</banner>"
    false
  end

  # create test db
  def create_test_database
    colour_puts "<banner>create test database</banner>"
    false
  end
end

module ContributeHelper
  class Dependency
    def self.name(name=nil)
      if name then @name = name else @name end
    end
    
    attr_reader :location
    
    def initialize
      @found = false
      @location = nil
    end
    
    def name; self.class.name end
    
    def check; false end
    def check!
      @found = check 
    end
    
    def found?
      @found
    end
  end
  
  class Gem < Dependency
    def gem_name; self.class.name end
    def name; "#{super} gem" end
    
    def check
      ::Gem.available? self.gem_name
    end
  end
  
  
  
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

module Dependencies
  class Mysql < ContributeHelper::Gem
    name 'mysql'
  end
  
  class Ginger < ContributeHelper::Gem
    name 'ginger'
  end
  
  class Sphinx < ContributeHelper::Dependency
    name 'sphinx'
    
    def check
      output = `which searchd`
      @location = output.chomp if $? == 0
      $? == 0
    end
  end
end

Contribute.new.show