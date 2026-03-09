defmodule GettextSigils do
  @moduledoc false
  defmacro __using__(opts) do
    {sigils_opts, gettext_opts} = Keyword.pop(opts, :sigils, [])

    quote do
      use Gettext, unquote(gettext_opts)

      import GettextSigils.Sigil

      @__gettext_sigils__ unquote(sigils_opts)
    end
  end
end
