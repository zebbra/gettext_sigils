defmodule GettextSigils.Modifiers.PluralModifier do
  @moduledoc ~S"""
  Built-in modifier that implements the `N` sigil modifier's
  pluralization logic.

  Looks up `:count` in the bindings and, if present, returns
  `{:ok, {msgid, msgid, count, remaining_bindings}}` so the sigil macro
  emits a `dpngettext/6` call. If `:count` is absent, returns an error
  that the sigil macro raises as a compile-time `ArgumentError`.

  See the [Pluralization guide](pluralization.html) for the full
  semantics and examples.
  """

  use GettextSigils.Modifier

  @impl true
  def pluralize({msgid, bindings}, _opts) do
    case Keyword.pop(bindings, :count) do
      {nil, _} ->
        {:error, ~s|plural message requires a "count" binding, but none was found|}

      {count, remaining} ->
        {:ok, {msgid, msgid, count, remaining}}
    end
  end
end
