module Birdwatcher
  class ConfigurationWizard
    def start!
      configuration = gather_configuration
    end

    private

    def gather_configuration
      Birdwatcher::Console.instance.info("Starting configuration wizard.\n")
      configuration = {
        "database_connection_uri" => gather_database_connection_uri,
        "twitter"                 => gather_twitter_keys,
        "klout"                   => gather_klout_keys
      }
      Birdwatcher::Configuration.save!(configuration)
      Birdwatcher::Console.instance.newline
      Birdwatcher::Console.instance.info("Configuration saved to #{Birdwatcher::Configuration::CONFIGURATION_FILE_LOCATION.bold}")
    end

    def gather_database_connection_uri
      hostname = HighLine.ask("Enter PostgreSQL hostname: ") do |q|
        q.default = "localhost"
      end
      port = HighLine.ask("Enter PostgreSQL port: |5432| ", Integer) do |q|
        q.default = 5432
        q.in = 1..65_535
      end
      username = HighLine.ask("Enter PostgreSQL username: ") do |q|
        q.default = "birdwatcher"
      end
      password = HighLine.ask("Enter PostgreSQL password (masked): ") do |q|
        q.echo = "x"
      end
      database = HighLine.ask("Enter PostgreSQL database name: ") do |q|
        q.default = "birdwatcher"
      end
      "postgres://#{username}:#{password}@#{hostname}:#{port}/#{database}"
    end

    def gather_twitter_keys
      keys = []
      begin
        consumer_key    = HighLine.ask("Enter Twitter consumer key: ")
        consumer_secret = HighLine.ask("Enter Twitter consumer secret: ")
        keys << {
          "consumer_key"    => consumer_key,
          "consumer_secret" => consumer_secret
        }
      end while HighLine.agree("Enter another Twitter keypair? (y/n) ")
      keys
    end

    def gather_klout_keys
      keys = []
      puts "\nKlout access tokens can be used by modules to gather additional information on Twitter users."
      if HighLine.agree("Do you want to enter Klout access tokens? (y/n) ")
        begin
          keys << HighLine.ask("Enter Klout access token: ")
        end while HighLine.agree("Enter another Klout access token? (y/n) ")
      end
      keys
    end
  end
end
