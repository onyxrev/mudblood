defmodule Mudblood.Model do
  defmacro __using__(_) do
    quote do
      def __table do
        __MODULE__.__schema__(:source)
      end

      def __name do
        "#{__MODULE__}"
        |> String.split(".")
        |> List.last                                          # take the "AdminUser" from "MyApp.AdminUser"
        |> String.replace(~r/([A-Z]+)([A-Z][a-z])/,"\\1_\\2") # ... and snake case it (ex: "admin_user")
        |> String.replace(~r/([a-z\d])([A-Z])/,"\\1_\\2")
        |> String.replace("-", "_")
        |> String.downcase
      end

      def __plural_name do
        __table
      end
    end
  end
end
