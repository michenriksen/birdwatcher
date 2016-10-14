module Birdwatcher
  module Commands
    class Irb < Birdwatcher::Command
      self.meta = {
        :description => "Start an interactive Ruby shell",
        :names       => %w(irb),
        :usage       => "irb"
      }

     def self.detailed_usage
<<-USAGE
The #{'irb'.bold} command can be used start an interactive Ruby shell (IRB) with
all of the Birdwatcher classes and models loaded.

#{'NOTE:'.bold} This command is not intended for normal users of Birdwatcher but
can be convenient for debugging or more complex one-off data manipulation, if you
know what you're doing.

#{'USAGE:'.bold}

#{'Start an interactive Ruby shell:'.bold}
  irb
USAGE
      end

      def run
        require "irb"
        require "awesome_print"
        AwesomePrint.irb!
        suppress_warnings { IRB.start }
      end
    end
  end
end
