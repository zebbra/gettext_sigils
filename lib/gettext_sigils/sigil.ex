defmodule GettextSigils.Sigil do
  @moduledoc """
  Provides the `~t` sigil for interpolated translations.

  This module is automatically imported into modules that use `GettextSigils`.
  """

  alias GettextSigils.Interpolation
  alias GettextSigils.Modifiers

  @doc """
  Translates the given string using the `Gettext` module.

  The module has to `use GettextSigils` to import this sigil. See `GettextSigils` for setup.
  """

  @spec sigil_t(Macro.t(), charlist()) :: Macro.t()
  defmacro sigil_t(term, modifiers) do
    opts = Module.get_attribute(__CALLER__.module, :__gettext_sigils__)

    defaults = {Keyword.get(opts, :domain, :default), Keyword.get(opts, :context, nil)}

    modifier_map = Keyword.get(opts, :modifiers, %{})
    modifiers = Modifiers.lookup_modifiers!(modifiers, modifier_map)

    parsed = interpolate(term)
    {domain, context} = Modifiers.resolve_domain_context!(modifiers, parsed, defaults)

    parsed
    |> preprocess(modifiers)
    |> pluralize(modifiers)
    |> translate(domain, context)
    |> postprocess(modifiers)
  end

  defp interpolate(term), do: Interpolation.parse!(term)

  defp preprocess(parsed, modifiers), do: Modifiers.preprocess!(modifiers, parsed)

  defp pluralize(parsed, modifiers), do: Modifiers.pluralize!(modifiers, parsed)

  # Emits a runtime call to `Modifiers.postprocess!/2` that walks the
  # resolved modifier chain at runtime, piping the translated string
  # through each modifier's `postprocess/2` callback. The chain is
  # baked into the call site as a literal.
  defp postprocess(inner, modifiers) do
    quote do
      GettextSigils.Modifiers.postprocess!(
        unquote(Macro.escape(modifiers)),
        unquote(inner)
      )
    end
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
