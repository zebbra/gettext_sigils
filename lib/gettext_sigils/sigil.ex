defmodule GettextSigils.Sigil do
  @moduledoc """
  Provides the `~t` sigil for interpolated translations.

  This module is automatically imported into modules that use `GettextSigils`.
  """

  alias GettextSigils.Interpolation
  alias GettextSigils.Modifiers
  alias GettextSigils.Options
  alias GettextSigils.Pluralization

  @doc """
  Translates the given string using the `Gettext` module.

  Elixir string interpolations are converted to `Gettext` interpolation syntax (e.g. `%{name}`),
  with their values as bindings.
  """

  @spec sigil_t(Macro.t(), charlist()) :: Macro.t()
  defmacro sigil_t(term, modifiers) do
    opts = Module.get_attribute(__CALLER__.module, :__gettext_sigils__)
    separator = Options.pluralization_separator(opts)

    {domain, context} = Modifiers.resolve!(modifiers, opts)

    term
    |> Interpolation.parse!()
    |> Pluralization.maybe_split!(separator)
    |> translate(domain, context)
  end

  defp translate({msgid, bindings}, domain, context) do
    quote do
      dpgettext(
        unquote(domain),
        unquote(context),
        unquote(msgid),
        unquote(bindings)
      )
    end
  end

  defp translate({msgid, msgid_plural, count, bindings}, domain, context) do
    quote do
      dpngettext(
        unquote(domain),
        unquote(context),
        unquote(msgid),
        unquote(msgid_plural),
        unquote(count),
        unquote(bindings)
      )
    end
  end
end
