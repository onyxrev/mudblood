defmodule Crudblood.Model do
  defmacro __using__(_) do
    quote do
      def table do
        @table
      end

      def name do
        @name
      end

      def plural_name do
        @plural_name
      end
    end
  end
end
