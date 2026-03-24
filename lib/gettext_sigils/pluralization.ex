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
  """

  @type singular() :: {binary(), Keyword.t()}
  @type plural() :: {binary(), binary(), Macro.t(), Keyword.t()}

  @spec pluralize!(singular()) :: plural()
  def pluralize!({msgid, bindings}) do
    {count, remaining} = extract_count!(bindings)
    {msgid, msgid, count, remaining}
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
end
