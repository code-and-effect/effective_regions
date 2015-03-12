module Effective
  module Templates
    class Template

      # This is used by the effective_regions_helper effective_regions_include_tags
      # And ends up in the javascript CKEDITOR.config['effective_regions'] top level namespace
      # Passing the controller is hacky but it works
      def self.all(controller)
        EffectiveRegions.templates.map do |template|
          {
            :title => template.title,
            :description => template.description,
            :image => template.image || "#{template.class_name}.png",
            :html => controller.render_to_string(:partial => template.to_partial_path, :object => template, :locals => {:template => template})
          }
        end
      end

      def title
        class_name.to_s.humanize
      end

      def description
        "Insert #{title}"
      end

      def image
        "#{class_name}.png"
      end

      def to_partial_path
        "effective/templates/#{class_name}"
      end

      def class_name
        @class_name ||= self.class.name.demodulize.underscore.to_sym
      end

    end
  end
end
