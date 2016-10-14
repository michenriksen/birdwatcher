module Birdwatcher
  module Modules
    module Users
      class KloutScore < Birdwatcher::Module
        self.meta = {
          :name        => "User Klout Score",
          :description => "Enrich users with their Klout score",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "THREADS" => {
              :value       => 5,
              :description => "Number of concurrent threads",
              :required    => false
            }
          }
        }

        def self.info
<<-INFO
The User Klout Score module can be used to retrieve the Klout Score of all users
in the currently active workspace.

The Klout score is a score between 1-100 and represents a user's influence. The
more influential a user is, the higher their Klout score. Read more about how it
works here: https://klout.com/corp/score

#{'Note:'.bold} This module requires that users have been enriched with their
Klout ID from the #{'users/klout_id'.bold} module. It also requires that Birdwatcher has
been configured with one or more Klout API keys in order to work.
INFO
        end

        def run
          if !klout_client
            error("Birdwatcher has not been configured with any Klout API keys")
            return false
          end
          users = current_workspace.users_dataset.where("klout_id IS NOT NULL").order(:screen_name)
          if users.empty?
            error("There are no users with Klout IDs")
            return false
          end
          threads = thread_pool(option_setting("THREADS").to_i)
          users.each do |user|
            threads.process do
              begin
                if klout_score = klout_client.get_score(user.klout_id)
                  user.klout_score = klout_score
                  info("User #{user.screen_name.bold} has a Klout score of #{klout_score.to_s.bold}")
                else
                  error("Could not get Klout score for #{user.screen_name.bold}")
                end
                user.save
              rescue => e
                error("Processing of #{user.screen_name.bold} failed (#{e.class})")
              end
            end
          end
          threads.shutdown
        end
      end
    end
  end
end
