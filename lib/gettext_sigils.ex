defmodule GettextSigils do
  defmacro __using__(opts) do
    {domain, opts} = Keyword.pop(opts, :domain, :default)
    {context, opts} = Keyword.pop(opts, :context, nil)

    quote do
      use Gettext, unquote(opts)
      import GettextSigils.Sigil
      @__gettext_sigils_domain__ unquote(domain)
      @__gettext_sigils_context__ unquote(context)
    end
  end
end
