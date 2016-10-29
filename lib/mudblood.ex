defmodule Crudblood do
  @moduledoc """
  A DRY way to get CRUD.
  """

  @doc """
  Decides to use the override_config or application config.
  The result is merged with the default configuration options specified by Crudblood.
  """
  @spec config(Map.t | nil) :: Map.t
  def config(override_config) do
    configuration = if is_nil(override_config) || Enum.empty?(override_config) do
      Enum.into(Application.get_env(:crudblood, Crudblood), %{})
    else
      override_config
    end

    Map.merge(%{}, configuration)
  end
end
