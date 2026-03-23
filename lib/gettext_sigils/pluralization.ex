defmodule GettextSigils.Pluralization do
  @moduledoc ~S"""
  Handles pluralization for the `~t` sigil's `N` modifier.

  When the `N` modifier is present, the message is used as both `msgid` and
  `msgid_plural`, and the `:count` binding is extracted as the `n` argument
  to `dpngettext/6`.

  ## Examples

      ~t"#{count} error(s)"N
      #=> dpngettext("default", nil, "%{count} error(s)", "%{count} error(s)", count)

  The resulting PO entry can be translated with distinct singular/plural forms:

      msgid "%{count} error(s)"
      msgid_plural "%{count} error(s)"
      msgstr[0] "One error"
      msgstr[1] "%{count} errors"

  ## Deprecated: Separator-based pluralization

  Using a separator (`||`) to split singular/plural forms is deprecated and
  will be removed in a future version. Migrate to the shared-message approach:

      # deprecated
      ~t"One error||#{count} errors"N

      # use instead
      ~t"#{count} error(s)"N
  """

  @type singular() :: {binary(), Keyword.t()}
  @type plural() :: {binary(), binary(), Macro.t(), Keyword.t()}

  @spec split!(singular(), binary()) :: plural()
  def split!({msgid, bindings}, separator) do
    case String.split(msgid, separator) do
      [_single] ->
        {count, remaining} = extract_count!(bindings)
        {msgid, msgid, count, remaining}

      [singular, plural] ->
        IO.warn(
          "using a separator (#{inspect(separator)}) for pluralization in ~t sigil is deprecated, " <>
            ~s'use a shared message instead, e.g. ~t"\#{count} item(s)"N. ' <>
            "See https://github.com/zebbra/gettext_sigils/issues/20"
        )

        {count, remaining} = extract_count!(bindings)
        {singular, plural, count, remaining}

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
