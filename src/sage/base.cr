require "./policy/*"

module Sage
  abstract class Base
    include Policy::Definition
    include Behavior

    abstract def check_policy(action) : Bool
    abstract def perform_pre_check
    abstract def initialize(user, resource)
    abstract def user

    def self.apply(user, action, resource)
      {% begin %}
        {{@type}}.new(user, resource).apply(action)
      {% end %}
    end

    def sage_user
      user
    end

    def allow!
      :allow
    end

    def disallow!
      :disallow
    end

    def perform_pre_check; end

    def default_ability
      false
    end

    def check_policy(action)
      default_ability
    end

    def apply(action)
      res = perform_pre_check
      return res unless res.nil?
      found_action = find_action_name(action)
      check_policy(found_action)
    end

    def find_action_name(action)
      action
    end

    macro inherited
      POLICIES = [] of String
      PRE_CHECKS = [] of String
      ALIASES = {} of Symbol => Array(Symbol)

      macro finished
        def perform_pre_check
          \{% for method in PRE_CHECKS %}
            res = \{{method.id}}
            return true if res == :allow
            return false if res == :disallow
          \{% end %}
          \{% if @type.superclass.constant("PRE_CHECKS") != nil %}
            super
          \{% end %}
        end

        def check_policy(action)
          \{% if POLICIES.size > 0 %}
          case action
          \{% for method in POLICIES %}
          when :\{{method.id}}
            \{{method.id}}
          \{% end %}
          else
          \{% end %}
            super(action)
          \{% if POLICIES.size > 0 %} end \{% end %}
        end

        def find_action_name(action)
          \{% if ALIASES.size > 0 %}
            case action
            \{% for original, aliases in ALIASES %}
            when \{{aliases.splat}}
              return \{{original}}
            \{% end %}
            end
          \{% end %}
          super(action)
        end
      end
    end
  end
end
