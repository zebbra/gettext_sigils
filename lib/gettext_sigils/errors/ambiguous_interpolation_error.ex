defmodule GettextSigils.AmbiguousInterpolationError do
  @moduledoc """
  Raised when a `~t` sigil produces duplicate interpolation keys bound to different expressions.

  For example, `~t"\#{x :: foo} \#{x :: bar}"` raises this error because the key `x`
  maps to two different expressions. Use distinct keys to disambiguate.
  """
  defexception [:expr, :msgid, :keys]

  @impl true
  def message(%{expr: expr, msgid: msgid, keys: keys}) do
    """
    Expression results in ambiguous Gettext interpolation keys:

      expr: ~t#{Macro.to_string(expr)}
      msgid: "#{msgid}" (ambiguous keys: #{Enum.join(keys, ", ")})

    use the "::" operator to define a unique key-value binding, e.g. ~t"\#{key :: <binding>}"
    """
  end
end
