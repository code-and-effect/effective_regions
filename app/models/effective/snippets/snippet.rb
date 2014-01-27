require 'virtus'

module Effective
  module Snippets
    class Snippet
      include Virtus.model

      attr_accessor :attributes
      attr_accessor :options

      attribute :name, String
      attribute :required, Boolean

      def initialize(attributes = {}, options = {})
        @attributes ||= attributes
        @options ||= options

        (@attributes || []).each { |k, v| self.send("#{k}=", v) if respond_to?("#{k}=") }
      end

      # def to_partial_path
      #   "/effective/snippets/#{snippet_class_name}/#{snippet_class_name}"
      # end

      # # These are render options. For a controller to call render on.
      def render_params(render_options = {})
        partial_path = "/effective/snippets/#{snippet_class_name}/#{snippet_class_name}"
        {:partial => partial_path, :locals => {snippet_class_name => self}.merge(options).merge(render_options)}
      end

      def page_form(controller)
        # form = nil
        # controller.view_context.simple_form_for Effective::PageForm.new([self]), :url => '/', :action => :show do |f| form = f end
        # form
      end

      def value_type
        String
      end

      def required?
        self[:required] || false
      end

      def required_html_class
        required? ? 'required' : 'optional'
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

      def snippet_filter
        snippet_name
      end
    end
  end
end
