defmodule Crudblood.ApiModel do
  defmacro __using__(_) do
    quote do
      def create(current_user, params) do
        config = Crudblood.config(%{})
        changeset = __changeset(params, __empty_model)

        changeset
        |> __can?(current_user, :create)
        |> case do
             true  -> config.repo.insert(changeset)
             false -> __forbidden
           end
      end

      def read_all(current_user, params \\ %{}) do
        config = Crudblood.config(%{})

        __can?(__model, current_user, :read_all)
        |> case do
             true  ->
               # FIXME: this is janky as hell
               {:ok,
                # TODO: support more params like limit and offset
                __model.__table
                |> Query.table()
                |> Query.filter(params)
                |> config.repo.run
                |> Enum.fetch(0)
               }
             false ->
               __forbidden
           end
      end

      def read(current_user, id) do
        config = Crudblood.config(%{})
        resource = config.repo.get(__model, id)

        resource
        |> __can?(current_user, :read)
        |> case do
             true  -> {:ok, resource}
             false -> __forbidden
           end
      end

      def update(current_user, params, id) do
        config = Crudblood.config(%{})
        resource = config.repo.get(__model, id)
        changeset = __changeset(params, resource)

        changeset
        |> __can?(current_user, :update)
        |> case do
             true  -> config.repo.update(changeset)
             false -> __forbidden
           end
      end

      def destroy(current_user, id) do
        config = Crudblood.config(%{})
        resource = config.repo.get(__model, id)

        resource
        |> __can?(current_user, :destroy)
        |> case do
             true  -> {:ok, config.repo.delete(resource)}
             false -> __forbidden
           end
      end

      defp __forbidden do
        {:error, :forbidden}
      end

      defp __changeset(params, changing_model) do
        __model.changeset(changing_model, params)
      end

      defp __empty_model do
        Code.eval_string("%#{__model}{}") |> elem(0)
      end

      # if @model is specified, it'll use that. otherwise it'll try to
      # guess the model module based on the name of the api model
      # (example: MyApp.SomeThing.UserApiModel would evaluate to
      # MyApp.SomeThing.User)
      defp __model do
        @model || "#{__MODULE__}"
        |> String.replace(~r/^(.*)\.(.*)ApiModel$/, "\\1.\\2")
        |> Code.eval_string
        |> elem(0)
      end

      defp __can?(resource_being_accessed, current_resource, action) do
        # if a can? method is defined, use it to decide whether to
        # allow the action. otherwise just allow all actions
        if __MODULE__.__info__(:functions)[:can?] == 3 do
          can?(resource_being_accessed, current_resource, action)
        else
          true
        end
      end
    end
  end
end
