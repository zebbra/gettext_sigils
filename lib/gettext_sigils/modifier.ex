defmodule GettextSigils.Modifier do
  @moduledoc """
  Behaviour for `~t` sigil modifiers.

  Implement this behaviour to extend the `~t` sigil with per-call
  transformations: validate opts (`init/1`), compute the Gettext
  domain/context (`domain_context/3`), rewrite the message at compile time
  (`preprocess/2`), turn it into a plural form (`pluralize/2`), or
  transform the final translated string at runtime (`postprocess/2`).

  All callbacks are optional. `use GettextSigils.Modifier` installs no-op
  defaults; override only what you need:

      defmodule MyApp.UpcaseModifier do
        use GettextSigils.Modifier

        @impl true
        def postprocess(string, _opts), do: {:ok, String.upcase(string)}
      end

  Wire it up via the `:modifiers` option:

      use GettextSigils,
        backend: MyApp.Gettext,
        sigils: [
          modifiers: [
            u: MyApp.UpcaseModifier,
            # with opts:
            s: {MyApp.ShoutModifier, intensity: 3}
          ]
        ]

  Every callback returns `{:ok, value}` or `{:error, reason}`, where
  `reason` is either a string or any exception struct (e.g. a
  `NimbleOptions.ValidationError`). Exception structs are normalized to
  strings via `Exception.message/1`. `init/1` errors raise a
  `NimbleOptions.ValidationError` at `use GettextSigils` time; all other
  errors raise `ArgumentError` at the respective compile or runtime stage.

  See the [Modifiers guide](modifiers.html) for full callback semantics,
  chaining rules, timing, and examples.
  """

  @type msgid :: binary()
  @type bindings :: keyword()
  @type input :: {msgid, bindings}
  @type opts :: keyword()
  @type reason :: String.t() | Exception.t()
  @type result(value) :: {:ok, value} | {:error, reason}
  @type domain :: binary() | :default | nil
  @type context :: binary() | nil
  @type domain_context :: {domain, context}
  @type pluralized ::
          input
          | {msgid, msgid, Macro.t(), bindings}

  @callback init(opts) :: result(opts)
  @callback domain_context(input, opts, domain_context) :: result(domain_context)
  @callback preprocess(input, opts) :: result(input)
  @callback postprocess(String.t(), opts) :: result(term())
  @callback pluralize(input, opts) :: result(pluralized)

  defmacro __using__(_opts) do
    quote do
      @behaviour GettextSigils.Modifier

      @impl true
      def init(opts), do: {:ok, opts}

      @impl true
      def domain_context(_input, _opts, domain_context), do: {:ok, domain_context}

      @impl true
      def preprocess(input, _opts), do: {:ok, input}

      @impl true
      def postprocess(string, _opts), do: {:ok, string}

      @impl true
      def pluralize(input, _opts), do: {:ok, input}

      defoverridable init: 1,
                     domain_context: 3,
                     preprocess: 2,
                     postprocess: 2,
                     pluralize: 2
    end
  end
end
