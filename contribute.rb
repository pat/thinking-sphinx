#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'pp'

begin
  require 'Win32/Console/ANSI' if RUBY_PLATFORM =~ /mswin/
rescue LoadError
end

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-g [NAME]", "--ginger [NAME]", "Ginger gem name") do |name|
    options[:ginger] = name
  end

  opts.on("-s [NAME]", "--sphinx [NAME]", "Sphinx daemon name") do |name|
    options[:sphinx] = name
  end
end.parse!

OPTIONS = options

module ContributeHelper; end

class Contribute
  include ContributeHelper

  def dependencies
    [
      Dependencies::Sphinx,
      Dependencies::Mysql,
      Dependencies::AR,
      Dependencies::Rspec,
      Dependencies::Cucumber,
      Dependencies::Yard,
      Dependencies::Jeweler,
      Dependencies::Ginger,
    ]
  end

  def show
    show_welcome_screen

    (
      check_for_dependencies   &&
      create_database_yaml     &&
      check_mysql_is_working   &&
      create_test_database
    ) || exit(1)

    show_done_screen
  end

private
WELCOME_SCREEN = <<-EO_WELCOME
<banner>Thinking Sphinx Contribution</banner>

Thanks for contributing to Thinking Sphinx.

In this script we'll help you get setup to hack:

 <b>1.</b> We'll check that you have the right software installed and running.
 <b>2.</b> We'll set up the test database for specs to run against.

EO_WELCOME

DONE_SCREEN = <<-EO_DONE
<banner>Setup done!</banner>

All done! Now you can start hacking by running

  <b>rake spec</b>

EO_DONE

REVIEW_YAML = <<-EO_REVIEW_YAML

Please review the database details in the yaml file details before continuing.

This file is used by the specs to connect to the database.

Current details:
EO_REVIEW_YAML



MYSQL_FAILED = <<-EO_MYSQL_FAILED

Looks like we couldn't successfully talk to the mysql database.

Don't worry though...

EO_MYSQL_FAILED

CREATE_DATABASE_FAILED = <<-EO_CREATE_DATABASE_FAILED

Looks like we couldn't create a test database to work against.

Don't worry though...

EO_CREATE_DATABASE_FAILED

  def show_welcome_screen
    colour_puts WELCOME_SCREEN
    wait!
  end

  def show_done_screen
    colour_puts DONE_SCREEN
  end

  # create database.yml
  def create_database_yaml
    colour_puts "<banner>creating database yaml</banner>"
    puts


    config = {
          'username' => 'root',
          'password' => nil,
          'host'     => 'localhost'
        }


    colour_print " * <b>#{db_yml}</b>... "
    unless File.exist?(db_yml)
      open(db_yml,'w') {|f| f << config.to_yaml}
      colour_puts "<green>created</green>"
    else
      config = YAML.load_file(db_yml)
      colour_puts "<green>already exists</green>"
    end

    colour_puts REVIEW_YAML

    config.each do |(k,v)|
      colour_puts " * <b>#{k}</b>: #{v}"
    end

    puts

    wait!
    true
  end

  def check_mysql_is_working
    require 'activerecord'
    colour_puts "<banner>check mysql is working</banner>"
    puts

    connect_to_db

    print " * connecting to mysql... "

    begin
      ActiveRecord::Base.connection.select_value('select sysdate() from dual')

      colour_puts "<green>successful</green>"
      puts

      return true
    rescue defined?(JRUBY_VERSION) ? Java::JavaSql::SQLException : Mysql::Error
      colour_puts "<red>failed</red>"

      puts MYSQL_FAILED
    end

    false
  end

  # create test db
  def create_test_database
    colour_puts "<banner>create test database</banner>"
    puts

    connect_to_db

    colour_print " * <b>creating thinking_sphinx database</b>... "
    begin
      ActiveRecord::Base.connection.create_database('thinking_sphinx')
      colour_puts "<green>successful</green>"
      puts
      return true
    rescue ActiveRecord::StatementInvalid
      if $!.message[/database exists/]
        colour_puts "<green>successful</green> (database already existed)"
        puts
        return true
      else
        colour_puts "<red>failed</red>"
        colour_puts CREATE_DATABASE_FAILED
      end
    end

    false
  end

  # project
  def ts_root
    File.expand_path(File.dirname(__FILE__))
  end

  def specs
    ts_root / 'spec'
  end

  def db_yml
    specs / 'fixtures' / 'database.yml'
  end

  def mysql_adapter
    defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql'
  end

  def connect_to_db
    config = YAML.load_file(db_yml)
    config.update(:adapter => mysql_adapter)
    config.symbolize_keys!

    ActiveRecord::Base.establish_connection(config)
  end
