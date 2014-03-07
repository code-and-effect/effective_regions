module Effective
  module Snippets
    class CurrentUserInfo < Snippet
      attribute :method, String

      def snippet_name
        'Current User Info'
      end

      def snippet_description
        'Inserts info as per current_user'
      end

    end
  end
end
