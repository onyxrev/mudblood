defmodule Crudblood.Mixfile do
  use Mix.Project

  def project do
    [
      app: :crudblood,
      version: "0.0.3",
      elixir: "~> 1.0",
      elixirc_paths: elixirc_paths(Mix.env),
      description: description,
      package: package,
      deps: deps
    ]
  end

  def application do
    [applications: applications(Mix.env)]
  end

  #
  # Private
  #

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["test/support"] ++ elixirc_paths(:prod)
  defp elixirc_paths(_),     do: ["lib"]

  defp applications(:test) do
    [:logger, :ecto] ++ applications(:prod)
  end

  defp applications(_) do
    [:ecto, :phoenix]
  end

  defp deps do
    [
      {:ecto, "~> 1.1.9"},
      {:phoenix, "~> 1.2.0"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Dan Connor Consulting"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/onyxrev/crudblood"}
    ]
  end

  defp description do
    """
    A DRY way to get CRUD.
    """
  end

end
