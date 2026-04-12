defmodule GettextSigils.Options do
  @schema NimbleOptions.new!(
            domain: [
              type: {:or, [:string, {:in, [:default]}]},
              doc:
                "Default Gettext domain within the module that is using `GettextSigils`. Use the `:default` atom to follow the backend's configured default domain, or a binary to override."
            ],
            context: [
              type: {:or, [:string, nil]},
              doc:
                "Default Gettext context within the module that is using `GettextSigils`. May be `nil` (the default) or a binary."
            ],
            modifiers: [
              type: {:list, {:custom, __MODULE__, :validate_modifier, []}},
              default: [],
              doc: """
              A keyword list of options applied when using the `~t` sigil with modifiers.

              The key has to be an atom between `:a` and `:z`. Uppercase modifiers are used by the library (eg. `N` for pluralization).

              Each entry can be a static keyword list, a module atom, or a `{module, opts}` tuple.
              The keyword-list form is shorthand for the built-in `GettextSigils.Modifiers.KeywordModifier`, whose options are:

              #{NimbleOptions.docs(GettextSigils.Modifiers.KeywordModifier.schema(), nest_level: 1)}
              """
            ]
          )

  @moduledoc """
  Validates `:sigils` options passed to `use GettextSigils`. All other options are passed through to `use Gettext`.

  ## Options

  #{NimbleOptions.docs(@schema)}

  ## Example

      use GettextSigils,
        backend: MyApp.Gettext,
        sigils: [
          domain: "default",
          context: "dashboard",
          modifiers: [
            e: [domain: "errors"],
            a: [context: "admin"]
          ]
        ]

  """

  alias GettextSigils.Modifiers.KeywordModifier

  @modifier_keys Enum.map(?a..?z, &List.to_atom([&1]))

  @doc """
  Validates the given options or raises a `NimbleOptions.ValidationError` if invalid.

  After validation, the `:modifiers` keyword list is converted into a map keyed by
  the character code of each modifier letter (e.g. `?e` instead of `:e`) so that
  modifier lookup can do a direct `Map.fetch/2` against the sigil charlist without
  re-converting characters to atoms on every expansion.
  """
  @spec validate!(keyword()) :: keyword() | no_return()
  def validate!(opts) do
    opts
    |> deprecate_nil_domain()
    |> NimbleOptions.validate!(@schema)
    |> Keyword.update!(:modifiers, &modifiers_to_map/1)
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

  defp modifiers_to_map(modifiers) do
    Map.new(modifiers, fn {key, value} ->
      [char] = Atom.to_charlist(key)
      {char, value}
    end)
  end

  @doc false
  def validate_modifier({key, _value}) when key not in @modifier_keys do
    {:error, "modifier keys must be lowercase letters (a-z), got: #{inspect(key)}"}
  end

  def validate_modifier({key, value}) when is_list(value) do
    init_modifier(key, KeywordModifier, value)
  end

  def validate_modifier({key, module}) when is_atom(module) do
    validate_modifier_module(key, module, [])
  end

  def validate_modifier({key, {module, opts}}) when is_atom(module) and is_list(opts) do
    validate_modifier_module(key, module, opts)
  end

  def validate_modifier({key, {module, bad_opts}}) when is_atom(module) do
    {:error, "modifier #{inspect(key)}: options must be a keyword list, got: #{inspect(bad_opts)}"}
  end

  def validate_modifier({key, value}) do
    {:error,
     "modifier #{inspect(key)}: expected a keyword list, module, or {module, keyword} tuple, " <>
       "got: #{inspect(value)}"}
  end

  defp validate_modifier_module(key, module, opts) do
    Code.ensure_compiled!(module)

    if implements_modifier?(module) do
      init_modifier(key, module, opts)
    else
      {:error, "modifier #{inspect(key)}: #{inspect(module)} does not implement GettextSigils.Modifier"}
    end
  end

  defp init_modifier(key, module, opts) do
    case module.init(opts) do
      {:ok, validated} ->
        {:ok, {key, {module, validated}}}

      {:error, reason} ->
        {:error, "modifier #{inspect(key)}: #{GettextSigils.Modifiers.format_error(reason)}"}
    end
  end

  defp implements_modifier?(module) do
    behaviours = module.module_info(:attributes)[:behaviour] || []
    GettextSigils.Modifier in behaviours
  end
end
