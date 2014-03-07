require 'virtus'

module Effective
  module Snippets
    class Snippet
      include Virtus.model

      attr_accessor :attributes
      attr_accessor :options

      attribute :id, String # This will be snippet_12345
      attribute :region, Effective::Region # The region Object
      attribute :name, String # This ends up being the class name, it's set by EffectiveMercury on its update

      def initialize(attributes = {}, options = {})
        @attributes ||= attributes
        @options ||= options

        (@attributes || []).each { |k, v| self.send("#{k}=", v) if respond_to?("#{k}=") }
      end

      def to_partial_path
        "effective/snippets/#{snippet_class_name}/#{snippet_class_name}"
      end

      ### The following methods are used for the Mercury Editor snippets pane.
      def snippet_class_name
        @snippet_class_name ||= self.class.name.demodulize.underscore.to_sym
      end

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
