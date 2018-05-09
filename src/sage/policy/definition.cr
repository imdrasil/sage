module Sage::Policy::Definition
  macro constructor(user_class, resource_class)
    getter user : {{user_class}}, resource : {{resource_class}}

    def initialize(@user, @resource)
    end
  end

  macro pre_check(*methods)
    {% for method in methods %}
      {% PRE_CHECKS << method.id.stringify %}
    {% end %}
  end

  macro ability(name)
    {% POLICIES << name.id.stringify %}

    def {{name.id}} : Bool
      {{yield}}
    end
  end

  macro alias_ability(*abilities, to ability)
    {%
      ALIASES[ability] = [] of Array(String) if ALIASES[ability] == nil
      container = ALIASES[ability]
    %}
    {% for aliased_ability in abilities %}
      {% container << aliased_ability %}
    {% end %}
  end
end
