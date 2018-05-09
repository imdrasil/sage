# Sage

Sage - is a lightweight library for defining resource access policy rules.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  sage:
    github: imdrasil/sage
```

## Usage

The core component of Sage is a *policy class* - it describes access policies to resource. That's why it is assumed you define a separate policy class for each resource you want to specify access restrictions.

Consider a simple example:

```crystal
# It is not necessary to define application base policy class
# but this allows to put all shared behavior and configs in one place
abstract class ApplicationPolicy < Sage::Base
end

class PostPolicy < ApplicationPolicy
  constructor(User, Post)

  ability :edit?
    user.admin? || user.id == resource.id
  end

  ability :show?
    true
  end
end
```

Now you can add authorization to your app:

```crystal
abstract class ApplicationController
  include Sage::Behavior

  private def current_user
    User.current_user
  end
end

class PostsController
  def update
    @post = Post.find(params["id"])
    authorize! :update?, @post

    # ...
  end
end
```

In the above example Sage automatically refers policy class from the given `@post` variable - `Post -> PostPolicy`. The `user` is automatically used from calling `sage_user` method (which by default calls `current_user`).

When authorization is passed successfully (corresponding ability returned `true`), nothing happens, but in case of an authorization failure `Sage::UnauthorizedError` error is raised.

There are also an `able?` nad `unable?` methods which return `true` or `false`:

```crystal
able?(:update?, @post)
unable?(:update?, @post)
```

Also you may specify exact policy class:

```crystal
able?(:update, @post, within: EditorPostPolicy)
authorize!(:update?, @post, within: EditorPostPolicy)
```

### Writing Policies

Policy class contains defined abilities (partially they are just a predicate methods) which are used to authorize activities.

Each policy record is instantiated with the target `resource : T` object and authorization context `user : U`. To avoid generics, they should define corresponding attribute types for themselves. As a plugin `constructor` macro could be used for doing this:

```crystal
class PostPolicy < Sage::Base
  constructor(User, Post)

  # This call is the same as

  getter user : User, resource : Post

  def initialize(@user, @resource)
  end
end
```

> NOTE: `#user` method is abstract so should be defined by subclasses.

To define ability use corresponding macro `ability`:

```crystal
class PostPolicy < Sage::Base
  # ...
  ability :update? do
    user.admin? || user.id == resource.user_id
  end
end
```

#### Calling other policies

It may be useful to call other resource policy from within a current one. For doing this you can use standard `#able?` and `#unable?` methods:

```crystal
class CommentPolicy < Sage::Policy
  # ...

  ability :update? do
    user.admin? || user.id == resource.id || able?(:update?, resource.post)
  end
end
```

### Testing

Policies can be tested as any other Crystal classes:

```crystal
describe PostPolicy do
  described_class = PostPolicy

  describe "#update?"
    it "returns false when the user is not admin nor author" do
      user = User.new
      post = Post.new
      policy = described_class.new(user, post)
      policy.apply(:update?).should be_false
    end

    it "returns true when the user is admin" do
      user = User.new(:admin)
      post = Post.new
      policy = described_class.new(user, post)
      policy.apply(:update?).should be_true
    end

    it "returns true when the user is author" do
      user = User.new
      post = Post.new(user_id: user.id)
      policy = described_class.new(user, post)
      policy.apply(:update?).should be_true
    end
  end
end
```

### Aliases

Sage allows you to add ability aliases. It may be useful when you rely on implicit rules in your code:

```crystal
class PostController
  def edit
    # ...
    authorize! :edit?, @post
    # ...
  end

  def update
    # ...
    authorize! :update?, @post
    # ...
  end

  def destroy
    # ...
    authorize! :destroy?, @post
    # ...
  end
end
```

In your policy you can create alias to avoid code duplication:

```crystal
class PostPolicy < Sage::Base
  # ...
  alias_ability :update?, :edit?, to: :update?
  # ...
end
```

> NOTE: `alias_ability` doesn't create aliased methods and resolve them only during `Sage::Base#apply` call (which is under the hood of `able?` and `authorize!`).

#### Default Ability

When Sage can't resolve ability name it calls `Sage::Base#default_ability` method which by default returns `false`. You may override it to define another behavior.

### Pre-Checks

Sometimes it happens that some of your abilities (or even all of them) starts with the same conditions. Example:

```crystal
class PostPolicy < Sage::Base
  # ...
  ability :show? do
    user.admin? || resource.published?
  end

  ability :update? do
    user.admin? || user.id == resource.user_id
  end
  # ...
end
```

You can separate the common parts from all abilities to a separate *pre-checks*:

```crystal
class PostPolicy < Sage::Base
  # ...
  pre_check :admin?

  ability :show? do
    resource.published?
  end

  ability :update? do
    user.id == resource.user_id
  end

  private def admin?
    allow! if user.admin?
  end
  # ...
end
```

Pre-checks are executed before ability invocation. They allow to halt the authorization process - just return `allow!` or `disallow!` call value. Any other returned value is ignored.

## Contributing

1. Fork it ( https://github.com/imdrasil/sage/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [imdrasil](https://github.com/imdrasil) Roman Kalnytskyi - creator, maintainer

### Inspired by

- [Action Policy](https://github.com/palkan/action_policy)
- [Pundit](https://github.com/varvet/pundit)
- [CancanCan](https://github.com/CanCanCommunity/cancancan)
