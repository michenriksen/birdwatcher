module Birdwatcher
  module Modules
    module Users
      class Import < Birdwatcher::Module
        self.meta = {
          :name        => "User Importer",
          :description => "Import users from a file containing screen names.",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "FILE" => {
              :value       => nil,
              :description => "File to read screen names from.",
              :required    => true
            }
          }
        }

        def self.info
<<-INFO
The User Importer module is a simple module to add a large number of users to
the currently active workspace by parsing a file containing screen names.

The file is expected to contain one screen name per line, without the @ sign or
https://twitter.com/ in front of them.
INFO
        end

        def run
          filename = File.expand_path(option_setting("FILE"))
          if !File.exists?(filename)
            error("File #{filename.bold} does not exist")
            return false
          end
          if !File.readable?(filename)
            error("File #{filename.bold} is not readable")
            return false
          end
          threads = thread_pool
          File.read(filename).each_line do |screen_name|
            threads.process do
              begin
                screen_name.strip!
                next if screen_name.empty?
                if current_workspace.users_dataset.first(:screen_name => screen_name)
                  info("User #{screen_name.bold} is already in the workspace")
                  next
                end
                user = twitter_client.user(screen_name)
                save_user(user)
                info("Added #{screen_name.bold} to workspace")
              rescue Twitter::Error::NotFound
                error("There is no user with screen name: #{screen_name.bold}")
              end
            end
          end
          threads.shutdown
        end
      end
    end
  end
end
