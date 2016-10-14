module Birdwatcher
  module Commands
    class Query < Birdwatcher::Command
      self.meta = {
        :description => "Execute SQL query",
        :names       => %w(query sql),
        :usage       => "query QUERY"
      }

      def self.detailed_usage
<<-USAGE
The #{'query'.bold} command can be used to execute raw SQL queries against the
underlying database for Birdwatcher. The query results will be shown in a formatted
table.

#{'IMPORTANT:'.bold} The query command does not automatically isolate the data
to the current workspace so queries will need to handle that on their own.
Most tables will have a column called #{'workspace_id'.bold} which will contain
the numeric ID of the workspace the object belongs to.

For a more machine-parsable query result, please see the #{'query_csv'.bold} command.

#{'USAGE EXAMPLES:'.bold}

#{'See current workspaces:'.bold}
  query SELECT * from workspaces ORDER BY name

#{'See geo coordinates for all statuses in a workspace:'.bold}
  query SELECT longitude,latitude FROM statuses WHERE geo IS TRUE AND workspace_id = 1

#{'See statuses containing the word "password":'.bold}
  query SELECT u.screen_name, s.text, s.posted_at FROM users AS u JOIN statuses AS s ON s.user_id = u.id WHERE s.text LIKE '%password%'

#{'See status geographic places by frequency:'.bold}
  query SELECT COUNT(*) AS count, place_name FROM statuses WHERE place_name IS NOT NULL GROUP BY place_name ORDER BY count DESC
USAGE
      end

      def run
        if !arguments?
          error("You must provide an SQL query to execute")
          return false
        end

        query  = arguments.join(" ")
        result = database[query]
        rows   = result.map { |r| r.to_hash.values }
        table  = Terminal::Table.new(
          :headings => result.columns.map { |c| c.to_s.bold },
          :rows     => rows
        ).to_s
        page_text(table)
      rescue Sequel::DatabaseError => e
        error("Syntax error: #{e.message}")
      end
    end
  end
end
