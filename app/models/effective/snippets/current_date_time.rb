module Effective
  module Snippets
    class CurrentDateTime < Snippet

      def snippet_attributes
        super + [:format]
      end

      def snippet_tag
        :span
      end

    end
  end
end
