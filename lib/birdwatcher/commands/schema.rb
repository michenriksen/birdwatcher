module Birdwatcher
  module Commands
    class Schema < Birdwatcher::Command
      self.meta = {
        :description => "Show schema for database table",
        :names       => %w(schema table),
        :usage       => "schema [TABLE_NAME]"
      }

      def self.detailed_usage
<<-USAGE
The #{'schema'.bold} command can be used to get schema information on tables in
the database.

#{'USAGE:'.bold}

#{'List all available tables:'.bold}
  schema

#{'See columns, indexes and foreign keys on a table:'.bold}
  schema statuses
USAGE
      end

      def run
        if !arguments?
          tables = database.tables.sort
          output_available_tables(tables)
          return
        end
        table  = arguments.first.strip
        tables = database.tables.sort.map(&:to_s)
        if !tables.include?(table)
          error("Unknown table: #{table.bold}")
          newline
          output_available_tables(tables)
          return false
        end
        schema       = database.schema(table.to_sym)
        indexes      = database.indexes(table.to_sym)
        foreign_keys = database.foreign_key_list(table.to_sym)
        info("Schema information for table #{table.bold}:")
        newline
        output_schema_table(schema)
        newline
        info("Indexes on table #{table.bold}:")
        newline
        output_index_table(indexes)
        newline
        info("Foreign keys on table #{table.bold}:")
        newline
        output_foreign_key_table(foreign_keys)
        newline
      end

      private

      def output_available_tables(tables)
        info("Available tables:")
        newline
        tables.each do |table|
          output " * #{table.to_s.bold}"
        end
        newline
      end

      def output_schema_table(schema)
        table_rows = []
        schema.each do |column|
          name, attr = column
          table_rows << [
            name,
            attr[:db_type],
            (attr[:default] ? attr[:default] : "NULL"),
            (attr[:allow_null] ? "Yes" : "No"),
            (attr[:primary_key] ? "Yes" : "No"),
          ]
        end
        output Terminal::Table.new(
          :headings => ["Column Name", "Type", "Default", "Allow NULL", "Primary Key"].map(&:bold),
          :rows     => table_rows
        )
      end

      def output_index_table(indexes)
        table_rows = []
        indexes.each_pair do |name, index|
          table_rows << [
            name.to_s,
            index[:columns].map(&:to_s).join(", "),
            (index[:unique] ? "Yes" : "No")
          ]
        end
        output Terminal::Table.new(
          :headings => ["Index Name", "Column(s)", "Unique"].map(&:bold),
          :rows     => table_rows
        )
      end

      def output_foreign_key_table(foreign_keys)
        table_rows = []
        foreign_keys.each do |foreign_key|
          table_rows << [
            foreign_key[:columns].map(&:to_s).join(", "),
            foreign_key[:table].to_s,
            foreign_key[:key].map(&:to_s).join(", ")
          ]
        end
        output Terminal::Table.new(
          :headings => ["Column(s)", "Referenced Table", "Referenced Column(s)"].map(&:bold),
          :rows     => table_rows
        )
      end
    end
  end
end
