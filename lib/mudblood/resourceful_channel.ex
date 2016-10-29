defmodule Mudblood.ResourcefulChannel do
  defmacro __using__(_) do
    quote do
      defp __create_resource(api_model, payload, socket, clauses \\ []) do
        current_resource = get_current_resource(socket)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model.create(current_resource, payload), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            {:reply, {:error, %{reason: "unauthorized"}}, socket}
          {{:error, changeset}, _, nil} ->
            changeset_view = Mudblood.config(%{}).changeset_view

            {:reply, {:error, Map.put(changeset_view.render("error.json", changeset: changeset), :reason, "invalid")}, socket}
          {{:ok, resource}, nil, _} ->
            {:reply, {:ok, resource}, socket}
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp __index_resource(api_model, payload, socket, clauses \\ []) do
        current_resource = get_current_resource(socket)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model.read_all(current_resource, payload), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            {:reply, {:error, %{reason: "unauthorized"}}, socket}
          {{:ok, resources}, nil, _} ->
            {:reply, {:ok, resources}, socket}
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp show_resource(api_model, id, socket, clauses \\ []) do
        current_resource = get_current_resource(socket)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model.read(current_resource, id), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            {:reply, {:error, %{reason: "unauthorized"}}, socket}
          {{:ok, resource}, nil, _} ->
            {:reply, {:ok, resource}, socket}
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp __update_resource(api_model, resource_payload, socket, id, clauses \\ []) do
        current_resource = get_current_resource(socket)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model.update(current_resource, resource_payload, id), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            {:reply, {:error, %{reason: "unauthorized"}}, socket}
          {{:error, changeset}, _, nil} ->
            changeset_view = Mudblood.config(%{}).changeset_view

            {:reply, {:error, Map.put(changeset_view.render("error.json", changeset: changeset), :reason, "invalid")}, socket}
          {{:ok, resource}, nil, _} ->
            {:reply, {:ok, resource}, socket}
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp __delete_resource(api_model, id, socket, clauses \\ []) do
        current_resource = get_current_resource(socket)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model.destroy(current_resource, id), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            {:reply, {:error, %{reason: "unauthorized"}}, socket}
          {{:ok, resource}, nil, _} ->
            {:reply, :ok, socket}
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end
    end
  end
end
