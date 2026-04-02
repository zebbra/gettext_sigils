defmodule GettextSigils.Pluralization do
  @moduledoc ~S"""
  Handles pluralization for the `~t` sigil's `N` modifier.

  When the `N` modifier is present, the message is used as both `msgid` and
  `msgid_plural`, and a binding is extracted as the `n` argument
  to `dpngettext/6`.

  If the message has a single binding, it is used as the count regardless of
  its name. If there are multiple bindings, one must be named `:count`.

  ## Examples

      ~t"#{count} error(s)"N
      #=> dpngettext("default", nil, "%{count} error(s)", "%{count} error(s)", count)

  The resulting PO entry can be translated with distinct singular/plural forms:

      msgid "%{count} error(s)"
      msgid_plural "%{count} error(s)"
      msgstr[0] "One error"
      msgstr[1] "%{count} errors"
  """

  @type singular() :: {binary(), Keyword.t()}
  @type plural() :: {binary(), binary(), Macro.t(), Keyword.t()}

  @spec pluralize!(singular()) :: plural()
  def pluralize!({_msgid, []}) do
    raise ArgumentError,
          "plural message requires at least one binding for the count"
  end

  def pluralize!({msgid, [{_key, value}]}) do
    {msgid, msgid, value, []}
  end

  def pluralize!({msgid, bindings}) do
    case Keyword.pop(bindings, :count) do
      {nil, _} ->
        raise ArgumentError,
              "plural message with multiple bindings requires a \"count\" binding to identify the pluralizer"

      {count, remaining} ->
        {msgid, msgid, count, remaining}
    end
  end
end
