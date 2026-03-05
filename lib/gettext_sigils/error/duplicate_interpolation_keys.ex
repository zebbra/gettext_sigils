defmodule GettextSigils.Error.DuplicateInterpolationKeys do
  defexception [:expr, :msgid, :duplicates]

  @impl true
  def message(%{expr: expr, msgid: msgid, duplicates: duplicates}) do
    """
    Expression results in duplicate Gettext interpolation keys:

      expr: ~t#{Macro.to_string(expr)}
      msgid: "#{msgid}" (duplicates: #{Enum.join(duplicates, ", ")})

    use the "::" operator to define a unique key-value binding, e.g. ~t"\#{key :: <binding>}"
    """
  end
end
