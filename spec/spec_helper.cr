require "spec"
require "../src/sage"

class User
  property role : Symbol

  def initialize(@role = :user)
  end
end

class Post
  property state : Symbol

  def initialize(@state = :draft)
  end
end

abstract class ApplicationPolicy < Sage::Base
end

class UserPolicy < ApplicationPolicy
  constructor User, User

  ability :update? do
    user.object_id == resource.object_id
  end
end

class PostPolicy < ApplicationPolicy
  pre_check :admin_check, :guest_check, :return_integer

  alias_ability :create?, :destroy?, to: :manage?
  alias_ability :update?, to: :edit?

  getter user

  def initialize(@user : User, @post : Post)
  end

  ability :edit? do
    @post.state != :published
  end

  ability :manage? do
    @post.state == :manageable
  end

  private def admin_check
    allow! if @user.role == :admin
  end

  private def guest_check
    disallow! if @user.role == :guest
  end

  private def return_integer
    42
  end
end

class CustomPostPolicy < PostPolicy
  ability :upgrade? do
    @user.role == :publisher
  end
end
