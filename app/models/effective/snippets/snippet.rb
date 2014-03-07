require 'virtus'

module Effective
  module Snippets
    class Snippet
      include Virtus.model

      attr_accessor :attributes
      attr_accessor :options

      attribute :id, String # This will be snippet_12345
      attribute :region, Effective::Region # The region Object

      def initialize(attributes = {}, options = {})
        @attributes ||= attributes
        @options ||= options

        (@attributes || []).each { |k, v| self.send("#{k}=", v) if respond_to?("#{k}=") }
      end

      def id
        super.presence || "snippet_#{object_id}"
      end

      def to_partial_path
        "effective/snippets/#{class_name}/#{class_name}"
      end

      def to_editable_div
        "<div data-snippet='#{id}' class='#{class_name}_snippet'>[#{id}]</div>"
      end

      def class_name
        @class_name ||= self.class.name.demodulize.underscore.to_sym
      end

      ### The following methods are used for the Mercury Editor snippets pane.
      def snippet_name
        self.name.demodulize
      end

      def snippet_description
      end

      def snippet_image
      end

      def snippet_has_options?
        true
      end
    end
  end
end
