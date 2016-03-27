defmodule Crudblood.ApiModel do
  defmacro __using__(_) do
    quote do
      def create(current_user, params) do
        config = Crudblood.config(%{})
        changeset = changeset(params, empty_model)

        changeset
        |> model.can?(current_user, :create)
        |> case do
             true  -> config.repo.insert(changeset)
             false -> forbidden
           end
      end

      def read_all(current_user, params \\ %{}) do
        model.can?(current_user, :read_all)
        |> case do
             true  ->
               # FIXME: this is janky as hell
               {:ok,
                # TODO: support more params like limit and offset
                model.table
                |> Query.table()
                |> Query.filter(params)
                |> Crudblood.config.repo.run
                |> Enum.fetch(0)
               }
             false ->
               forbidden
           end
      end

      def read(current_user, id) do
        config = Crudblood.config(%{})
        resource = config.repo.get(model, id)

        resource
        |> model.can?(current_user, :read)
        |> case do
             true  -> {:ok, resource}
             false -> forbidden
           end
      end

      def update(current_user, params, id) do
        config = Crudblood.config(%{})
        resource = config.repo.get(model, id)
        changeset = changeset(params, resource)

        changeset
        |> model.can?(current_user, :update)
        |> case do
             true  -> config.repo.update(changeset)
             false -> forbidden
           end
      end

      def destroy(current_user, id) do
        config = Crudblood.config(%{})
        resource = config.repo.get(model, id)

        resource
        |> model.can?(current_user, :destroy)
        |> case do
             true  -> {:ok, config.repo.delete(resource)}
             false -> forbidden
           end
      end

      defp forbidden do
        {:error, :forbidden}
      end

      defp changeset(params, changing_model) do
        model.changeset(changing_model, params)
      end

      defp empty_model do
        Code.eval_string("%#{model}{}") |> elem(0)
      end

      # if @model is specified, it'll use that. otherwise it'll try to
      # guess the model module based on the name of the api model
      # (example: MyApp.SomeThing.UserApiModel would evaluate to
      # MyApp.SomeThing.User)
      defp model do
        @model || "#{__MODULE__}"
        |> String.replace(~r/^(.*)\.(.*)ApiModel$/, "\\1.\\2")
        |> Code.eval_string
        |> elem(0)
      end
    end
  end
end
