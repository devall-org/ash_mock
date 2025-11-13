defmodule AshMock.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_mock,
      version: "0.2.2",
      elixir: "~> 1.17",
      consolidate_protocols: Mix.env() not in [:dev, :test],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A mock resource generator extension for Ash resources.",
      package: package(),
      source_url: "https://github.com/devall-org/ash_mock",
      homepage_url: "https://github.com/devall-org/ash_mock",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
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
      {:ash, ">= 0.0.0"},
      {:ash_random_params, ">= 0.0.0"},
      {:spark, ">= 0.0.0"},
      {:sourceror, ">= 0.0.0", only: [:dev, :test], optional: true},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "ash_mock",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/devall-org/ash_mock"
      }
    ]
  end
end
