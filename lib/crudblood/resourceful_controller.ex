defmodule Crudblood.ResourcefulController do
  defmacro __using__(_) do
    quote do
      def action(conn, _) do
        apply(__MODULE__, action_name(conn), [conn,
                                              conn.params,
                                              Guardian.Plug.current_resource(conn)])
      end

      def index(conn, params, current_user) do
        index_resource(conn, params, current_user)
      end

      def create(conn, params, current_user) do
        create_resource(conn, params, current_user)
      end

      def show(conn, %{"id" => id}, current_user) do
        show_resource(conn, id, current_user)
      end

      def update(conn, params, current_user) do
        update_resource(conn, resource_params(conn), params["id"], current_user)
      end

      def delete(conn, %{"id" => id}, current_user) do
        delete_resource(conn, id, current_user)
      end

      defp create_resource(conn, _params, current_user, clauses \\ []) do
        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).create(current_user, resource_params(conn)), on_success, on_failure} do
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

      defp index_resource(conn, current_user, params, clauses \\ []) do
        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).read_all(current_user, params), on_success, on_failure} do
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

      defp show_resource(conn, id, current_user, clauses \\ []) do
        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).read(current_user, id), on_success, on_failure} do
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

      defp update_resource(conn, resource_params, id, current_user, clauses \\ []) do
        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).update(current_user, resource_params, id), on_success, on_failure} do
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

      defp delete_resource(conn, id, current_user, clauses \\ []) do
        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {api_model(conn).destroy(current_user, id), on_success, on_failure} do
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
    end
  end
end
