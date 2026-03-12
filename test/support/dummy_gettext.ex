defmodule GettextSigilsTest.DummyGettext do
  @moduledoc """
  A dummy Gettext backend for testing that returns the domain and context
  as part of the translated string instead of looking up PO files.

  ## Return format

      "domain[/context]: msgid"

  For example:

      handle_missing_translation("en", "errors", "admin", "Not found", %{})
      #=> {:ok, "errors/admin: Not found"}

      handle_missing_translation("en", "default", nil, "Hello", %{})
      #=> {:ok, "default: Hello"}

  Interpolation bindings are applied normally.
  """

  use Gettext.Backend, otp_app: :gettext_sigils

  @impl Gettext.Backend
  def handle_missing_translation(_locale, domain, msgctxt, msgid, bindings) do
    result = prefix(domain, msgctxt) <> interpolate(msgid, bindings)
    {:ok, result}
  end

  @impl Gettext.Backend
  def handle_missing_plural_translation(_locale, domain, msgctxt, msgid, msgid_plural, n, bindings) do
    msg = if n == 1, do: msgid, else: msgid_plural
    bindings = Map.put(bindings, :count, n)
    result = prefix(domain, msgctxt) <> interpolate(msg, bindings)
    {:ok, result}
  end

  @impl Gettext.Backend
  def handle_missing_bindings(_exception, incomplete) do
    incomplete
  end

  defp prefix(domain, nil), do: "#{domain}: "
  defp prefix(domain, msgctxt), do: "#{domain}/#{msgctxt}: "

  defp interpolate(msgid, bindings) when bindings == %{}, do: msgid

  defp interpolate(msgid, bindings) do
    Enum.reduce(bindings, msgid, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
