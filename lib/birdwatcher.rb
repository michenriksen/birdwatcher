require "singleton"
require "yaml"
require "sequel"
require "twitter"
require "colorize"
require "thread/pool"
require "httparty"
require "terminal-table"
require "highline/import"
require "tty-pager"
require "sentimental"
require "graphviz"
require "chronic"
require "magic_cloud"
require "cairo"
require "birdwatcher/version"
require "birdwatcher/util"
require "birdwatcher/http_client"
require "birdwatcher/klout_client"
require "birdwatcher/punchcard"
require "birdwatcher/kml"
require "birdwatcher/console"
require "birdwatcher/configuration"
require "birdwatcher/configuration_wizard"

Dir[File.join(File.dirname(__FILE__), "birdwatcher", "concerns", "*.rb")].each do |file|
  require file
end

require "birdwatcher/command"
require "birdwatcher/module"

Dir[File.join(File.dirname(__FILE__), "birdwatcher", "commands", "*.rb")].each do |file|
  require file
end

Dir[File.join(File.dirname(__FILE__), "birdwatcher", "modules", "**/*.rb")].each do |file|
  require file
end

module Birdwatcher
  # Your code goes here...
end
