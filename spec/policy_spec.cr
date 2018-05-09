require "./spec_helper"

describe Sage::Policy do
  describe "#apply" do
    policy = CustomPostPolicy

    context "with inherited ability" do
      it { CustomPostPolicy.new(User.new(), Post.new()).apply(:edit?).should be_true }
      it { CustomPostPolicy.new(User.new(), Post.new(:published)).apply(:edit?).should be_false }
      it { CustomPostPolicy.new(User.new(:publisher), Post.new()).apply(:upgrade?).should be_true }
      it { CustomPostPolicy.new(User.new(), Post.new()).apply(:create?).should be_false }
    end

    context "with pre check" do
      it { policy.new(User.new(:admin), Post.new(:published)).apply(:edit?).should be_true }
      it { policy.new(User.new(:guest), Post.new()).apply(:edit?).should be_false }
    end

    context "with undefined policy" do
      it { CustomPostPolicy.new(User.new, Post.new).apply(:gibberish?).should be_false }
    end

    context "with alias" do
      it { policy.new(User.new, Post.new).apply(:update?).should be_true }
      it { policy.new(User.new, Post.new(:manageable)).apply(:create?).should be_true }

      it { policy.new(User.new, Post.new(:published)).apply(:update?).should be_false }
      it { policy.new(User.new, Post.new).apply(:destroy?).should be_false }
    end
  end
end
