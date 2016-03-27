# Crudblood

Crudblood is a collection of modules designed to make super dry, convention-based CRUD APIs with Phoenix Framework.

*Crudblood is currently a work in progress and is not intended for production use.*

## Parts

Crudblood is organized into three parts:

### Crudblood.ResourcefulController
The "resourceful controller" module provides convention-based CRUD actions. It mostly handles requests and responses and delegates most of the heavy lifting to...

### Crudblood.APIModel
API models provide a common interface for CRUD operations against models. Why do we need API models when we have regular Ecto models? The API models handle authorization checks. They also provides a standardized way to do work normally done in controllers. In an ideal world controllers just handle routing and responding to requests. API models are also easier to unit test than controllers because the code lives outside of the request context.

### Crudblood.Model
The model module just provides some convenience methods (table, name, plural_name) for working conventionally with parameters as needed by the API Model and Resourceful Controller modules.

## Configuration

### config/config.exs
You'll need to configure Crudblood in your config/config.exs file with the following options:

```elixir
config :crudblood, Crudblood,
  app: MyApp,
  changeset_view: MyApp.ChangesetView,
  repo: MyApp.Repo
```

### Models
Use the Crudblood.Model module like so:

```elixir
defmodule MyApp.User do
  use Crudblood.Model
end
```

#### Permissions

I define permissions right on the models themselves by configuring a method called "can?" like so:

```elixir
defmodule MyApp.User do
  ...
  # permissions

  def can?(_user, _current_user, :create) do
    true
  end

  def can?(%MyApp.User{id: id}, %MyApp.User{id: id}, action)
  when action in [:read, :destroy], do: true

  def can?(%MyApp.User{id: user_id}, :read_all), do: false

  def can?(changeset = %Ecto.Changeset{}, %MyApp.User{id: id}, :update) do
    !changeset.changes[:id] && id == changeset.model.id
  end

  def can?(_, _, _), do: false
end
```

This example uses pattern matching and/or boolean logic to return whether an operation is allowed (true) or forbidden (false).

### Controllers
You'll also need to tell Crudblood what API Model to use for the Resourceful Controller. Here I'm configuring it to use MyApp.UserApiModel and I also use Crudblood.ResourcefulController:

```elixir
defmodule MyApp.UserController do
  @api_model MyApp.UserApiModel

  use Crudblood.ResourcefulController
end
```

You'll need to configure a method to tell Crudblood where it can find the current resource in the connection (the current user, etc). I like to add this method for all my controllers by adding the following method that delegates to the Guardian module to web/web.ex:

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
  use Crudblood.ApiModel
end
```

If you want to override any of the API Model default CRUD methods you can do so like this:

```elixir
defmodule MyApp.UserApiModel do
  use Crudblood.ApiModel

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

Crudblood ApiModel tries to guess your data model name from the name of the ApiModel (example: MyApp.UserApiModel translates to MyApp.User), but if your api models or models don't follow that pattern (I, for example, version my api models like MyApp.V1.UserApiModel), you can specify the model to use by setting @model:

```elixir
defmodule MyApp.UserApiModel do
  @model MyApp.User
end
```

----------------

So why would you do all of this? Well, your business logic will probably mostly disappear and your controllers will probably be magical and look lean like this:

```elixir
defmodule MyApp.ProfileController do
  @api_model MyApp.ProfileApiModel

  use MyApp.Web, :controller
  use Crudblood.ResourcefulController
end
```

And you can test your business logic using your API Models instead of with controller specs.

-----------------

## The Future
I'd really like to reduce the amount of configuration necessary. These modules are based on similar work I've done with Rails. Rails provides some really nice interfaces for making this sort of convention-based logic easy... stuff like pluralization and looking up resources in controller contexts. If folks can help me pull these sorts of features out of Phoenix Framework that'd be fantastic. But Phoenix is much simpler than Rails. That's a good thing... but it does mean we have to do a little more work to get magic to happen.
