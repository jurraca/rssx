defmodule Rssx.MixProject do
  use Mix.Project

  def project do
    [
      app: :rssx,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_xml_to_map, "~> 2.0"},
      {:req, "~> 0.5.0"},
      {:floki, "~> 0.35.0"}
    ]
  end
end
