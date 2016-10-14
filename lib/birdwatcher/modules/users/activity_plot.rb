module Birdwatcher
  module Modules
    module Statuses
      class ActivityPlot < Birdwatcher::Module
        self.meta = {
          :name        => "Activity Plot",
          :description => "Generates punchcard plot of a user's activity",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "DEST" => {
              :value       => nil,
              :description => "Destination file",
              :required    => true
            },
            "USER" => {
              :value       => nil,
              :description => "Screen name of user to analyze",
              :required    => true
            },
            "ONLY_REPLIES" => {
              :value       => false,
              :description => "Only plot when the user replies to other users",
              :required    => false,
              :boolean     => true
            }
          }
        }

        def self.info
<<-INFO
The Activity Plot module can generate a punchcard plot of when a user is the
most engaged with Twitter. The plot can be used to find the most likely time
(day and hour) where a user will engage with Twitter content.

The generated file is in PNG format.
INFO
        end

        def run
          if !user = current_workspace.users_dataset.first(:screen_name => option_setting("USER"))
            error("User #{screen_name.bold} was not found in workspace")
            return false
          end
          if option_setting("ONLY_REPLIES")
            timestamps = user.statuses_dataset.where("text LIKE '@%'").map(&:posted_at)
          else
            timestamps = user.statuses.map(&:posted_at)
          end
          if timestamps.empty?
            error("There are no statuses to process")
            return false
          end
          punchcard = Birdwatcher::Punchcard.new(timestamps)
          task("Generating activity plot from #{timestamps.count.to_s.bold} statuses...") do
            punchcard.generate(option_setting("DEST"))
          end
          info("Activity plot written to #{option_setting('DEST').bold}")
        end
      end
    end
  end
end
