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
    {domain, context, plural?} = Modifiers.resolve!(modifiers, opts)

    term
    |> Interpolation.parse!()
    |> maybe_pluralize!(opts, plural?)
    |> translate(domain, context)
  end

  defp maybe_pluralize!(parsed, _opts, false = _plural?) do
    parsed
  end

  defp maybe_pluralize!(parsed, opts, true = _plural?) do
    separator = Options.pluralization_separator(opts)
    Pluralization.split!(parsed, separator)
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
