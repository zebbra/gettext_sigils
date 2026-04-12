defmodule GettextSigils.Modifiers.KeywordModifier do
  @schema NimbleOptions.new!(
            domain: [
              type: {:or, [:string, {:in, [:default]}]},
              doc:
                "Gettext domain. Use the `:default` atom to select the backend's configured default domain, or a binary to override."
            ],
            context: [
              type: {:or, [:string, nil]},
              doc: "Gettext context. Use `nil` to clear the context, or a binary to override."
            ]
          )

  @moduledoc """
  Built-in modifier that implements the static keyword-list form of
  modifier configuration.

  When a user writes `modifiers: [e: [domain: "errors"]]`, the keyword
  list is normalized to `{KeywordModifier, [domain: "errors"]}` so all
  modifiers flow through the same resolution path. See the
  [Modifiers guide](modifiers.html) for details.

  ## Options

  #{NimbleOptions.docs(@schema)}

  """

  use GettextSigils.Modifier

  @doc """
  Returns the `NimbleOptions` schema for this modifier's opts. Exposed so
  that `GettextSigils.Options` can interpolate the rendered docs into its
  top-level schema docstring without duplicating the schema definition.
  """
  @spec schema() :: NimbleOptions.t()
  def schema, do: @schema

  @impl true
  def init(opts) do
    opts
    |> deprecate_nil_domain()
    |> NimbleOptions.validate(@schema)
  end

  defp deprecate_nil_domain(opts) do
    case Keyword.fetch(opts, :domain) do
      {:ok, nil} ->
        IO.warn("setting :domain to nil is deprecated, use :default instead")
        Keyword.put(opts, :domain, :default)

      _ ->
        opts
    end
  end

  @impl true
  def domain_context(_input, opts, {domain, context}) do
    new_domain = Keyword.get(opts, :domain, domain)
    new_context = Keyword.get(opts, :context, context)
    {:ok, {new_domain, new_context}}
  end
end
