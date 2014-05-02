module Effective
  module Templates
    class Template
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
