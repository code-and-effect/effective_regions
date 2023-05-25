module Effective
  module Snippets
    class ReadMoreDivider < Snippet
      TOKEN = "<div style='display: none;'>READ_MORE_DIVIDER</div>"

      def snippet_attributes
        super + [:throwaway]
      end

    end
  end
end
