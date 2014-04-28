module Effective
  module Snippets
    class CurrentUserInfo < Snippet
      attribute :method, String

      def snippet_tag
        :span
      end
      
    end
  end
end
