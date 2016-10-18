module Birdwatcher
  module Modules
    module Reporting
      class Csv < Birdwatcher::Module
        self.meta = {
          :name        => "CSV Exporter",
          :description => "Export result from SQL query to a CSV file",
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
            "HEADERS" => {
              :value       => true,
              :description => "Add CSV headers to the file",
              :required    => false,
              :boolean     => true
            }
          }
        }

        def self.info
<<-INFO
The CSV exporter can write the results of an SQL query to a file in CSV format.

#{'IMPORTANT:'.bold} The module does not limit the data returned from the query
to the currently active workspace, the query will need to take that in to
consideration if necessary.
INFO
        end

        def run
          result      = nil
          rows        = nil
          headers     = nil
          csv         = nil
          destination = option_setting("DEST")
          task("Executing SQL query...") do
            begin
              result  = database[option_setting("QUERY")]
              rows    = result.map { |r| r.to_hash.values }
              headers = result.columns.map { |c| c.to_s }
            rescue Sequel::DatabaseError => e
              error("Syntax error: #{e.message}")
              return false
            end
          end
          task("Generating CSV...") do
            csv = CSV.generate(:write_headers => option_setting("HEADERS"), :headers => headers) do |doc|
              rows.each { |r| doc << r }
            end
          end
          task("Writing #{pluralize(rows.count, 'row', 'rows')} to file...") do
            File.open(destination, "w") do |f|
              f.write(csv)
            end
          end
          file_size = number_to_human_size(File.size(destination))
          info("Wrote #{file_size.bold} to #{destination.bold}")
        end
      end
    end
  end
end
