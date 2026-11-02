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
    opts = options!(__CALLER__, modifiers)

    defaults = {Keyword.get(opts, :domain, :default), Keyword.get(opts, :context, nil)}

    modifier_map = Keyword.get(opts, :modifiers, %{})
    modifiers = Modifiers.lookup_modifiers!(modifiers, modifier_map)

    parsed = interpolate(term)
    {domain, context} = Modifiers.resolve_domain_context!(modifiers, parsed, defaults)

    parsed
    |> preprocess(modifiers)
    |> pluralize(modifiers)
    |> translate_or_noop(domain, context, modifiers)
  end

  # Outside a function `~t` expands before the module body runs, so only a noop message with
  # options stored at expansion time can work there.
  defp options!(%{function: nil} = env, modifiers) do
    if ?X not in modifiers, do: raise_outside_function!(env, "needs the X modifier")

    Module.get_attribute(env.module, :__gettext_sigils__) ||
      raise_outside_function!(env, "needs literal :sigils options in the latest `use GettextSigils`")
  end

  defp options!(env, _modifiers), do: Module.get_attribute(env.module, :__gettext_sigils__)

  defp raise_outside_function!(env, reason) do
    raise CompileError,
      file: env.file,
      line: env.line,
      description: "~t outside a function in #{inspect(env.module)} #{reason}; otherwise use ~t inside a function"
  end

  defp interpolate(term), do: Interpolation.parse!(term)

  defp preprocess(parsed, modifiers), do: Modifiers.preprocess!(modifiers, parsed)

  defp pluralize(parsed, modifiers), do: Modifiers.pluralize!(modifiers, parsed)

  # A noop message is never looked up, so there is no translation to postprocess.
  defp translate_or_noop({:noop, pluralized}, domain, context, _modifiers), do: noop(pluralized, domain, context)

  defp translate_or_noop(pluralized, domain, context, modifiers) do
    pluralized
    |> translate(domain, context)
    |> postprocess(modifiers)
  end

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

  defp noop({msgid, _bindings}, domain, context) do
    quote do
      dpgettext_noop(
        unquote(domain),
        unquote(context),
        unquote(msgid)
      )
    end
  end

  defp noop({msgid, msgid_plural, _count, _bindings}, domain, context) do
    quote do
      dpngettext_noop(
        unquote(domain),
        unquote(context),
        unquote(msgid),
        unquote(msgid_plural)
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
