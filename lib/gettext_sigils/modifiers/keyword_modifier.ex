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
            ],
            preprocess: [
              type: {:custom, __MODULE__, :validate_fn, []},
              doc: """
              A remote function capture (e.g. `&MyApp.Util.trim/1`) called at
              compile time with the parsed `{msgid, bindings}` tuple. It must
              return `{:ok, {msgid, bindings}}` or `{:error, reason}`.
              """
            ],
            postprocess: [
              type: {:custom, __MODULE__, :validate_fn, []},
              doc: """
              A remote function capture (e.g. `&String.upcase/1`) called at
              runtime with the final translated string. It must return
              `{:ok, value}` (any term) or `{:error, reason}`.
              """
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

  The `:preprocess` and `:postprocess` values must be **remote function
  captures** (e.g. `&String.upcase/1`) because they are baked into the
  runtime AST of each `~t` call site. Anonymous functions like
  `fn s -> ... end` and local captures are rejected at `use GettextSigils`
  time.
  """

  use GettextSigils.Modifier

  @doc """
  Returns the `NimbleOptions` schema for this modifier's opts. Exposed so
  that `GettextSigils.Options` can interpolate the rendered docs into its
  top-level schema docstring without duplicating the schema definition.
  """
  @spec schema() :: NimbleOptions.t()
  def schema, do: @schema

  @doc false
  def validate_fn(fun) when is_function(fun, 1) do
    case Function.info(fun, :type) do
      {:type, :external} ->
        {:ok, fun}

      _ ->
        {:error,
         "must be a remote function capture like `&Module.function/1`, " <>
           "anonymous and local functions cannot be used here"}
    end
  end

  def validate_fn(other) do
    {:error, "expected a remote function capture (arity 1), got: #{inspect(other)}"}
  end

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

  @impl true
  def preprocess(parsed, opts) do
    case Keyword.fetch(opts, :preprocess) do
      {:ok, fun} -> fun.(parsed)
      :error -> {:ok, parsed}
    end
  end

  @impl true
  def postprocess(string, opts) do
    case Keyword.fetch(opts, :postprocess) do
      {:ok, fun} -> fun.(string)
      :error -> {:ok, string}
    end
  end
end
