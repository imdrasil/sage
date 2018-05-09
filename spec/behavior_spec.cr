require "./spec_helper"

abstract class ApplicationController
  include Sage::Behavior

  def initialize(@user : User, @action : Symbol)
  end

  def current_user
    @user
  end

  abstract def resource

  macro render_methods
    def call_authorize!
      authorize!(@action, resource)
    end

    def call_able?
      able?(@action, resource)
    end

    def call_unable?
      unable?(@action, resource)
    end

    def call_policy
      policy(resource)
    end
  end
end

class PostController < ApplicationController
  def initialize(user, @post : Post, action)
    initialize(user, action)
  end

  def resource
    @post
  end

  render_methods
end

class UserController < ApplicationController
  def initialize(user, @given_user : User, action)
    initialize(user, action)
  end

  def resource
    @given_user
  end

  render_methods
end

describe Sage::Behavior do
  describe "%authorize!" do
    it { PostController.new(User.new, Post.new, :edit?).call_authorize! }

    it do
      expect_raises(Sage::UnauthorizedError, "You don't have the required permissions to execute this action") do
        PostController.new(User.new(), Post.new(:published), :edit?).call_authorize!
      end
    end
  end

  describe "%policy" do
    it { PostController.new(User.new(), Post.new(), :edit?).call_policy.is_a?(PostPolicy).should be_true }
  end

  describe "#able?" do
    it { PostController.new(User.new(), Post.new(), :edit?).call_able?.should be_true }
    it { PostController.new(User.new(), Post.new(:published), :edit?).call_able?.should be_false }
  end

  describe "#unable?" do
    it { UserController.new(User.new(), User.new(), :update?).call_unable?.should be_true }
    it { PostController.new(User.new(), Post.new, :edit?).call_unable?.should be_false }
  end
end
