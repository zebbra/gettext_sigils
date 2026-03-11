defmodule GettextSigils.Errors.AmbiguousInterpolationKeys do
  @moduledoc false
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
