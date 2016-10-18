module Birdwatcher
  module Modules
    module Reporting
      class Json < Birdwatcher::Module
        self.meta = {
          :name        => "JSON Exporter",
          :description => "Export result from SQL query to a JSON file",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "DEST" => {
              :value       => nil,
              :description => "Destination file",
              :required    => true
            },
            "QUERY" => {
              :value       => nil,
              :description => "SQL query to execute",
              :required    => true
            },
            "PRETTY_FORMATTING" => {
              :value       => false,
              :description => "Output pretty formatted JSON",
              :required    => false,
              :boolean     => true
            }
          }
        }

        def self.info
<<-INFO
The JSON exporter can write the results of an SQL query to a file in JSON format.

#{'IMPORTANT:'.bold} The module does not limit the data returned from the query
to the currently active workspace, the query will need to take that in to
consideration if necessary.
INFO
        end

        def run
          result      = nil
          rows        = nil
          json        = nil
          destination = option_setting("DEST")
          task("Executing SQL query...") do
            begin
              result  = database[option_setting("QUERY")]
              rows    = result.map { |r| r.to_hash }
            rescue Sequel::DatabaseError => e
              error("Syntax error: #{e.message}")
              return false
            end
          end
          task("Generating JSON...") do
            if option_setting("PRETTY_FORMATTING")
              json = JSON.pretty_generate(rows)
            else
              json = JSON.generate(rows)
            end
          end
          task("Writing #{pluralize(rows.count, 'row', 'rows')} to file...") do
            File.open(destination, "w") do |f|
              f.write(json)
            end
          end
          file_size = number_to_human_size(File.size(destination))
          info("Wrote #{file_size.bold} to #{destination.bold}")
        end
      end
    end
  end
end
