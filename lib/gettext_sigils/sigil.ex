defmodule GettextSigils.Sigil do
  @moduledoc """
  Provides the `~t` sigil for interpolated translations.

  This module is automatically imported into modules that use `GettextSigils`.
  """

  alias GettextSigils.Interpolation
  alias GettextSigils.Modifiers

  @doc """
  Translates the given string using the `Gettext` module.

  Elixir string interpolations are converted to `Gettext` interpolation syntax (e.g. `%{name}`),
  with their values as bindings.
  """

  @spec sigil_t(Macro.t(), charlist()) :: Macro.t()
  defmacro sigil_t(term, modifiers) do
    opts = Module.get_attribute(__CALLER__.module, :__gettext_sigils__)

    {domain, context} = Modifiers.resolve!(modifiers, opts)
    {msgid, bindings} = Interpolation.parse!(term)

    quote do
      dpgettext(
        unquote(domain),
        unquote(context),
        unquote(msgid),
        unquote(bindings)
      )
    end
  end
end
