defmodule GettextSigils.Sigil do
  @moduledoc false

  defmacro sigil_t(ast, _modifiers) do
    {msgid, bindings} = GettextSigils.Bindings.parse!(ast)
    translate(__CALLER__, msgid, bindings)
  end

  defp translate(caller, msgid, bindings) do
    domain = Module.get_attribute(caller.module, :__gettext_sigils_domain__)
    context = Module.get_attribute(caller.module, :__gettext_sigils_context__)

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
