defmodule Crudblood.Model do
  defmacro __using__(_) do
    quote do
      def table do
        __MODULE__.__schema__(:source)
      end

      def name do
        "#{__MODULE__}"
        |> String.split(".")
        |> List.last                                          # take the "AdminUser" from "MyApp.AdminUser"
        |> String.replace(~r/([A-Z]+)([A-Z][a-z])/,"\\1_\\2") # ... and snake case it (ex: "admin_user")
        |> String.replace(~r/([a-z\d])([A-Z])/,"\\1_\\2")
        |> String.replace("-", "_")
        |> String.downcase
      end

      def plural_name do
        table
      end
    end
  end
end
