defmodule Crudblood.Model do
  defmacro __using__(_) do
    quote do
      def table do
        __MODULE__.__schema__(:source)
      end

      def name do
        "#{__MODULE__}" |>
          String.split(".") |>
          List.last |>
          String.downcase
      end

      def plural_name do
        table
      end
    end
  end
end
