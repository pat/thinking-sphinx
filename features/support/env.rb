require 'rubygems'
require 'cucumber'
require 'spec'
require 'fileutils'
require 'ginger'
require 'will_paginate'

$:.unshift File.dirname(__FILE__) + '/../../lib'

require 'thinking_sphinx'
require 'cucumber/thinking_sphinx/internal_world'

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.setup
