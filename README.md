# Mudblood

Mudblood is a collection of modules designed to make super dry, convention-based CRUD APIs with Phoenix Framework.

*Mudblood is currently a work in progress and is not intended for production use.*

## Parts

Mudblood is organized into three parts:

### Mudblood.ResourcefulController
The "resourceful controller" module provides convention-based CRUD actions. It mostly handles requests and responses and delegates most of the heavy lifting to...

### Mudblood.APIModel
API models provide a common interface for CRUD operations against models. Why do we need API models when we have regular Ecto models? The API models handle authorization checks. They also provides a standardized way to do work normally done in controllers. In an ideal world controllers just handle routing and responding to requests. API models are also easier to unit test than controllers because the code lives outside of the request context.

### Mudblood.Model
The model module just provides some convenience methods (table, name, plural_name) for working conventionally with parameters as needed by the API Model and Resourceful Controller modules.

## Configuration

### config/config.exs
You'll need to configure Mudblood in your `config/config.exs` file with the following options:

```elixir
config :mudblood, Mudblood,
  app: MyApp,
  changeset_view: MyApp.ChangesetView,
  repo: MyApp.Repo
```

### Models
Use the `Mudblood.Model` module like so:

```elixir
defmodule MyApp.User do
  use Mudblood.Model
end
```

### Controllers
You'll need to use `Mudblood.ResourcefulController`.

```elixir
defmodule MyApp.UserController do
  use Mudblood.ResourcefulController
end
```

`Mudblood.ResourcefulController` will try to guess the name of your api model from the name of the controller (example: `MyApp.UserController` translates to `MyApp.UserApiModel`). If your api model or controller doesn't follow that convention, you can specify the api model to use by setting `@api_model`:

```elixir
defmodule MyApp.UserController do
  @api_model MyApp.SomeApiModel

  use Mudblood.ResourcefulController
end
```

You'll need to configure a method to tell Mudblood where it can find the current resource in the connection (the current user, etc). I like to add this method for all my controllers by adding the following method that delegates to the Guardian module to `web/web.ex`:

```elixir
defmodule MyApp.Web do
  ...
  def controller do
    quote do
    ...
      defp get_current_resource(conn) do
        Guardian.Plug.current_resource(conn)
      end
    end
  end
end
```

If you aren't using Guardian, provide an interface to extract the current user given the connection.

## API Models
You will need to build an API Model for each of your models. Fortunately you probably won't need any custom logic and your API Models can be as simple as this:

```elixir
defmodule MyApp.UserApiModel do
  use Mudblood.ApiModel
end
```

You can define permissions for the CRUD operations by providing a `can?` method on your api models. It can use a combination of pattern matching and/or boolean logic and should return true or false to allow or disallow the action. The `can?` method receives three arguments: [`resource_being_accessed`, `accessing_resource`, `action`]. The CRUD actions are [`:create`, `:read_all`, `:read`, `:update`, `:destroy`]. If a `can?` method is not defined then all actions will be allowed.

##### Permissions Example:

```elixir
defmodule MyApp.UserApiModel do
  ...
  # permissions

  # anyone can create a user
  def can?(_user, _current_user, :create) do
    true
  end

  # allow read and destroy when the resource user id is the same as
  # the accessing user id
  def can?(%MyApp.User{id: id}, %MyApp.User{id: id}, action)
  when action in [:read, :destroy], do: true

  # no user can read all users
  def can?(%MyApp.User{id: user_id}, :read_all), do: false

  # a user can update as long as the changeset id isn't changing and
  # the changeset id is the accessing user id
  def can?(changeset = %Ecto.Changeset{}, %MyApp.User{id: id}, :update) do
    !changeset.changes[:id] && id == changeset.model.id
  end

  # everything else is not allowed
  def can?(_, _, _), do: false
end

```


If you want to override any of the API Model default CRUD methods you can do so like this:

```elixir
defmodule MyApp.UserApiModel do
  use Mudblood.ApiModel

  # I've got a custom create method!
  def create(current_user, params) do
    changeset = changeset(params, empty_model)

    # ... custom logic ...

    changeset
    |> @model.can?(current_user, :create)
    |> case do
         true  -> MyApp.Repo.insert(changeset)
         false -> forbidden
       end
  end
end
```

`Mudblood.ApiModel` tries to guess your data model name from the name of the ApiModel (example: `MyApp.UserApiModel` translates to `MyApp.User`), but if your api models or models don't follow that pattern (I, for example, version my api models like `MyApp.V1.UserApiModel`), you can specify the model to use by setting `@model`:

```elixir
defmodule MyApp.UserApiModel do
  @model MyApp.User
end
```

----------------

So why would you do all of this? Well, your business logic will probably mostly disappear and your controllers will probably be magical and look lean like this:

```elixir
defmodule MyApp.ProfileController do
  use MyApp.Web, :controller
  use Mudblood.ResourcefulController
end
```

And you can test your business logic using your API Models instead of with controller specs.
