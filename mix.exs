defmodule GettextSigils.MixProject do
  use Mix.Project

  @description """
  A ~t sigil for Gettext translations, to reduce boilerplate and improve readability.
  """

  @version "0.1.0"

  def project do
    [
      app: :gettext_sigils,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Gettext Sigils",
      description: @description,
      source_url: "https://github.com/zebbra/gettext_sigils",
      docs: docs(),
      aliases: aliases(),
      package: package()
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
      {:gettext, "~> 1.0"},
      {:tidewave, "~> 0.5", only: [:dev]},
      {:igniter, "~> 0.6", only: [:dev]},
      {:bandit, "~> 1.0", only: [:dev]},
      {:styler, "~> 1.11", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "GettextSigils",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      name: "gettext_sigils",
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      links: %{
        "GitHub" => "https://github.com/zebbra/gettext_sigils"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      tidewave: "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
    ]
  end
end
