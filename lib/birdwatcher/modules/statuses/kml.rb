module Birdwatcher
  module Modules
    module Statuses
      class Kml < Birdwatcher::Module
        self.meta = {
          :name        => "KML Document",
          :description => "Creates a KML document of statuses with Geo locations",
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
            }
          }
        }

        def self.info
<<-INFO
KML is a file format used to display geographic data in an Earth browser such as
Google Earth. You can create KML files to pinpoint locations, add image overlays,
and expose rich data in new ways. KML is an international standard maintained by
the Open Geospatial Consortium, Inc. (OGC).

This module can generate a KML document containing all statuses with geo information
which can be loaded into an application like Google Earth to browse and analyze
statuses.

The module supports mapping statuses from all or specific users.
INFO
        end

        def run
          if option_setting("USERS")
            users = current_workspace.users_dataset
              .where("screen_name IN ?", option_setting("USERS").split(" ").map(&:strip))
              .order(:screen_name)
          else
            users = current_workspace.users_dataset.order(:screen_name)
          end
          if users.empty?
            error("There are no users to process")
            return false
          end
          kml_document = Birdwatcher::KML.new(
            :name => "Statuses with geo locations"
          )
          users.each do |user|
            statuses = user.statuses_dataset.where(:geo => true).order(Sequel.desc(:posted_at)).eager(:user)
            if statuses.count.zero?
              warn("User #{user.screen_name.bold} has no statuses with geo location; skipping")
              next
            end
            kml_document.add_folder(user.screen_name,
              :name        => "#{user.name} (@#{user.screen_name})",
              :description => "Statuses from #{user.screen_name}"
            )
            statuses.each do |status|
              kml_document.add_placemark_to_folder(user.screen_name,
                :id          => status.twitter_id,
                :name        => "@#{escape_html(user.screen_name)}, #{format_date(status.posted_at)}",
                :description => make_status_description(status),
                :Snippet     => escape_html(excerpt(status.text, 80)),
                :Style       => "<Icon><href>#{escape_html(user.profile_image_url)}</href></Icon>",
                :Point       => "<coordinates>#{escape_html(status.latitude)},#{escape_html(status.longitude)}</coordinates>",
                :address     => "#{escape_html(status.place_name)}, #{escape_html(status.place_country)}",
                :TimeStamp   => escape_html(status.posted_at.strftime('%Y-%m-%dT%l:%M:%S%z'))
              )
            end
            info "Added #{pluralize(statuses.count, 'status', 'statuses')} from #{user.screen_name.bold}"
          end
          File.write(option_setting("DEST"), kml_document.generate)
          info("Wrote KML document to #{option_setting('DEST').bold}")
        end

        private

        def make_status_description(status)
          "<![CDATA[\n" +
          "  <table>\n" +
          "    <tr>\n" +
          "      <td style='vertical-align:top'>\n" +
          "        <img src='#{escape_html(status.user.profile_image_url)}' alt='#{escape_html(status.user.screen_name)}' />\n" +
          "      </td>\n" +
          "      <td>\n" +
          "        <strong>#{escape_html(status.user.name)}</strong> <span style='color: #8899a6'>@#{escape_html(status.user.screen_name)} &middot; <a href='https://twitter.com/#{escape_html(status.user.screen_name)}/status/#{escape_html(status.twitter_id)}' style='color: inherit'>#{format_date(status.posted_at)}</a></span><br />\n" +
          "          <p style='font-size: 16px'>#{escape_html(status.text)}</p>\n" +
          "          <p style='font-style: italic'>#{escape_html(status.place_name)}, #{escape_html(status.place_country)}</p>\n" +
          "      </td>\n" +
          "    </tr>\n" +
          "  </table>\n" +
          "]]>\n"
        end

        def format_date(time)
          time.strftime("%b %d, %Y")
        end
      end
    end
  end
end
