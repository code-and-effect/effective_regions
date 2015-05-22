module Effective
  module Snippets
    class CurrentDateTime < Snippet
      attribute :format, String

      def snippet_tag
        :span
      end

    end
  end
end
