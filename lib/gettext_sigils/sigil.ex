defmodule GettextSigils.Sigil do
  @moduledoc """
  Provides the `~t` sigil for interpolated translations.

  This module is automatically imported into modules that use `GettextSigils`.
  """

  alias GettextSigils.Interpolation
  alias GettextSigils.Modifiers
  alias GettextSigils.Pluralization

  @doc """
  Translates the given string using the `Gettext` module.

  The module has to use `GettextSigils` to import this sigil. See the [README](../../README.md) for more information.
  """

  @spec sigil_t(Macro.t(), charlist()) :: Macro.t()
  defmacro sigil_t(term, modifiers) do
    opts = Module.get_attribute(__CALLER__.module, :__gettext_sigils__)
    {domain, context, plural?} = Modifiers.resolve!(modifiers, opts)

    term
    |> Interpolation.parse!()
    |> maybe_pluralize!(plural?)
    |> translate(domain, context)
  end

  defp maybe_pluralize!(parsed, false = _plural?), do: parsed
  defp maybe_pluralize!(parsed, true = _plural?), do: Pluralization.pluralize!(parsed)

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
