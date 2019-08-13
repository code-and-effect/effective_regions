module Effective
  module Snippets
    class DropCap < Snippet

      def snippet_attributes
        super + [:letter, :html_class]
      end

    end
  end
end
