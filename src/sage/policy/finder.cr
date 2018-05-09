module Sage
  module Policy
    abstract class Finder
      def self.policy(user, resource : T) forall T
        {% begin %}
          {{"#{T}Policy".id}}.new(user, resource)
        {% end %}
      end
    end
  end
end
