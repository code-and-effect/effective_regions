module Effective
  module Snippets
    class CurrentUserInfo < Snippet

      def snippet_attributes
        super + [:method]
      end

      def snippet_tag
        :span
      end
      
    end
  end
end
