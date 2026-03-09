defmodule GettextSigils.Sigil do
  @moduledoc false

  defmacro sigil_t(ast, modifiers) do
    {msgid, bindings} = GettextSigils.Bindings.parse(ast)
    translate(__CALLER__, msgid, bindings, modifiers)
  end

  defp translate(caller, msgid, bindings, modifiers) do
    opts = Module.get_attribute(caller.module, :__gettext_sigils__)
    domain = Keyword.get(opts, :default_domain, :default)
    context = Keyword.get(opts, :default_context, nil)
    modifier_defs = Keyword.get(opts, :modifiers, [])

    {domain, context} = resolve_modifiers(modifiers, modifier_defs, domain, context)

    quote do
      dpgettext(
        unquote(domain),
        unquote(context),
        unquote(msgid),
        unquote(bindings)
      )
    end
  end

  defp resolve_modifiers([], _defs, domain, context), do: {domain, context}

  defp resolve_modifiers(modifiers, modifier_defs, domain, context) do
    Enum.reduce(modifiers, {domain, context}, fn modifier, {d, c} ->
      key = List.to_atom([modifier])

      case Keyword.fetch(modifier_defs, key) do
        {:ok, opts} ->
          d = Keyword.get(opts, :domain, d)
          c = if Keyword.has_key?(opts, :context), do: Keyword.get(opts, :context), else: c
          {d, c}

        :error ->
          raise ArgumentError,
            "unknown sigil modifier #{inspect(key)}, " <>
              "defined modifiers: #{inspect(Keyword.keys(modifier_defs))}"
      end
    end)
  end
end
