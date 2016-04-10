defmodule Crudblood.Model do
  defmacro __using__(_) do
    quote do
      def __table do
        __MODULE__.__schema__(:source)
      end

      def __name do
        "#{__MODULE__}"
        |> String.split(".")
        |> List.last # take the "AdminUser" from "MyApp.AdminUser"
        |> Phoenix.Naming.underscore
      end

      def __plural_name do
        __table
      end
    end
  end
end