end







class String
  def /(other)
    "#{self}/#{other}"
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

    if !all_found
      print "You may wish to try setting additional options. Use ./contribute.rb -h for details"
      puts
    end

    all_found
  end

  def colourise_output?
    @colourise_output = !!(RUBY_PLATFORM !~ /mswin/ || defined?(Win32::Console::ANSI)) if @colourise_output.nil?
    @colourise_output
  end

  DEFAULT_TERMINAL_COLORS = "\e[0m\e[37m\e[40m"
  MONOCHROME_OUTPUT = "\\1"
  def subs_colour(data)
    data = data.gsub(%r{<b>(.*?)</b>}m, colourise_output? ? "\e[1m\\1#{DEFAULT_TERMINAL_COLORS}" : MONOCHROME_OUTPUT)
    data.gsub!(%r{<red>(.*?)</red>}m, colourise_output? ? "\e[1m\e[31m\\1#{DEFAULT_TERMINAL_COLORS}" : MONOCHROME_OUTPUT)
    data.gsub!(%r{<green>(.*?)</green>}m, colourise_output? ? "\e[1m\e[32m\\1#{DEFAULT_TERMINAL_COLORS}" : MONOCHROME_OUTPUT)
    data.gsub!(%r{<yellow>(.*?)</yellow>}m, colourise_output? ? "\e[1m\e[33m\\1#{DEFAULT_TERMINAL_COLORS}" : MONOCHROME_OUTPUT)
    data.gsub!(%r{<banner>(.*?)</banner>}m, colourise_output? ? "\e[33m\e[44m\e[1m\\1#{DEFAULT_TERMINAL_COLORS}" : MONOCHROME_OUTPUT)

    return data
  end

  def colour_puts(text)
    puts subs_colour(text)
  end

  def colour_print(text)
    print subs_colour(text)
  end


  def wait!
    colour_puts "<b>Hit Enter to continue, or Ctrl-C to quit.</b>"
    STDIN.readline
  rescue Interrupt
    exit!
  end
end

module Dependencies
  class Mysql < ContributeHelper::Gem
    name(defined?(JRUBY_VERSION) ? 'jdbc-mysql' : 'mysql')
  end
  
  class Rspec < ContributeHelper::Gem
    name 'rspec'
  end

  class Cucumber < ContributeHelper::Gem
    name 'cucumber'
  end

  class Yard < ContributeHelper::Gem
    name 'yard'
  end

  class Jeweler < ContributeHelper::Gem
    name 'jeweler'
  end

  class AR < ContributeHelper::Gem
    name 'activerecord'
  end

  class Ginger < ContributeHelper::Gem
    name(OPTIONS.has_key?(:ginger) ? OPTIONS[:ginger] : 'ginger')
  end

  class Sphinx < ContributeHelper::Dependency
    name 'sphinx'

    def check
      app_name = OPTIONS.has_key?(:sphinx) ? OPTIONS[:sphinx] : 'searchd'
      app_name << '.exe' if RUBY_PLATFORM =~ /mswin/ && app_name[-4, 4] != '.exe'

      !(@location = ENV['PATH'].split(File::PATH_SEPARATOR).map { |path| File.join(path, app_name) }.find { |path| File.file?(path) && File.executable?(path) }).nil?
    end
  end
end

Contribute.new.show
