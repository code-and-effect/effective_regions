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

      def data
        self.attributes.reject { |k, v| ['region', 'id', 'class_name'].include?(k) }
      end

      def to_partial_path
        "effective/snippets/#{class_name}/#{class_name}"
      end

      def class_name
        @class_name ||= self.class.name.demodulize.underscore.to_sym
      end

      ### The following methods are used for the CKEditor widget creation.

      # Either a string, or false if there are no options.
      def snippet_dialog_url
        "/assets/effective/snippets/#{class_name}.js"
      end

    end
  end
end
