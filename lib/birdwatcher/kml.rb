module Birdwatcher
  # KML Document generator
  #
  # KML is a file format used to display geographic data in an Earth browser
  # such as Google Earth. You can create KML files to pinpoint locations, add
  # image overlays, and expose rich data in new ways. KML is an international
  # standard maintained by the Open Geospatial Consortium, Inc. (OGC).
  #
  # This class supports generating basic KML documents with Placemarks and Folders.
  #
  # @note Attribute values ARE NOT automatically escaped. All values will have to be given in an HTML escaped fashion if there is a risk that they might contain unexpected or dangerous HTML.
  # @see https://developers.google.com/kml/
  class KML
    # KML document header
    DOCUMENT_HEADER =
<<-HEAD
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
HEAD

    # KML document footer
    DOCUMENT_FOOTER =
<<-FOOT
</Document>
</kml>
FOOT

    class Error < StandardError; end
    class UnknownFolderError < Birdwatcher::KML::Error; end

    # Class initializer
    #
    # @param attributes [Hash] Document attributes
    # @see https://developers.google.com/kml/documentation/kmlreference#document
    def initialize(attributes = {})
      @attributes = attributes
      @folders    = {}
      @placemarks = []
    end

    # Add a Placemark
    #
    # @param attributes [Hash] Placemark attributes
    # @see https://developers.google.com/kml/documentation/kmlreference#placemark
    def add_placemark(attributes)
      @placemarks << attributes
    end

    # Add a Folder
    #
    # @param id [String] Folder ID
    # @param attributes [Hash] Folder attributes
    #
    # @see https://developers.google.com/kml/documentation/kmlreference#folder
    def add_folder(id, attributes)
      @folders[id] = {
        :placemarks => []
      }.merge(attributes)
    end

    # Add a Placemark to a Folder
    #
    # @param folder_id [String]
    # @param attributes [Hash] Placemark attributes
    #
    # @raise [Birdwatcher::KML::UnknownFolderError] if folder doesn't exist
    # @see https://developers.google.com/kml/documentation/kmlreference#placemark
    def add_placemark_to_folder(folder_id, attributes)
      fail(UnknownFolderError, "There is no folder with id: #{folder_id}") unless @folders.key?(folder_id)
      @folders[folder_id][:placemarks] << attributes
    end

    # Generate the KML document
    #
    # @return the final KML document
    def generate
      output = generate_document_header
      @folders.each_pair { |id, attributes| output += generate_folder(id, attributes) }
      output += @placemarks.map { |p| generate_placemark(p) }.join
      output += generate_document_footer
    end

    private

    # Generate document header
    # @private
    def generate_document_header
      header = DOCUMENT_HEADER
      @attributes.each_pair { |k, v| header += "<#{k}>#{escape(v)}</#{k}>\n" }
      header
    end

    # Generate document footer
    # @private
    def generate_document_footer
      DOCUMENT_FOOTER
    end

    # Generate Placemark element
    # @private
    def generate_placemark(attributes)
      placemark = attributes.key?(:id) ? "<Placemark id='#{escape(attributes[:id])}'>" : "<Placemark>"
      attributes.delete(:id)
      attributes.each_pair { |k, v| placemark += "<#{k}>#{v}</#{k}>\n" }
      placemark += "</Placemark>\n"
    end

    # Generate Folder element
    # @private
    def generate_folder(id, attributes)
      placemarks = attributes.delete(:placemarks)
      folder = "<Folder id='#{escape(id)}'>"
      attributes.each_pair { |k, v| folder += "<#{k}>#{escape(v)}</#{k}>\n" }
      folder += placemarks.map { |p| generate_placemark(p) }.join
      folder += "</Folder>\n"
    end

    # HTML escape a string
    # @private
    def escape(string)
      CGI.escapeHTML(string.to_s)
    end
  end
end
