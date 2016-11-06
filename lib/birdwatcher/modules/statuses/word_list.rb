module Birdwatcher
  module Modules
    module Statuses
      class Wordlist < Birdwatcher::Module
        self.meta = {
          :name        => "Word List",
          :description => "Generates a word list from statuses",
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
            "MIN_WORD_COUNT" => {
              :value       => 3,
              :description => "Exclude words mentioned fewer times than specified",
              :required    => false
            },
            "MIN_WORD_LENGTH" => {
              :value       => 6,
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
              :value       => true,
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
              :value       => nil,
              :description => "Cap list of words to specified amount",
              :required    => false
            },
            "INCLUDE_COUNT" => {
              :value => false,
              :description => "Include the count with the words",
              :required => false,
              :boolean => true
            }
          }
        }

        def self.info
<<-INFO
The Word List module can generate a simple word list or dictionary from words
used in statuses across all or specific users.

Since users Tweet about their hobbies, interests, work, etc. generating a word
list from statuses can be very effective for password cracking.
INFO
        end

        def run
          if option_setting("USERS")
            screen_names = option_setting("USERS").split(" ").map(&:strip)
            user_ids     = current_workspace.users_dataset.where("screen_name IN ?", screen_names).map(&:id)
            statuses     = current_workspace.statuses_dataset.where("user_id IN ?", user_ids)
          else
            statuses = current_workspace.statuses_dataset
          end
          if statuses.count.zero?
            error("There are no statuses to process")
            return false
          end
          word_list = make_word_list(
            :min_word_count       => option_setting("MIN_WORD_COUNT"),
            :min_word_length      => option_setting("MIN_WORD_LENGTH"),
            :exclude_words        => option_setting("EXCLUDE_WORDS").to_s.split(" ").map(&:strip),
            :exclude_stopwords    => option_setting("EXCLUDE_STOPWORDS"),
            :exclude_common_words => option_setting("EXCLUDE_COMMON"),
            :exclude_hashtags     => option_setting("EXCLUDE_HASHTAGS"),
            :exclude_mentions     => option_setting("EXCLUDE_MENTIONS"),
            :word_cap             => option_setting("WORD_CAP"),
            :stopwords_file       => File.join(DATA_DIRECTORY, "english_stopwords.txt"),
            :common_words_file    => File.join(DATA_DIRECTORY, "top100Kenglishwords.txt")
          )
          task("Processing #{statuses.count.to_s.bold} statuses...") do
            statuses.each do |status|
              word_list.add_to_corpus(status.text)
              if option_setting("INCLUDE_PAGE_TITLES")
                status.urls_dataset
                  .where("title IS NOT NULL")
                  .where("final_url NOT LIKE 'https://twitter.com/%'")
                  .map(&:title).each do |page_title|
                  word_list.add_to_corpus(page_title)
                end
              end
            end
            word_list.process
          end
          task("Writing #{pluralize(word_list.word_list.length, 'word', 'words')} to file...") do
            File.open(option_setting("DEST"), "w") do |f|
              word_list.word_list.each do |word_and_count|
                word, count = word_and_count
                if option_setting("INCLUDE_COUNT")
                  f.puts("#{word}, #{count}")
                else
                  f.puts(word)
                end
              end
            end
          end
          file_size = number_to_human_size(File.size(option_setting("DEST")))
          info("Wrote #{file_size.bold} to #{option_setting('DEST').bold}")
        end
      end
    end
  end
end
