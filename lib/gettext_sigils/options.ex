defmodule GettextSigils.Options do
  @modifier_value_schema NimbleOptions.new!(
                           domain: [
                             type: :any,
                             doc: "Gettext domain to use when using this modifier."
                           ],
                           context: [
                             type: :any,
                             doc: "Gettext context to use when using this modifier."
                           ]
                         )

  @schema NimbleOptions.new!(
            domain: [
              type: :any,
              doc: "Default Gettext domain within the module that is using `GettextSigils`."
            ],
            context: [
              type: :any,
              doc: "Default Gettext context within the module that is using `GettextSigils`."
            ],
            modifiers: [
              type: {:list, {:custom, __MODULE__, :validate_modifier, []}},
              default: [],
              doc: """
              A keyword list of options applied when using the `~t` sigil with modifiers.

              The key has to be an atom between `:a` and `:z`. Uppercase modifiers are used by the library (eg. `N` for pluralization).

              Each modifier can define the following options:

              #{NimbleOptions.docs(@modifier_value_schema, nest_level: 1)}
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

  @modifier_keys Enum.map(?a..?z, &List.to_atom([&1]))

  @doc "Validates the given options or raises a `NimbleOptions.ValidationError` if invalid."
  @spec validate!(keyword()) :: keyword() | no_return()
  def validate!(opts) do
    NimbleOptions.validate!(opts, @schema)
  end

  @doc false
  def validate_modifier({key, value}) when key in @modifier_keys and is_list(value) do
    case NimbleOptions.validate(value, @modifier_value_schema) do
      {:ok, validated} -> {:ok, {key, validated}}
      {:error, error} -> {:error, "modifier #{inspect(key)}: #{Exception.message(error)}"}
    end
  end

  def validate_modifier({key, value}) when key in @modifier_keys do
    {:error, "modifier #{inspect(key)}: options must be a keyword list, got: #{inspect(value)}"}
  end

  def validate_modifier({key, _value}) do
    {:error, "modifier keys must be lowercase letters (a-z), got: #{inspect(key)}"}
  end
end
