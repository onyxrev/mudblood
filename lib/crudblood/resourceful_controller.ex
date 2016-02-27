defmodule Crudblood.ResourcefulController do
  defmacro __using__(_) do
    quote do
      def index(conn, params) do
        index_resource(conn, params)
      end

      def create(conn, params) do
        create_resource(conn, params)
      end

      def show(conn, %{"id" => id}) do
        show_resource(conn, id)
      end

      def update(conn, params) do
        update_resource(conn, resource_params(conn), params["id"])
      end

      def delete(conn, %{"id" => id}) do
        delete_resource(conn, id)
      end

      defp create_resource(conn, _params, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).create(current_resource, resource_params(conn)), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            conn
            |> send_resp(:forbidden, "")
            |> halt
          {{:error, changeset}, _, nil} ->
            changeset_view = Crudblood.config(%{}).changeset_view

            conn
            |> put_status(:unprocessable_entity)
            |> render(changeset_view, "error.json", changeset: changeset)
          {{:ok, resource}, nil, _} ->
            conn
            |> put_status(:created)
            |> put_resp_header("location", created_resource_path(conn, resource))
            |> render("show.json", render_params(conn, resource))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp index_resource(conn, params, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).read_all(current_resource, params), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            conn
            |> send_resp(:forbidden, "")
            |> halt
          {{:ok, resources}, nil, _} ->
            render(conn, "index.json", render_plural_params(conn, resources))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp show_resource(conn, id, clauses \\ []) do
        current_resource = Crudblood.config(%{}).current_resource_method(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).read(current_resource, id), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            conn
            |> send_resp(:forbidden, "")
            |> halt
          {{:ok, resource}, nil, _} ->
            render(conn, "show.json", render_params(conn, resource))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp update_resource(conn, resource_params, id, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).update(current_resource, resource_params, id), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            conn
            |> send_resp(:forbidden, "")
            |> halt
          {{:error, changeset}, _, nil} ->
            changeset_view = Crudblood.config(%{}).changeset_view

            conn
            |> put_status(:unprocessable_entity)
            |> render(changeset_view, "error.json", changeset: changeset)
          {{:ok, resource}, nil, _} ->
            render(conn, "show.json", render_params(conn, resource))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp delete_resource(conn, id, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).destroy(current_resource, id), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            conn
            |> send_resp(:forbidden, "")
            |> halt
          {{:ok, resource}, nil, _} ->
            send_resp(conn, :no_content, "")
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp api_model(conn) do
        Code.eval_string(@api_model) |> elem(0)
      end

      defp model(conn) do
        app = Crudblood.config(%{}).app

        Code.eval_string("#{app}.#{resource_string(conn)}") |> elem(0)
      end

      defp resource_atom(conn) do
        resource_string(conn)
        |> String.downcase
        |> String.to_atom
      end

      defp resource_string(conn) do
        conn.private[:phoenix_controller]
        |> Module.split
        |> List.last
        |> String.replace("Controller", "")
      end

      defp resource_params(conn) do
        conn.params |> Map.fetch!(Atom.to_string(resource_atom(conn)))
      end

      defp render_params(conn, resource) do
        Map.put(%{}, model(conn).name |> String.to_atom, resource)
      end

      defp render_plural_params(conn, resources) do
        # FIXME: is there some better way to pluralize a model name?
        Map.put(%{}, model(conn).plural_name |> String.to_atom, resources)
      end

      defp created_resource_path(conn, created_resource) do
        [conn.request_path, created_resource.id] |> Enum.join("/")
      end

      defp get_current_resource(conn) do
        IO.puts "get_current_resource not implemented!"
      end
    end
  end
end
