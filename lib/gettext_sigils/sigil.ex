defmodule GettextSigils.Sigil do
  @moduledoc false

  defmacro sigil_t(ast, _modifiers) do
    {msgid, bindings} = GettextSigils.Bindings.parse!(ast)
    translate(__CALLER__, msgid, bindings)
  end

  defp translate(caller, msgid, bindings) do
    opts = Module.get_attribute(caller.module, :__gettext_sigils__)
    domain = Keyword.get(opts, :default_domain, :default)
    context = Keyword.get(opts, :default_context, nil)

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
