module Effective
  module Snippets
    class Snippet
      # SO I have to add some restrictions on how snippets are built:

      # Each Snippet has to be a block (or inline) element with nested children.
      # It has to start with a root object
      # That root object has to do {snippet_data(snippet)}
      #attr_accessor :id       # This will be snippet_12345
      #attr_accessor :region   # The region Object

      def snippet_attributes
        [:id, :region]
      end

      # This is going to return all snippet objects that are saved in any Effective::Regions
      def self.all(type = nil)
        if type.present?
          name = case type
          when Snippet
            type.class_name.to_s
          when Class
            type.name.demodulize.underscore
          when String
            type.demodulize.underscore
          else
            raise 'Expected a class name, an instance of a snippet, or a string'
          end.to_sym

          Effective::Region.with_snippets
            .where("#{EffectiveRegions.regions_table_name}.snippets ILIKE ?", "%class_name: #{name}%")
            .flat_map { |region| region.snippet_objects }
            .select { |snippet| snippet.class_name == name }
        else
          Effective::Region.with_snippets.flat_map { |region| region.snippet_objects }
        end
      end

      # This is used by the effective_regions_helper effective_regions_include_tags
      # And ends up in the javascript CKEDITOR.config['effective_regions'] top level namespace
      def self.definitions(controller = nil)
        {}.tap do |snippets|
          EffectiveRegions.snippets.each do |snippet|
            snippets[snippet.class_name] = {
              :dialog_url => snippet.snippet_dialog_url,
              :label => snippet.snippet_label,
              :description => snippet.snippet_description,
              :inline => snippet.snippet_inline,
              :editables => snippet.snippet_editables,
              :tag => snippet.snippet_tag.to_s
            }
          end
        end
      end

      # If you define "attribute :something, Array" in your derived class
      # You can call effective_region post, :content :snippet_locals => {:something => [1,2,3]}
      # And it will be assigned when the effective_region is rendered

      def initialize(atts = {})
        snippet_attributes.each { |name| self.class.send(:attr_accessor, name) }
        (atts || {}).each { |k, v| self.send("#{k}=", v) if respond_to?("#{k}=") }
      end

      def id
        @id || "snippet_#{object_id}"
      end

      def region
        @region || Effective::Region.new
      end

      def data
        (self.snippet_attributes - [:region, :id]).inject({}) { |h, name| h[name] = public_send(name); h}
      end

      def to_partial_path
        "effective/snippets/#{class_name}"
      end

      def class_name
        @class_name ||= self.class.name.demodulize.underscore.to_sym
      end

      ### The following methods are used for the CKEditor widget creation.
      def snippet_label
        class_name.to_s.humanize
      end

      def snippet_description
        "Insert #{snippet_label}"
      end

      def snippet_dialog_url
        "/assets/effective/snippets/#{class_name}.js"
      end

      # This is the tag that the ckeditor snippet will be created as
      # It supports divs and spans, but that's it
      # No ULs, or LIs
      def snippet_tag
        :div
      end

      def snippet_inline
        [:span].include?(snippet_tag)
      end

      def snippet_editables
        false
      end

    end
  end
end
