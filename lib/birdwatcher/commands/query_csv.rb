module Birdwatcher
  module Commands
    class QueryCsv < Birdwatcher::Command
      self.meta = {
        :description => "Execute SQL query and return result as CSV",
        :names       => %w(query_csv csv),
        :usage       => "query_csv QUERY"
      }

      def self.detailed_usage
<<-USAGE
The #{'query_csv'.bold} command can be used to execute raw SQL queries against the
underlying database for Birdwatcher. The query results will be shown in CSV format
for easy parsing by other tools or code.

#{'IMPORTANT:'.bold} The query_csv command does not automatically isolate the data
to the current workspace so queries will need to handle that on their own.
Most tables will have a column called #{'workspace_id'.bold} which will contain
the numeric ID of the workspace the object belongs to.

#{'USAGE EXAMPLES:'.bold}

#{'See current workspaces:'.bold}
  query_csv SELECT * from workspaces ORDER BY name

#{'See geo coordinates for all statuses in a workspace:'.bold}
  query_csv SELECT longitude,latitude FROM statuses WHERE geo IS TRUE AND workspace_id = 1

#{'See statuses containing the word "password":'.bold}
  query_csv SELECT u.screen_name, s.text, s.posted_at FROM users AS u JOIN statuses AS s ON s.user_id = u.id WHERE s.text LIKE '%password%'

#{'See status geographic places by frequency:'.bold}
  query_csv SELECT COUNT(*) AS count, place_name FROM statuses WHERE place_name IS NOT NULL GROUP BY place_name ORDER BY count DESC
USAGE
      end

      def run
        if !arguments?
          error("You must provide an SQL query to execute")
          return false
        end

        query   = arguments.join(" ")
        result  = database[query]
        rows    = result.map { |r| r.to_hash.values }
        headers = result.columns.map { |c| c.to_s }
        csv = CSV.generate(:write_headers => true, :headers => headers) do |doc|
          rows.each { |r| doc << r }
        end
        page_text(csv)
      rescue Sequel::DatabaseError => e
        error("Syntax error: #{e.message}")
      end
    end
  end
end
