defmodule GettextSigils.Pluralization do
  @moduledoc ~S"""
  Splits a parsed `~t` sigil into singular and plural forms for Gettext pluralization.

  When the `msgid` contains a separator character, it is split into two parts —
  a singular and a plural form — and the `:count` binding is extracted to be
  passed as the `n` argument to `dpngettext/6`.

  ## Separator

  The default separator is `‖` (U+2016 DOUBLE VERTICAL LINE). It can be changed
  per-module or globally:

  ```elixir
  # config/config.exs
  config :gettext_sigils, pluralization: [separator: "||"]

  # per-module
  use GettextSigils,
    backend: MyApp.Gettext,
    sigils: [pluralization: [separator: "||"]]
  ```

  ## Examples

  ```elixir
  ~t"One error‖#{count} errors"
  #=> dpngettext("default", nil, "One error", "%{count} errors", count)

  ~t"One user‖#{count :: length(users)} users"
  #=> dpngettext("default", nil, "One user", "%{count} users", length(users))
  ```

  The `count` binding must appear in at least one part (singular or plural).
  It is removed from the bindings and only passed as the `n` argument.
  """

  @type singular() :: {binary(), Keyword.t()}
  @type plural() :: {binary(), binary(), Macro.t(), Keyword.t()}

  @spec maybe_split!(singular(), binary()) :: singular() | plural()
  def maybe_split!({msgid, bindings}, separator) do
    case String.split(msgid, separator) do
      [_single] ->
        {msgid, bindings}

      [singular, plural] ->
        {count, remaining_bindings} = extract_count!(bindings)
        {singular, plural, count, remaining_bindings}

      _parts ->
        raise ArgumentError,
              "plural message contains more than one separator #{inspect(separator)}, expected exactly one"
    end
  end

  defp extract_count!(bindings) do
    case Keyword.pop(bindings, :count) do
      {nil, _} ->
        raise ArgumentError,
              "plural message requires a \"count\" binding, but none was found"

      {count, remaining} ->
        {count, remaining}
    end
  end

  def default_separator do
    :gettext_sigils
    |> Application.get_env(:pluralization, [])
    |> Keyword.fetch!(:separator)
  end
end
