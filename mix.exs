defmodule GettextSigils.MixProject do
  use Mix.Project

  @description """
  A ~t sigil for Gettext translations, to reduce boilerplate and improve readability.
  """

  @version "0.3.1"
  @github_url "https://github.com/zebbra/gettext_sigils"

  def project do
    [
      app: :gettext_sigils,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      usage_rules: usage_rules(),

      # Docs
      name: "Gettext Sigils",
      docs: docs(),

      # Hex
      description: @description,
      source_url: @github_url,
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [preferred_envs: ["test.watch": :test]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, "~> 1.0"},
      {:nimble_options, "~> 1.1"},
      {:igniter, "~> 0.7", optional: true},
      {:tidewave, "~> 0.5", only: [:dev]},
      {:usage_rules, "~> 1.0", only: [:dev]},
      {:bandit, "~> 1.0", only: [:dev]},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.11", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:phx_new, "~> 1.7", optional: true, only: [:dev, :test]}
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

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        {"README.md", title: "Home"},
        {"CHANGELOG.md", title: "Changelog"},
        "guides/llm.md"
      ],
      groups_for_extras: [
        Guides: Path.wildcard("guides/*.md")
      ],
      groups_for_modules: []
    ]
  end

  defp package do
    [
      name: "gettext_sigils",
      licenses: ["MIT"],
      files: ~w(lib usage-rules.md usage-rules .formatter.exs mix.exs README.md LICENSE),
      links: %{
        "GitHub" => @github_url
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      precommit: [
        "lint"
      ],
      lint: [
        "compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "credo --strict"
      ],
      tidewave: "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
    ]
  end
end
