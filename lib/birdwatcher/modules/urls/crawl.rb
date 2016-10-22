module Birdwatcher
  module Modules
    module Urls
      class Crawl < Birdwatcher::Module
        self.meta = {
          :name        => "URL Crawler",
          :description => "Enrich gathered URLs with HTTP status codes, content types and page titles",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "USER_AGENT" => {
              :value       => nil,
              :description => "Specific HTTP User-Agent to use (randomized user-agents if not set)",
              :required    => false
            },
            "TIMEOUT" => {
              :value       => Birdwatcher::HttpClient::DEFAULT_TIMEOUT,
              :description => "Request timeout in seconds",
              :required    => false
            },
            "RETRIES" => {
              :value       => Birdwatcher::HttpClient::DEFAULT_RETRIES,
              :description => "Amount of retries on failed requests",
              :required    => false
            },
            "RETRY_FAILED" => {
              :value       => false,
              :description => "Retry previously failed crawls",
              :required    => false,
              :boolean     => true
            },
            "PROXY_ADDR" => {
              :value       => nil,
              :description => "HTTP proxy address to use for requests",
              :required    => false
            },
            "PROXY_PORT" => {
              :value       => nil,
              :description => "HTTP proxy port to use for requests",
              :required    => false
            },
            "PROXY_USER" => {
              :value       => nil,
              :description => "HTTP proxy user to use for requests",
              :required    => false
            },
            "PROXY_PASS" => {
              :value       => nil,
              :description => "HTTP proxy user to use for requests",
              :required    => false
            },
            "THREADS" => {
              :value       => 10,
              :description => "The number of concurrent threads",
              :required    => false
            }
          }
        }

        PAGE_TITLE_REGEX = /<title>(.*?)<\/title>/i

        def self.info
<<-INFO
The URL Crawler module crawls shared URLs and enriches them with additional
information:

  * HTTP status code (200, 404, 500, etc.)
  * Content type (application/html, application/pdf, etc)
  * Page title (if HTML document)

Page titles can be included in the Word Cloud generated with the
#{'statuses/word_cloud'.bold} module.

#{'CAUTION:'.bold} Depending on the users in the workspace, it might not be safe
to blindly request shared URLs. Consider using the #{'PROXY_ADDR'.bold} and #{'PROXY_PORT'.bold}
module options.
INFO
        end

        def run
          if option_setting("RETRY_FAILED")
            urls = current_workspace.urls_dataset
              .where("crawled_at IS NULL or (crawled_at IS NOT NULL AND http_status IS NULL)")
              .order(Sequel.desc(:posted_at))
          else
            urls = current_workspace.urls_dataset
              .where(:crawled_at => nil)
              .order(Sequel.desc(:posted_at))
          end
          if urls.empty?
            error("There are currently no URLs in this workspace")
            return false
          end
          threads     = thread_pool(option_setting("THREADS").to_i)
          http_client = Birdwatcher::HttpClient.new(
            :timeout        => option_setting("TIMEOUT").to_i,
            :retries        => option_setting("RETRIES").to_i,
            :user_agent     => option_setting("USER_AGENT"),
            :http_proxyaddr => option_setting("PROXY_ADDR"),
            :http_proxyport => (option_setting("PROXY_PORT") ? option_setting("PROXY_PORT").to_i : nil),
            :http_proxyuser => option_setting("PROXY_USER"),
            :http_proxypass => option_setting("PROXY_PASS")
          )
          urls.each do |url|
            threads.process do
              begin
                Timeout::timeout(option_setting("TIMEOUT").to_i * 2) do
                  response = http_client.do_head(url.url)
                  url.final_url    = response.url
                  url.http_status  = response.status
                  url.content_type = response.headers["content-type"]
                  if response.headers.key?("content-type") && response.headers["content-type"].include?("text/html")
                    url.title = extract_page_title(http_client.do_get(response.url).body)
                  end
                  url.crawled_at = Time.now
                  url.save
                  info("Crawled #{url.url.bold} (#{response.status} - #{response.headers["content-type"]})")
                end
              rescue => e
                url.crawled_at = Time.now
                url.save
                error("Crawling failed for #{url.url.bold} (#{e.class})")
              end
            end
          end
          threads.shutdown
        end

        private

        def extract_page_title(body)
          title = body.scan(PAGE_TITLE_REGEX).first
          return nil if title.nil?
          CGI.unescapeHTML(title.first)
        end
      end
    end
  end
end
