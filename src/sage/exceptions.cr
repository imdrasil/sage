module Sage
  class UnauthorizedError < Exception
    def initialize(message : Nil, action : Symbol)
      @message = "You don't have the required permissions to execute this action"
    end
  end
end
