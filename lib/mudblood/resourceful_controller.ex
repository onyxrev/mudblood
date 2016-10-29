defmodule Crudblood.ResourcefulController do
  defmacro __using__(_) do
    quote do
      def index(conn, params) do
        __index_resource(conn, params)
      end

      def create(conn, params) do
        __create_resource(conn, params)
      end

      def show(conn, %{"id" => id}) do
        __show_resource(conn, id)
      end

      def update(conn, params) do
        __update_resource(conn, __resource_params(conn), params["id"])
      end

      def delete(conn, %{"id" => id}) do
        __delete_resource(conn, id)
      end

      defp __create_resource(conn, _params, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {__api_model(conn).create(current_resource, __resource_params(conn)), on_success, on_failure} do
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
            |> put_resp_header("location", __created_resource_path(conn, resource))
            |> render("show.json", __render_params(conn, resource))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp __index_resource(conn, params, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {__api_model(conn).read_all(current_resource, params), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            conn
            |> send_resp(:forbidden, "")
            |> halt
          {{:ok, resources}, nil, _} ->
            render(conn, "index.json", __render_plural_params(conn, resources))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp __show_resource(conn, id, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {__api_model(conn).read(current_resource, id), on_success, on_failure} do
          {{:error, :forbidden}, _, nil} ->
            conn
            |> send_resp(:forbidden, "")
            |> halt
          {{:ok, resource}, nil, _} ->
            render(conn, "show.json", __render_params(conn, resource))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp __update_resource(conn, resource_params, id, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {__api_model(conn).update(current_resource, resource_params, id), on_success, on_failure} do
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
            render(conn, "show.json", __render_params(conn, resource))
          {{:ok, resource}, on_success, _} ->
            on_success.(resource)
          {{:error, result}, _, on_failure} ->
            on_failure.(result)
        end
      end

      defp __delete_resource(conn, id, clauses \\ []) do
        current_resource = get_current_resource(conn)

        on_success = Keyword.get(clauses, :success, nil)
        on_failure = Keyword.get(clauses, :failure, nil)

        case {__api_model(conn).destroy(current_resource, id), on_success, on_failure} do
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

      defp __api_model(conn) do
        @api_model || "#{__MODULE__}"
        |> String.replace(~r/^(.*)Controller/, "\\1ApiModel")
        |> Code.eval_string
        |> elem(0)
      end

      defp __model(conn) do
        app = Crudblood.config(%{}).app

        Code.eval_string("#{app}.#{__resource_string(conn)}") |> elem(0)
      end

      defp __resource_atom(conn) do
        __resource_string(conn)
        |> String.downcase
        |> String.to_atom
      end

      defp __resource_string(conn) do
        conn.private[:phoenix_controller]
        |> Module.split
        |> List.last
        |> String.replace("Controller", "")
      end

      defp __resource_params(conn) do
        conn.params |> Map.fetch!(Atom.to_string(__resource_atom(conn)))
      end

      defp __render_params(conn, resource) do
        Map.put(%{}, __model(conn).__name |> String.to_atom, resource)
      end

      defp __render_plural_params(conn, resources) do
        # FIXME: is there some better way to pluralize a model name?
        Map.put(%{}, __model(conn).__plural_name |> String.to_atom, resources)
      end

      defp __created_resource_path(conn, created_resource) do
        [conn.request_path, created_resource.id] |> Enum.join("/")
      end

      defp get_current_resource(conn) do
        IO.puts "get_current_resource not implemented!"
      end
    end
  end
end
