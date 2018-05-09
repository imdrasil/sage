require "./policy/finder"

module Sage
  module Behavior
    macro authorize!(action, object)
      raise Sage::UnauthorizedError.new(unauthorized_error_message, {{action}}) unless able?({{action}}, {{object}})
    end

    macro authorize!(action, object, within policy_class)
      raise Sage::UnauthorizedError.new(unauthorized_error_message, {{action}}) unless able?({{action}}, {{object}}, {{policy_class}})
    end

    macro policy(object)
      ::Sage::Policy::Finder.policy(sage_user, {{object}})
    end

    def able?(action : Symbol, object)
      policy(object).apply(action)
    end

    def unable?(action : Symbol, object)
      !able?(action, object)
    end

    def able?(action : Symbol, object, within : T.class) forall T
      T.new(sage_user, object).apply(action)
    end

    def unable?(action : Symbol, object, within)
      !able?(action, object, within)
    end

    def sage_user
      current_user
    end

    def unauthorized_error_message; end
  end
end
