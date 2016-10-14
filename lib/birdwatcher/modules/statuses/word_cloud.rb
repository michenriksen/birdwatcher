module Birdwatcher
  module Modules
    module Statuses
      class WordCloud < Birdwatcher::Module
        self.meta = {
          :name        => "Word Cloud",
          :description => "Generates a word cloud from statuses",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "DEST" => {
              :value       => nil,
              :description => "Destination file",
              :required    => true
            },
            "USERS" => {
              :value       => nil,
              :description => "Space-separated list of screen names (all users if empty)",
              :required    => false
            },
            "SINCE" => {
              :value       => nil,
              :description => "Process statuses posted since specified time (last 7 days if empty)",
              :required    => false
            },
            "BEFORE" => {
              :value       => nil,
              :description => "Process statuses posted before specified time (from now if empty)",
              :required    => false
            },
            "MIN_WORD_COUNT" => {
              :value       => 3,
              :description => "Exclude words mentioned fewer times than specified",
              :required    => false
            },
            "MIN_WORD_LENGTH" => {
              :value       => 3,
              :description => "Exclude words smaller than specified",
              :required    => false
            },
            "EXCLUDE_STOPWORDS" => {
              :value       => true,
              :description => "Exclude english stopwords",
              :required    => false,
              :boolean     => true
            },
            "EXCLUDE_COMMON" => {
              :value       => true,
              :description => "Exclude common english words",
              :required    => false,
              :boolean     => true
            },
            "EXCLUDE_WORDS" => {
              :value       => nil,
              :description => "Space-separated list of words to exclude",
              :required    => false
            },
            "EXCLUDE_HASHTAGS" => {
              :value       => false,
              :description => "Exclude Hashtags",
              :required    => false,
              :boolean     => true
            },
            "EXCLUDE_MENTIONS" => {
              :value       => true,
              :description => "Exclude @username mentions",
              :required    => false,
              :boolean     => true
            },
            "INCLUDE_PAGE_TITLES" => {
              :value       => false,
              :description => "Include web page titles from shared URLs (requires crawling with urls/crawl)",
              :required    => false,
              :boolean     => true
            },
            "WORD_CAP" => {
              :value       => 200,
              :description => "Cap list of words to specified amount",
              :required    => false
            },
            "PALETTE" => {
              :value       => "#8F99AB #A3ADC2 #272A2F #474C55 #3D4148 #021121 #293642 #516982 #516982 #415569",
              :description => "Space-separated list of hex color codes to use for word cloud",
              :required    => true
            },
            "IMAGE_WIDTH" => {
              :value       => 1024,
              :description => "Image width in pixels",
              :required    => true
            },
            "IMAGE_HEIGHT" => {
              :value       => 1024,
              :description => "Image height in pixels",
              :required    => true
            },
          }
        }

        DEFAULT_EXCLUDED_WORDS = %w(rt via oh)

        def self.info
<<-INFO
The Word Cloud module can generate a classic weighted word cloud from words used
in statuses across all or specific users and between different times.

The module is heavily configurable; have a look at the options with #{'show options'.bold}

Please note that configuring the module with a long timespan might result in a
very long execution time when the word cloud image is generated.

The generated image will be in PNG format.
INFO
        end

        def run
          if option_setting("USERS")
            user_ids = current_workspace.users_dataset.where("screen_name IN ?", option_setting("USERS").split(" ").map(&:strip)).map(&:id)
            statuses = current_workspace.statuses_dataset.where("user_id IN ?", user_ids)
          else
            statuses = current_workspace.statuses_dataset
          end
          if option_setting("SINCE")
            since = parse_time(option_setting("SINCE")).strftime("%Y-%m-%d")
          else
            since = (Date.today - 7).strftime("%Y-%m-%d")
          end
          if option_setting("BEFORE")
            before = parse_time(option_setting("BEFORE")).strftime("%Y-%m-%d")
          else
            before = Time.now.strftime("%Y-%m-%d")
          end
          statuses = statuses.where("DATE(posted_at) >= DATE(?) AND DATE(posted_at) <= DATE(?)", since, before).all
          if statuses.count.zero?
            error("There are no statuses to process")
            return false
          end
          prepare_exclusion_list
          words        = {}
          sorted_words = []
          task("Processing #{statuses.count.to_s.bold} statuses...") do
            statuses.each do |status|
              split_into_words(status.text).each do |word|
                next if exclude_word?(word)
                words.key?(word) ? words[word] += 1 : words[word] = 1
              end
              if option_setting("INCLUDE_PAGE_TITLES")
                status.urls_dataset
                .where("title IS NOT NULL")
                .where("final_url NOT LIKE 'https://twitter.com/%'")
                .map(&:title).each do |page_title|
                  split_into_words(page_title).each do |word|
                    next if exclude_word?(word)
                    words.key?(word) ? words[word] += 1 : words[word] = 1
                  end
                end
              end
            end
            if option_setting("MIN_WORD_COUNT")
              words.delete_if { |word, count| count < option_setting("MIN_WORD_COUNT").to_i }
            end
            sorted_words = words.sort_by { |word, count| count}.reverse
            if option_setting("WORD_CAP")
              sorted_words = sorted_words.take(option_setting("WORD_CAP").to_i)
            end
          end
          task("Generating word cloud, patience please...") do
            cloud = MagicCloud::Cloud.new(sorted_words,
              :rotate  => :none,
              :palette => option_setting("PALETTE").split(" ").map(&:strip)
            ).draw(option_setting("IMAGE_WIDTH").to_i, option_setting("IMAGE_HEIGHT").to_i).to_blob { self.format = "png" }
            File.open(option_setting("DEST"), "wb") { |f| f.write(cloud) }
          end
          info("Word cloud written to #{option_setting('DEST').bold}")
        end

        private

        def prepare_exclusion_list
          @exclusion_list = DEFAULT_EXCLUDED_WORDS
          if option_setting("EXCLUDE_WORDS")
            @exclusion_list += option_setting("EXCLUDE_WORDS").split(" ").map { |w| w.strip.downcase }
          end
          if option_setting("EXCLUDE_STOPWORDS")
            @exclusion_list += read_data_file("english_stopwords.txt").split("\n").map { |w| w.strip.downcase }
          end
          if option_setting("EXCLUDE_COMMON")
            @exclusion_list += read_data_file("top100Kenglishwords.txt").split("\n").map(&:strip)
          end
        end

        def exclude_word?(word)
          return true if word.empty?
          return true if option_setting("MIN_WORD_LENGTH") && word.length < option_setting("MIN_WORD_LENGTH").to_i
          return true if option_setting("EXCLUDE_HASHTAGS") && word.start_with?("#")
          return true if option_setting("EXCLUDE_MENTIONS") && word.start_with?("@")
          return true if @exclusion_list.include?(word)
        end

        def split_into_words(text)
          text = text.downcase.strip.gsub(/https?:\/\/[\S]+/, "").gsub(/[^0-9a-z@#_ ]/i, " ")
          text.split(" ").map(&:strip)
        end
      end
    end
  end
end
