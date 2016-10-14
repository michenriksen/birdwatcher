module Birdwatcher
  module Modules
    module Statuses
      class Sentiment < Birdwatcher::Module
        self.meta = {
          :name        => "Status Sentiment Analysis",
          :description => "Enrich statuses with sentiment score",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "THREADS" => {
              :value       => Birdwatcher::Concerns::Concurrency::DEFAULT_THREAD_POOL_SIZE,
              :description => "Number of concurrent threads",
              :required    => false
            }
          }
        }

        def self.info
<<-INFO
The Status Sentiment Analysis module can calculate the rough sentiment of statuses
in the workspace. Each status will get a sentiment score of Negative, Positive
or Neutral.

Please note that sentiment analysis is not very accurate and should always be
manually reviewed for serious work.
INFO
        end

        def run
          statuses = current_workspace.statuses_dataset.where(:sentiment => nil)
          if statuses.empty?
            error("There are no statuses to analyze")
            return false
          end
          analyser = Sentimental.new
          threads  = thread_pool(option_setting("THREADS").to_i)
          task("Training the sentiment analyzer...") do
            analyser.load_defaults
          end
          statuses.each do |status|
            threads.process do
              begin
                text = sanitize_text(status.text)
                sentiment = analyser.sentiment(text)
                case sentiment
                when :positive
                  info("Positive: ".bold.light_green + Birdwatcher::Util.excerpt(status.text, 80))
                when :negative
                  info("Negative: ".bold.light_red + Birdwatcher::Util.excerpt(status.text, 80))
                else
                  info(" Neutral: ".bold + Birdwatcher::Util.excerpt(status.text, 80))
                end
                status.sentiment = sentiment.to_s
                status.save
              rescue => e
                error("Sentiment analysis for status #{status.id.bold} failed (#{e.class})")
              end
            end
          end
          threads.shutdown
        end

        private

        def sanitize_text(text)
          text.split(" ").map(&:strip).delete_if do |word|
            word.start_with?("@") ||
            word.start_with?(".@")
            word.start_with?("#") ||
            word.downcase.start_with?("http") ||
            %w(rt oh).include?(word.downcase)
          end.join(" ")
        end
      end
    end
  end
end
