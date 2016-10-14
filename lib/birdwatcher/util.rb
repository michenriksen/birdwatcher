module Birdwatcher
  module Util
    def self.time_ago_in_words(time)
      return "a very very long time ago" if time.year < 1800
      secs = Time.now - time
      return "just now" if secs > -1 && secs < 1
      return "" if secs <= -1
      pair = ago_in_words_pair(secs)
      ary = ago_in_words_singularize(pair)
      ary.size == 0 ? "" : ary.join(" and ") << " ago"
    end

    def self.ago_in_words_pair(secs)
      [[60, :seconds], [60, :minutes], [24, :hours], [100_000, :days]].map{ |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i} #{name}"
        end
      }.compact.reverse[0..1]
    end

    def self.ago_in_words_singularize(pair)
      if pair.size == 1
        pair.map! {|part| part[0, 2].to_i == 1 ? part.chomp("s") : part }
      else
        pair.map! {|part| part[0, 2].to_i == 1 ? part.chomp("s") : part[0, 2].to_i == 0 ? nil : part }
      end
      pair.compact
    end

    def self.parse_time(time)
      ::Chronic.parse(time)
    end

    def self.strip_html(string)
      string.to_s.gsub(/<\/?[^>]*>/, "")
    end

    def self.strip_control_characters(string)
      string = string.to_s.uncolorize
      string.split("").delete_if do |char|
        char.ascii_only? and (char.ord < 32 or char.ord == 127)
      end.join("")
    end

    def self.escape_html(string)
      CGI.escapeHTML(string.to_s)
    end

    def self.unescape_html(string)
      CGI.unescapeHTML(string.to_s)
    end

    def self.pluralize(count, singular, plural)
      count == 1 ? "1 #{singular}" : "#{count} #{plural}"
    end

    def self.excerpt(text, max_length, omission = "...")
      text = text.gsub(/\s/, " ").split(" ").map(&:strip).join(" ")
      return text if text.length < max_length
      text[0..max_length] + omission
    end

    def self.suppress_output(&block)
      original_stdout = $stdout
      $stdout = fake = StringIO.new
      begin
        yield
      ensure
        $stdout = original_stdout
      end
      fake.string
    end

    def self.suppress_warnings(&block)
      warn_level = $VERBOSE
      $VERBOSE = nil
      result = block.call
      $VERBOSE = warn_level
      result
    end
  end
end
