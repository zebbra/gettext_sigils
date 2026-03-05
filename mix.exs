defmodule GettextSigils.MixProject do
  use Mix.Project

  def project do
    [
      app: :gettext_sigils,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      usage_rules: usage_rules(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp usage_rules do
    [
      file: "AGENTS.md",
      usage_rules: [
        :usage_rules,
        {~r/.*/, link: :markdown}
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, "~> 0.26"},
      {:tidewave, "~> 0.5", only: [:dev]},
      {:usage_rules, "~> 1.0", only: [:dev]},
      {:igniter, "~> 0.6", only: [:dev]},
      {:bandit, "~> 1.0", only: [:dev]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      tidewave:
        "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
    ]
  end
end
